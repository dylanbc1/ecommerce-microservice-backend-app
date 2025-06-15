#!/bin/bash
echo "🚀 Starting complete ecommerce stack..."

# Iniciar servicios principales
if [ -f "compose.yml" ]; then
    echo "📦 Starting microservices..."
    docker-compose -f compose.yml up -d
    sleep 30
fi

# Iniciar stack de monitoreo
if [ -f "monitoring/docker-compose.yml" ]; then
    echo "📊 Starting monitoring stack..."
    docker-compose -f monitoring/docker-compose.yml up -d
    sleep 20
fi

echo "✅ Stack startup completed!"
echo
echo "🌐 Access URLs:"
echo "- Application: http://localhost:8080"
echo "- Grafana: http://localhost:3000 (admin/admin)"
echo "- Prometheus: http://localhost:9090"
echo "- Kibana: http://localhost:5601"
echo "- Jaeger: http://localhost:16686"
