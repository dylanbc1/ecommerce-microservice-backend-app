#!/bin/bash
# SOLUCIÓN DEFINITIVA basada en investigación real

echo "🎯 SOLUCIÓN FINAL - LOMBOK + JENKINS COMPATIBILITY FIX"
echo "======================================================"
echo ""
echo "📊 Problema identificado:"
echo "   - Jenkins Docker usa Java 11 por defecto"
echo "   - Tu Jenkins puede estar usando Java 17+ internamente"
echo "   - Lombok 1.18.20 NO es compatible con Java 17+"
echo "   - Necesitas Lombok 1.18.30+ para Java 17+"
echo ""

# Método 1: Upgrade a Lombok 1.18.30+ (RECOMENDADO)
echo "🔧 MÉTODO 1: Upgrade a Lombok 1.18.30+"
echo "========================================="

SERVICES=("user-service" "product-service" "order-service" "payment-service" "proxy-client")

for service in "${SERVICES[@]}"; do
    if [ -d "$service" ]; then
        echo "📝 Updating $service..."
        
        # Backup
        cp "$service/pom.xml" "$service/pom.xml.final-backup"
        
        # Cambiar a versión 1.18.30+ que SÍ funciona con Java 17+
        sed -i 's/<lombok.version>.*<\/lombok.version>/<lombok.version>1.18.30<\/lombok.version>/g' "$service/pom.xml"
        sed -i '/<groupId>org\.projectlombok<\/groupId>/{N;s/<version>.*<\/version>/<version>1.18.30<\/version>/;}' "$service/pom.xml"
        
        # Actualizar maven-compiler-plugin a versión compatible
        sed -i 's/<version>3\.8\.1<\/version>/<version>3.11.0<\/version>/g' "$service/pom.xml"
        
        echo "   ✅ $service actualizado a Lombok 1.18.30"
    fi
done

echo ""
echo "🧪 TESTING CON VERSIÓN CORRECTA..."
echo "=================================="

for service in "${SERVICES[@]}"; do
    if [ -d "$service" ]; then
        echo "🔨 Testing $service con Lombok 1.18.30..."
        cd "$service"
        
        # Clean + compile test
        if ./mvnw clean compile -q -DskipTests > /dev/null 2>&1; then
            echo "   ✅ $service COMPILA EXITOSAMENTE!"
        else
            echo "   ⚠️ $service - verificando error específico..."
            ./mvnw compile 2>&1 | grep -E "(ERROR|Failed)" | head -2
        fi
        cd ..
    fi
done

echo ""
echo "🐳 MÉTODO 2: Alternative - Jenkins con Java 11 específico"
echo "=========================================================="
echo "Si aún falla, puedes forzar Jenkins a usar Java 11 específicamente:"
echo ""
echo "# En tu Dockerfile de Jenkins:"
echo "FROM jenkins/jenkins:lts-jdk11"
echo ""
echo "# O en docker-compose.yml:"
echo "services:"
echo "  jenkins:"
echo "    image: jenkins/jenkins:lts-jdk11  # Usa Java 11 específicamente"
echo ""

echo "🎯 MÉTODO 3: Verificar versión de Java en Jenkins"
echo "================================================="
echo "1. Ve a Jenkins > Manage Jenkins > System Information"
echo "2. Busca 'java.version' - debe ser 11.x.x"
echo "3. Si es 17+ o 21+, usa Lombok 1.18.30+"
echo "4. Si es 11.x.x, usa Lombok 1.18.20"
echo ""

echo "📋 RESUMEN DE COMPATIBILIDAD:"
echo "============================"
echo "Java 8:     Lombok 1.18.16+"
echo "Java 11:    Lombok 1.18.20+"
echo "Java 17:    Lombok 1.18.30+"
echo "Java 21:    Lombok 1.18.30+"
echo ""

echo "🚀 PRÓXIMOS PASOS:"
echo "=================="
echo "1. git add ."
echo "2. git commit -m 'fix: upgrade lombok to 1.18.30 for java 17+ compatibility'"
echo "3. git push"
echo "4. Ejecutar pipeline Jenkins"
echo ""
echo "💡 Si SIGUE fallando:"
echo "   - Verificar versión de Java en Jenkins (System Information)"
echo "   - Usar jenkins/jenkins:lts-jdk11 en Docker"
echo "   - O usar Lombok 1.18.34 (última versión estable)"