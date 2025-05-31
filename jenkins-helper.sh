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
