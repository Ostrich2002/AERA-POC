variable "project" {
  description = "The Id of the GCP project."
  type = string
  nullable = false
}

variable "service_account_id" {
  type = string
  nullable = false
}
