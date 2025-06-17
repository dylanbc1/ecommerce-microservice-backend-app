terraform {
  required_version = ">= 1.0"
  
  
  
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

# Database Module
module "database" {
  source = "./modules/database"
  
  project_id   = var.gcp_project_id
  region       = var.gcp_region
  environment  = var.environment
  project_name = var.project_name
  
  network_id = module.network.vpc_id
  
  db_instance_tier = var.db_instance_tier
  db_name         = var.db_name
  db_user         = var.db_user
  db_password     = var.db_password
  
  tags = local.common_tags
}

# Compute Module
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
  
  db_host     = module.database.db_public_ip
  db_name     = var.db_name
  db_user     = var.db_user
  db_password = var.db_password
  
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
