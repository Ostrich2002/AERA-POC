data "google_container_cluster" "this" {
  name     = var.gke_cluster_name
  location = var.region
}

data "google_client_config" "this" {

}

provider "helm" {
  kubernetes {
    host  = "https://${data.google_container_cluster.this.endpoint}"
    token = data.google_client_config.this.access_token
    cluster_ca_certificate = base64decode(
    data.google_container_cluster.this.master_auth[0].cluster_ca_certificate, )
    # exec {
    #   api_version = "client.authentication.k8s.io/v1beta1"
    #   command     = "gke-gcloud-auth-plugin"
    # }
  }
}

provider "kubernetes" {
  host  = "https://${data.google_container_cluster.this.endpoint}"
  token = data.google_client_config.this.access_token
  cluster_ca_certificate = base64decode(
  data.google_container_cluster.this.master_auth[0].cluster_ca_certificate, )
  # exec {
  #   api_version = "client.authentication.k8s.io/v1beta1"
  #   command     = "gke-gcloud-auth-plugin"
  # }
}

provider "kustomization" {
  kubeconfig_raw = <<-EOT
        apiVersion: v1
        clusters:
        - cluster:
            certificate-authority-data: ${data.google_container_cluster.this.master_auth[0].cluster_ca_certificate}
            server: https://${data.google_container_cluster.this.endpoint}
          name: gke
        contexts:
        - context:
            cluster: gke
            user: gke
          name: gke
        current-context: gke
        kind: Config
        preferences: {}
        users:
        - name: gke
          user:
            token: ${data.google_client_config.this.access_token}
        EOT
}


# Ingress Nginx, Link - https://kubernetes.github.io/ingress-nginx/deploy/#quick-start
resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.11.1"
  namespace        = "ingress-nginx"
  create_namespace = true

}

data "kustomization_build" "argocd" {
  path = "${path.module}/../../deployments/argocd-ha"
}


# Create argocd namespace and other priority resources
resource "kustomization_resource" "namespace" {
  for_each = data.kustomization_build.argocd.ids_prio[0]

  manifest = data.kustomization_build.argocd.manifests[each.value]

}

# Install argicd ha resources
resource "kustomization_resource" "argocd" {
  for_each = setunion(data.kustomization_build.argocd.ids_prio[1], data.kustomization_build.argocd.ids_prio[2])

  manifest = data.kustomization_build.argocd.manifests[each.value]

  depends_on = [
    helm_release.nginx_ingress,
    kustomization_resource.namespace
  ]

}
