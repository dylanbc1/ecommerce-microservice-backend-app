#!/bin/bash

echo "🚀 Quick Jenkins Pipeline Setup"
echo "==============================="

# Detener proceso anterior si está colgado
echo "🛑 Stopping any hanging processes..."
docker stop jenkins-pipeline docker-registry 2>/dev/null || true
docker rm jenkins-pipeline docker-registry 2>/dev/null || true

# Crear directorio
mkdir -p jenkins-quick-setup
cd jenkins-quick-setup

# Docker compose optimizado
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

  docker-registry:
    image: registry:2
    container_name: docker-registry
    ports:
      - "5000:5000"
    volumes:
      - registry_data:/var/lib/registry

volumes:
  jenkins_home:
  registry_data:
EOF

echo "🚀 Starting services..."
docker-compose up -d

# Esperar menos tiempo
echo "⏳ Waiting 30 seconds for Jenkins to start..."
sleep 30

# Método más rápido: usar imagen con Docker preinstalado
echo "🐳 Quick Docker CLI setup..."
docker exec jenkins-pipeline bash -c '
    apt-get update -qq && 
    apt-get install -y curl -qq &&
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg &&
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(grep VERSION_CODENAME /etc/os-release | cut -d= -f2) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null &&
    apt-get update -qq &&
    apt-get install -y docker-ce-cli -qq
' &

# Mientras se instala Docker, obtener la contraseña
echo "🔑 Getting admin password..."
sleep 10
PASSWORD=$(docker exec jenkins-pipeline cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "Password not ready yet")

# Esperar que termine la instalación de Docker
wait

echo ""
echo "✅ Quick setup complete!"
echo "=================================="
echo "Jenkins Admin Password: $PASSWORD"
echo "=================================="
echo "📍 Jenkins URL: http://localhost:8080"
echo "📍 Registry URL: http://localhost:5000"
echo ""
echo "🔥 FAST TRACK:"
echo "1. Go to http://localhost:8080"
echo "2. Use password above"
echo "3. Click 'Install suggested plugins' (this will include Pipeline)"
echo "4. Wait 3-5 minutes for plugins to install"
echo "5. Create admin user"
echo ""

# Verificar Docker
echo "🐳 Docker test:"
docker exec jenkins-pipeline docker --version 2>/dev/null || echo "Docker still installing..."

echo "📊 Container status:"
docker ps