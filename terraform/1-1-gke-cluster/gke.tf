locals {
  gke_settings = jsondecode(var.gke_settings)

  autoscaling_resource_limits = local.gke_settings.cluster_autoscaling.enabled ? concat([{
    resource_type = "cpu"
    minimum       = local.gke_settings.cluster_autoscaling.min_cpu_cores
    maximum       = local.gke_settings.cluster_autoscaling.max_cpu_cores
    }, {
    resource_type = "memory"
    minimum       = local.gke_settings.cluster_autoscaling.min_memory_gb
    maximum       = local.gke_settings.cluster_autoscaling.max_memory_gb
  }], local.gke_settings.cluster_autoscaling.gpu_resources) : []
}

data "google_container_engine_versions" "gke_version" {
  location       = local.gke_settings.region
  version_prefix = local.gke_settings.kubernetes_version
}

resource "google_service_account" "default" {
  account_id   = "service-account-id"
  display_name = "Service Account"
}

resource "google_container_cluster" "primary" {
  name                = local.gke_settings.name
  location            = local.gke_settings.regional ? local.gke_settings.region : local.gke_settings.zones[0]
  node_locations      = local.gke_settings.zones
  cluster_ipv4_cidr   = lookup(local.gke_settings, "cluster_ipv4_cidr", null)
  network             = local.gke_settings.network
  deletion_protection = local.gke_settings.deletion_protection
  min_master_version  = data.google_container_engine_versions.gke_version.valid_master_versions[0]
  initial_node_count  = lookup(local.gke_settings, "initial_node_count", 1)


  remove_default_node_pool = true


  cluster_autoscaling {
    enabled = local.gke_settings.cluster_autoscaling.enabled

    dynamic "auto_provisioning_defaults" {
      for_each = local.gke_settings.cluster_autoscaling.enabled ? [1] : []

      content {
        service_account = lookup(local.gke_settings, "service_account", google_service_account.default.email)
        oauth_scopes    = local.gke_settings.node_pools_oauth_scopes["all"]

        boot_disk_kms_key = local.gke_settings.boot_disk_kms_key

        management {
          auto_repair  = lookup(local.gke_settings.cluster_autoscaling, "auto_repair", true)
          auto_upgrade = lookup(local.gke_settings.cluster_autoscaling, "auto_upgrade", true)
        }

        disk_size = lookup(local.gke_settings.cluster_autoscaling, "disk_size", 100)
        disk_type = lookup(local.gke_settings.cluster_autoscaling, "disk_type", "pd-standard")

        upgrade_settings {
          strategy        = lookup(local.gke_settings.cluster_autoscaling, "strategy", "SURGE")
          max_surge       = lookup(local.gke_settings.cluster_autoscaling, "strategy", "SURGE") == "SURGE" ? lookup(local.gke_settings.cluster_autoscaling, "max_surge", 0) : null
          max_unavailable = lookup(local.gke_settings.cluster_autoscaling, "strategy", "SURGE") == "SURGE" ? lookup(local.gke_settings.cluster_autoscaling, "max_unavailable", 0) : null

          dynamic "blue_green_settings" {
            for_each = lookup(local.gke_settings.cluster_autoscaling, "strategy", "SURGE") == "BLUE_GREEN" ? [1] : []
            content {
              node_pool_soak_duration = lookup(local.gke_settings.cluster_autoscaling, "node_pool_soak_duration", null)

              standard_rollout_policy {
                batch_soak_duration = lookup(local.gke_settings.cluster_autoscaling, "batch_soak_duration", null)
                batch_percentage    = lookup(local.gke_settings.cluster_autoscaling, "batch_percentage", null)
                batch_node_count    = lookup(local.gke_settings.cluster_autoscaling, "batch_node_count", null)
              }
            }
          }
        }

        shielded_instance_config {
          enable_secure_boot          = lookup(local.gke_settings.cluster_autoscaling, "enable_secure_boot", false)
          enable_integrity_monitoring = lookup(local.gke_settings.cluster_autoscaling, "enable_integrity_monitoring", true)
        }


        image_type = lookup(local.gke_settings.cluster_autoscaling, "image_type", "COS_CONTAINERD")
      }
    }

    autoscaling_profile = local.gke_settings.cluster_autoscaling.autoscaling_profile != null ? local.gke_settings.cluster_autoscaling.autoscaling_profile : "BALANCED"

    dynamic "resource_limits" {
      for_each = local.autoscaling_resource_limits
      content {
        resource_type = lookup(resource_limits.value, "resource_type")
        minimum       = lookup(resource_limits.value, "minimum")
        maximum       = lookup(resource_limits.value, "maximum")
      }
    }
  }



  addons_config {
    http_load_balancing {
      disabled = !local.gke_settings.http_load_balancing.enabled
    }

    horizontal_pod_autoscaling {
      disabled = !local.gke_settings.horizontal_pod_autoscaling.enabled
    }

    network_policy_config {
      disabled = !local.gke_settings.network_policy_config.enabled
    }

    dns_cache_config {
      enabled = local.gke_settings.dns_cache_config.enabled
    }

    gcp_filestore_csi_driver_config {
      enabled = local.gke_settings.gcp_filestore_csi_driver_config.enabled
    }

    gce_persistent_disk_csi_driver_config {
      enabled = local.gke_settings.gce_persistent_disk_csi_driver_config.enabled
    }

    config_connector_config {
      enabled = local.gke_settings.config_connector_config.enabled
    }

    gke_backup_agent_config {
      enabled = local.gke_settings.gke_backup_agent_config.enabled
    }

    gcs_fuse_csi_driver_config {
      enabled = local.gke_settings.gcs_fuse_csi_driver_config.enabled
    }


    stateful_ha_config {
      enabled = local.gke_settings.stateful_ha_config.enabled
    }

    dynamic "ray_operator_config" {
      for_each = lookup(local.gke_settings.ray_operator_config, "enabled", false) ? [local.gke_settings.ray_operator_config] : []

      content {

        enabled = ray_operator_config.value.enabled

        ray_cluster_logging_config {
          enabled = ray_operator_config.value.logging_enabled
        }
        ray_cluster_monitoring_config {
          enabled = ray_operator_config.value.monitoring_enabled
        }
      }
    }
  } # End of add-ons config

}



resource "google_container_node_pool" "custom" {
  for_each = local.gke_settings.node_pools

  name     = each.value.name
  location = "us-central1"

  // use node_locations if provided, defaults to cluster level node_locations if not specified
  node_locations = lookup(each.value, "node_locations", "") != "" ? split(",", each.value["node_locations"]) : null

  cluster = google_container_cluster.primary.name

  version = google_container_cluster.primary.min_master_version

  initial_node_count = lookup(each.value, "autoscaling", true) ? lookup(
    each.value,
    "initial_node_count",
    lookup(each.value, "min_count", 1)
  ) : null

  max_pods_per_node = lookup(each.value, "max_pods", null)

  node_count = lookup(each.value, "autoscaling", true) ? null : lookup(each.value, "node_count", 1)

  dynamic "autoscaling" {
    for_each = lookup(each.value, "autoscaling", true) ? [each.value] : []
    content {
      min_node_count       = lookup(autoscaling.value, "min_count", 1)
      max_node_count       = lookup(autoscaling.value, "max_count", 100)
      location_policy      = lookup(autoscaling.value, "location_policy", null)
      total_min_node_count = lookup(autoscaling.value, "total_min_count", null)
      total_max_node_count = lookup(autoscaling.value, "total_max_count", null)
    }
  }

  dynamic "network_config" {
    for_each = length(lookup(each.value, "pod_range", "")) > 0 ? [each.value] : []
    content {
      pod_range            = lookup(network_config.value, "pod_range", null)
      enable_private_nodes = lookup(network_config.value, "enable_private_nodes", null)
    }
  }

  management {
    auto_repair  = lookup(each.value, "auto_repair", true)
    auto_upgrade = lookup(each.value, "auto_upgrade", true)
  }

  upgrade_settings {
    strategy        = lookup(each.value, "strategy", "SURGE")
    max_surge       = lookup(each.value, "strategy", "SURGE") == "SURGE" ? lookup(each.value, "max_surge", 1) : null
    max_unavailable = lookup(each.value, "strategy", "SURGE") == "SURGE" ? lookup(each.value, "max_unavailable", 0) : null

    dynamic "blue_green_settings" {
      for_each = lookup(each.value, "strategy", "SURGE") == "BLUE_GREEN" ? [1] : []
      content {
        node_pool_soak_duration = lookup(each.value, "node_pool_soak_duration", null)

        standard_rollout_policy {
          batch_soak_duration = lookup(each.value, "batch_soak_duration", null)
          batch_percentage    = lookup(each.value, "batch_percentage", null)
          batch_node_count    = lookup(each.value, "batch_node_count", null)
        }
      }
    }
  }


  dynamic "queued_provisioning" {
    for_each = lookup(each.value, "queued_provisioning", false) ? [true] : []
    content {
      enabled = lookup(each.value, "queued_provisioning", null)
    }
  }

  node_config {
    preemptible                 = lookup(each.value, "preemptible", false)
    spot                        = lookup(each.value, "spot", false)
    image_type                  = lookup(each.value, "image_type", "COS_CONTAINERD")
    machine_type                = lookup(each.value, "machine_type", "e2-medium")
    min_cpu_platform            = lookup(each.value, "min_cpu_platform", "")
    enable_confidential_storage = lookup(each.value, "enable_confidential_storage", false)
    local_ssd_count             = lookup(each.value, "local_ssd_count", 0)
    disk_size_gb                = lookup(each.value, "disk_size_gb", 100)
    disk_type                   = lookup(each.value, "disk_type", "pd-standard")
    logging_variant             = lookup(each.value, "logging_variant", "DEFAULT")
    boot_disk_kms_key           = lookup(each.value, "boot_disk_kms_key", "")


    dynamic "gcfs_config" {
      for_each = lookup(each.value, "enable_gcfs", false) ? [true] : []
      content {
        enabled = gcfs_config.value
      }
    }

    dynamic "gvnic" {
      for_each = lookup(each.value, "enable_gvnic", false) ? [true] : []
      content {
        enabled = gvnic.value
      }
    }

    dynamic "reservation_affinity" {
      for_each = lookup(each.value, "queued_provisioning", false) || lookup(each.value, "consume_reservation_type", "") != "" ? [each.value] : []
      content {
        consume_reservation_type = lookup(reservation_affinity.value, "queued_provisioning", false) ? "NO_RESERVATION" : lookup(reservation_affinity.value, "consume_reservation_type", null)
        key                      = lookup(reservation_affinity.value, "reservation_affinity_key", null)
        values                   = lookup(reservation_affinity.value, "reservation_affinity_values", null) == null ? null : [for s in split(",", lookup(reservation_affinity.value, "reservation_affinity_values", null)) : trimspace(s)]
      }
    }


    dynamic "taint" {
      for_each = lookup(each.value, "node_taints", null) == null ? [each.value.node_taints] : []
      content {
        effect = taint.value.effect
        key    = taint.value.key
        value  = taint.value.value
      }
    }

    # tags = {}

    dynamic "ephemeral_storage_local_ssd_config" {
      for_each = lookup(each.value, "local_ssd_ephemeral_storage_count", 0) > 0 ? [each.value.local_ssd_ephemeral_storage_count] : []
      content {
        local_ssd_count = ephemeral_storage_local_ssd_config.value
      }
    }

    dynamic "local_nvme_ssd_block_config" {
      for_each = lookup(each.value, "local_nvme_ssd_count", 0) > 0 ? [each.value.local_nvme_ssd_count] : []
      content {
        local_ssd_count = local_nvme_ssd_block_config.value
      }
    }

    # Supports a single secondary boot disk because `map(any)` must have the same values type.
    dynamic "secondary_boot_disks" {
      for_each = lookup(each.value, "secondary_boot_disk", "") != "" ? [each.value.secondary_boot_disk] : []
      content {
        disk_image = secondary_boot_disks.value
        mode       = "CONTAINER_IMAGE_CACHE"
      }
    }

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = lookup(
      each.value,
      "service_account",
      google_service_account.default.email,
    )

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]


    dynamic "guest_accelerator" {
      for_each = lookup(each.value, "accelerator_count", 0) > 0 ? [1] : []
      content {
        type               = lookup(each.value, "accelerator_type", "")
        count              = lookup(each.value, "accelerator_count", 0)
        gpu_partition_size = lookup(each.value, "gpu_partition_size", null)

        dynamic "gpu_driver_installation_config" {
          for_each = lookup(each.value, "gpu_driver_version", "") != "" ? [1] : []
          content {
            gpu_driver_version = lookup(each.value, "gpu_driver_version", "")
          }
        }

        dynamic "gpu_sharing_config" {
          for_each = lookup(each.value, "gpu_sharing_strategy", "") != "" ? [1] : []
          content {
            gpu_sharing_strategy       = lookup(each.value, "gpu_sharing_strategy", "")
            max_shared_clients_per_gpu = lookup(each.value, "max_shared_clients_per_gpu", 2)
          }
        }
      }
    }

    dynamic "advanced_machine_features" {
      for_each = lookup(each.value, "threads_per_core", 0) > 0 || lookup(each.value, "enable_nested_virtualization", false) ? [1] : []
      content {
        threads_per_core             = lookup(each.value, "threads_per_core", 0)
        enable_nested_virtualization = lookup(each.value, "enable_nested_virtualization", null)
      }
    }

    shielded_instance_config {
      enable_secure_boot          = lookup(each.value, "enable_secure_boot", false)
      enable_integrity_monitoring = lookup(each.value, "enable_integrity_monitoring", true)
    }

  }

  lifecycle {
    ignore_changes = [initial_node_count]

  }

  #   timeouts {
  #     create = lookup(var.timeouts, "create", "45m")
  #     update = lookup(var.timeouts, "update", "45m")
  #     delete = lookup(var.timeouts, "delete", "45m")
  #   }


}
