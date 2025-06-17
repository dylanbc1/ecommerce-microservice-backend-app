terraform {
  required_version = ">= 1.0"
  
 

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

# Local values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Network Module
module "network" {
  source = "./modules/network"
  
  project_id    = var.gcp_project_id
  region        = var.gcp_region
  environment   = var.environment
  project_name  = var.project_name
  
  vpc_cidr = var.vpc_cidr
  subnets  = var.subnets
  
  tags = local.common_tags
}

# Compute Module - SIN DEPENDENCIAS DE DATABASE
module "compute" {
  source = "./modules/compute"
  
  project_id   = var.gcp_project_id
  region       = var.gcp_region
  zone         = var.gcp_zone
  environment  = var.environment
  project_name = var.project_name
  
  network_id    = module.network.vpc_id
  subnet_id     = module.network.subnet_id
  
  machine_type = var.machine_type
  

  # Variables temporales para la base de datos
  db_host     = "localhost"
  db_name     = "temp_db"
  db_user     = "temp_user"
  db_password = "temp_password"
  
  tags = local.common_tags
}

# Kubernetes Module (if needed)
module "kubernetes" {
  source = "./modules/kubernetes"
  count  = var.enable_gke ? 1 : 0
  
  project_id   = var.gcp_project_id
  region       = var.gcp_region
  environment  = var.environment
  project_name = var.project_name
  
  network_id    = module.network.vpc_id
  subnet_id     = module.network.subnet_id
  
  node_count    = var.gke_node_count
  machine_type  = var.gke_machine_type
  
  tags = local.common_tags
}