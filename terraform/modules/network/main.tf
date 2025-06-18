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

# Regla de firewall para microservicios con acceso externo completo
resource "google_compute_firewall" "allow_microservices_external" {
  name    = "${var.project_name}-${var.environment}-allow-microservices-external"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = [
      "80",    # Nginx Dashboard
      "443",   # HTTPS
      "8080",  # API Gateway
      "8761",  # Eureka Service Discovery
      "9411",  # Zipkin Tracing
      "9296",  # Config Server
      "8300",  # Order Service
      "8400",  # Payment Service
      "8500",  # Product Service
      "8600",  # Shipping Service
      "8700",  # User Service
      "8800",  # Favourite Service
      "8900",  # Proxy Client
      "8888"   # Jenkins
    ]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["microservices", "web-server", "http-server"]
  
  description = "Allow external access to all microservices ports"
}
