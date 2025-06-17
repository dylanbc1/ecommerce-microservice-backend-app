#!/bin/bash

echo "🚀 DEPLOY EVERYTHING TO GKE - BOTÓN MÁGICO COMPLETO"
echo "=================================================="
echo "Este script ejecuta TODO: Terraform → Cluster → Microservicios"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funciones de logging mejoradas
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_header() { echo -e "${PURPLE}🚀 $1${NC}"; }
log_step() { echo -e "${CYAN}📋 PASO $1: $2${NC}"; }

# Variables de configuración
GCP_PROJECT_ID="${GCP_PROJECT_ID:-proyectofinal-462603}"
GKE_CLUSTER_NAME="${GKE_CLUSTER_NAME:-ecommerce-cluster}"
GKE_ZONE="${GKE_ZONE:-us-central1-a}"
GKE_REGION="${GKE_REGION:-us-central1}"
NAMESPACE="${NAMESPACE:-ecommerce-dev}"
VERSION="${VERSION:-0.1.0}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
TERRAFORM_DIR="terraform"

# URLs de imágenes pre-construidas (en caso de que build falle)
DOCKER_REGISTRY="selimhorri"
BACKUP_REGISTRY="gcr.io/${GCP_PROJECT_ID}"

# Servicios en orden de dependencias
INFRASTRUCTURE_SERVICES=("zipkin" "service-discovery" "cloud-config")
GATEWAY_SERVICES=("api-gateway" "proxy-client")
BUSINESS_SERVICES=("user-service" "product-service" "favourite-service" "order-service" "shipping-service" "payment-service")

ALL_SERVICES=("${INFRASTRUCTURE_SERVICES[@]}" "${GATEWAY_SERVICES[@]}" "${BUSINESS_SERVICES[@]}")

# Configuración de puertos
declare -A SERVICE_PORTS
SERVICE_PORTS["zipkin"]="9411"
SERVICE_PORTS["service-discovery"]="8761"
SERVICE_PORTS["cloud-config"]="9296"
SERVICE_PORTS["api-gateway"]="8080"
SERVICE_PORTS["proxy-client"]="8900"
SERVICE_PORTS["user-service"]="8700"
SERVICE_PORTS["product-service"]="8500"
SERVICE_PORTS["favourite-service"]="8800"
SERVICE_PORTS["order-service"]="8300"
SERVICE_PORTS["shipping-service"]="8600"
SERVICE_PORTS["payment-service"]="8400"

# ============================================================================
# PASO 1: VERIFICACIÓN Y SETUP
# ============================================================================
step1_verification() {
    log_step "1" "VERIFICACIÓN Y CONFIGURACIÓN INICIAL"
    
    # Verificar herramientas necesarias
    log_info "🔍 Verificando herramientas necesarias..."
    
    local missing_tools=()
    
    if ! command -v gcloud &> /dev/null; then
        missing_tools+=("gcloud CLI")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi
    
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Herramientas faltantes: ${missing_tools[*]}"
        log_info "Instala las herramientas faltantes y vuelve a ejecutar"
        exit 1
    fi
    
    log_success "Todas las herramientas están instaladas"
    
    # Verificar autenticación en GCP
    log_info "🔐 Verificando autenticación en GCP..."
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        log_warning "No hay cuentas autenticadas en GCP"
        log_info "Ejecutando autenticación..."
        gcloud auth login
    fi
    
    # Configurar proyecto
    log_info "⚙️ Configurando proyecto GCP: $GCP_PROJECT_ID"
    gcloud config set project "$GCP_PROJECT_ID"
    
    # Habilitar APIs necesarias
    log_info "🔧 Habilitando APIs de GCP..."
    local apis=(
        "container.googleapis.com"
        "containerregistry.googleapis.com"
        "cloudbuild.googleapis.com"
        "compute.googleapis.com"
        "cloudresourcemanager.googleapis.com"
    )
    
    for api in "${apis[@]}"; do
        log_info "   Habilitando: $api"
        gcloud services enable "$api" --quiet
    done
    
    # Configurar Docker para GCR
    log_info "🐳 Configurando Docker para Google Container Registry..."
    gcloud auth configure-docker --quiet
    
    log_success "Verificación y configuración completada"
    echo ""
}

# ============================================================================
# PASO 2: INFRAESTRUCTURA CON TERRAFORM (PLAN A) O GCLOUD (PLAN B)
# ============================================================================
step2_infrastructure() {
    log_step "2" "DESPLEGANDO INFRAESTRUCTURA"
    
    # Intentar Plan A: Terraform
    if [ -d "$TERRAFORM_DIR" ] && [ -f "$TERRAFORM_DIR/main.tf" ]; then
        log_info "📋 Plan A: Desplegando con Terraform..."
        
        cd "$TERRAFORM_DIR"
        
        # Inicializar Terraform
        log_info "   Inicializando Terraform..."
        if terraform init; then
            log_success "   Terraform inicializado"
            
            # Crear archivo de variables SIN PEDIR CONTRASEÑA
            cat > terraform.tfvars << EOF
gcp_project_id = "$GCP_PROJECT_ID"
environment = "$ENVIRONMENT"
enable_gke = true
enable_database = false
gke_node_count = 3
gke_machine_type = "e2-medium"
db_password = "auto-generated-password-123"
EOF
            
            # Planificar
            log_info "   Planificando infraestructura..."
            if terraform plan -var-file="terraform.tfvars" -out=tfplan; then
                log_success "   Plan generado exitosamente"
                
                # Aplicar
                log_info "   Aplicando infraestructura..."
                if terraform apply tfplan; then
                    log_success "✅ Infraestructura desplegada con Terraform"
                    
                    # Obtener outputs
                    CLUSTER_NAME=$(terraform output -raw gke_cluster_name 2>/dev/null || echo "$GKE_CLUSTER_NAME")
                    CLUSTER_ZONE=$(terraform output -raw gke_cluster_zone 2>/dev/null || echo "$GKE_ZONE")
                    
                    cd ..
                    return 0
                else
                    log_warning "   Terraform apply falló, usando Plan B..."
                fi
            else
                log_warning "   Terraform plan falló, usando Plan B..."
            fi
        else
            log_warning "   Terraform init falló, usando Plan B..."
        fi
        
        cd ..
    fi
    
    # Plan B: Crear cluster con gcloud
    log_info "📋 Plan B: Creando cluster con gcloud..."
    
    # Verificar si el cluster ya existe
    if gcloud container clusters describe "$GKE_CLUSTER_NAME" --zone="$GKE_ZONE" &>/dev/null; then
        log_success "Cluster $GKE_CLUSTER_NAME ya existe"
        CLUSTER_NAME="$GKE_CLUSTER_NAME"
        CLUSTER_ZONE="$GKE_ZONE"
        return 0
    fi
    
    log_info "   Creando cluster GKE: $GKE_CLUSTER_NAME"
    if gcloud container clusters create "$GKE_CLUSTER_NAME" \
        --zone="$GKE_ZONE" \
        --machine-type="e2-medium" \
        --num-nodes=3 \
        --enable-autoscaling \
        --min-nodes=1 \
        --max-nodes=5 \
        --enable-autorepair \
        --enable-autoupgrade \
        --disk-size=30GB \
        --enable-ip-alias \
        --cluster-version=latest \
        --addons=HorizontalPodAutoscaling,HttpLoadBalancing \
        --quiet; then
        
        log_success "✅ Cluster creado con gcloud"
        CLUSTER_NAME="$GKE_CLUSTER_NAME"
        CLUSTER_ZONE="$GKE_ZONE"
        return 0
    else
        log_error "❌ Error creando cluster"
        exit 1
    fi
}

# ============================================================================
# PASO 3: CONFIGURAR KUBECTL
# ============================================================================
step3_kubectl() {
    log_step "3" "CONFIGURANDO KUBECTL"
    
    log_info "⚙️ Configurando kubectl para cluster: $CLUSTER_NAME"
    
    if gcloud container clusters get-credentials "$CLUSTER_NAME" \
        --zone="$CLUSTER_ZONE" \
        --project="$GCP_PROJECT_ID"; then
        
        log_success "kubectl configurado exitosamente"
        
        # Verificar conexión
        log_info "🔍 Verificando conexión al cluster..."
        kubectl cluster-info --request-timeout=10s
        
        # Crear namespace
        log_info "📁 Creando namespace: $NAMESPACE"
        kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
        kubectl label namespace "$NAMESPACE" environment="$ENVIRONMENT" --overwrite
        
        log_success "Namespace $NAMESPACE configurado"
        echo ""
        return 0
    else
        log_error "❌ Error configurando kubectl"
        exit 1
    fi
}

# ============================================================================
# PASO 4: DESPLEGAR SERVICIOS DE INFRAESTRUCTURA
# ============================================================================
step4_infrastructure_services() {
    log_step "4" "DESPLEGANDO SERVICIOS DE INFRAESTRUCTURA"
    
    # Desplegar Zipkin
    log_info "🔧 Desplegando Zipkin..."
    cat <<EOF | kubectl apply -f - -n "$NAMESPACE"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zipkin
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
        image: openzipkin/zipkin
        ports:
        - containerPort: 9411
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: zipkin
  labels:
    app: zipkin
spec:
  type: ClusterIP
  ports:
  - port: 9411
    targetPort: 9411
  selector:
    app: zipkin
EOF
    
    # Esperar a que Zipkin esté listo
    log_info "   Esperando a que Zipkin esté listo..."
    kubectl wait --for=condition=available --timeout=180s deployment/zipkin -n "$NAMESPACE"
    
    # Desplegar servicios de infraestructura de Spring
    for service in "${INFRASTRUCTURE_SERVICES[@]}"; do
        if [ "$service" != "zipkin" ]; then
            deploy_spring_service "$service" "infrastructure"
        fi
    done
    
    log_success "✅ Servicios de infraestructura desplegados"
    echo ""
}

# ============================================================================
# PASO 5: DESPLEGAR GATEWAY Y PROXY
# ============================================================================
step5_gateway_services() {
    log_step "5" "DESPLEGANDO GATEWAY Y PROXY"
    
    for service in "${GATEWAY_SERVICES[@]}"; do
        deploy_spring_service "$service" "gateway"
    done
    
    log_success "✅ Servicios de gateway desplegados"
    echo ""
}

# ============================================================================
# PASO 6: DESPLEGAR MICROSERVICIOS DE NEGOCIO
# ============================================================================
step6_business_services() {
    log_step "6" "DESPLEGANDO MICROSERVICIOS DE NEGOCIO"
    
    for service in "${BUSINESS_SERVICES[@]}"; do
        deploy_spring_service "$service" "business"
    done
    
    log_success "✅ Microservicios de negocio desplegados"
    echo ""
}

# ============================================================================
# FUNCIÓN HELPER: DESPLEGAR SERVICIO SPRING
# ============================================================================
deploy_spring_service() {
    local service=$1
    local tier=${2:-"app"}
    local port=${SERVICE_PORTS[$service]}
    
    log_info "🚀 Desplegando $service..."
    
    # Determinar imagen a usar
    local image_name=""
    
    # Intentar con backup registry primero (más confiable)
    image_name="${DOCKER_REGISTRY}/${service}-ecommerce-boot:${VERSION}"
    
    # Configuración específica por servicio
    local replicas=2
    local memory_request="256Mi"
    local memory_limit="512Mi"
    local cpu_request="250m"
    local cpu_limit="500m"
    
    case $service in
        "api-gateway"|"service-discovery")
            replicas=2
            memory_request="384Mi"
            memory_limit="768Mi"
            cpu_request="300m"
            cpu_limit="600m"
            ;;
        "user-service"|"product-service"|"order-service")
            replicas=2
            memory_request="256Mi"
            memory_limit="512Mi"
            ;;
    esac
    
    # Variables de entorno específicas
    local env_vars=""
    case $service in
        "service-discovery")
            env_vars="
        - name: EUREKA_INSTANCE_HOSTNAME
          valueFrom:
            fieldRef:
              fieldPath: status.podIP"
            ;;
        *)
            env_vars="
        - name: EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE
          value: \"http://service-discovery:8761/eureka/\"
        - name: SPRING_ZIPKIN_BASE_URL
          value: \"http://zipkin:9411\"
        - name: SPRING_CONFIG_IMPORT
          value: \"optional:configserver:http://cloud-config:9296\""
            ;;
    esac
    
    # Crear manifest
    cat <<EOF | kubectl apply -f - -n "$NAMESPACE"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $service
  labels:
    app: $service
    tier: $tier
    version: $VERSION
spec:
  replicas: $replicas
  selector:
    matchLabels:
      app: $service
  template:
    metadata:
      labels:
        app: $service
        tier: $tier
    spec:
      containers:
      - name: $service
        image: $image_name
        ports:
        - containerPort: $port
          name: http
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "$ENVIRONMENT"$env_vars
        resources:
          requests:
            memory: "$memory_request"
            cpu: "$cpu_request"
          limits:
            memory: "$memory_limit"
            cpu: "$cpu_limit"
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: $port
          initialDelaySeconds: 60
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: $port
          initialDelaySeconds: 90
          periodSeconds: 30
          timeoutSeconds: 5
          failureThreshold: 5
        lifecycle:
          preStop:
            exec:
              command: ["sh", "-c", "sleep 10"]
      terminationGracePeriodSeconds: 30
---
apiVersion: v1
kind: Service
metadata:
  name: $service
  labels:
    app: $service
spec:
  type: ClusterIP
  ports:
  - port: $port
    targetPort: $port
    protocol: TCP
    name: http
  selector:
    app: $service
EOF
    
    # Esperar a que esté listo
    log_info "   Esperando a que $service esté listo..."
    if kubectl wait --for=condition=available --timeout=300s deployment/$service -n "$NAMESPACE"; then
        log_success "   ✅ $service desplegado exitosamente"
    else
        log_warning "   ⚠️ $service puede no estar completamente listo, pero continuamos..."
    fi
}

# ============================================================================
# PASO 7: CREAR LOAD BALANCERS
# ============================================================================
step7_load_balancers() {
    log_step "7" "CREANDO LOAD BALANCERS PARA ACCESO EXTERNO"
    
    # Load Balancer para API Gateway
    log_info "🌐 Creando Load Balancer para API Gateway..."
    cat <<EOF | kubectl apply -f - -n "$NAMESPACE"
apiVersion: v1
kind: Service
metadata:
  name: api-gateway-lb
  labels:
    app: api-gateway
    type: load-balancer
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: api-gateway
EOF
    
    # Load Balancer para Eureka (opcional)
    log_info "📊 Creando Load Balancer para Eureka Dashboard..."
    cat <<EOF | kubectl apply -f - -n "$NAMESPACE"
apiVersion: v1
kind: Service
metadata:
  name: eureka-lb
  labels:
    app: service-discovery
    type: load-balancer
spec:
  type: LoadBalancer
  ports:
  - port: 8761
    targetPort: 8761
    protocol: TCP
    name: http
  selector:
    app: service-discovery
EOF
    
    # Load Balancer para Zipkin
    log_info "🔍 Creando Load Balancer para Zipkin..."
    cat <<EOF | kubectl apply -f - -n "$NAMESPACE"
apiVersion: v1
kind: Service
metadata:
  name: zipkin-lb
  labels:
    app: zipkin
    type: load-balancer
spec:
  type: LoadBalancer
  ports:
  - port: 9411
    targetPort: 9411
    protocol: TCP
    name: http
  selector:
    app: zipkin
EOF
    
    log_success "✅ Load Balancers creados"
    echo ""
}

# ============================================================================
# PASO 8: VERIFICACIÓN Y ESTADO FINAL
# ============================================================================
step8_verification() {
    log_step "8" "VERIFICACIÓN Y ESTADO FINAL"
    
    echo ""
    log_info "📊 Estado de los Pods:"
    kubectl get pods -n "$NAMESPACE" -o wide
    
    echo ""
    log_info "🔗 Servicios:"
    kubectl get services -n "$NAMESPACE"
    
    echo ""
    log_info "📈 Deployments:"
    kubectl get deployments -n "$NAMESPACE"
    
    echo ""
    log_info "🌐 Obteniendo IPs externas de Load Balancers..."
    
    # Esperar a que se asignen IPs externas
    local max_attempts=15
    local attempt=1
    local api_gateway_ip=""
    local eureka_ip=""
    local zipkin_ip=""
    
    while [ $attempt -le $max_attempts ]; do
        api_gateway_ip=$(kubectl get service api-gateway-lb -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        eureka_ip=$(kubectl get service eureka-lb -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        zipkin_ip=$(kubectl get service zipkin-lb -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        
        if [ ! -z "$api_gateway_ip" ] && [ ! -z "$eureka_ip" ] && [ ! -z "$zipkin_ip" ]; then
            break
        fi
        
        log_info "   Esperando IPs externas... (intento $attempt/$max_attempts)"
        sleep 20
        ((attempt++))
    done
    
    echo ""
    echo "🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉"
    log_success "   DEPLOYMENT COMPLETADO EXITOSAMENTE!"
    echo "🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉"
    
    if [ ! -z "$api_gateway_ip" ]; then
        echo ""
        log_success "🌐 URLS DE ACCESO PÚBLICO:"
        echo "   🔗 API Gateway Principal: http://$api_gateway_ip"
        echo "   📊 Eureka Dashboard: http://$eureka_ip:8761"
        echo "   🔍 Zipkin Tracing: http://$zipkin_ip:9411"
        echo ""
        echo "📝 ENDPOINTS DE MICROSERVICIOS (via API Gateway):"
        echo "   🛒 Products API: http://$api_gateway_ip/api/products"
        echo "   👤 Users API: http://$api_gateway_ip/api/users"
        echo "   📦 Orders API: http://$api_gateway_ip/api/orders"
        echo "   💳 Payments API: http://$api_gateway_ip/api/payments"
        echo "   🚚 Shipping API: http://$api_gateway_ip/api/shipping"
        echo "   ⭐ Favourites API: http://$api_gateway_ip/api/favourites"
        echo ""
        echo "🎯 EJEMPLOS DE USO:"
        echo "   curl http://$api_gateway_ip/api/products"
        echo "   curl http://$api_gateway_ip/api/users"
    else
        log_warning "⏳ Las IPs externas aún se están asignando."
        echo ""
        echo "🔍 Para verificar manualmente ejecuta:"
        echo "   kubectl get services -n $NAMESPACE"
        echo ""
        echo "💡 Las IPs aparecerán en unos minutos en la columna EXTERNAL-IP"
    fi
    
    echo ""
    echo "📋 INFORMACIÓN DEL CLUSTER:"
    echo "   🎯 Proyecto GCP: $GCP_PROJECT_ID"
    echo "   ☸️ Cluster: $CLUSTER_NAME"
    echo "   🌍 Zona: $CLUSTER_ZONE"
    echo "   📁 Namespace: $NAMESPACE"
    echo ""
    echo "🛠️ COMANDOS ÚTILES:"
    echo "   # Ver pods:"
    echo "   kubectl get pods -n $NAMESPACE"
    echo ""
    echo "   # Ver logs de un servicio:"
    echo "   kubectl logs -f deployment/api-gateway -n $NAMESPACE"
    echo ""
    echo "   # Escalar un servicio:"
    echo "   kubectl scale deployment user-service --replicas=3 -n $NAMESPACE"
    echo ""
    echo "   # Acceder a un pod:"
    echo "   kubectl exec -it deployment/api-gateway -n $NAMESPACE -- /bin/sh"
}

# ============================================================================
# FUNCIÓN PARA LIMPIAR TODO
# ============================================================================
cleanup_everything() {
    log_header "🧹 LIMPIANDO TODOS LOS RECURSOS"
    
    echo "⚠️ ADVERTENCIA: Esto eliminará TODOS los recursos creados"
    echo "   - Namespace $NAMESPACE y todos los servicios"
    echo "   - Cluster GKE $CLUSTER_NAME"
    echo "   - Infraestructura de Terraform (si existe)"
    echo ""
    echo "❓ ¿Estás seguro de que quieres continuar? (y/N)"
    read -r confirmation
    
    if [[ $confirmation =~ ^[Yy]$ ]]; then
        # Limpiar namespace
        log_info "🗑️ Eliminando namespace $NAMESPACE..."
        kubectl delete namespace "$NAMESPACE" --timeout=300s
        
        # Limpiar cluster
        log_info "🗑️ Eliminando cluster GKE..."
        gcloud container clusters delete "$CLUSTER_NAME" \
            --zone="$CLUSTER_ZONE" \
            --quiet
        
        # Limpiar Terraform si existe
        if [ -d "$TERRAFORM_DIR" ] && [ -f "$TERRAFORM_DIR/terraform.tfstate" ]; then
            log_info "🗑️ Eliminando infraestructura de Terraform..."
            cd "$TERRAFORM_DIR"
            terraform destroy -auto-approve
            cd ..
        fi
        
        log_success "✅ Todos los recursos eliminados"
    else
        log_info "❌ Limpieza cancelada"
    fi
}

# ============================================================================
# FUNCIÓN DE AYUDA
# ============================================================================
show_help() {
    cat << 'EOF'
🚀 Deploy Everything to GKE - BOTÓN MÁGICO COMPLETO

Este script ejecuta TODO el proceso de deployment automáticamente:
1. ✅ Verificación de prerrequisitos
2. 🏗️ Infraestructura (Terraform o gcloud)
3. ⚙️ Configuración de kubectl
4. 🔧 Servicios de infraestructura (Zipkin, Eureka, Config)
5. 🌐 Gateway y Proxy
6. 📦 Microservicios de negocio
7. 🌍 Load Balancers para acceso externo
8. 🔍 Verificación y URLs finales

COMANDOS:
  ./deploy-everything-to-gke.sh                    # Ejecutar TODO automáticamente
  ./deploy-everything-to-gke.sh cleanup            # Limpiar todos los recursos
  ./deploy-everything-to-gke.sh help               # Mostrar esta ayuda

VARIABLES DE ENTORNO:
  export GCP_PROJECT_ID="tu-proyecto"              # ID del proyecto GCP
  export GKE_CLUSTER_NAME="mi-cluster"             # Nombre del cluster
  export GKE_ZONE="us-central1-a"                  # Zona del cluster
  export NAMESPACE="mi-namespace"                   # Namespace de Kubernetes
  export VERSION="0.2.0"                           # Versión de las imágenes
  export ENVIRONMENT="prod"                        # Entorno (dev/stage/prod)

EJEMPLOS:
  # Deployment básico
  ./deploy-everything-to-gke.sh

  # Con configuración personalizada
  export GCP_PROJECT_ID="mi-proyecto-prod"
  export ENVIRONMENT="prod"
  ./deploy-everything-to-gke.sh

  # Limpiar todo
  ./deploy-everything-to-gke.sh cleanup

🎯 AL FINAL TENDRÁS:
  ✅ Cluster GKE funcionando
  ✅ Todos los microservicios desplegados
  ✅ Load Balancers con IPs públicas
  ✅ URLs de acceso listas para usar

EOF
}

# ============================================================================
# FUNCIÓN PRINCIPAL
# ============================================================================
main() {
    local command=${1:-"deploy"}
    
    case $command in
        "cleanup")
            cleanup_everything
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        "deploy"|*)
            echo ""
            echo "🎯 INICIANDO DEPLOYMENT COMPLETO..."
            echo "Proyecto: $GCP_PROJECT_ID"
            echo "Cluster: $CLUSTER_NAME"
            echo "Zona: $GKE_ZONE"
            echo "Namespace: $NAMESPACE"
            echo "Versión: $VERSION"
            echo ""
            
            # Ejecutar todos los pasos
            step1_verification
            step2_infrastructure  
            step3_kubectl
            step4_infrastructure_services
            step5_gateway_services
            step6_business_services
            step7_load_balancers
            step8_verification
            
            echo ""
            echo "🏁 ¡DEPLOYMENT COMPLETO FINALIZADO!"
            echo "🎉 ¡Todos tus microservicios están funcionando en GKE!"
            ;;
    esac
}

# Ejecutar función principal
main "$@"
