resource "local_file" "gke_sa_credentials" {
  depends_on         = [google_service_account_key.gke_sa_key]
  content            = google_service_account_key.gke_sa_key.private_key
  filename           = "${path.module}/credentials.json"
}
