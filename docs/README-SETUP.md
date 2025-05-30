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
