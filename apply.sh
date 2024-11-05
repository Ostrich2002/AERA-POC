#!/bin/bash

set -e

# Global variables
BASE_DIR="$(pwd)/terraform"
TF_COMMAND="terragrunt init && terragrunt apply -auto-approve"
CLUSTER_NAME="aera-infra-demo-gke-cluster"
REGION="us-central1"
PROJECT_ID="project-build-2bb6"

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

gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"

# Create Kubernetes secret for Crossplane GCP provider using the service account key
if [[ -f "${BASE_DIR}/0-2-sa/credentials.json" ]]; then
  kubectl create namespace crossplane-system --dry-run=client -o yaml | kubectl apply -f -
  kubectl create secret generic gcp-creds -n crossplane-system \
    --from-file=credentials.json="${BASE_DIR}/0-2-sa/credentials.json" --dry-run=client -o yaml | kubectl apply -f -
  echo "Kubernetes secret created for Crossplane."
else
  echo "Service account key not found. Skipping secret creation."
fi

# Stage 2: Argo CD
stage=2
level=1
apply_terragrunt "${BASE_DIR}/${stage}-${level}-argo-cd"  # Setup Argo CD

GKE_OUTPUTS=$(terragrunt run-all output --terragrunt-config "${BASE_DIR}/1-1-gke-cluster/terragrunt.hcl")

stage=2
level=2
apply_terragrunt "${BASE_DIR}/${stage}-${level}-crossplane"