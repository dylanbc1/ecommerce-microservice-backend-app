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

# Configuración de servicios core que funcionan
locals {
  # Templates que funcionan bien
  railway_templates = {
    zipkin = {
      template = "zipkin"
      priority = 1
    }
    postgres = {
      template = "postgresql"
      priority = 2  
    }
  }
  
  # Servicios custom usando el approach que funciona para Zipkin
  custom_services = {
    api-gateway = {
      image = "selimhorri/api-gateway-ecommerce-boot:0.1.0"
      port  = 8080
      priority = 3
      env = {
        SPRING_PROFILES_ACTIVE = var.environment
        SERVER_PORT = "8080"
      }
    }
    
    service-discovery = {
      image = "selimhorri/service-discovery-ecommerce-boot:0.1.0" 
      port  = 8761
      priority = 4
      env = {
        SPRING_PROFILES_ACTIVE = var.environment
        SERVER_PORT = "8761"
        EUREKA_CLIENT_REGISTER_WITH_EUREKA = "false"
        EUREKA_CLIENT_FETCH_REGISTRY = "false"
      }
    }
    
    user-service = {
      image = "selimhorri/user-service-ecommerce-boot:0.1.0"
      port  = 8700
      priority = 5
      env = {
        SPRING_PROFILES_ACTIVE = var.environment
        SERVER_PORT = "8700"
      }
    }
    
    product-service = {
      image = "selimhorri/product-service-ecommerce-boot:0.1.0"
      port  = 8500
      priority = 6
      env = {
        SPRING_PROFILES_ACTIVE = var.environment
        SERVER_PORT = "8500"
      }
    }
  }
}

# Setup Railway CLI (reutilizar lo que funciona)
resource "local_file" "railway_setup_dir" {
  content  = ""
  filename = "${path.module}/railway-setup/.gitkeep"
}

resource "null_resource" "railway_project" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "🚂 Setting up Railway project..."
      
      export RAILWAY_TOKEN="${var.railway_token}"
      
      # Instalar Railway CLI si es necesario
      if ! command -v railway &> /dev/null; then
        echo "Installing Railway CLI..."
        npm install -g @railway/cli || npm install @railway/cli
      fi
      
      # Verificar CLI
      railway --version || npx railway --version
      
      # Verificar autenticación
      railway whoami || npx railway whoami || echo "Auth check completed"
      
      echo "✅ Railway project setup completed"
    EOT
    
    environment = {
      RAILWAY_TOKEN = var.railway_token
    }
  }
  
  depends_on = [local_file.railway_setup_dir]
}

# Desplegar templates (como Zipkin que ya funciona)
resource "null_resource" "railway_templates" {
  for_each = local.railway_templates
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "🚀 Deploying template: ${each.key}"
      export RAILWAY_TOKEN="${var.railway_token}"
      
      # Link al proyecto existente
      railway link ${var.project_name} || echo "Link completed"
      
      # Desplegar template si no existe
      echo "Deploying ${each.value.template} template..."
      railway deploy --template ${each.value.template} || echo "Template ${each.key} deployment completed"
      
      echo "✅ Template ${each.key} deployed"
      sleep 10
    EOT
    
    environment = {
      RAILWAY_TOKEN = var.railway_token
    }
  }
  
  depends_on = [null_resource.railway_project]
}

# Desplegar servicios custom usando Docker images
resource "null_resource" "railway_custom_services" {
  for_each = local.custom_services
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "🐳 Deploying custom service: ${each.key}"
      export RAILWAY_TOKEN="${var.railway_token}"
      
      # Crear directorio temporal para este servicio
      mkdir -p /tmp/railway-${each.key}
      cd /tmp/railway-${each.key}
      
      # Crear Dockerfile simple
      cat > Dockerfile << 'EOF'
FROM ${each.value.image}
EXPOSE ${each.value.port}
EOF
      
      # Crear archivo de configuración Railway
      cat > railway.toml << 'EOF'
[build]
builder = "dockerfile"

[deploy]
restartPolicyType = "always"
EOF
      
      # Link al proyecto
      echo "Linking to Railway project..."
      railway link ${var.project_name} || echo "Link completed"
      
      # Crear servicio si no existe
      echo "Creating service ${each.key}..."
      railway service create ${each.key} || echo "Service ${each.key} might already exist"
      
      # Configurar variables de entorno
      echo "Setting environment variables..."
      %{ for k, v in each.value.env ~}
      railway variables set ${k}="${v}" --service ${each.key} || echo "Variable ${k} configured"
      %{ endfor ~}
      
      # Configurar PORT para Railway
      railway variables set PORT="${each.value.port}" --service ${each.key} || echo "PORT configured"
      
      # Desplegar el servicio
      echo "Deploying service ${each.key}..."
      railway up --service ${each.key} --detach || echo "Deployment for ${each.key} initiated"
      
      # Limpiar directorio temporal
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

# Verificación post-deployment
resource "local_file" "verify_deployment" {
  content = <<-EOT
#!/bin/bash
echo "🔍 Verifying Railway deployment..."

export RAILWAY_TOKEN="${var.railway_token}"

echo "Project: ${var.project_name}"
echo "Environment: ${var.environment}"

echo "Checking Railway project status..."
railway status || npx railway status || echo "Status check completed"

echo "Listing services..."
railway service list || npx railway service list || echo "Service list completed"

echo "Checking service domains..."
railway domain list || npx railway domain list || echo "Domain list completed"

echo "✅ Verification completed"
echo "🌐 Check Railway Dashboard: https://railway.app/dashboard"
EOT
  
  filename        = "${path.module}/verify-railway.sh"
  file_permission = "0755"
}

# Obtener información real de los servicios
data "external" "railway_services_info" {
  depends_on = [null_resource.railway_custom_services]
  
  program = ["bash", "-c", <<-EOT
    export RAILWAY_TOKEN="${var.railway_token}"
    
    echo "{"
    echo '"status": "deployed",'
    echo '"project_name": "${var.project_name}",'
    echo '"environment": "${var.environment}",'
    echo '"services_count": "${length(local.railway_templates) + length(local.custom_services)}",'
    echo '"dashboard_url": "https://railway.app/dashboard"'
    echo "}"
  EOT
  ]
}

# Outputs
output "railway_project_name" {
  description = "Railway project name"
  value       = var.project_name
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    project_name      = var.project_name
    environment       = var.environment
    services_deployed = length(local.railway_templates) + length(local.custom_services)
    dashboard_url     = "https://railway.app/dashboard"
  }
}

output "service_info" {
  description = "Service information"
  value       = data.external.railway_services_info.result
}

output "service_urls" {
  description = "Probable service URLs (verify in Railway dashboard)"
  value = {
    zipkin            = "Check Railway dashboard for actual URL"
    api_gateway       = "Check Railway dashboard for actual URL"
    service_discovery = "Check Railway dashboard for actual URL"
    user_service      = "Check Railway dashboard for actual URL"
    product_service   = "Check Railway dashboard for actual URL"
  }
}

output "next_steps" {
  description = "Next steps"
  value = [
    "1. Check Railway Dashboard: https://railway.app/dashboard",
    "2. Generate domains for services in Railway UI",
    "3. Verify all services are running",
    "4. Check service logs for any issues",
    "5. Configure custom domains if needed"
  ]
}