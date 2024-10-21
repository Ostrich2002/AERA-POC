gke_settings =  {
  name                     = "aera-infra-demo-gke-cluster"
  kubernetes_version       = "1.29.7"
  regional                 = true
  region                   = "us-central1"
  zones                    = ["us-central1-a", "us-central1-b", "us-central1-c"]
  network                  = "aera-infra-demo-vpc01"
  ip_range_pods            = "us-central1-01-gke-01-pods"
  ip_range_services        = "us-central1-01-gke-01-services"
  remove_default_node_pool = true
  deletion_protection      = false
  boot_disk_kms_key        = null
  initial_node_count       = 1


  http_load_balancing = {
    enabled = false
  }

  horizontal_pod_autoscaling = {
    enabled = true
  }

  network_policy_config = {
    enabled = false
  }

  dns_cache_config = {
    enabled = false
  }

  gcp_filestore_csi_driver_config = {
    enabled = false
  }

  gce_persistent_disk_csi_driver_config = {
    enabled = false
  }

  config_connector_config = {
    enabled = false
  }

  gke_backup_agent_config = {

    enabled = false
  }

  gcs_fuse_csi_driver_config = {
    enabled = false
  }

  stateful_ha_config = {
    enabled = false
  }

  ray_operator_config = {
    enabled            = false,
    logging_enabled    = false,
    monitoring_enabled = false
  }

  cluster_autoscaling = {
    enabled                     = false
    autoscaling_profile         = "BALANCED"
    min_cpu_cores               = 0
    max_cpu_cores               = 0
    min_memory_gb               = 0
    max_memory_gb               = 0
    gpu_resources               = []
    auto_repair                 = true
    auto_upgrade                = true
    disk_size                   = 100
    disk_type                   = "pd-standard"
    image_type                  = "COS_CONTAINERD"
    strategy                    = "SURGE"
    max_surge                   = "0"
    max_unavailable             = "0"
    node_pool_soak_duration     = "5s"
    batch_soak_duration         = "5s"
    batch_percentage            = "0.5"
    batch_node_count            = "0"
    enable_secure_boot          = false
    enable_integrity_monitoring = true
  }


  node_pools = {
    core-1 = {
      name               = "coresvcs1"
      machine_type       = "e2-medium"
      node_locations     = "us-central1-a,us-central1-b"
      node_count         = 1
      initial_node_count = 1
      min_count          = 1
      max_count          = 3
      max_pods           = 50
      local_ssd_count    = 0
      spot               = false
      disk_size_gb       = 40
      disk_type          = "pd-standard"
      image_type         = "UBUNTU_CONTAINERD"
      enable_gcfs        = false
      enable_gvnic       = false
      logging_variant    = "DEFAULT"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = false
      autoscaling        = true

      # accelerator_count           = 1
      # accelerator_type            = "nvidia-l4"
      # gpu_driver_version          = "LATEST"
      # gpu_sharing_strategy        = "TIME_SHARING"
      # max_shared_clients_per_gpu = 2

      node_taints = []
      node_labels = {
        "groupname" = "core-services"
      }
    },
    core-2 = {
      name               = "coresvcs2"
      machine_type       = "e2-medium"
      node_locations     = "us-central1-a,us-central1-b"
      node_count         = 1
      initial_node_count = 1
      min_count          = 1
      max_count          = 3
      max_pods           = 10
      local_ssd_count    = 0
      spot               = false
      disk_size_gb       = 40
      disk_type          = "pd-standard"
      image_type         = "UBUNTU_CONTAINERD"
      enable_gcfs        = false
      enable_gvnic       = false
      logging_variant    = "DEFAULT"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = false
      autoscaling        = true

      # accelerator_count           = 1
      # accelerator_type            = "nvidia-l4"
      # gpu_driver_version          = "LATEST"
      # gpu_sharing_strategy        = "TIME_SHARING"
      # max_shared_clients_per_gpu = 2

      node_taints = []
      node_labels = {
        "groupname" = "core-services"
      }
    },

  }

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  tags = {}

}
