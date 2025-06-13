# Random suffix for unique naming
resource "random_id" "db_name_suffix" {
  byte_length = 4
}

# Cloud SQL Database Instance
resource "google_sql_database_instance" "main" {
  name             = "${var.project_name}-${var.environment}-db-${random_id.db_name_suffix.hex}"
  database_version = "POSTGRES_13"
  region           = var.region

  settings {
    tier = var.db_instance_tier

    backup_configuration {
      enabled = true
    }

    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        name  = "allow-all"
        value = "0.0.0.0/0"
      }
    }

    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    user_labels = {
      for k, v in var.tags : lower(replace(k, " ", "_")) => lower(replace(v, " ", "_"))
    }
  }

  deletion_protection = false
}

# Database
resource "google_sql_database" "database" {
  name     = var.db_name
  instance = google_sql_database_instance.main.name
}

# Database User
resource "google_sql_user" "users" {
  name     = var.db_user
  instance = google_sql_database_instance.main.name
  password = var.db_password
}
