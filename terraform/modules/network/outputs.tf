output "vpc_id" {
  description = "ID of the VPC"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "Name of the VPC"
  value       = google_compute_network.vpc.name
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = google_compute_subnetwork.public_subnet.id
}

output "subnet_ids" {
  description = "IDs of all subnets"
  value = {
    public  = google_compute_subnetwork.public_subnet.id
    private = google_compute_subnetwork.private_subnet.id
  }
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = google_compute_subnetwork.private_subnet.id
}
