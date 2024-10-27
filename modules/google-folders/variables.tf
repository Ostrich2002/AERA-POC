variable "org_id" {
  type        = string
  description = "The Organization Id "
}

variable "folder_map" {
  type        = any
  description = "Folder structure as a map"
}


#new addition for projects
variable "billing_account_id" {
  type = string
  description = "Billing account ID for project creation"
}

variable "project_owner_email" {
  type = string
  description = "Email of the project owner for IAM"
}

variable "billing_account_user_email" {
  description = "The user email to be assigned billing permissions."
  type        = string
}