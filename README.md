# Setup GCP Lending Zone Using Terraform
This guide outlines the process of setting up a GCP Lending Zone using Terraform, an infrastructure as code tool. The Lending Zone includes essential networking, security, and foundational resources in GCP, necessary for deploying and managing cloud environments. By leveraging Terraform and Terragrunt, you'll create and manage these resources efficiently, ensuring a consistent and scalable infrastructure setup.


## Prerequisites
Before you begin, ensure you have the following tools installed and configured on your machine:

1. **Install Terraform**
  - Terraform is an open-source infrastructure as code software tool that provides a consistent CLI workflow to manage hundreds of cloud services.
  - Installation instructions can be found on the [Terraform website](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).

2. **Install Terragrunt**
  - Terragrunt is a thin wrapper for Terraform that provides extra tools for keeping your configurations DRY, managing remote state, and working with modules.
  - Installation instructions are available on the [Terragrunt website](https://terragrunt.gruntwork.io/docs/getting-started/install/).

3. **Initialize Google Cloud SDK (`gcloud`)**
  - The Google Cloud SDK provides the gcloud CLI tool that allows you to manage Google Cloud resources.
  - Run `gcloud init` to initialize the SDK and authenticate with your Google Cloud account. This will also set up the default project, region, and zone.
  - Instructions can be found in the [Google Cloud SDK documentation](https://cloud.google.com/sdk/docs/initializing).

## Configure variables
- Update the `gke_settings.tfvars` and `terragrunt.hcl` file to customize the setup according to your environment.
- Variables typically include:
  - `project`: Your GCP project ID.
  - `region`: The region where your resources will be deployed.
  - `zone`: The zone within the region.

## Create GCP resources

```
./apply.sh
```

## Delete GCP resources
```
./destroy.sh
```
