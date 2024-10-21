variable "gke_cluster_name" {
  description = "The name of the GKE cluster."
  type = string
  nullable = false
}

variable "region" {
  description = "The name of the GCP region."
  type = string
  nullable = false
}
