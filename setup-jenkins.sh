#!/bin/bash

echo "🚀 Complete Jenkins Pipeline Setup"
echo "=================================="

# Paso 1: Limpiar estado actual
echo "🧹 Step 1: Cleaning current state..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

# Verificar que el puerto esté libre
echo "🔌 Checking port 8080..."
if ss -tulpn | grep -q :8080; then
    echo "❌ Port 8080 is still in use. Please kill the process manually:"
    ss -tulpn | grep :8080
    exit 1
fi

echo "✅ Port 8080 is available"

# Paso 2: Crear directorio de trabajo
echo "📁 Step 2: Creating workspace..."
mkdir -p jenkins-pipeline-setup
cd jenkins-pipeline-setup

# Paso 3: Crear archivos de configuración
echo "📝 Step 3: Creating configuration files..."

# Crear docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  jenkins:
    image: jenkins/jenkins:lts
    container_name: jenkins-pipeline
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - DOCKER_HOST=unix:///var/run/docker.sock
    user: root
    restart: unless-stopped
    networks:
      - jenkins-net

  docker-registry:
    image: registry:2
    container_name: docker-registry
    ports:
      - "5000:5000"
    volumes:
      - registry_data:/var/lib/registry
    restart: unless-stopped
    networks:
      - jenkins-net

volumes:
  jenkins_home:
  registry_data:

networks:
  jenkins-net:
    driver: bridge
EOF

# Paso 4: Levantar Jenkins
echo "🚀 Step 4: Starting Jenkins..."
docker-compose up -d

# Paso 5: Instalar Docker CLI en Jenkins
echo "🐳 Step 5: Installing Docker CLI in Jenkins..."
sleep 15  # Esperar que Jenkins inicie

# Instalar Docker CLI dentro del contenedor
docker exec -u root jenkins-pipeline bash -c '
    apt-get update && 
    apt-get install -y curl &&
    curl -fsSL https://get.docker.com -o get-docker.sh &&
    sh get-docker.sh &&
    usermod -aG docker jenkins
'

# Paso 6: Instalar plugins esenciales
echo "🔌 Step 6: Installing Pipeline plugins..."
docker exec jenkins-pipeline bash -c '
    echo "workflow-aggregator:latest" > /tmp/plugins.txt
    echo "pipeline-stage-view:latest" >> /tmp/plugins.txt
    echo "pipeline-maven:latest" >> /tmp/plugins.txt
    echo "docker-workflow:latest" >> /tmp/plugins.txt
    echo "git:latest" >> /tmp/plugins.txt
    echo "github:latest" >> /tmp/plugins.txt
    echo "maven-plugin:latest" >> /tmp/plugins.txt
    jenkins-plugin-cli --plugin-file /tmp/plugins.txt
'

# Paso 7: Reiniciar Jenkins para aplicar plugins
echo "🔄 Step 7: Restarting Jenkins to apply plugins..."
docker restart jenkins-pipeline

# Esperar a que Jenkins reinicie
echo "⏳ Waiting for Jenkins to restart..."
sleep 30

# Paso 8: Obtener contraseña
echo "🔑 Step 8: Getting admin password..."
echo ""
echo "=================================="
echo "Jenkins Admin Password:"
docker exec jenkins-pipeline cat /var/jenkins_home/secrets/initialAdminPassword
echo "=================================="
echo ""

# Paso 9: Verificar instalación
echo "✅ Step 9: Verifying installation..."
echo "🐳 Docker version in Jenkins:"
docker exec jenkins-pipeline docker --version

echo ""
echo "🎉 Setup Complete!"
echo "📍 Jenkins URL: http://localhost:8080"
echo "📍 Registry URL: http://localhost:5000"
echo ""
echo "📋 Next Steps:"
echo "1. Go to http://localhost:8080"
echo "2. Use the admin password shown above"
echo "3. Install suggested plugins (or skip and install later)"
echo "4. Create your admin user"
echo "5. You should now see 'Pipeline' as an option when creating new jobs!"

# Mostrar status final
docker ps