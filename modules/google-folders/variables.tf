variable "org_id" {
  description = "Organization ID"
  type        = string
}

variable "folder_map" {
  description = "Map of folders to create under the organization."
  type        = any
}

variable "billing_account" {
  description = "Billing account ID for GCP projects."
  type        = string
}

variable "project_permissions" {
  description = "Roles to assign to a service account or user for each project."
  type        = list(string)
  default     = ["roles/viewer", "roles/editor"]  # Adjust as needed
}

variable "project_owners" {
  description = "List of owners for each project."
  type        = list(string)
}

variable "admin_project_id" {
  description = "Existing project ID for Terraform to use as its base project."
  type        = string
}
