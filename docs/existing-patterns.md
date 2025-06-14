# Patrones de Diseño Existentes en la Arquitectura

## 1. **API Gateway Pattern**
**Ubicación:** `compose.yml` - `api-gateway-container`
**Propósito:** Punto único de entrada para todos los microservicios
**Beneficios:**
- Centraliza autenticación y autorización
- Simplifica el acceso del cliente
- Permite rate limiting y logging centralizado

## 2. **Service Registry Pattern**
**Ubicación:** `compose.yml` - `service-discovery-container` (Eureka)
**Propósito:** Registro y descubrimiento automático de servicios
**Beneficios:**
- Auto-registro de servicios
- Balanceamiento de carga automático
- Tolerancia a fallos de instancias

## 3. **Externalized Configuration Pattern**
**Ubicación:** `compose.yml` - `cloud-config-container`
**Propósito:** Configuración centralizada para todos los microservicios
**Beneficios:**
- Configuración sin rebuild
- Gestión centralizada de propiedades
- Configuración específica por ambiente

## 4. **Database per Service Pattern**
**Ubicación:** Cada microservicio tiene su propia lógica de datos
**Propósito:** Independencia de datos entre servicios
**Beneficios:**
- Autonomía de equipos
- Escalabilidad independiente
- Tecnologías de datos específicas

## 5. **Distributed Tracing Pattern**
**Ubicación:** `compose.yml` - `zipkin-container`
**Propósito:** Rastreo de requests a través de múltiples servicios
**Beneficios:**
- Debugging distribuido
- Análisis de performance
- Visibilidad de dependencias

## 6. **Proxy Pattern**
**Ubicación:** `compose.yml` - `proxy-client-container`
**Propósito:** Intermediario para comunicación entre servicios
**Beneficios:**
- Abstracción de comunicación
- Retry y timeout management
- Load balancing
