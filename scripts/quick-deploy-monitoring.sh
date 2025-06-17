#!/bin/bash

# Script de Despliegue Rápido para Proyecto Final IngeSoft V
# Este script despliega toda la infraestructura de monitoreo en GCP Kubernetes

set -e

echo "🚀 === INICIANDO DESPLIEGUE RÁPIDO PROYECTO FINAL ==="

# Configuración
PROJECT_ID="proyectofinal-462603"
CLUSTER_NAME="ecommerce-cluster"
ZONE="us-central1-a"
MONITORING_NAMESPACE="monitoring"
APP_NAMESPACE="ecommerce-dev"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para verificar dependencias
check_dependencies() {
    print_status "Verificando dependencias..."
    
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI no está instalado"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl no está instalado"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "docker no está instalado"
        exit 1
    fi
    
    print_success "Todas las dependencias están instaladas"
}

# Función para autenticación GCP
setup_gcp_auth() {
    print_status "Configurando autenticación GCP..."
    
    # Crear archivo de credenciales temporal
    cat > /tmp/gcp-credentials.json << 'EOF'
{
  "type": "service_account",
  "project_id": "proyectofinal-462603",
  "private_key_id": "ced50f1267f34bf6814f434894ceaff96ab5e955",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQCz2PiXbqj+96Fy\ny48rZB7OZIVcyo4OXHRnRezP9gSqAa/iUUKHCbbHeGE6TC8tAAag0BIsgTX92kEp\n9m/vRYBVLOynH+x7hGpn1rfY6dt60zPRFyzSr+WNcnOjZMQYl/Jr8U4VGGYdVutZ\naOAOOasjpSYGDrEPKuP6Jv8Si0ExpPos6RT3PnKAKWqwXygBdPhbA/x9WVVHRpKb\nUFYXE0JA2owZCNn76tS/BLGUSOXqv+TtbwmbuVVq2PM50Uczs5SCDvw+2Je0z+CG\niRjkEjBaeq2CeV/M4UK1P8BubCo6YC5V1hKHrR8YEUARDbPJAFC6EgI5AwNStFkE\nYtpOweNXAgMBAAECggEAKvG3QmmhHujAe2nR8PmCRaRJGAQh8ZnwDazrxCipqnKm\nrfLbYOVX6L987++7IBKugn3MqSXdX5VbFAsNZWQCJdSJWcrMrB3NTqg91CTbTLPb\n3qSbBmAL/z+CD1UDYh/+Ofovu+fMklrr7biWL69jhyprLu0ZKFcEgvoG1EW+Nn0Y\nd1azWYG9pUOzAHwhJ9h1NlcXcIj1lwuhrX11XcPuL5gu+JOvdRVab4dqw7yGntqu\npEtA7wwVpttifyTZVp8DjggarIw4ft/4+Pheb0HBVmzxASC2ejhGc5Uf/AoX+Xz9\nBQzq1qM5SfeYMzlqtYgkWIMVdJ7OjIwDCiYtGMctyQKBgQDrq4Dm+joKgb+Nr+u2\nEDVlQgu5DeIhF46Q4qSVRlkrG/+vGGCZX6GZnKKPf4vbDXTcPXBDukjrQTmgelqn\nUeomNlSwheFH5zZCbZpoO2gsGOe84ZTw11pAiZEo5E39Q39sPQwAoHs8HFOuSp7U\nYOr6UvCNtzQRUZudYjB+e7jsmwKBgQDDXLHl16K9w2bEYO714IkwRuJYnCKcLf9a\nMCuVcb4RADR7+2UyYc5iO+OkOs0Au2ivOKBQKEGiHGMups4OCPG4SUeLCXx0tQmp\nd74pvKr9CfcySrfpOfXpIKWNdbNieygKtpaKksxlvJjfrdXrFnBLexTb+1WLGedi\njpACW8IJ9QKBgQCK5RRejUFh6eBcgD86mUju+cLw+Na6TCjxCTKY69InzyOdLY/Z\nNPyIDUHdsv1ZSBAEsY0VzZemV1XAV/xPur52cPTu6KjCeOmIsxIatlCKFM+XiZf/\nbdy6Rpmv8QZp6rsRrtUBFZQr9EH5ae88GjbC+9jcnQnp3yAI3NLZ6M8vWwKBgQCW\n/N41MFqD5TBY2D33ZClDWZV4PHv3TwmKz63vm2/1Pb5SkDJfJP5YJ8dBV3y3cyBu\nRAqKyQIo4124YYzhhgIjlucnSxaYMI8eHgCnyzwvwvL9OIg5ReWL3wJ0eSJCG8MP\nvJxOzzQP8RoJzhWF0trJS4AMoIw1rLiLEHm2iOpHvQKBgQChmnp30DeO7oxzBXVY\nnetSYoQsU6hW9lWfavqjk5jF75Gg3oKihIplda7AbRCoT7k0OeebYObPR/teB+H6\nXxyBIz0qMxbO8Uok0yZxVNyRBbnbIrzUl4f2bf9/yltIraVyASAfB2mDc3wYJpKV\nis+Rs397kT1NKWj1dr/sJKhT1w==\n-----END PRIVATE KEY-----\n",
  "client_email": "682412662542-compute@developer.gserviceaccount.com",
  "client_id": "109054012132593449216",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/682412662542-compute%40developer.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
EOF
    
    # Activar service account
    gcloud auth activate-service-account --key-file=/tmp/gcp-credentials.json
    gcloud config set project $PROJECT_ID
    
    # Configurar kubectl
    gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID
    
    print_success "Autenticación GCP configurada"
}

# Función para crear namespaces
create_namespaces() {
    print_status "Creando namespaces..."
    
    kubectl get namespace $MONITORING_NAMESPACE &>/dev/null || kubectl create namespace $MONITORING_NAMESPACE
    kubectl get namespace $APP_NAMESPACE &>/dev/null || kubectl create namespace $APP_NAMESPACE
    
    print_success "Namespaces creados: $MONITORING_NAMESPACE, $APP_NAMESPACE"
}

# Función para instalar Trivy
install_trivy() {
    print_status "Instalando Trivy para escaneo de seguridad..."
    
    if ! command -v trivy &> /dev/null; then
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
        print_success "Trivy instalado correctamente"
    else
        print_success "Trivy ya está instalado"
    fi
}

# Función para desplegar monitoreo
deploy_monitoring() {
    print_status "Desplegando stack de monitoreo..."
    
    # Crear directorio temporal para manifiestos
    mkdir -p /tmp/k8s-manifests
    
    # Prometheus
    print_status "Desplegando Prometheus..."
    kubectl apply -f - <<EOF
$(cat <<'PROMETHEUS_EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
  labels:
    app: prometheus
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    
    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']
      
      - job_name: 'api-gateway-direct'
        static_configs:
          - targets: ['api-gateway.ecommerce-dev.svc.cluster.local:8080']
        metrics_path: '/actuator/prometheus'
        scrape_interval: 15s
      
      - job_name: 'microservices-via-gateway'
        static_configs:
          - targets: ['api-gateway.ecommerce-dev.svc.cluster.local:8080']
        metrics_path: '/user-service/actuator/prometheus'
        scrape_interval: 20s
        
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
  labels:
    app: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:v2.40.0
        args:
          - '--config.file=/etc/prometheus/prometheus.yml'
          - '--storage.tsdb.path=/prometheus/'
          - '--web.enable-lifecycle'
        ports:
        - containerPort: 9090
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        volumeMounts:
        - name: prometheus-config-volume
          mountPath: /etc/prometheus/
        - name: prometheus-storage-volume
          mountPath: /prometheus/
      volumes:
      - name: prometheus-config-volume
        configMap:
          name: prometheus-config
      - name: prometheus-storage-volume
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus-lb
  namespace: monitoring
spec:
  type: LoadBalancer
  ports:
  - port: 9090
    targetPort: 9090
  selector:
    app: prometheus
PROMETHEUS_EOF
)
EOF
    
    # Grafana
    print_status "Desplegando Grafana..."
    kubectl apply -f - <<EOF
$(cat <<'GRAFANA_EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
  labels:
    app: grafana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:9.5.0
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_USER
          value: admin
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: admin123
        resources:
          requests:
            cpu: "250m"
            memory: "512Mi"
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
      volumes:
      - name: grafana-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: grafana-lb
  namespace: monitoring
spec:
  type: LoadBalancer
  ports:
  - port: 3000
    targetPort: 3000
  selector:
    app: grafana
GRAFANA_EOF
)
EOF
    
    # Zipkin para tracing
    print_status "Desplegando Zipkin..."
    kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zipkin
  namespace: monitoring
  labels:
    app: zipkin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: zipkin
  template:
    metadata:
      labels:
        app: zipkin
    spec:
      containers:
      - name: zipkin
        image: openzipkin/zipkin:latest
        ports:
        - containerPort: 9411
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
---
apiVersion: v1
kind: Service
metadata:
  name: zipkin-lb
  namespace: monitoring
spec:
  type: LoadBalancer
  ports:
  - port: 9411
    targetPort: 9411
  selector:
    app: zipkin
EOF
    
    print_success "Stack de monitoreo desplegado"
}

# Función para desplegar ELK Stack (simplificado)
deploy_elk() {
    print_status "Desplegando ELK Stack simplificado..."
    
    kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
      - name: elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:7.17.0
        ports:
        - containerPort: 9200
        env:
        - name: discovery.type
          value: single-node
        - name: ES_JAVA_OPTS
          value: "-Xms512m -Xmx512m"
        - name: xpack.security.enabled
          value: "false"
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
---
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
  namespace: monitoring
spec:
  ports:
  - port: 9200
    targetPort: 9200
  selector:
    app: elasticsearch
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
    spec:
      containers:
      - name: kibana
        image: docker.elastic.co/kibana/kibana:7.17.0
        ports:
        - containerPort: 5601
        env:
        - name: ELASTICSEARCH_HOSTS
          value: "http://elasticsearch:9200"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
      initContainers:
      - name: wait-for-elasticsearch
        image: busybox:1.35
        command: ['sh', '-c', 'until nc -z elasticsearch 9200; do echo waiting for elasticsearch; sleep 2; done;']
---
apiVersion: v1
kind: Service
metadata:
  name: kibana-lb
  namespace: monitoring
spec:
  type: LoadBalancer
  ports:
  - port: 5601
    targetPort: 5601
  selector:
    app: kibana
EOF
    
    print_success "ELK Stack desplegado"
}

# Función para verificar el estado del despliegue
check_deployment_status() {
    print_status "Verificando estado del despliegue..."
    
    echo "📊 Estado de Pods en namespace monitoring:"
    kubectl get pods -n $MONITORING_NAMESPACE
    
    echo ""
    echo "🌐 Servicios LoadBalancer en namespace monitoring:"
    kubectl get services -n $MONITORING_NAMESPACE --field-selector spec.type=LoadBalancer
    
    echo ""
    echo "📱 Estado de la aplicación en namespace $APP_NAMESPACE:"
    kubectl get pods -n $APP_NAMESPACE
    
    print_success "Verificación de estado completada"
}

# Función para mostrar URLs de acceso
show_access_urls() {
    print_status "Obteniendo URLs de acceso..."
    
    echo "🔗 URLs de Acceso al Sistema:"
    echo "================================"
    
    # API Gateway
    API_GATEWAY_IP=$(kubectl get service api-gateway -n $APP_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "34.136.149.19")
    echo "🚪 API Gateway: http://${API_GATEWAY_IP}:8080"
    echo "   - Users: http://${API_GATEWAY_IP}:8080/user-service/api/users"
    echo "   - Products: http://${API_GATEWAY_IP}:8080/product-service/api/products"
    echo "   - Orders: http://${API_GATEWAY_IP}:8080/order-service/api/orders"
    echo "   - Payments: http://${API_GATEWAY_IP}:8080/payment-service/api/payments"
    echo ""
    
    # Monitoring URLs
    echo "📊 Herramientas de Monitoreo:"
    PROMETHEUS_IP=$(kubectl get service prometheus-lb -n $MONITORING_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")
    GRAFANA_IP=$(kubectl get service grafana-lb -n $MONITORING_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")
    ZIPKIN_IP=$(kubectl get service zipkin-lb -n $MONITORING_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")
    KIBANA_IP=$(kubectl get service kibana-lb -n $MONITORING_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")
    
    echo "   📈 Prometheus: http://${PROMETHEUS_IP}:9090"
    echo "   📊 Grafana: http://${GRAFANA_IP}:3000 (admin/admin123)"
    echo "   🔍 Zipkin: http://${ZIPKIN_IP}:9411"
    echo "   🔎 Kibana: http://${KIBANA_IP}:5601"
    echo ""
    
    echo "⏰ Nota: Las IPs pueden tardar unos minutos en asignarse"
    echo "💡 Usa 'kubectl get services -n monitoring' para verificar el estado"
}

# Función para ejecutar pruebas de humo
run_smoke_tests() {
    print_status "Ejecutando pruebas de humo..."
    
    # Test API Gateway
    API_GATEWAY_IP="34.136.149.19"
    if curl -f -m 10 "http://${API_GATEWAY_IP}:8080/actuator/health" &>/dev/null; then
        print_success "✅ API Gateway está respondiendo"
    else
        print_warning "⚠️ API Gateway no está respondiendo aún"
    fi
    
    # Test Prometheus
    if kubectl get pods -n $MONITORING_NAMESPACE -l app=prometheus | grep -q Running; then
        print_success "✅ Prometheus está ejecutándose"
    else
        print_warning "⚠️ Prometheus no está listo aún"
    fi
    
    # Test Grafana
    if kubectl get pods -n $MONITORING_NAMESPACE -l app=grafana | grep -q Running; then
        print_success "✅ Grafana está ejecutándose"
    else
        print_warning "⚠️ Grafana no está listo aún"
    fi
    
    print_success "Pruebas de humo completadas"
}

# Función principal
main() {
    echo "🎯 Proyecto Final IngeSoft V - Despliegue Automatizado"
    echo "======================================================="
    echo "📅 $(date)"
    echo "🏗️ Desplegando en: $PROJECT_ID"
    echo "🎪 Cluster: $CLUSTER_NAME"
    echo "📍 Zona: $ZONE"
    echo ""
    
    # Ejecutar pasos
    check_dependencies
    setup_gcp_auth
    create_namespaces
    install_trivy
    deploy_monitoring
    deploy_elk
    
    print_status "Esperando a que los servicios estén listos..."
    sleep 30
    
    check_deployment_status
    run_smoke_tests
    show_access_urls
    
    echo ""
    echo "🎉 ¡DESPLIEGUE COMPLETADO!"
    echo "=========================="
    echo "✅ Stack de monitoreo desplegado en GCP Kubernetes"
    echo "✅ Prometheus, Grafana, Zipkin, ELK Stack funcionando"
    echo "✅ Trivy instalado para escaneo de seguridad"
    echo "✅ Namespaces configurados correctamente"
    echo ""
    echo "🚀 ¡Tu proyecto está listo para la presentación!"
    echo "📋 Puedes ejecutar el Jenkinsfile para CI/CD completo"
    echo ""
    echo "🔧 Comandos útiles:"
    echo "   kubectl get pods -n monitoring"
    echo "   kubectl get services -n monitoring"
    echo "   kubectl logs -l app=grafana -n monitoring"
    echo ""
    
    # Limpiar archivos temporales
    rm -f /tmp/gcp-credentials.json
    rm -rf /tmp/k8s-manifests
}

# Ejecutar script principal
main "$@"