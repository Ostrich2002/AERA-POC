# provider "helm" {
#   kubernetes {
#     host                   = "https://${dependency.gke-cluster.outputs.endpoint}"
#     token                  = dependency.gke-cluster.outputs.access_token
#     cluster_ca_certificate = base64decode(dependency.gke-cluster.outputs.cluster_ca_certificate)
#   }
# }

provider "helm" {
  kubernetes {
    host                   = "https://${var.host}"
    token                  = var.token
    cluster_ca_certificate = var.cluster_ca_certificate
  }
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

# Optional: Crossplane GCP Provider Configuration
resource "helm_release" "provider_gcp" {
  depends_on       = [helm_release.crossplane]
  name             = "provider-gcp"
  repository       = "https://charts.crossplane.io/stable"
  chart            = "provider-gcp"
  namespace        = var.namespace
  version          = var.provider_gcp_chart_version

  values = [
    <<EOF
      credentials:
        secretRef:
          namespace: ${var.namespace}
          name: gcp-creds
          key: credentials.json
    EOF
  ]
}

