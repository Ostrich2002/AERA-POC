output "endpoint" {
  value = google_container_cluster.primary.endpoint
}

data "google_client_config" "default" {}

output "access_token" {
  value = data.google_client_config.default.access_token
  sensitive = true

}

output "cluster_ca_certificate" {
  value = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
}

output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "kubeconfig" {
  value = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
}