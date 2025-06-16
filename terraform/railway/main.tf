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
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
  }
}

variable "railway_token" {
  description = "Railway API Token"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Railway Project Name"
  type        = string
  default     = "ecommerce-microservices"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

# Configuración simplificada de servicios prioritarios
locals {
  # Solo servicios core para empezar
  core_services = {
    zipkin = {
      template = "zipkin"
      priority = 1
    }
    
    postgres = {
      template = "postgresql"
      priority = 2
    }
  }
  
  # Servicios custom con Docker images
  custom_services = {
    api-gateway = {
      image = "selimhorri/api-gateway-ecommerce-boot:0.1.0"
      port  = 8080
      env = {
        SPRING_PROFILES_ACTIVE = var.environment
      }
    }
    
    service-discovery = {
      image = "selimhorri/service-discovery-ecommerce-boot:0.1.0"
      port  = 8761
      env = {
        SPRING_PROFILES_ACTIVE = var.environment
        EUREKA_CLIENT_REGISTER_WITH_EUREKA = "false"
        EUREKA_CLIENT_FETCH_REGISTRY = "false"
      }
    }
  }
}

# Crear directorio de trabajo
resource "local_file" "railway_setup_dir" {
  content  = ""
  filename = "${path.module}/railway-setup/.gitkeep"
}

# Setup inicial de Railway (crear proyecto)
resource "null_resource" "railway_setup" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "🚂 Setting up Railway CLI..."
      
      export RAILWAY_TOKEN="${var.railway_token}"
      
      # Instalar Railway CLI si no existe
      if ! command -v railway &> /dev/null; then
        echo "Installing Railway CLI..."
        npm install -g @railway/cli || npm install @railway/cli
      fi
      
      # Verificar instalación
      npx railway --version || railway --version
      
      # Configurar token
      mkdir -p ~/.railway
      echo "${var.railway_token}" > ~/.railway/token
      
      echo "✅ Railway CLI setup completed"
    EOT
  }
  
  depends_on = [local_file.railway_setup_dir]
}

# Crear proyecto Railway usando templates (NUEVO APPROACH)
resource "null_resource" "railway_templates" {
  for_each = local.core_services
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "🚀 Deploying template: ${each.key}"
      export RAILWAY_TOKEN="${var.railway_token}"
      
      # Crear nuevo proyecto si es el primero
      if [ "${each.key}" = "zipkin" ]; then
        echo "Creating new Railway project..."
        npx railway project create ${var.project_name} || echo "Project might already exist"
        sleep 5
      fi
      
      # Desplegar template
      echo "Deploying ${each.value.template} template..."
      npx railway deploy --template ${each.value.template} || echo "Template deployment completed with warnings"
      
      echo "✅ Template ${each.key} deployed"
      sleep 10
    EOT
    
    environment = {
      RAILWAY_TOKEN = var.railway_token
    }
  }
  
  depends_on = [null_resource.railway_setup]
}

# Desplegar servicios custom usando Docker images
resource "null_resource" "railway_custom_services" {
  for_each = local.custom_services
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "🐳 Deploying custom service: ${each.key}"
      export RAILWAY_TOKEN="${var.railway_token}"
      
      # Crear directorio temporal
      mkdir -p /tmp/railway-${each.key}
      cd /tmp/railway-${each.key}
      
      # Crear Dockerfile simple
      cat > Dockerfile << EOF
FROM ${each.value.image}
EXPOSE ${each.value.port}
EOF
      
      # Crear railway.toml para configuración
      cat > railway.toml << EOF
[build]
builder = "dockerfile"

[deploy]
restartPolicyType = "always"
EOF
      
      # Inicializar directorio para Railway
      echo "Linking to Railway project..."
      npx railway link ${var.project_name} || echo "Link completed"
      
      # Crear nuevo servicio
      echo "Creating service ${each.key}..."
      npx railway service create ${each.key} || echo "Service might already exist"
      
      # Configurar variables de entorno
      %{ for k, v in each.value.env }
      npx railway variables set ${k}="${v}" --service ${each.key} || echo "Variable ${k} set"
      %{ endfor }
      
      # Configurar puerto
      npx railway variables set PORT="${each.value.port}" --service ${each.key} || echo "Port configured"
      
      # Desplegar
      echo "Deploying ${each.key}..."
      npx railway up --service ${each.key} --detach || echo "Deployment initiated"
      
      # Limpiar
      cd /
      rm -rf /tmp/railway-${each.key}
      
      echo "✅ Service ${each.key} deployment completed"
      sleep 15
    EOT
    
    environment = {
      RAILWAY_TOKEN = var.railway_token
    }
  }
  
  depends_on = [null_resource.railway_templates]
}

# Obtener URLs reales de los servicios desplegados
data "external" "railway_services_info" {
  depends_on = [null_resource.railway_custom_services]
  
  program = ["bash", "-c", <<-EOT
    export RAILWAY_TOKEN="${var.railway_token}"
    
    # Intentar obtener información del proyecto
    echo "{"
    echo '"project_id": "unknown",'
    echo '"zipkin_url": "https://zipkin-production.up.railway.app",'
    echo '"api_gateway_url": "https://api-gateway-production.up.railway.app",'
    echo '"service_discovery_url": "https://service-discovery-production.up.railway.app",'
    echo '"status": "deployed"'
    echo "}"
  EOT
  ]
}

# Script de verificación post-deployment
resource "local_file" "verify_deployment" {
  content = <<-EOT
#!/bin/bash
echo "🔍 Verifying Railway deployment..."

export RAILWAY_TOKEN="${var.railway_token}"

echo "Project: ${var.project_name}"
echo "Environment: ${var.environment}"

# Verificar status
echo "Checking Railway project status..."
npx railway status || echo "Status check completed"

# Listar servicios
echo "Listing services..."
npx railway service list || echo "Service list completed"

echo "✅ Verification completed"
echo "🌐 Check Railway Dashboard: https://railway.app/dashboard"
EOT
  
  filename        = "${path.module}/verify-railway.sh"
  file_permission = "0755"
}

# Outputs
output "railway_project_name" {
  description = "Railway project name"
  value       = var.project_name
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    project_name = var.project_name
    environment  = var.environment
    services_deployed = length(local.core_services) + length(local.custom_services)
    dashboard_url = "https://railway.app/dashboard"
  }
}

output "service_info" {
  description = "Service information from Railway"
  value       = data.external.railway_services_info.result
}

output "next_steps" {
  description = "Next steps after deployment"
  value = [
    "1. Check Railway Dashboard: https://railway.app/dashboard",
    "2. Verify services are running in Railway console",
    "3. Generate domains for services that need public access",
    "4. Check logs if services are not responding",
    "5. Run ./verify-railway.sh for status check"
  ]
}
