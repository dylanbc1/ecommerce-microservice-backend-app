# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "${var.project_name}-${var.environment}-gke"
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network_id
  subnetwork = var.subnet_id

  # Configuration for network policy
  network_policy {
    enabled = true
  }

  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Resource labels
  resource_labels = var.tags
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.project_name}-${var.environment}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    preemptible  = true
    machine_type = var.machine_type

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gke_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = var.tags

    tags = ["${var.environment}-gke-node"]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Service Account for GKE nodes
resource "google_service_account" "gke_service_account" {
  account_id   = "${var.project_name}-${var.environment}-gke-sa"
  display_name = "GKE Service Account for ${var.project_name} ${var.environment}"
}

# IAM bindings for the service account
resource "google_project_iam_member" "gke_service_account_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}
