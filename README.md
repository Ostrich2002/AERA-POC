# Terraform GCP Infra

A repository for managing Google Cloud Platform (GCP) infrastructure using Terraform. This repository contains various Terraform modules designed to automate and streamline the provisioning and management of GCP resources.

# run this command to create secret named gcp-folders-map that contains your terraform.tfvars data
kubectl create secret generic gcp-folders-map \
  --from-file=terraform.tfvars=./terraform.tfvars \
  -n crossplane-system
