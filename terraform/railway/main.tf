# terraform/railway/main.tf - Para proyecto existente

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

variable "railway_token" {
  description = "Railway Project Token (not team token)"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Railway Project Name (must exist already)"
  type        = string
  default     = "ecommerce-microservices"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

# Configuración simplificada - servicios uno por uno
locals {
  # Solo servicios esenciales para empezar
  services = {
    zipkin = {
      image = "openzipkin/zipkin"
      port  = 9411
      env = {
        STORAGE_TYPE = "mem"
      }
    }
    
    api-gateway = {
      image = "selimhorri/api-gateway-ecommerce-boot:0.1.0"
      port  = 8080
      env = {
        SPRING_PROFILES_ACTIVE = var.environment
        SERVER_PORT = "8080"
      }
    }
  }
}

# Verificar que el proyecto existe y podemos acceder
resource "null_resource" "verify_railway_access" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "🔍 Verifying Railway access..."
      export RAILWAY_TOKEN="${var.railway_token}"
      
      # Verificar CLI
      if ! command -v railway &> /dev/null; then
        npm install -g @railway/cli || npm install @railway/cli
      fi
      
      # Verificar autenticación
      echo "Testing authentication..."
      if ! railway whoami; then
        echo "❌ Authentication failed"
        exit 1
      fi
      
      # Verificar acceso al proyecto
      echo "Testing project access..."
      if ! railway project list | grep -q "${var.project_name}"; then
        echo "❌ Project '${var.project_name}' not found or not accessible"
        echo "Available projects:"
        railway project list || echo "Could not list projects"
        exit 1
      fi
      
      echo "✅ Railway access verified"
    EOT
    
    environment = {
      RAILWAY_TOKEN = var.railway_token
    }
  }
}

# Desplegar servicios uno por uno
resource "null_resource" "deploy_service" {
  for_each = local.services
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "🚀 Deploying service: ${each.key}"
      export RAILWAY_TOKEN="${var.railway_token}"
      
      # Crear directorio temporal
      mkdir -p /tmp/railway-${each.key}
      cd /tmp/railway-${each.key}
      
      # Crear archivos necesarios
      cat > Dockerfile << 'EOF'
FROM ${each.value.image}
EXPOSE ${each.value.port}
EOF
      
      # Link al proyecto existente
      railway link ${var.project_name}
      
      # Verificar que estamos linkeados correctamente
      railway status
      
      # Crear servicio
      railway service create ${each.key} || echo "Service might already exist"
      
      # Configurar variables
      %{ for k, v in each.value.env ~}
      railway variables set ${k}="${v}" --service ${each.key}
      %{ endfor ~}
      railway variables set PORT="${each.value.port}" --service ${each.key}
      
      # Deploy
      railway up --service ${each.key} --detach
      
      # Verificar deployment
      sleep 10
      railway logs --service ${each.key} || echo "Could not fetch logs"
      
      # Limpiar
      cd /
      rm -rf /tmp/railway-${each.key}
      
      echo "✅ Service ${each.key} deployment completed"
    EOT
    
    environment = {
      RAILWAY_TOKEN = var.railway_token
    }
  }
  
  depends_on = [null_resource.verify_railway_access]
}

# Output con información útil
output "deployment_status" {
  description = "Deployment status"
  value = {
    project_name = var.project_name
    services = keys(local.services)
    dashboard_url = "https://railway.app/dashboard"
    verify_command = "railway status"
  }
}

output "troubleshooting" {
  description = "Troubleshooting information"
  value = [
    "1. Verify project exists: railway project list",
    "2. Check service status: railway status", 
    "3. View logs: railway logs --service [service-name]",
    "4. Generate domains: In Railway UI, go to service settings",
    "5. Check Railway Dashboard: https://railway.app/dashboard"
  ]
}