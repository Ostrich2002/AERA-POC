# vpc
resource "google_compute_network" "vpc" {
  name = var.vpc_name
}

# Subnet
# resource "google_compute_subnetwork" "subnet" {
#   name          = "${var.vpc_name}-subnet"
#   ip_cidr_range = "10.0.0.0/16"
#   region        = var.region
#   network       = google_compute_network.vpc.name
# }


resource "google_compute_subnetwork" "subnet" {
  count         = length(var.subnets)
  name          = "${var.vpc_name}-${var.subnets[count.index].name}"
  ip_cidr_range = var.subnets[count.index].ip_cidr_range
  region        = var.subnets[count.index].region
  network       = google_compute_network.vpc.name
}

