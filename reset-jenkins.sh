#!/bin/bash

echo "🔧 Resetting Jenkins configuration..."

# Detener servicios
echo "🛑 Stopping Jenkins..."
docker-compose down

# Limpiar volúmenes (CUIDADO: esto borra toda la configuración)
echo "🗑️  Cleaning volumes..."
docker volume rm jenkins-docker-setup_jenkins_home || true
docker volume rm jenkins-docker-setup_registry_data || true

# Recrear con el docker-compose corregido
echo "🚀 Starting fresh Jenkins..."
docker-compose up -d

# Esperar a que Jenkins inicie
echo "⏳ Waiting for Jenkins to fully start..."
sleep 45

# Mostrar el password inicial
echo ""
echo "🔑 Jenkins initial admin password:"
docker exec jenkins-with-docker cat /var/jenkins_home/secrets/initialAdminPassword

echo ""
echo "✅ Jenkins reset complete!"
echo "📍 Access Jenkins at: http://localhost:8080"
echo "📍 Docker Registry at: http://localhost:5000"
echo ""
echo "📋 Next steps:"
echo "1. Go to http://localhost:8080"
echo "2. Use the password above"
echo "3. Install suggested plugins"
echo "4. Create your admin user"
echo "5. Test Docker functionality"

# Verificar que Docker funciona
echo ""
echo "🐳 Testing Docker access..."
sleep 10
docker exec jenkins-with-docker docker --version
docker exec jenkins-with-docker docker info --format '{{.ServerVersion}}'