output "instance_ids" {
  description = "IDs of the compute instances"
  value       = google_compute_instance.microservice_instances[*].id
}

output "instance_ips" {
  description = "External IP addresses of the instances"
  value       = google_compute_instance.microservice_instances[*].network_interface[0].access_config[0].nat_ip
}

output "instance_internal_ips" {
  description = "Internal IP addresses of the instances"
  value       = google_compute_instance.microservice_instances[*].network_interface[0].network_ip
}

output "instance_names" {
  description = "Names of the instances"
  value       = google_compute_instance.microservice_instances[*].name
}
