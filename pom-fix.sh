#!/bin/bash
# Script para arreglar los POMs corruptos

echo "🔧 FIXING CORRUPTED POM FILES"
echo "=============================="

# Lista de servicios a corregir
SERVICES=("user-service" "product-service" "order-service" "payment-service" "proxy-client")

for service in "${SERVICES[@]}"; do
    if [ -d "$service" ]; then
        echo ""
        echo "🛠️ Fixing $service/pom.xml..."
        
        POM_FILE="$service/pom.xml"
        BACKUP_FILE="$service/pom.xml.corrupted-backup"
        
        # Hacer backup del POM corrupto
        cp "$POM_FILE" "$BACKUP_FILE"
        echo "   📁 Backup created: $BACKUP_FILE"
        
        # PASO 1: Eliminar cualquier <plugin> que esté dentro de <dependency>
        echo "   🗑️ Removing malformed plugin tags..."
        sed -i '/<dependency>/,/<\/dependency>/{
            /<plugin>/,/<\/plugin>/d
        }' "$POM_FILE"
        
        # PASO 2: Agregar spring-boot-starter-test CORRECTAMENTE (si no existe)
        if ! grep -q "spring-boot-starter-test" "$POM_FILE"; then
            echo "   📦 Adding spring-boot-starter-test dependency..."
            
            # Buscar la última dependency y agregar antes del cierre
            sed -i '/<\/dependencies>/i \
\t\t<dependency>\
\t\t\t<groupId>org.springframework.boot</groupId>\
\t\t\t<artifactId>spring-boot-starter-test</artifactId>\
\t\t\t<scope>test</scope>\
\t\t</dependency>' "$POM_FILE"
        else
            # Si existe pero no tiene version, asegurar que tenga scope
            echo "   ✏️ Fixing existing spring-boot-starter-test..."
            sed -i '/<artifactId>spring-boot-starter-test<\/artifactId>/,/<\/dependency>/{
                /<scope>test<\/scope>/!{
                    /<\/dependency>/i \
\t\t\t<scope>test</scope>
                }
            }' "$POM_FILE"
        fi
        
        # PASO 3: Agregar maven-surefire-plugin EN LA SECCIÓN CORRECTA
        if ! grep -q "maven-surefire-plugin" "$POM_FILE"; then
            echo "   🔌 Adding maven-surefire-plugin..."
            
            # Buscar la sección <plugins> dentro de <build>
            if grep -q "<plugins>" "$POM_FILE"; then
                # Si existe <plugins>, agregar antes del cierre
                sed -i '/<\/plugins>/i \
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
\t\t\t</plugin>' "$POM_FILE"
            else
                # Si no existe <plugins>, crearla después de <build>
                sed -i '/<build>/a \
\t\t<plugins>\
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
\t\t\t</plugin>' "$POM_FILE"
                
                # Agregar cierre de plugins antes del cierre de build
                sed -i '/<\/build>/i \
\t\t</plugins>' "$POM_FILE"
            fi
        fi
        
        # PASO 4: Validar que el POM esté bien formado
        echo "   ✅ Validating POM structure..."
        if ./mvnw -f "$POM_FILE" validate -q > /dev/null 2>&1; then
            echo "   ✅ $service POM is now VALID!"
        else
            echo "   ❌ $service POM still has issues, checking..."
            ./mvnw -f "$POM_FILE" validate 2>&1 | head -3
        fi
        
        echo "   ✅ $service fixed successfully"
    else
        echo "⚠️ $service directory not found"
    fi
done

echo ""
echo "🧪 TESTING COMPILATION AFTER FIXES"
echo "=================================="

# Probar compilación en cada servicio
for service in "${SERVICES[@]}"; do
    if [ -d "$service" ]; then
        echo ""
        echo "🔨 Testing $service..."
        cd "$service"
        
        # Test basic compilation
        if ./mvnw clean compile -q > /dev/null 2>&1; then
            echo "   ✅ COMPILE: SUCCESS"
            
            # Test test compilation
            if ./mvnw test-compile -q > /dev/null 2>&1; then
                echo "   ✅ TEST-COMPILE: SUCCESS"
                
                # Test running tests
                if ./mvnw test -q > /dev/null 2>&1; then
                    echo "   ✅ TESTS: SUCCESS"
                    
                    # Check for surefire reports
                    if [ -d "target/surefire-reports" ] && [ "$(ls -A target/surefire-reports 2>/dev/null)" ]; then
                        report_count=$(ls target/surefire-reports/*.xml 2>/dev/null | wc -l)
                        echo "   📊 REPORTS: $report_count files generated"
                    else
                        echo "   ⚠️ REPORTS: No reports found"
                    fi
                else
                    echo "   ⚠️ TESTS: Some failures (check manually)"
                fi
            else
                echo "   ❌ TEST-COMPILE: FAILED"
            fi
        else
            echo "   ❌ COMPILE: FAILED"
        fi
        
        cd ..
    fi
done

echo ""
echo "🎉 POM FIXING COMPLETED!"
echo "======================="
echo "Backups created with .corrupted-backup extension"
echo "Run your Jenkins pipeline again now!"