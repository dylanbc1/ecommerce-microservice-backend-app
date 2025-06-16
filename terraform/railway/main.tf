# terraform/railway/main.tf
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

# Variables
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
  default     = "production"
}

variable "github_repo" {
  description = "GitHub Repository URL"
  type        = string
  default     = "https://github.com/SelimHorri/ecommerce-microservice-backend-app"
}

# Configuración de servicios
locals {
  microservices = {
    # Infraestructura básica
    zipkin = {
      image       = "openzipkin/zipkin"
      port        = 9411
      priority    = 1
      env = {
        STORAGE_TYPE = "mem"
      }
    }
    
    # Servicios core
    service-discovery = {
      image       = "selimhorri/service-discovery-ecommerce-boot:0.1.0"
      port        = 8761
      priority    = 2
      env = {
        SPRING_PROFILES_ACTIVE = var.environment
        EUREKA_CLIENT_REGISTER_WITH_EUREKA = "false"
        EUREKA_CLIENT_FETCH_REGISTRY = "false"
        EUREKA_SERVER_WAIT_TIME_IN_MS_WHEN_SYNC_EMPTY = "0"
      }
    }
    
    cloud-config = {
      image       = "selimhorri/cloud-config-ecommerce-boot:0.1.0"
      port        = 9296
      priority    = 3
      env = {
        SPRING_PROFILES_ACTIVE = var.environment
        SPRING_CLOUD_CONFIG_SERVER_GIT_URI = var.github_repo
      }
    }
    
    # API Gateway
    api-gateway = {
      image       = "selimhorri/api-gateway-ecommerce-boot:0.1.0"
      port        = 8080
      priority    = 4
      env = {
        SPRING_PROFILES_ACTIVE = var.environment
      }
    }
    
    # Servicios de negocio
    order-service = {
      image       = "selimhorri/order-service-ecommerce-boot:0.1.0"
      port        = 8300
      priority    = 5
      env = {
        SPRING_PROFILES_ACTIVE = var.environment
      }
    }
    
    payment-service = {
      image       = "selimhorri/payment-service-ecommerce-boot:0.1.0"
      port        = 8400
      priority    = 5
      env = {
        SPRING_PROFILES_ACTIVE = var.environment
      }
    }
    
    product-service = {
      image       = "selimhorri/product-service-ecommerce-boot:0.1.0"
      port        = 8500
      priority    = 5
      env = {
        SPRING_PROFILES_ACTIVE = var.environment
      }
    }
    
    shipping-service = {
      image       = "selimhorri/shipping-service-ecommerce-boot:0.1.0"
      port        = 8600
      priority    = 5
      env = {
        SPRING_PROFILES_ACTIVE = var.environment
      }
    }
    
    user-service = {
      image       = "selimhorri/user-service-ecommerce-boot:0.1.0"
      port        = 8700
      priority    = 5
      env = {
        SPRING_PROFILES_ACTIVE = var.environment
      }
    }
    
    favourite-service = {
      image       = "selimhorri/favourite-service-ecommerce-boot:0.1.0"
      port        = 8800
      priority    = 5
      env = {
        SPRING_PROFILES_ACTIVE = var.environment
      }
    }
    
    proxy-client = {
      image       = "selimhorri/proxy-client-ecommerce-boot:0.1.0"
      port        = 8900
      priority    = 6
      env = {
        SPRING_PROFILES_ACTIVE = var.environment
      }
    }
    
    # Servicios adicionales del patrón
    hystrix-dashboard = {
      image       = "mlabouardy/hystrix-dashboard:latest"
      port        = 9002
      priority    = 7
      env = {
        SPRING_PROFILES_ACTIVE = var.environment
      }
    }
    
    feature-toggle-service = {
      image       = "unleash/unleash-server:latest"
      port        = 4242
      priority    = 8
      env = {
        DATABASE_URL = "postgres://railway_user:password@railway_postgres:5432/railway_db"
        DATABASE_SSL = "false"
      }
    }
  }
  
  # Servicios de monitoreo
  monitoring_services = {
    prometheus = {
      image       = "prom/prometheus:latest"
      port        = 9090
      priority    = 10
      env = {}
    }
    
    grafana = {
      image       = "grafana/grafana:latest"
      port        = 3000
      priority    = 11
      env = {
        GF_SECURITY_ADMIN_PASSWORD = "admin"
        GF_USERS_ALLOW_SIGN_UP = "false"
      }
    }
    
    alertmanager = {
      image       = "prom/alertmanager:latest"
      port        = 9093
      priority    = 12
      env = {}
    }
    
    elasticsearch = {
      image       = "docker.elastic.co/elasticsearch/elasticsearch:7.17.0"
      port        = 9200
      priority    = 13
      env = {
        "discovery.type" = "single-node"
        "ES_JAVA_OPTS" = "-Xms512m -Xmx512m"
        "xpack.security.enabled" = "false"
      }
    }
    
    kibana = {
      image       = "docker.elastic.co/kibana/kibana:7.17.0"
      port        = 5601
      priority    = 14
      env = {}
    }
    
    jaeger = {
      image       = "jaegertracing/all-in-one:latest"
      port        = 16686
      priority    = 15
      env = {
        COLLECTOR_ZIPKIN_HTTP_PORT = "9411"
      }
    }
    
    node-exporter = {
      image       = "prom/node-exporter:latest"
      port        = 9100
      priority    = 16
      env = {}
    }
  }
  
  # Combinar todos los servicios
  all_services = merge(local.microservices, local.monitoring_services)
}

# Crear directorio de trabajo
resource "local_file" "railway_setup_dir" {
  content  = ""
  filename = "${path.module}/railway-setup/.gitkeep"
}

# Crear proyecto Railway
resource "null_resource" "railway_project" {
  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}
      railway login --browserless
      railway create ${var.project_name} || railway link
    EOT
    
    environment = {
      RAILWAY_TOKEN = var.railway_token
    }
  }
  
  depends_on = [local_file.railway_setup_dir]
}

# Crear servicios Railway en orden de prioridad
resource "null_resource" "railway_services" {
  for_each = local.all_services
  
  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}
      
      # Crear directorio para el servicio
      mkdir -p railway-services/${each.key}
      cd railway-services/${each.key}
      
      # Crear Dockerfile
      cat > Dockerfile << 'EOF'
FROM ${each.value.image}

# Configurar puerto
EXPOSE ${each.value.port}

# Variables de entorno se configuran en Railway UI o CLI
EOF
      
      # Crear railway.json
      cat > railway.json << 'EOF'
{
  "deploy": {
    "dockerfile": "Dockerfile",
    "restartPolicyType": "always"
  }
}
EOF
      
      # Crear servicio en Railway
      railway service create ${each.key} || true
      
      # Configurar variables de entorno
      ${join("\n", [for k, v in each.value.env : "railway variables set ${k}=\"${v}\" --service ${each.key} || true"])}
      
      # Variables comunes para servicios Spring Boot
      if [[ "${each.value.image}" == *"ecommerce-boot"* ]]; then
        railway variables set SPRING_ZIPKIN_BASE_URL="https://zipkin-${var.environment}.up.railway.app" --service ${each.key} || true
        railway variables set EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE="https://service-discovery-${var.environment}.up.railway.app/eureka/" --service ${each.key} || true
        railway variables set SPRING_CONFIG_IMPORT="optional:configserver:https://cloud-config-${var.environment}.up.railway.app" --service ${each.key} || true
      fi
      
      # Desplegar servicio
      railway up --detach --service ${each.key}
      
      # Esperar entre deploys según prioridad
      sleep $((${each.value.priority} * 10))
    EOT
    
    environment = {
      RAILWAY_TOKEN = var.railway_token
    }
  }
  
  depends_on = [null_resource.railway_project]
  
  triggers = {
    service_config = jsonencode(each.value)
    timestamp = timestamp()
  }
}

# Configurar base de datos PostgreSQL
resource "null_resource" "railway_database" {
  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}
      railway add postgresql
      railway variables set DATABASE_URL="$PGHOST:$PGPORT/$PGDATABASE?user=$PGUSER&password=$PGPASSWORD"
    EOT
    
    environment = {
      RAILWAY_TOKEN = var.railway_token
    }
  }
  
  depends_on = [null_resource.railway_project]
}

# Script de configuración post-deploy
# Script de configuración post-deploy
resource "local_file" "post_deploy_script" {
  content = <<-EOT
#!/bin/bash
echo "Post-deploy configuration for ${var.project_name}"
echo "Environment: ${var.environment}"
echo "Deployment completed successfully"
EOT
  
  filename        = "${path.module}/railway-services/post-deploy.sh"
  file_permission = "0755"
}

# Output de URLs de servicios
data "external" "service_urls" {
  depends_on = [null_resource.railway_services]
  
  program = ["bash", "-c", <<-EOT
    echo '{'
    echo '"api_gateway": "https://api-gateway-${var.environment}.up.railway.app",'
    echo '"service_discovery": "https://service-discovery-${var.environment}.up.railway.app",'
    echo '"grafana": "https://grafana-${var.environment}.up.railway.app",'
    echo '"prometheus": "https://prometheus-${var.environment}.up.railway.app",'
    echo '"kibana": "https://kibana-${var.environment}.up.railway.app",'
    echo '"jaeger": "https://jaeger-${var.environment}.up.railway.app",'
    echo '"zipkin": "https://zipkin-${var.environment}.up.railway.app"'
    echo '}'
  EOT
  ]
}

# Outputs
output "railway_project_name" {
  description = "Railway project name"
  value       = var.project_name
}

output "service_urls" {
  description = "URLs of deployed services"
  value       = data.external.service_urls.result
}

output "main_urls" {
  description = "Main application URLs"
  value = {
    api_gateway      = "https://api-gateway-${var.environment}.up.railway.app"
    service_discovery = "https://service-discovery-${var.environment}.up.railway.app"
    monitoring_stack = "https://grafana-${var.environment}.up.railway.app"
    tracing         = "https://zipkin-${var.environment}.up.railway.app"
    logs           = "https://kibana-${var.environment}.up.railway.app"
  }
}

output "deployment_commands" {
  description = "Commands to manage the deployment"
  value = [
    "railway status",
    "railway logs --service api-gateway",
    "railway variables list --service api-gateway",
    "railway metrics --service api-gateway"
  ]
}