resource "google_service_account" "gke_sa" {
  account_id   = var.service_account_id
  display_name = "GKE Service Account"
}

# Assign roles to the service account
resource "google_project_iam_member" "gke_sa_container_admin" {
  project = var.project
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_project_iam_member" "gke_sa_network_admin" {
  project = var.project
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_project_iam_member" "gke_sa_iam_sa_user" {
  project = var.project
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_service_account_key" "gke_sa_key" {
  service_account_id = google_service_account.gke_sa.id
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}


# Output the path where the key is stored
output "gke_sa_key_path" {
  value = google_service_account_key.gke_sa_key.private_key
  sensitive = true
}