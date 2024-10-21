provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.service_account_key_file)
}

# -------------------------------
# VPC and Subnet Configuration
# -------------------------------

resource "google_compute_network" "vpc_network" {
  name                    = "crossplane-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "crossplane-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc_network.self_link
}

# -------------------------------
# Firewall Rules
# -------------------------------

resource "google_compute_firewall" "internal" {
  name    = "crossplane-allow-internal"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["10.0.0.0/16"]
}

resource "google_compute_firewall" "external" {
  name    = "crossplane-allow-external"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "443", "6443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# -------------------------------
# GKE Cluster Configuration
# -------------------------------

resource "google_container_cluster" "primary" {
  name               = "crossplane-gke-cluster"
  location           = var.region
  initial_node_count = 3
  deletion_protection = false
  network            = google_compute_network.vpc_network.name
  subnetwork         = google_compute_subnetwork.subnet.name

  node_config {
    machine_type = "n1-standard-2"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

resource "google_container_node_pool" "primary_nodes" {
  cluster    = google_container_cluster.primary.name
  location   = google_container_cluster.primary.location
  node_count = 2

  node_config {
    machine_type = "n1-standard-2"
  }
}

# -------------------------------
# IAM Role Assignments for Existing Service Account
# -------------------------------

resource "google_project_iam_member" "crossplane_sa_container_admin" {
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${var.existing_service_account_email}"
}

resource "google_project_iam_member" "crossplane_sa_network_admin" {
  project = var.project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${var.existing_service_account_email}"
}

resource "google_project_iam_member" "crossplane_sa_storage" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${var.existing_service_account_email}"
}

resource "google_project_iam_member" "crossplane_sa_iam_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${var.existing_service_account_email}"
}

resource "google_project_iam_member" "crossplane_sa_logging_admin" {
  project = var.project_id
  role    = "roles/logging.admin"
  member  = "serviceAccount:${var.existing_service_account_email}"
}

resource "google_project_iam_member" "crossplane_sa_monitoring_admin" {
  project = var.project_id
  role    = "roles/monitoring.admin"
  member  = "serviceAccount:${var.existing_service_account_email}"
}

# -------------------------------
# Install Crossplane and Helm
# -------------------------------

resource "null_resource" "install_crossplane" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${google_container_cluster.primary.location}

      while true; do
          STATUS=$(gcloud container clusters describe ${google_container_cluster.primary.name} --region ${google_container_cluster.primary.location} --format="value(status)")
          if [ "$STATUS" == "RUNNING" ]; then
              echo "Cluster is running"
              break
          else
              echo "Waiting for cluster to be ready... Current status: $STATUS"
              sleep 15
          fi
      done

      curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
      helm repo add crossplane-stable https://charts.crossplane.io/stable
      helm repo update
      helm install crossplane crossplane-stable/crossplane --namespace crossplane-system --create-namespace
      kubectl apply -f provider-gcp-storage.yaml
    EOT
  }

  depends_on = [
    google_container_cluster.primary,
    google_container_node_pool.primary_nodes,
    google_project_iam_member.crossplane_sa_container_admin,
    google_project_iam_member.crossplane_sa_network_admin,
    google_project_iam_member.crossplane_sa_storage,
    google_project_iam_member.crossplane_sa_iam_sa_user,
    google_project_iam_member.crossplane_sa_logging_admin,
    google_project_iam_member.crossplane_sa_monitoring_admin
  ]
}
