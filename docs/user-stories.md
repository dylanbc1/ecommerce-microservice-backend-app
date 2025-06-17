# Historias de Usuario - Ecommerce Microservices

## Epic 1: Infraestructura y Arquitectura

### US-001: Configurar Service Discovery
**Como** desarrollador  
**Quiero** implementar un service discovery (Eureka)  
**Para que** los microservicios puedan descubrirse automáticamente

**Criterios de Aceptación**:
- ✅ Eureka Server funcionando en puerto 8761
- ✅ Dashboard de Eureka accesible vía web
- ✅ Microservicios se registran automáticamente
- ✅ Health checks funcionando
- ✅ Load balancing automático entre instancias

**Story Points**: 3  
**Sprint**: 1  
**Estado**: ✅ Completado

**Tareas de Implementación**:
- [x] Configurar Eureka Server
- [x] Agregar dependencias Spring Cloud
- [x] Configurar application.yml
- [x] Implementar health checks
- [x] Crear tests de conectividad

---

### US-002: Implementar API Gateway
**Como** cliente de la API  
**Quiero** un punto único de entrada (API Gateway)  
**Para que** pueda acceder a todos los microservicios de forma consistente

**Criterios de Aceptación**:
- ✅ Gateway funcionando en puerto 8080
- ✅ Routing automático hacia microservicios
- ✅ Load balancing integrado
- ✅ CORS configurado correctamente
- ✅ Rate limiting implementado
- ✅ Logging centralizado de requests

**Story Points**: 3  
**Sprint**: 1  
**Estado**: ✅ Completado

**Tareas de Implementación**:
- [x] Configurar Spring Cloud Gateway
- [x] Definir rutas hacia microservicios
- [x] Implementar filtros de autenticación
- [x] Configurar CORS y headers
- [x] Agregar logging y monitoring

---

### US-003: Configurar Config Server
**Como** desarrollador  
**Quiero** centralizar la configuración en un Config Server  
**Para que** pueda gestionar configuraciones sin redeploy

**Criterios de Aceptación**:
- ✅ Config Server funcionando en puerto 9296
- ✅ Configuraciones centralizadas por ambiente
- ✅ Microservicios obtienen config automáticamente
- ✅ Refresh de configuración sin restart
- ✅ Configuración versionada en Git

**Story Points**: 2  
**Sprint**: 1  
**Estado**: ✅ Completado

---

## Epic 2: Gestión de Usuarios

### US-004: Desarrollar User Service
**Como** usuario del sistema  
**Quiero** poder registrarme y gestionar mi perfil  
**Para que** pueda acceder a las funcionalidades del e-commerce

**Criterios de Aceptación**:
- ✅ Registro de usuario con email único
- ✅ Login con credenciales válidas
- ✅ Gestión de perfil (crear, leer, actualizar, eliminar)
- ✅ Validación de datos de entrada
- ✅ Encriptación de contraseñas
- ✅ API REST bien documentada

**Story Points**: 5  
**Sprint**: 2  
**Estado**: ✅ Completado


**Tareas de Implementación**:
- [x] Crear entidad User con validaciones
- [x] Implementar UserRepository con JPA
- [x] Desarrollar UserService con lógica de negocio
- [x] Crear UserController con endpoints REST
- [x] Implementar tests unitarios (85% coverage)
- [x] Agregar tests de integración
- [x] Documentar API con OpenAPI

---

## Epic 3: Catálogo de Productos

### US-005: Desarrollar Product Service
**Como** cliente  
**Quiero** poder buscar y ver productos disponibles  
**Para que** pueda explorar el catálogo y tomar decisiones de compra

**Criterios de Aceptación**:
- ✅ Catálogo de productos con información completa
- ✅ Búsqueda por nombre, categoría y precio
- ✅ Filtrado y ordenamiento
- ✅ Gestión de stock en tiempo real
- ✅ Imágenes y descripciones detalladas
- ✅ Paginación para listas grandes

**Story Points**: 4  
**Sprint**: 2  
**Estado**: ✅ Completado


---

### US-006: Implementar Comunicación entre Servicios
**Como** desarrollador  
**Quiero** que los microservicios se comuniquen eficientemente  
**Para que** puedan intercambiar información necesaria

**Criterios de Aceptación**:
- ✅ Proxy Client para llamadas HTTP entre servicios
- ✅ Circuit breaker para resilencia
- ✅ Retry logic con backoff exponencial
- ✅ Timeout configurables
- ✅ Logging de comunicación entre servicios

**Story Points**: 3  
**Sprint**: 2  
**Estado**: ✅ Completado

---

## Epic 4: Procesamiento de Órdenes

### US-007: Desarrollar Order Service
**Como** cliente  
**Quiero** poder crear y gestionar mis órdenes de compra  
**Para que** pueda comprar productos del catálogo

**Criterios de Aceptación**:
- ✅ Creación de órdenes con múltiples productos
- ✅ Cálculo automático de totales y impuestos
- ✅ Validación de stock disponible
- ✅ Estados de orden (pendiente, confirmada, enviada, entregada)
- ✅ Historial de órdenes por usuario
- ✅ Cancelación de órdenes pendientes

**Story Points**: 5  
**Sprint**: 3  
**Estado**: ✅ Completado


**Flujo de Negocio**:
1. Cliente agrega productos al carrito
2. Se valida stock disponible via Product Service
3. Se verifica usuario via User Service
4. Se crea orden con estado "PENDING"
5. Se reserva stock en Product Service
6. Se procesa pago via Payment Service
7. Si pago exitoso → estado "CONFIRMED"
8. Se activa Shipping Service para envío

---

## Epic 5: Pagos y Facturación

### US-008: Desarrollar Payment Service
**Como** cliente  
**Quiero** poder pagar mis órdenes de forma segura  
**Para que** pueda completar mis compras

**Criterios de Aceptación**:
- ✅ Procesamiento de pagos con tarjeta de crédito
- ✅ Validación de datos de tarjeta
- ✅ Integración con gateway de pagos externo (simulado)
- ✅ Manejo de diferentes estados de pago
- ✅ Reintento automático para pagos fallidos
- ✅ Notificaciones de estado de pago

**Story Points**: 4  
**Sprint**: 3  
**Estado**: ✅ Completado

**Estados de Pago**:
- `PENDING`: Pago iniciado
- `PROCESSING`: En proceso con gateway
- `COMPLETED`: Pago exitoso
- `FAILED`: Pago fallido
- `REFUNDED`: Pago reembolsado

---

## Epic 6: Gestión de Envíos

### US-009: Desarrollar Shipping Service
**Como** cliente  
**Quiero** poder rastrear mis envíos  
**Para que** sepa cuándo recibiré mis productos

**Criterios de Aceptación**:
- ✅ Creación automática de envío tras pago exitoso
- ✅ Cálculo de costos de envío por ubicación
- ✅ Tracking de envíos con estados
- ✅ Estimación de fecha de entrega
- ✅ Notificaciones de cambio de estado
- ✅ Integración con Order Service

**Story Points**: 3  
**Sprint**: 3  
**Estado**: ✅ Completado

---

### US-010: Implementar Favourite Service
**Como** cliente  
**Quiero** poder guardar productos como favoritos  
**Para que** pueda acceder fácilmente a productos de mi interés

**Criterios de Aceptación**:
- ✅ Agregar/quitar productos de favoritos
- ✅ Listar productos favoritos por usuario
- ✅ Verificar si producto está en favoritos
- ✅ Notificaciones de cambios de precio en favoritos
- ✅ Wishlist compartible

**Story Points**: 3  
**Sprint**: 3  
**Estado**: ✅ Completado

---

## Epic 7: Testing y Calidad

### US-011: Implementar Suite de Tests Completa
**Como** desarrollador  
**Quiero** tener cobertura completa de tests  
**Para que** el sistema sea confiable y mantenible

**Criterios de Aceptación**:
- ✅ Tests unitarios 
- ✅ Tests de integración entre servicios
- ✅ Tests end-to-end de flujos completos
- ✅ Tests de performance con Locust
- ✅ Tests de contratos entre servicios
- ✅ Tests de seguridad automatizados

**Story Points**: 8  
**Sprint**: Todos  
**Estado**: ✅ Completado

**Métricas Alcanzadas**:
- Coverage unitario: 84.2%
- Tests de integración: 23 casos
- Tests E2E: 5 flujos principales
- Performance: < 200ms response time
- Error rate: 0.0%

---

## Epic 8: CI/CD y DevOps

### US-012: Implementar Pipeline CI/CD Completo
**Como** DevOps engineer  
**Quiero** automatizar todo el proceso de deployment  
**Para que** las entregas sean rápidas y confiables

**Criterios de Aceptación**:
- ✅ Pipeline automático para dev/stage/prod
- ✅ Tests automatizados en cada commit
- ✅ Deployment automático tras tests exitosos
- ✅ Rollback automático en caso de fallos
- ✅ Notificaciones de estado de deployments
- ✅ Métricas de deployment y performance

**Story Points**: 6  
**Sprint**: Todos  
**Estado**: ✅ Completado

---

## Resumen de Historias de Usuario

### Por Epic
| Epic | Historias | Story Points | Estado |
|------|-----------|--------------|--------|
| Infraestructura | 3 | 8 | ✅ Completado |
| Gestión Usuarios | 1 | 5 | ✅ Completado |
| Catálogo | 2 | 7 | ✅ Completado |
| Órdenes | 1 | 5 | ✅ Completado |
| Pagos | 1 | 4 | ✅ Completado |
| Envíos | 2 | 6 | ✅ Completado |
| Testing | 1 | 8 | ✅ Completado |
| CI/CD | 1 | 6 | ✅ Completado |
| **Total** | **12** | **49** | **100%** |



### Criterios de Aceptación Globales
Todas las historias deben cumplir:
- ✅ **Funcionalidad**: Feature working según especificación
- ✅ **Tests**: Unit + Integration tests implementados
- ✅ **Documentation**: API documented con OpenAPI
- ✅ **Performance**: Response time < 200ms
- ✅ **Security**: Validaciones y sanitización implementadas
- ✅ **Monitoring**: Logs y métricas configuradas
- ✅ **Deploy**: Deployable via CI/CD pipeline