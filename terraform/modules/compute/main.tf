# Compute Engine instances for microservices
resource "google_compute_instance" "microservice_instances" {
  count        = 3
  name         = "${var.project_name}-${var.environment}-instance-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.subnet_id
    
    access_config {
      // Ephemeral external IP
    }
  }

  metadata = {
    environment = var.environment
    project     = var.project_name
    
    # SSH Keys (reemplaza con tu llave pública)
    ssh-keys = "debian:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... tu-llave-publica-aqui"
    
    # Database connection info
    db_host     = var.db_host
    db_name     = var.db_name
    db_user     = var.db_user
  }

  metadata_startup_script = templatefile("${path.module}/startup-script.sh", {
    db_host     = var.db_host
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
    environment = var.environment
  })

  tags = ["${var.environment}-microservice", "http-server", "https-server", "ssh", "allow-ssh"]

  labels = {
    for k, v in var.tags : lower(replace(k, " ", "_")) => lower(replace(v, " ", "_"))
  }
}
