#!/bin/bash

set -e

# Global variables
BASE_DIR="$(pwd)/terraform"
TF_COMMAND="terragrunt init && terragrunt destroy -auto-approve"

# Function to run Terragrunt for a given stage and level
destroy_terragrunt() {
  local dir="$1"

  if [[ -d "$dir" ]]; then
    echo "Running Terragrunt in directory: $dir"
    cd "$dir" || exit
    eval $TF_COMMAND
  else
    echo "Directory $dir does not exist. Skipping ..."
  fi
}


# Stage 2: Argo CD
stage=2
level=1
destroy_terragrunt "${BASE_DIR}/${stage}-${level}-argo-cd"  # Destroy Argo CD

# Stage 1: GKE Cluster
stage=1
level=1
destroy_terragrunt "${BASE_DIR}/${stage}-${level}-gke-cluster"  # Destroy GKE cluster

# Stage 0: VPC, Service Accounts, Firewall Rules
stage=0
level=3
destroy_terragrunt "${BASE_DIR}/${stage}-${level}-firewall"  # Destroy firewall rules

level=2
destroy_terragrunt "${BASE_DIR}/${stage}-${level}-sa"  # Destroy Service Account(s)

level=1
destroy_terragrunt "${BASE_DIR}/${stage}-${level}-vpc"  # Destroy VPC
