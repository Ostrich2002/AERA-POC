#!/bin/bash

set -e

# Global variables
BASE_DIR="$(pwd)/terraform"
TF_COMMAND="terragrunt init && terragrunt apply -auto-approve"

# Function to run Terragrunt for a given stage and level
apply_terragrunt() {
  local dir="$1"

  if [[ -d "$dir" ]]; then
    echo "Running Terragrunt in directory: $dir"
    cd "$dir" || exit
    eval $TF_COMMAND
  else
    echo "Directory $dir does not exist. Skipping ..."
  fi
}

# Stage 0: VPC, Service Accounts, Firewall Rules
stage=0
level=1
apply_terragrunt "${BASE_DIR}/${stage}-${level}-vpc"  # Create VPC

level=2
apply_terragrunt "${BASE_DIR}/${stage}-${level}-sa"  # Create Service Account(s)

level=3
apply_terragrunt "${BASE_DIR}/${stage}-${level}-firewall"  # Setup firewall rules

# Stage 1: GKE Cluster
stage=1
level=1
apply_terragrunt "${BASE_DIR}/${stage}-${level}-gke-cluster"  # Setup GKE cluster

# Stage 2: Argo CD
stage=2
level=1
apply_terragrunt "${BASE_DIR}/${stage}-${level}-argo-cd"  # Setup Argo CD
