#!/bin/bash

# start-jenkins.sh - Script para iniciar Jenkins con configuración para Taller 2
# Versión optimizada para Docker Desktop + Kubernetes

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

echo "🚀 Iniciando Jenkins para Taller 2"
echo "=================================="
echo

# Verificar que Docker esté corriendo
if ! docker info &> /dev/null; then
    error "Docker no está corriendo. Por favor iniciar Docker Desktop."
    exit 1
fi

# Verificar si Jenkins ya está corriendo
if docker ps --format "table {{.Names}}" | grep -q "jenkins-taller2"; then
    warn "Jenkins ya está corriendo"
    
    echo "¿Qué deseas hacer?"
    echo "1) Ver logs de Jenkins"
    echo "2) Reiniciar Jenkins"
    echo "3) Parar Jenkins"
    echo "4) Salir"
    read -p "Selecciona una opción (1-4): " choice
    
    case $choice in
        1)
            echo "Mostrando logs de Jenkins..."
            docker logs -f jenkins-taller2
            ;;
        2)
            log "Reiniciando Jenkins..."
            docker restart jenkins-taller2
            ;;
        3)
            log "Parando Jenkins..."
            docker stop jenkins-taller2
            docker rm jenkins-taller2
            ;;
        4)
            exit 0
            ;;
        *)
            error "Opción no válida"
            exit 1
            ;;
    esac
    exit 0
fi

# Crear volumen para Jenkins si no existe
if ! docker volume inspect jenkins_home &> /dev/null; then
    log "Creando volumen jenkins_home..."
    docker volume create jenkins_home
fi

# Verificar puertos disponibles
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    error "Puerto 8080 ya está en uso. Liberar el puerto antes de continuar."
    exit 1
fi

if lsof -Pi :50000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    warn "Puerto 50000 ya está en uso. Jenkins funcionará pero sin agentes externos."
fi

log "Iniciando contenedor de Jenkins..."

# Crear red personalizada si no existe
if ! docker network inspect jenkins-network &> /dev/null; then
    log "Creando red jenkins-network..."
    docker network create jenkins-network
fi

# Obtener ruta de kubectl de forma segura
KUBECTL_PATH=$(which kubectl 2>/dev/null || echo "")
KUBE_CONFIG_PATH="$HOME/.kube"

# Preparar volúmenes opcionales
KUBECTL_VOLUME=""
KUBE_CONFIG_VOLUME=""

if [ -n "$KUBECTL_PATH" ] && [ -f "$KUBECTL_PATH" ]; then
    KUBECTL_VOLUME="-v \"$KUBECTL_PATH\":/usr/local/bin/kubectl:ro"
    log "kubectl encontrado en: $KUBECTL_PATH"
else
    warn "kubectl no encontrado. Se instalará dentro del contenedor si es necesario."
fi

if [ -d "$KUBE_CONFIG_PATH" ]; then
    KUBE_CONFIG_VOLUME="-v \"$KUBE_CONFIG_PATH\":/var/jenkins_home/.kube:ro"
    log "Configuración de Kubernetes encontrada en: $KUBE_CONFIG_PATH"
else
    warn "Configuración de Kubernetes no encontrada en $KUBE_CONFIG_PATH"
fi

# Iniciar Jenkins con configuración optimizada
docker run -d \
  --name jenkins-taller2 \
  --network jenkins-network \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)":/workspace:ro \
  --restart unless-stopped \
  --env JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Dhudson.security.csrf.DefaultCrumbIssuer.EXCLUDE_SESSION_ID=true" \
  --env JENKINS_OPTS="--httpPort=8080" \
  jenkins/jenkins:lts

if [ $? -eq 0 ]; then
    log "✅ Jenkins iniciado exitosamente"
else
    error "❌ Error al iniciar Jenkins"
    exit 1
fi

# Configurar kubectl dentro del contenedor si no se montó desde el host
if [ -z "$KUBECTL_PATH" ]; then
    log "Instalando kubectl dentro del contenedor..."
    docker exec -u root jenkins-taller2 bash -c '
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
        chmod +x kubectl && \
        mv kubectl /usr/local/bin/
    ' || warn "No se pudo instalar kubectl automáticamente"
fi

# Esperar a que Jenkins esté listo
log "Esperando a que Jenkins esté listo..."
echo -n "Iniciando"

max_attempts=60
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if curl -f -s http://localhost:8080/login >/dev/null 2>&1; then
        echo -e "\n"
        log "✅ Jenkins está listo!"
        break
    fi
    echo -n "."
    sleep 2
    attempt=$((attempt + 1))
done

if [ $attempt -eq $max_attempts ]; then
    echo -e "\n"
    error "Jenkins tardó demasiado en iniciar. Verificar logs:"
    echo "docker logs jenkins-taller2"
    exit 1
fi

# Obtener contraseña inicial de Jenkins
log "Obteniendo contraseña inicial de Jenkins..."
sleep 5

if docker exec jenkins-taller2 test -f /var/jenkins_home/secrets/initialAdminPassword; then
    JENKINS_PASSWORD=$(docker exec jenkins-taller2 cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null)
    
    echo
    info "🔑 CONTRASEÑA INICIAL DE JENKINS:"
    echo -e "${YELLOW}${JENKINS_PASSWORD}${NC}"
    echo
else
    warn "No se pudo obtener la contraseña inicial. Verificar logs."
fi

# Mostrar información de acceso
echo "📋 INFORMACIÓN DE ACCESO"
echo "========================"
echo "🌐 URL: http://localhost:8080"
echo "👤 Usuario: admin (después del setup inicial)"
echo "🔑 Contraseña inicial: ${JENKINS_PASSWORD:-'Ver logs con: docker logs jenkins-taller2'}"
echo
echo "📋 COMANDOS ÚTILES:"
echo "🔍 Ver logs: docker logs -f jenkins-taller2"
echo "🔄 Reiniciar: docker restart jenkins-taller2"
echo "🛑 Parar: docker stop jenkins-taller2"
echo "🗑️ Eliminar: docker stop jenkins-taller2 && docker rm jenkins-taller2"
echo

# Verificar conectividad con Kubernetes
log "Verificando conectividad con Kubernetes..."
if docker exec jenkins-taller2 kubectl version --client >/dev/null 2>&1; then
    log "✅ kubectl está disponible en Jenkins"
    if docker exec jenkins-taller2 kubectl cluster-info >/dev/null 2>&1; then
        log "✅ Jenkins puede conectarse a Kubernetes"
    else
        warn "⚠️ kubectl disponible pero no se puede conectar al cluster. Verificar configuración."
    fi
else
    warn "⚠️ kubectl no está disponible en Jenkins."
fi

# Crear script de ayuda
cat << 'EOF' > jenkins-helper.sh
#!/bin/bash
# Script de ayuda para Jenkins

case $1 in
    "logs")
        docker logs -f jenkins-taller2
        ;;
    "password")
        docker exec jenkins-taller2 cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "Contraseña no disponible"
        ;;
    "restart")
        docker restart jenkins-taller2
        ;;
    "stop")
        docker stop jenkins-taller2
        ;;
    "remove")
        docker stop jenkins-taller2
        docker rm jenkins-taller2
        ;;
    "status")
        docker ps --filter name=jenkins-taller2 --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    "kubectl")
        docker exec -it jenkins-taller2 kubectl "$@"
        ;;
    *)
        echo "Uso: $0 {logs|password|restart|stop|remove|status|kubectl}"
        echo
        echo "Comandos disponibles:"
        echo "  logs     - Mostrar logs de Jenkins"
        echo "  password - Mostrar contraseña inicial"
        echo "  restart  - Reiniciar Jenkins"
        echo "  stop     - Parar Jenkins"
        echo "  remove   - Eliminar contenedor de Jenkins"
        echo "  status   - Mostrar estado de Jenkins"
        echo "  kubectl  - Ejecutar kubectl desde Jenkins"
        ;;
esac
EOF

chmod +x jenkins-helper.sh

log "✅ Script de ayuda creado: jenkins-helper.sh"

echo
info "🎯 PRÓXIMOS PASOS:"
echo "1. Abrir http://localhost:8080 en el navegador"
echo "2. Usar la contraseña inicial mostrada arriba"
echo "3. Instalar plugins sugeridos"
echo "4. Crear usuario administrador"
echo "5. Configurar pipeline con el Jenkinsfile del proyecto"
echo
info "💡 TIP: Usar './jenkins-helper.sh logs' para ver logs en tiempo real"
echo
log "🚀 ¡Jenkins listo para el Taller 2!"