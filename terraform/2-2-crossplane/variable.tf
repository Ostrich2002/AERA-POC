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

variable "namespace" {
  description = "Namespace in which to install Crossplane"
  type        = string
  default     = "crossplane-system"
}

variable "crossplane_chart_version" {
  description = "Version of the Crossplane Helm chart"
  type        = string
  default     = "1.11.1"  # Ensure this matches the version in crossplane.tf
}

variable "provider_gcp_chart_version" {
  description = "Version of the GCP provider chart for Crossplane"
  type        = string
  default     = "0.21.1"  # Ensure this matches the version in crossplane.tf
}

variable "host" {
  type    = string
  default = ""
}

variable "token" {
  type    = string
  default = ""
}

variable "cluster_ca_certificate" {
  type    = string
  default = ""
}
