#!/bin/bash

set -e

# Global variables
BASE_DIR="$(pwd)/terraform"
TF_COMMAND="terragrunt init && terragrunt destroy -auto-approve"
CLUSTER_NAME="aera-infra-demo-gke-cluster"
REGION="us-central1"
PROJECT_ID="project-build-2bb6"

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

gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"

# Stage 2: Crossplane
stage=2
level=2
destroy_terragrunt "${BASE_DIR}/${stage}-${level}-crossplane"

# # Destroy Crossplane only if GKE outputs are available
# if terragrunt output-all --terragrunt-config "${BASE_DIR}/1-1-gke-cluster/terragrunt.hcl" | grep -q "endpoint" && \
#    terragrunt output-all --terragrunt-config "${BASE_DIR}/1-1-gke-cluster/terragrunt.hcl" | grep -q "access_token" && \
#    terragrunt output-all --terragrunt-config "${BASE_DIR}/1-1-gke-cluster/terragrunt.hcl" | grep -q "cluster_ca_certificate" && \
#    terragrunt output-all --terragrunt-config "${BASE_DIR}/1-1-gke-cluster/terragrunt.hcl" | grep -q "cluster_name" && \
#    terragrunt output-all --terragrunt-config "${BASE_DIR}/1-1-gke-cluster/terragrunt.hcl" | grep -q "kubeconfig"; then
#     echo "GKE outputs found. Proceeding with Crossplane destruction."
#     destroy_terragrunt "${BASE_DIR}/${stage}-${level}-crossplane"
# else
#     echo "GKE outputs not found. Skipping Crossplane destruction."
# fi

# Stage 2: Argo CD
stage=2
level=1
destroy_terragrunt "${BASE_DIR}/${stage}-${level}-argo-cd"  # Destroy Argo CD

# Delete Kubernetes secret for Crossplane GCP provider
kubectl delete secret gcp-creds -n crossplane-system --ignore-not-found
kubectl delete namespace crossplane-system --ignore-not-found
echo "Kubernetes secret and namespace deleted for Crossplane."

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
