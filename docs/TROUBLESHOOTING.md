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
