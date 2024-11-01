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

# Stage 2: Crossplane (only if GKE outputs are available)
# Check for multiple GKE outputs
# if terragrunt run-all output --terragrunt-config "${BASE_DIR}/1-1-gke-cluster/terragrunt.hcl" | grep -q "endpoint" && \
#    terragrunt run-all output --terragrunt-config "${BASE_DIR}/1-1-gke-cluster/terragrunt.hcl" | grep -q "access_token" && \
#    terragrunt run-all output --terragrunt-config "${BASE_DIR}/1-1-gke-cluster/terragrunt.hcl" | grep -q "cluster_ca_certificate" && \
#    terragrunt run-all output --terragrunt-config "${BASE_DIR}/1-1-gke-cluster/terragrunt.hcl" | grep -q "cluster_name" && \
#    terragrunt run-all output --terragrunt-config "${BASE_DIR}/1-1-gke-cluster/terragrunt.hcl" | grep -q "kubeconfig"; then
#   echo "All required GKE outputs found. Proceeding with Crossplane installation."


#   stage=2
#   level=2
#   apply_terragrunt "${BASE_DIR}/${stage}-${level}-crossplane"  # Setup Crossplane
# else
#   echo "One or more required GKE outputs not found. Skipping Crossplane installation."
# fi


GKE_OUTPUTS=$(terragrunt run-all output --terragrunt-config "${BASE_DIR}/1-1-gke-cluster/terragrunt.hcl")

# if [[ "$(echo "$GKE_OUTPUTS" | grep -q "endpoint")" && \
#       "$(echo "$GKE_OUTPUTS" | grep -q "access_token")" && \
#       "$(echo "$GKE_OUTPUTS" | grep -q "cluster_ca_certificate")" ]]; then
#     echo "All required GKE outputs found. Proceeding with Crossplane installation."
#     apply_terragrunt "${BASE_DIR}/2-2-crossplane"
# else
#     echo "One or more required GKE outputs not found. Skipping Crossplane installation."
# fi

stage=2
level=2
apply_terragrunt "${BASE_DIR}/${stage}-${level}-crossplane"