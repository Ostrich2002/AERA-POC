/*locals {
  inputs_from_tfvars = jsondecode(read_tfvars_file("${path_relative_from_include()}/gke_settings.tfvars"))
  project       = "supply-chain-twin-349311"
  region        = "us-central1"
  state_bucket  = "aera-infra-tf-state-${local.project}"
  environment   = "build"
}*/

locals {
  # Read tfvars file for other settings
  inputs_from_tfvars = jsondecode(read_tfvars_file("${path_relative_from_include()}/gke_settings.tfvars"))

  # Project and environment settings
  project       = "supply-chain-twin-349311"
  region        = "us-central1"
  state_bucket  = "aera-infra-tf-state-${local.project}"
  environment   = "build"
  
  # VPC and subnet settings (assuming these might also be read from a tfvars file or defined here)
  vpc_settings = {
    vpc_name = "aera-infra-demo-vpc01"
    subnets  = [
      {
        name          = "subnet1"
        ip_cidr_range = "10.0.0.0/24"
        region        = local.region
      },
      {
        name          = "subnet2"
        ip_cidr_range = "10.0.1.0/24"
        region        = local.region
      }
    ]
  }
}


/*inputs =   {
  gke_settings = local.inputs_from_tfvars.gke_settings
  project             = local.project
  region              = local.region
  gke_cluster_name  = local.inputs_from_tfvars.gke_settings.name
  vpc_name            = "aera-infra-demo-vpc01"
  service_account_id  = "aera-infra-demo-sa"
}*/

inputs = {
  # Existing inputs
  gke_settings       = local.inputs_from_tfvars.gke_settings
  project            = local.project
  region             = local.region
  gke_cluster_name   = local.inputs_from_tfvars.gke_settings.name
  service_account_id = "aera-infra-demo-sa"

  # New inputs for VPC and subnets
  vpc_name = local.vpc_settings.vpc_name
  subnets  = local.vpc_settings.subnets
}




remote_state {
  backend = "gcs"

  generate = {
    path      = "tg_backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket    = "${local.state_bucket}"
    prefix    = "${local.region}/${local.environment}/${path_relative_to_include()}"
    project   = "${local.project}"
    location  = "${local.region}"
 }
}

generate "provider" {
  path      = "tg_provider.tf"
  if_exists = "overwrite_terragrunt"

  contents  = <<-EOF
  terraform {
    required_providers {
      google = {
        source  = "hashicorp/google"
        version = "5.39.0"
      }
      kustomization = {
        source  = "kbst/kustomization"
        version = "0.9.0"
      }
    }
  }

  provider "google" {
    project = "${local.project}"
    region  = "${local.region}"

    default_labels = {
      terraform   = true
      region      = "${local.region}"
      aera-owner  = "devops"
      env         = "${local.environment}"
    }
  }

  EOF
}
