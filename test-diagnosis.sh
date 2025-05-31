#!/bin/bash
# Script para diagnosticar y arreglar problema de tests

echo "🔍 DIAGNÓSTICO DE TESTS"
echo "======================"

# Verificar estructura de tests en cada servicio
SERVICES=("user-service" "product-service" "order-service" "payment-service" "proxy-client")

for service in "${SERVICES[@]}"; do
    if [ -d "$service" ]; then
        echo ""
        echo "📁 Analizando $service..."
        
        # Verificar si existen tests
        test_files=$(find "$service/src/test/java" -name "*Test.java" 2>/dev/null | wc -l)
        echo "   Tests encontrados: $test_files archivos"
        
        if [ "$test_files" -gt 0 ]; then
            echo "   📄 Archivos de test:"
            find "$service/src/test/java" -name "*Test.java" | head -3
        fi
        
        # Verificar configuración de maven-surefire-plugin en pom.xml
        if grep -q "maven-surefire-plugin" "$service/pom.xml"; then
            echo "   ✅ maven-surefire-plugin configurado"
        else
            echo "   ⚠️ maven-surefire-plugin NO configurado"
        fi
        
        # Verificar dependencias de test
        if grep -q "spring-boot-starter-test" "$service/pom.xml"; then
            echo "   ✅ spring-boot-starter-test presente"
        else
            echo "   ⚠️ spring-boot-starter-test FALTANTE"
        fi
        
        if grep -q "junit-jupiter" "$service/pom.xml"; then
            echo "   ✅ JUnit Jupiter presente"
        else
            echo "   ⚠️ JUnit Jupiter FALTANTE"
        fi
    fi
done

echo ""
echo "🔧 APLICANDO FIXES NECESARIOS"
echo "============================="

# Fix 1: Agregar dependencias de test faltantes
for service in "${SERVICES[@]}"; do
    if [ -d "$service" ]; then
        echo "🛠️ Fixing $service..."
        
        # Check if spring-boot-starter-test is missing
        if ! grep -q "spring-boot-starter-test" "$service/pom.xml"; then
            echo "   📦 Agregando spring-boot-starter-test..."
            
            # Add test dependency before closing dependencies tag
            sed -i '/<\/dependencies>/i \
\t\t<dependency>\
\t\t\t<groupId>org.springframework.boot</groupId>\
\t\t\t<artifactId>spring-boot-starter-test</artifactId>\
\t\t\t<scope>test</scope>\
\t\t</dependency>' "$service/pom.xml"
        fi
        
        # Add maven-surefire-plugin if missing
        if ! grep -q "maven-surefire-plugin" "$service/pom.xml"; then
            echo "   🔌 Agregando maven-surefire-plugin..."
            
            # Find spring-boot-maven-plugin and add surefire before it
            sed -i '/<groupId>org\.springframework\.boot<\/groupId>/i \
\t\t\t<plugin>\
\t\t\t\t<groupId>org.apache.maven.plugins</groupId>\
\t\t\t\t<artifactId>maven-surefire-plugin</artifactId>\
\t\t\t\t<version>2.22.2</version>\
\t\t\t\t<configuration>\
\t\t\t\t\t<useSystemClassLoader>false</useSystemClassLoader>\
\t\t\t\t\t<includes>\
\t\t\t\t\t\t<include>**/*Test.java</include>\
\t\t\t\t\t\t<include>**/*Tests.java</include>\
\t\t\t\t\t</includes>\
\t\t\t\t</configuration>\
\t\t\t</plugin>' "$service/pom.xml"
        fi
        
        echo "   ✅ $service configurado para tests"
    fi
done

echo ""
echo "🧪 TESTING COMPILATION"
echo "====================="

# Test compilation in each service
for service in "${SERVICES[@]}"; do
    if [ -d "$service" ]; then
        echo "🔨 Testing $service compilation..."
        cd "$service"
        
        # Try test compilation
        if ./mvnw clean test-compile -q > /dev/null 2>&1; then
            echo "   ✅ Test compilation SUCCESS"
            
            # Try running tests
            echo "   🏃 Running tests..."
            if ./mvnw test -q > /dev/null 2>&1; then
                echo "   ✅ Tests RUN SUCCESSFULLY"
                
                # Check if surefire reports were generated
                if [ -d "target/surefire-reports" ] && [ "$(ls -A target/surefire-reports)" ]; then
                    echo "   📊 Surefire reports generated:"
                    ls target/surefire-reports/*.xml 2>/dev/null | wc -l
                else
                    echo "   ⚠️ No surefire reports found"
                fi
            else
                echo "   ❌ Tests FAILED - checking error..."
                ./mvnw test 2>&1 | tail -5
            fi
        else
            echo "   ❌ Test compilation FAILED"
            ./mvnw test-compile 2>&1 | tail -3
        fi
        
        cd ..
    fi
done

echo ""
echo "💡 RECOMENDACIONES:"
echo "=================="
echo "1. Verificar que todos los tests usan JUnit 5 (@Test de org.junit.jupiter.api.Test)"
echo "2. Asegurar que las clases de test terminan en 'Test' o 'Tests'"
echo "3. Verificar que los tests están en src/test/java"
echo "4. Comprobar que no hay imports incorrectos en los tests"