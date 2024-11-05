include {
  path = find_in_parent_folders()
}

# Define the dependency on the GKE cluster setup
dependency "gke-cluster" {
  config_path = "../1-1-gke-cluster"
}


inputs = {
  gke_cluster_name            = dependency.gke-cluster.outputs.cluster_name
  region                      = "us-central1"
  namespace                  = "crossplane-system"
  crossplane_chart_version   = "1.17"
}
