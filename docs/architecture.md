# Arquitectura de Infraestructura

## Descripción General

Esta arquitectura implementa una aplicación de e-commerce con microservicios desplegada en Google Cloud Platform usando Terraform para la gestión de infraestructura como código.

## Componentes de la Arquitectura

### 1. Red (VPC)
- **VPC personalizada** con subredes públicas y privadas
- **Firewall rules** para controlar el tráfico
- **Cloud NAT** para acceso a internet desde subredes privadas

### 2. Compute
- **Compute Engine instances** para alojar la aplicación
- **Instance groups** para escalabilidad
- **Load balancer** para distribución de tráfico

### 3. Base de Datos
- **Cloud SQL (PostgreSQL)** para datos transaccionales
- **Cloud Memorystore (Redis)** para caché
- **Backup automático** y alta disponibilidad

### 4. Kubernetes 
- **Google Kubernetes Engine (GKE)** para orquestación de contenedores
- **Node pools** con auto-scaling
- **Workload Identity** para seguridad

### 5. Monitoreo y Logging
- **Cloud Monitoring** para métricas
- **Cloud Logging** para logs centralizados
- **Cloud Trace** para tracing distribuido

## Diagrama de Arquitectura

<div style="text-align: center; margin: 20px 0;">
  <a href="architecture.html" style="
    display: inline-block;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 15px 30px;
    text-decoration: none;
    border-radius: 10px;
    font-weight: bold;
    font-size: 16px;
    box-shadow: 0 4px 15px rgba(0,0,0,0.2);
    transition: transform 0.3s ease;
  " onmouseover="this.style.transform='translateY(-2px)'" onmouseout="this.style.transform='translateY(0)'">
    🏗️ Ver Diagrama Interactivo de Arquitectura
  </a>
</div>

**💡 Haz clic en el botón de arriba para ver el diagrama detallado e interactivo de la arquitectura del sistema.**

---



## Ambientes

### Development (dev)
- Recursos mínimos para desarrollo
- Instancias e2-micro
- Base de datos db-f1-micro
- Sin alta disponibilidad

### Staging (stage)
- Configuración similar a producción
- Instancias e2-small
- Base de datos db-g1-small
- GKE habilitado para pruebas

### Production (prod)
- Configuración optimizada para producción
- Instancias e2-standard-2
- Base de datos db-n1-standard-1
- Alta disponibilidad y respaldos automáticos
- Múltiples zonas de disponibilidad

## Seguridad

- **Network Segmentation**: Subredes separadas para cada capa
- **Firewall Rules**: Reglas estrictas de firewall
- **IAM Policies**: Acceso basado en roles
- **Encryption**: Encriptación en tránsito y en reposo
- **Secrets Management**: Uso de Secret Manager para credenciales

## Escalabilidad

- **Horizontal Scaling**: Auto-scaling de instancias
- **Load Balancing**: Distribución de carga
- **Database Scaling**: Read replicas para Cloud SQL
- **Caching**: Redis para reducir carga en base de datos

## Costos

### Estimación mensual por ambiente:

**Development**: ~$50-100 USD
- Instancias e2-micro
- Base de datos db-f1-micro
- Tráfico mínimo

**Staging**: ~$200-400 USD
- Instancias e2-small
- Base de datos db-g1-small
- GKE con 3 nodos

**Production**: ~$500-1000 USD
- Instancias e2-standard-2
- Base de datos db-n1-standard-1
- GKE con 5 nodos
- Load balancers y alta disponibilidad

## Componentes por Ambiente

### DEV Environment
- **Servidores**: 3x e2-micro (1 vCPU, 1GB RAM)
- **Base de datos**: db-f1-micro (0.6GB RAM)
- **Red**: ecommerce-microservice-dev-vpc

### STAGE Environment  
- **Servidores**: 3x e2-small (1 vCPU, 2GB RAM)
- **Base de datos**: db-g1-small (1.7GB RAM)
- **Red**: ecommerce-microservice-stage-vpc

### PROD Environment
- **Servidores**: 3x e2-medium (1 vCPU, 4GB RAM)
- **Base de datos**: db-n1-standard-1 (3.75GB RAM)
- **Red**: ecommerce-microservice-prod-vpc
- **Red**: ecommerce-microservice-prod-vpc
