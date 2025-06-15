# Network Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = module.network.subnet_id
}

# Compute Outputs
output "instance_public_ip" {
  description = "Public IP addresses of compute instances"
  value       = module.compute.instance_ips
}

output "instance_private_ip" {
  description = "Private IP addresses of compute instances"
  value       = module.compute.instance_internal_ips
}

output "ssh_connection_command" {
  description = "SSH connection commands for instances"
  value       = [for ip in module.compute.instance_ips : "ssh debian@${ip}"]
}


# Kubernetes Outputs (if enabled)
output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = var.enable_gke ? module.kubernetes[0].cluster_name : null
}

output "gke_cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = var.enable_gke ? module.kubernetes[0].cluster_endpoint : null
}
