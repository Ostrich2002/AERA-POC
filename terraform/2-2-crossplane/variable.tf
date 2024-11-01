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

variable "host" {}
variable "token" {}
variable "cluster_ca_certificate" {}
