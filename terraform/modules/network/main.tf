# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.project_name}-${var.environment}-vpc"
  auto_create_subnetworks = false
  
  project = var.project_id
}

# Subnets
resource "google_compute_subnetwork" "public_subnet" {
  name          = "${var.project_name}-${var.environment}-public-subnet"
  ip_cidr_range = var.subnets["public"].cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "private_subnet" {
  name          = "${var.project_name}-${var.environment}-private-subnet"
  ip_cidr_range = var.subnets["private"].cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Firewall Rules
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_name}-${var.environment}-allow-internal"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [var.vpc_cidr]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-${var.environment}-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh", "allow-ssh"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "${var.project_name}-${var.environment}-allow-http"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "3000", "8000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}
