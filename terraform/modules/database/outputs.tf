output "instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = google_sql_database_instance.main.name
}

output "instance_connection_name" {
  description = "The connection name of the Cloud SQL instance"
  value       = google_sql_database_instance.main.connection_name
}

output "db_public_ip" {
  description = "The public IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.main.public_ip_address
}

output "db_private_ip" {
  description = "The private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.main.private_ip_address
}

output "database_name" {
  description = "The name of the database"
  value       = google_sql_database.database.name
}

output "database_user" {
  description = "The database user"
  value       = google_sql_user.users.name
}
