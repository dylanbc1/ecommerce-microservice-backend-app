# Project Configuration
variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "proyectofinal-462603"
}

variable "gcp_credentials_file" {
  description = "Path to GCP credentials JSON file"
  type        = string
  default     = null
  sensitive   = true
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be dev, stage, or prod."
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ecommerce-microservice"
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnets" {
  description = "Subnet configuration"
  type = map(object({
    cidr = string
    zone = string
  }))
  default = {
    "public" = {
      cidr = "10.0.1.0/24"
      zone = "us-central1-a"
    }
    "private" = {
      cidr = "10.0.2.0/24"
      zone = "us-central1-b"
    }
  }
}

# Compute Configuration
variable "machine_type" {
  description = "Machine type for compute instances"
  type        = string
  default     = "e2-micro"
}

# Database Configuration
variable "db_instance_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "ecommerce_db"
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "ecommerce_user"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# Kubernetes Configuration
variable "enable_gke" {
  description = "Enable Google Kubernetes Engine"
  type        = bool
  default     = false
}

variable "gke_node_count" {
  description = "Number of GKE nodes"
  type        = number
  default     = 3
}

variable "gke_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}
