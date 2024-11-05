data "google_container_cluster" "this" {
  name     = var.gke_cluster_name
  location = var.region
}

data "google_client_config" "this" {}

provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.this.endpoint}"
    token                  = data.google_client_config.this.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.this.master_auth[0].cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.this.endpoint}"
  token                  = data.google_client_config.this.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.this.master_auth[0].cluster_ca_certificate)
}


# Install Crossplane using Helm
resource "helm_release" "crossplane" {
  name             = "crossplane"
  repository       = "https://charts.crossplane.io/stable"
  chart            = "crossplane"
  namespace        = var.namespace
  create_namespace = true
  version          = var.crossplane_chart_version

  values = [
    <<EOF
      provider:
        aws:
          enabled: false
        gcp:
          enabled: true
    EOF
  ]
}