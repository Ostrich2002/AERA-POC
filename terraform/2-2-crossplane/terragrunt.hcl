include {
  path = find_in_parent_folders()
}

# Define the dependency on the GKE cluster setup
dependency "gke-cluster" {
  config_path = "../1-1-gke-cluster"
}

/*inputs = {
  namespace                  = "crossplane-system"
  crossplane_chart_version   = "1.17"
  provider_gcp_chart_version = "1.0.1"

  endpoint                = dependency.gke-cluster.outputs.endpoint
  access_token            = dependency.gke-cluster.outputs.access_token
  cluster_ca_certificate  = dependency.gke-cluster.outputs.cluster_ca_certificate
  cluster_name            = dependency.gke-cluster.outputs.cluster_name
  kubeconfig              = dependency.gke-cluster.outputs.kubeconfig
}*/

inputs = {
  namespace                  = "crossplane-system"
  crossplane_chart_version   = "1.17"
  provider_gcp_chart_version = "1.0.1"
  
  # Passing GKE Outputs as Variables to Crossplane
  host                   = "https://${dependency.gke-cluster.outputs.endpoint}"
  token                  = dependency.gke-cluster.outputs.access_token
  cluster_ca_certificate = base64decode(dependency.gke-cluster.outputs.cluster_ca_certificate)
}
