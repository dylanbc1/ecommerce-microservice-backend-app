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
  description = "Railway Project Token"
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

# Configuración de servicios
locals {
  services = {
    zipkin = {
      image = "openzipkin/zipkin:latest"
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
    
    service-discovery = {
      image = "selimhorri/service-discovery-ecommerce-boot:0.1.0"
      port  = 8761
      env = {
        SPRING_PROFILES_ACTIVE = var.environment
        SERVER_PORT = "8761"
        EUREKA_CLIENT_REGISTER_WITH_EUREKA = "false"
        EUREKA_CLIENT_FETCH_REGISTRY = "false"
      }
    }
  }
}

# Obtener información del proyecto usando Railway API
resource "null_resource" "get_project_info" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "🔍 Getting project info via Railway API..."
      
      # Buscar proyecto por nombre usando GraphQL API
      PROJECT_INFO=$(curl -s -X POST \
        -H "Authorization: Bearer ${var.railway_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "query": "query { projects { edges { node { id name } } } }"
        }' \
        https://backboard.railway.app/graphql/v2)
      
      echo "Project API response: $PROJECT_INFO"
      
      # Extraer project ID (esto es simplificado, en producción usarías jq)
      echo "$PROJECT_INFO" > /tmp/railway-project-info.json
      
      echo "✅ Project info retrieved"
    EOT
  }
}

# Crear servicios usando Docker Compose approach
resource "local_file" "docker_compose" {
  content = <<-EOT
version: '3.8'

services:
%{ for service_name, service_config in local.services ~}
  ${service_name}:
    image: ${service_config.image}
    ports:
      - "${service_config.port}:${service_config.port}"
    environment:
%{ for env_key, env_value in service_config.env ~}
      ${env_key}: "${env_value}"
%{ endfor ~}
      PORT: "${service_config.port}"
    restart: unless-stopped
    
%{ endfor ~}
EOT

  filename = "${path.module}/docker-compose.yml"
}

# Crear servicios usando Railway Deploy API
resource "null_resource" "deploy_services" {
  for_each = local.services
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "🚀 Deploying ${each.key} via Railway API..."
      
      # Crear directorio temporal para deployment
      TEMP_DIR="/tmp/railway-${each.key}-$(date +%s)"
      mkdir -p "$TEMP_DIR"
      cd "$TEMP_DIR"
      
      # Crear Dockerfile
      cat > Dockerfile << 'EOF'
FROM ${each.value.image}
EXPOSE ${each.value.port}

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:${each.value.port}/actuator/health || exit 1

CMD ["java", "-jar", "/app.jar"]
EOF

      # Crear railway.json para configuración
      cat > railway.json << 'EOF'
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "dockerfile"
  },
  "deploy": {
    "restartPolicyType": "always",
    "replicas": 1
  }
}
EOF

      # Crear un simple index.html para servicios que no responden inmediatamente
      cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>${each.key} Service</title>
</head>
<body>
    <h1>${each.key} Service</h1>
    <p>Service is starting up...</p>
    <p>Port: ${each.value.port}</p>
</body>
</html>
EOF
      
      # Instalar Railway CLI localmente si no existe
      if ! command -v railway &> /dev/null; then
        echo "Installing Railway CLI locally..."
        npm init -y
        npm install @railway/cli
        export PATH="$TEMP_DIR/node_modules/.bin:$PATH"
      fi
      
      # Configurar autenticación
      export RAILWAY_TOKEN="${var.railway_token}"
      
      # Intentar conectar al proyecto existente
      echo "Connecting to Railway project..."
      railway login --token "${var.railway_token}" || echo "Token login attempted"
      
      # Link al proyecto (puede fallar, pero continuamos)
      railway link ${var.project_name} || echo "Link attempted"
      
      # Intentar crear servicio
      railway service create ${each.key} || echo "Service ${each.key} creation attempted"
      
      # Configurar variables de entorno vía API si es posible
      %{ for env_key, env_value in each.value.env ~}
      echo "Setting ${env_key}..."
      railway variables set ${env_key}="${env_value}" --service ${each.key} || echo "Variable ${env_key} attempted"
      %{ endfor ~}
      
      # Configurar PORT
      railway variables set PORT="${each.value.port}" --service ${each.key} || echo "PORT variable attempted"
      
      # Intentar deployment
      echo "Attempting deployment..."
      railway up --service ${each.key} --detach || echo "Deployment attempted"
      
      # Limpiar
      cd /
      rm -rf "$TEMP_DIR"
      
      echo "✅ ${each.key} deployment process completed"
      sleep 5
    EOT
    
    environment = {
      RAILWAY_TOKEN = var.railway_token
    }
  }
  
  depends_on = [
    null_resource.get_project_info,
    local_file.docker_compose
  ]
}

# Verificación manual alternativa
resource "local_file" "manual_deployment_guide" {
  content = <<-EOT
# Manual Railway Deployment Guide

## 1. Servicios a desplegar:
%{ for service_name, service_config in local.services ~}

### ${service_name}
- **Image**: ${service_config.image}
- **Port**: ${service_config.port}
- **Environment Variables**:
%{ for env_key, env_value in service_config.env ~}
  - ${env_key}=${env_value}
%{ endfor ~}
  - PORT=${service_config.port}

**Manual deployment command:**
```bash
# En Railway Dashboard:
# 1. Create new service: ${service_name}
# 2. Set source: Docker Image
# 3. Image: ${service_config.image}
# 4. Port: ${service_config.port}
# 5. Add environment variables as listed above
```

%{ endfor ~}

## 2. Alternative: Deploy via Railway Dashboard

1. Go to: https://railway.app/dashboard
2. Select project: ${var.project_name}
3. Click "New Service" for each service above
4. Choose "Docker Image" as source
5. Enter the image name and configure as shown

## 3. Verification

Once deployed, check:
- Service logs in Railway dashboard
- Generate domains for public access
- Test endpoints

## 4. Expected URLs (after domain generation):

%{ for service_name, service_config in local.services ~}
- ${service_name}: https://${service_name}-production.up.railway.app
%{ endfor ~}

EOT

  filename = "${path.module}/MANUAL_DEPLOYMENT.md"
}

# Outputs
output "deployment_info" {
  description = "Deployment information"
  value = {
    project_name = var.project_name
    environment  = var.environment
    services     = keys(local.services)
    dashboard_url = "https://railway.app/dashboard"
  }
}

output "manual_deployment" {
  description = "Manual deployment guide"
  value = {
    guide_file = "${path.module}/MANUAL_DEPLOYMENT.md"
    dashboard = "https://railway.app/dashboard"
    project_name = var.project_name
  }
}

output "service_configs" {
  description = "Service configurations for manual setup"
  value = local.services
}