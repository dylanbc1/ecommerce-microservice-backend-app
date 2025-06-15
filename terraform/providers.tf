# Provider configuration for Google Cloud
provider "google" {
  credentials = var.gcp_credentials_file != null ? file(var.gcp_credentials_file) : null
  project     = var.gcp_project_id
  region      = var.gcp_region
  zone        = var.gcp_zone
}

provider "google-beta" {
  credentials = var.gcp_credentials_file != null ? file(var.gcp_credentials_file) : null
  project     = var.gcp_project_id
  region      = var.gcp_region
  zone        = var.gcp_zone
}
