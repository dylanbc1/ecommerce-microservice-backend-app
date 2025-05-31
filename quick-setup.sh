#!/bin/bash

# quick-setup.sh - Script de configuración rápida para Taller 2
# Versión simplificada pero funcional

set -e

echo "🚀 Configuración Rápida - Taller 2: Pruebas y Lanzamiento"
echo "=========================================================="
echo

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
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

# Verificar requisitos
check_requirements() {
    log "Verificando requisitos del sistema..."
    
    # Docker
    if ! command -v docker &> /dev/null; then
        error "Docker no está instalado. Por favor instalar Docker Desktop."
        exit 1
    fi
    
    # Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        warn "Docker Compose no encontrado, pero no es crítico."
    fi
    
    # kubectl
    if ! command -v kubectl &> /dev/null; then
        error "kubectl no está instalado. Por favor instalar kubectl."
        exit 1
    fi
    
    # Java
    if ! command -v java &> /dev/null; then
        error "Java no está instalado. Se requiere Java 11+"
        exit 1
    fi
    
    # Maven
    if ! command -v mvn &> /dev/null; then
        warn "Maven no encontrado globalmente. Se usarán los wrappers ./mvnw"
    fi
    
    # Python (para Locust)
    if ! command -v python3 &> /dev/null; then
        warn "Python 3 no encontrado. Las pruebas de rendimiento podrían fallar."
    fi
    
    log "✅ Verificación de requisitos completada"
}

# Verificar Docker Desktop y Kubernetes
check_docker_kubernetes() {
    log "Verificando Docker Desktop y Kubernetes..."
    
    # Verificar que Docker esté corriendo
    if ! docker info &> /dev/null; then
        error "Docker no está corriendo. Por favor iniciar Docker Desktop."
        exit 1
    fi
    
    # Verificar Kubernetes
    if ! kubectl cluster-info &> /dev/null; then
        error "Kubernetes no está disponible. Habilitar Kubernetes en Docker Desktop."
        exit 1
    fi
    
    # Verificar contexto de Docker Desktop
    CURRENT_CONTEXT=$(kubectl config current-context)
    if [[ "$CURRENT_CONTEXT" != "docker-desktop" ]]; then
        warn "Contexto actual: $CURRENT_CONTEXT. Cambiando a docker-desktop..."
        kubectl config use-context docker-desktop
    fi
    
    log "✅ Docker Desktop y Kubernetes funcionando correctamente"
}

# Crear estructura de directorios
create_directory_structure() {
    log "Creando estructura de directorios..."
    
    # Directorios principales
    mkdir -p k8s/{namespace,api-gateway,proxy-client,user-service,product-service,order-service,payment-service}
    mkdir -p tests/{unit,integration,e2e,performance}
    mkdir -p tests/performance/results
    mkdir -p docker/scripts
    mkdir -p docs
    
    log "✅ Estructura de directorios creada"
}

# Configurar Jenkins local
setup_jenkins() {
    log "Configurando Jenkins local..."
    
    # Crear volumen para Jenkins si no existe
    if ! docker volume inspect jenkins_home &> /dev/null; then
        docker volume create jenkins_home
        log "Volumen jenkins_home creado"
    fi
    
    # Verificar si Jenkins ya está corriendo
    if docker ps | grep -q jenkins; then
        info "Jenkins ya está corriendo"
        return
    fi
    
    # Iniciar Jenkins
    cat << 'EOF' > docker/scripts/start-jenkins.sh
#!/bin/bash
docker run -d \
  --name jenkins-taller2 \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(which kubectl):/usr/local/bin/kubectl \
  -v ~/.kube:/var/jenkins_home/.kube \
  --restart unless-stopped \
  jenkins/jenkins:lts

echo "Jenkins iniciado en http://localhost:8080"
echo "Ejecutar 'docker logs jenkins-taller2' para ver la contraseña inicial"
EOF
    
    chmod +x docker/scripts/start-jenkins.sh
    
    info "Script de Jenkins creado en docker/scripts/start-jenkins.sh"
    info "Ejecutar './docker/scripts/start-jenkins.sh' para iniciar Jenkins"
}

# Crear manifiestos básicos de Kubernetes
create_kubernetes_manifests() {
    log "Creando manifiestos de Kubernetes..."
    
    # Namespace
    cat << 'EOF' > k8s/namespace/namespaces.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ecommerce-dev
  labels:
    environment: development
---
apiVersion: v1
kind: Namespace
metadata:
  name: ecommerce-stage
  labels:
    environment: staging
---
apiVersion: v1
kind: Namespace
metadata:
  name: ecommerce-prod
  labels:
    environment: production
EOF

    # Template de deployment
    cat << 'EOF' > k8s/deployment-template.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{SERVICE_NAME}}
  labels:
    app: {{SERVICE_NAME}}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: {{SERVICE_NAME}}
  template:
    metadata:
      labels:
        app: {{SERVICE_NAME}}
    spec:
      containers:
      - name: {{SERVICE_NAME}}
        image: {{IMAGE_NAME}}
        ports:
        - containerPort: {{PORT}}
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "kubernetes"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: {{PORT}}
          initialDelaySeconds: 60
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: {{SERVICE_NAME}}
  labels:
    app: {{SERVICE_NAME}}
spec:
  type: ClusterIP
  ports:
  - port: {{PORT}}
    targetPort: {{PORT}}
    protocol: TCP
    name: http
  selector:
    app: {{SERVICE_NAME}}
EOF

    log "✅ Manifiestos de Kubernetes creados"
}

# Crear archivos de pruebas de rendimiento
create_performance_tests() {
    log "Creando archivos de pruebas de rendimiento..."
    
    # Locustfile básico
    cat << 'EOF' > tests/performance/locustfile.py
from locust import HttpUser, task, between
import random

class EcommerceUser(HttpUser):
    wait_time = between(1, 3)
    
    @task(3)
    def browse_products(self):
        self.client.get("/app/api/products")
        
        # Ver producto específico
        product_id = random.randint(1, 10)
        self.client.get(f"/app/api/products/{product_id}")
    
    @task(2)
    def search_products(self):
        search_terms = ["laptop", "phone", "book"]
        term = random.choice(search_terms)
        self.client.get(f"/app/api/products/search?q={term}")
    
    @task(1)
    def view_categories(self):
        self.client.get("/app/api/categories")
EOF

    # Script de ejecución
    cat << 'EOF' > tests/performance/run_tests.py
#!/usr/bin/env python3
import subprocess
import sys
import os
from datetime import datetime

def run_performance_test(test_type="standard", host="http://localhost"):
    config = {
        "light": {"users": 10, "spawn_rate": 1, "duration": 60},
        "standard": {"users": 20, "spawn_rate": 2, "duration": 120},
        "stress": {"users": 50, "spawn_rate": 5, "duration": 300}
    }
    
    if test_type not in config:
        print(f"Tipo de prueba no válido: {test_type}")
        return False
    
    cfg = config[test_type]
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    cmd = [
        "locust",
        "-f", "locustfile.py",
        "--headless",
        "--users", str(cfg["users"]),
        "--spawn-rate", str(cfg["spawn_rate"]),
        "--run-time", f"{cfg['duration']}s",
        "--host", host,
        "--html", f"results/{test_type}_report_{timestamp}.html",
        "--csv", f"results/{test_type}_data_{timestamp}"
    ]
    
    print(f"Ejecutando prueba {test_type}...")
    try:
        result = subprocess.run(cmd, timeout=cfg["duration"]+60)
        return result.returncode == 0
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == "__main__":
    test_type = sys.argv[1] if len(sys.argv) > 1 else "standard"
    host = sys.argv[2] if len(sys.argv) > 2 else "http://localhost"
    
    success = run_performance_test(test_type, host)
    sys.exit(0 if success else 1)
EOF

    chmod +x tests/performance/run_tests.py
    
    # Requirements para Python
    cat << 'EOF' > tests/performance/requirements.txt
locust>=2.8.0
requests>=2.28.0
EOF

    log "✅ Archivos de pruebas de rendimiento creados"
}

# Crear archivo de configuración del proyecto
create_project_config() {
    log "Creando configuración del proyecto..."
    
    cat << 'EOF' > project-config.yaml
# Configuración del proyecto Taller 2
project:
  name: "ecommerce-microservices-taller2"
  version: "1.0.0"
  description: "Implementación simplificada del Taller 2"

microservices:
  - name: "api-gateway"
    port: 8080
    health_path: "/actuator/health"
  - name: "proxy-client"
    port: 8900
    health_path: "/actuator/health"
  - name: "user-service"
    port: 8700
    health_path: "/actuator/health"
  - name: "product-service"
    port: 8500
    health_path: "/actuator/health"
  - name: "order-service"
    port: 8300
    health_path: "/actuator/health"
  - name: "payment-service"
    port: 8400
    health_path: "/actuator/health"

environments:
  dev:
    namespace: "ecommerce-dev"
    replicas: 1
  stage:
    namespace: "ecommerce-stage"
    replicas: 2
  prod:
    namespace: "ecommerce-prod"
    replicas: 3

testing:
  performance:
    light:
      users: 10
      spawn_rate: 1
      duration: 60
    standard:
      users: 20
      spawn_rate: 2
      duration: 120
    stress:
      users: 50
      spawn_rate: 5
      duration: 300
EOF

    log "✅ Configuración del proyecto creada"
}

# Crear documentación básica
create_documentation() {
    log "Creando documentación básica..."
    
    cat << 'EOF' > docs/README-SETUP.md
# Guía de Configuración Rápida - Taller 2

## ✅ Requisitos Previos
- Docker Desktop con Kubernetes habilitado
- Java 11+
- kubectl configurado
- Python 3 (opcional, para pruebas de rendimiento)

## 🚀 Inicio Rápido

1. **Ejecutar configuración automática:**
   ```bash
   ./quick-setup.sh
   ```

2. **Iniciar Jenkins:**
   ```bash
   ./docker/scripts/start-jenkins.sh
   ```

3. **Obtener contraseña inicial de Jenkins:**
   ```bash
   docker logs jenkins-taller2
   ```

4. **Acceder a Jenkins:**
   - URL: http://localhost:8080
   - Instalar plugins sugeridos
   - Crear usuario administrador

## 🏗️ Estructura del Proyecto

```
.
├── Jenkinsfile              # Pipeline principal
├── k8s/                     # Manifiestos de Kubernetes
├── tests/                   # Todas las pruebas
│   ├── unit/               # Pruebas unitarias
│   ├── integration/        # Pruebas de integración
│   ├── e2e/               # Pruebas end-to-end
│   └── performance/        # Pruebas de rendimiento (Locust)
├── docker/                 # Scripts de Docker
└── docs/                   # Documentación
```

## 🧪 Ejecutar Pruebas

### Pruebas Unitarias
```bash
# En cada microservicio
./mvnw test
```

### Pruebas de Rendimiento
```bash
cd tests/performance
python3 run_tests.py standard
```

## 🚀 Ejecutar Pipeline

1. Crear nuevo pipeline en Jenkins
2. Usar "Pipeline script from SCM"
3. Apuntar al Jenkinsfile en el repositorio
4. Configurar parámetros:
   - ENVIRONMENT: dev/stage/master
   - BUILD_TAG: (automático)
   - SKIP_TESTS: false
   - PERFORMANCE_TEST_LEVEL: standard

## 📊 Resultados

- **Reportes de pruebas**: Disponibles en Jenkins
- **Release Notes**: Generadas automáticamente
- **Métricas de rendimiento**: En HTML artifacts
EOF

    cat << 'EOF' > docs/TROUBLESHOOTING.md
# Guía de Solución de Problemas

## 🐛 Problemas Comunes

### Jenkins no inicia
- Verificar que Docker esté corriendo
- Verificar puertos disponibles (8080, 50000)
- Revisar logs: `docker logs jenkins-taller2`

### Kubernetes no disponible
- Habilitar Kubernetes en Docker Desktop
- Verificar contexto: `kubectl config current-context`
- Cambiar contexto: `kubectl config use-context docker-desktop`

### Pruebas de rendimiento fallan
- Instalar Locust: `pip3 install locust`
- Verificar conectividad del host
- Revisar logs en tests/performance/results/

### Build Maven falla
- Verificar Java version: `java -version`
- Limpiar caché: `./mvnw clean`
- Verificar conectividad a internet

## 📞 Soporte

Si los problemas persisten:
1. Revisar logs detallados
2. Verificar requisitos del sistema
3. Consultar documentación original del proyecto
EOF

    log "✅ Documentación básica creada"
}

# Función principal
main() {
    echo "Iniciando configuración automática..."
    echo
    
    # Verificaciones
    check_requirements
    check_docker_kubernetes
    
    # Configuración
    create_directory_structure
    setup_jenkins
    create_kubernetes_manifests
    create_performance_tests
    create_project_config
    create_documentation
    
    echo
    log "🎉 ¡Configuración completada exitosamente!"
    echo
    info "Próximos pasos:"
    echo "1. Ejecutar: ./docker/scripts/start-jenkins.sh"
    echo "2. Acceder a http://localhost:8080"
    echo "3. Configurar pipeline con el Jenkinsfile"
    echo "4. Revisar docs/README-SETUP.md para más detalles"
    echo
    info "Estructura creada:"
    tree -L 2 -a 2>/dev/null || ls -la
}

# Verificar si se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi