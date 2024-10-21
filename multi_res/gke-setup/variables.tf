# variables.tf
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
  default     = "us-central1"  # You can override this in the .tfvars file
}

variable "service_account_id" {
  description = "The ID for the new service account to be created."
  type        = string
  default     = "crossplane-sa"  # You can set this as a default or override in terraform.tfvars
}

variable "existing_service_account_email" {
  description = "The email of the existing service account to use."
  type        = string
}

variable "service_account_key_file" {
  description = "The file path of the existing service account key."
  type        = string
}
