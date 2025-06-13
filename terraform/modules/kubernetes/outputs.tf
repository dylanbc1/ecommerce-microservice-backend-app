output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = google_container_cluster.primary.master_auth.0.cluster_ca_certificate
  sensitive   = true
}

output "service_account_email" {
  description = "Email of the GKE service account"
  value       = google_service_account.gke_service_account.email
}
