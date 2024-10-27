# variable "org_id" {
#   type        = string
#   description = "The Organization Id "
# }

# variable "folder_map" {
#   type        = any
#   description = "Folder structure as a map"
# }


# #new addition for projects
# variable "billing_account_id" {
#   type = string
#   description = "Billing account ID for project creation"
# }

# variable "project_owner_email" {
#   type = string
#   description = "Email of the project owner for IAM"
# }

# variable "billing_account_user_email" {
#   description = "The user email to be assigned billing permissions."
#   type        = string
# }



#--------------------NEW APPROACH--------------------------------------
variable "org_id" {
  description = "Organization ID"
  type        = string
}

variable "folder_map" {
  description = "Map of folders to create under the organization."
  type        = map(map(map(any)))
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
