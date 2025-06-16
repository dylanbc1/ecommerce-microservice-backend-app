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

# Configuración simplificada para debug
locals {
  # Solo un servicio para empezar y debuggear
  test_service = {
    image = "nginx:alpine"
    port  = 80
    name  = "test-nginx"
  }
}

# Setup Railway CLI
resource "local_file" "railway_debug_script" {
  content = <<-EOT
#!/bin/bash
set -e  # Exit on any error

echo "=== RAILWAY DEBUG SCRIPT ==="
echo "Project: ${var.project_name}"
echo "Environment: ${var.environment}"

# Set token (not sensitive in this context)
export RAILWAY_TOKEN="${var.railway_token}"

echo "Step 1: Installing Railway CLI..."
if ! command -v railway &> /dev/null; then
    npm install -g @railway/cli || {
        echo "Failed to install Railway CLI globally, trying locally..."
        npm install @railway/cli
        alias railway="npx railway"
    }
fi

echo "Step 2: Verify Railway CLI..."
railway --version || npx railway --version

echo "Step 3: Check authentication..."
railway whoami || npx railway whoami || echo "Auth check completed with warnings"

echo "Step 4: List existing projects..."
railway project list || npx railway project list || echo "Project list completed"

echo "Step 5: Create or link project..."
railway project create ${var.project_name} || {
    echo "Project might already exist, trying to link..."
    railway link ${var.project_name} || echo "Link attempted"
}

echo "Step 6: Check project status..."
railway status || npx railway status || echo "Status check completed"

echo "Step 7: List services..."
railway service list || npx railway service list || echo "No services yet"

echo "=== DEBUG SCRIPT COMPLETED ==="
EOT
  
  filename        = "${path.module}/railway-debug.sh"
  file_permission = "0755"
}

# Ejecutar debug script
resource "null_resource" "railway_debug" {
  provisioner "local-exec" {
    command = "bash ${path.module}/railway-debug.sh 2>&1 | tee ${path.module}/railway-debug.log"
    
    # NO usar environment para el token aquí para ver errores
  }
  
  depends_on = [local_file.railway_debug_script]
}

# Crear un servicio simple de prueba
resource "local_file" "test_service_dockerfile" {
  content = <<-EOT
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
EXPOSE 80
EOT
  
  filename = "${path.module}/test-service/Dockerfile"
}

resource "local_file" "test_service_html" {
  content = <<-EOT
<!DOCTYPE html>
<html>
<head>
    <title>Railway Test Service</title>
</head>
<body>
    <h1>🚂 Railway Test Service</h1>
    <p>Project: ${var.project_name}</p>
    <p>Environment: ${var.environment}</p>
    <p>If you see this, the Railway deployment is working!</p>
</body>
</html>
EOT
  
  filename = "${path.module}/test-service/index.html"
}

# Script para desplegar servicio de prueba
resource "local_file" "deploy_test_service" {
  content = <<-EOT
#!/bin/bash
set -e

echo "=== DEPLOYING TEST SERVICE ==="

export RAILWAY_TOKEN="${var.railway_token}"

cd ${path.module}/test-service

echo "Current directory: $(pwd)"
echo "Files in directory:"
ls -la

echo "Setting up Railway for this directory..."
railway link ${var.project_name} || echo "Link completed"

echo "Creating test service..."
railway service create test-nginx || echo "Service might already exist"

echo "Deploying test service..."
railway up --service test-nginx --detach || railway up --detach

echo "Checking deployment status..."
railway status || echo "Status check completed"

echo "Getting service info..."
railway service list || echo "Service list completed"

echo "=== TEST SERVICE DEPLOYMENT COMPLETED ==="
EOT
  
  filename        = "${path.module}/deploy-test.sh"
  file_permission = "0755"
  
  depends_on = [
    local_file.test_service_dockerfile,
    local_file.test_service_html
  ]
}

# Desplegar servicio de prueba
resource "null_resource" "deploy_test" {
  provisioner "local-exec" {
    command = "bash ${path.module}/deploy-test.sh 2>&1 | tee ${path.module}/deploy-test.log"
  }
  
  depends_on = [
    null_resource.railway_debug,
    local_file.deploy_test_service
  ]
}

# Outputs para debugging
output "debug_info" {
  description = "Debug information"
  value = {
    project_name = var.project_name
    environment  = var.environment
    debug_script = "${path.module}/railway-debug.sh"
    deploy_script = "${path.module}/deploy-test.sh"
    debug_log = "${path.module}/railway-debug.log"
    deploy_log = "${path.module}/deploy-test.log"
  }
}

output "debug_commands" {
  description = "Commands to run for debugging"
  value = [
    "Check debug log: cat terraform/railway/railway-debug.log",
    "Check deploy log: cat terraform/railway/deploy-test.log", 
    "Run debug manually: bash terraform/railway/railway-debug.sh",
    "Run deploy manually: bash terraform/railway/deploy-test.sh",
    "Check Railway dashboard: https://railway.app/dashboard"
  ]
}

output "troubleshooting_steps" {
  description = "Troubleshooting steps"
  value = [
    "1. Check if Railway token is valid",
    "2. Verify Railway CLI is working",
    "3. Check if project exists in Railway dashboard",
    "4. Look for error messages in log files",
    "5. Try manual deployment via Railway dashboard"
  ]
}