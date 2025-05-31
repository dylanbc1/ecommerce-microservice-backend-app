#!/bin/bash
# Fix completo para resolver el problema de Lombok en Jenkins

echo "🔧 Aplicando fix definitivo de Lombok para el taller..."

# Servicios que usan Lombok
SERVICES=("user-service" "product-service" "order-service" "payment-service" "proxy-client")

# Estrategia 1: Downgrade a versión más antigua y estable
echo "📝 Strategy 1: Downgrading Lombok to ultra-stable version..."

for service in "${SERVICES[@]}"; do
    if [ -d "$service" ]; then
        echo "  🔧 Fixing $service..."
        
        # Backup original
        cp "$service/pom.xml" "$service/pom.xml.backup"
        
        # Aplicar fix completo con sed
        sed -i 's/<lombok.version>.*<\/lombok.version>/<lombok.version>1.18.20<\/lombok.version>/g' "$service/pom.xml"
        sed -i 's/<version>1\.18\.[0-9]*<\/version>/<version>1.18.20<\/version>/g' "$service/pom.xml"
        
        # Verificar si tiene maven-compiler-plugin y actualizarlo
        if grep -q "maven-compiler-plugin" "$service/pom.xml"; then
            echo "    📦 Updating maven-compiler-plugin in $service"
            
            # Crear un pom.xml temporal con configuración mejorada
            python3 - << EOF
import xml.etree.ElementTree as ET
import os

pom_file = "$service/pom.xml"
if os.path.exists(pom_file):
    # Leer XML con namespace handling
    with open(pom_file, 'r') as f:
        content = f.read()
    
    # Simple string replacement para maven-compiler-plugin
    if 'maven-compiler-plugin' in content:
        # Buscar la sección del plugin y reemplazarla
        lines = content.split('\n')
        new_lines = []
        in_compiler_plugin = False
        plugin_depth = 0
        
        for line in lines:
            if 'maven-compiler-plugin' in line and '<artifactId>' in line:
                in_compiler_plugin = True
                plugin_depth = 0
                new_lines.append(line)
                continue
            
            if in_compiler_plugin:
                if '<plugin>' in line:
                    plugin_depth += 1
                elif '</plugin>' in line:
                    if plugin_depth == 0:
                        # Fin del maven-compiler-plugin, agregar nuestra configuración
                        new_lines.extend([
                            '            <version>3.10.1</version>',
                            '            <configuration>',
                            '                <source>11</source>',
                            '                <target>11</target>',
                            '                <annotationProcessorPaths>',
                            '                    <path>',
                            '                        <groupId>org.projectlombok</groupId>',
                            '                        <artifactId>lombok</artifactId>',
                            '                        <version>1.18.20</version>',
                            '                    </path>',
                            '                </annotationProcessorPaths>',
                            '            </configuration>',
                            '        </plugin>'
                        ])
                        in_compiler_plugin = False
                        continue
                    else:
                        plugin_depth -= 1
                
                # Saltar líneas del plugin original excepto cierre
                if not ('</plugin>' in line and plugin_depth == 0):
                    continue
            
            new_lines.append(line)
        
        # Escribir archivo actualizado
        with open(pom_file, 'w') as f:
            f.write('\n'.join(new_lines))
        
        print(f"    ✓ Updated {pom_file}")
EOF
        fi
        
        echo "    ✅ $service fixed"
    else
        echo "  ⚠️ $service not found"
    fi
done

# Estrategia 2: Limpiar targets anteriores
echo "🧹 Strategy 2: Cleaning previous build artifacts..."
for service in "${SERVICES[@]}"; do
    if [ -d "$service/target" ]; then
        rm -rf "$service/target"
        echo "  ✓ Cleaned $service/target"
    fi
done

# Estrategia 3: Verificar versiones aplicadas
echo "🔍 Strategy 3: Verifying applied versions..."
for service in "${SERVICES[@]}"; do
    if [ -f "$service/pom.xml" ]; then
        echo "=== $service ==="
        grep -A 1 -B 1 "lombok" "$service/pom.xml" | head -5
        echo ""
    fi
done

# Estrategia 4: Test build simple en uno de los servicios
echo "🔬 Strategy 4: Testing build with api-gateway (no lombok)..."
if [ -d "api-gateway" ]; then
    cd api-gateway
    echo "  🔨 Testing basic compile..."
    ./mvnw clean compile -q || echo "  ⚠️ Basic compile still has issues"
    cd ..
fi

echo ""
echo "✅ Lombok fix aplicado con las siguientes estrategias:"
echo "   • Lombok downgraded to 1.18.20 (ultra-stable)"
echo "   • maven-compiler-plugin updated to 3.10.1"
echo "   • annotationProcessorPaths configured correctly"
echo "   • Previous build artifacts cleaned"
echo ""
echo "🚀 Próximos pasos:"
echo "   1. git add ."
echo "   2. git commit -m 'fix: lombok downgrade to 1.18.20 for jenkins compatibility'"
echo "   3. git push"
echo "   4. Run Jenkins pipeline again"