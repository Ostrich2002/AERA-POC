resource "google_compute_firewall" "icmp" {
  name    = "icmp-allow-all-aera-demo"
  network = var.vpc_name

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}
