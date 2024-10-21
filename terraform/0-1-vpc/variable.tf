variable "vpc_name" {
  description = "The name of the VPC network."
  type = string
  nullable = false
}

variable "region" {
  description = "The name of the GCP region."
  type = string
  nullable = false
}


#new changes
variable "subnets" {
  description = "List of subnets to create within the VPC."
  type = list(object({
    name          = string
    ip_cidr_range = string
    region        = string
  }))
  nullable = false
}

