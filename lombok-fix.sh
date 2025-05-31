#!/bin/bash
# Script para fix definitivo de Lombok en el taller

echo "🔧 Aplicando fix de Lombok para compatibilidad Java 11..."

# 1. Cambiar version de Lombok en TODOS los pom.xml
echo "📝 Actualizando versiones de Lombok..."
find . -name "pom.xml" -exec sed -i 's/<lombok.version>1\.18\.30<\/lombok.version>/<lombok.version>1.18.24<\/lombok.version>/g' {} \;
find . -name "pom.xml" -exec sed -i 's/<version>1\.18\.30<\/version>/<version>1.18.24<\/version>/g' {} \;

# 2. Verificar servicios que usan Lombok
echo "🔍 Servicios que usan Lombok:"
LOMBOK_SERVICES=("user-service" "product-service" "order-service" "payment-service" "proxy-client")

for service in "${LOMBOK_SERVICES[@]}"; do
    if [ -d "$service" ]; then
        echo "  ✓ $service"
        
        # Actualizar compiler plugin si existe
        if grep -q "maven-compiler-plugin" "$service/pom.xml"; then
            echo "    📦 Actualizando maven-compiler-plugin en $service"
            
            # Crear backup
            cp "$service/pom.xml" "$service/pom.xml.backup"
            
            # Aplicar configuración corregida
            python3 - << EOF
import xml.etree.ElementTree as ET
import os

pom_file = "$service/pom.xml"
if os.path.exists(pom_file):
    # Leer XML
    tree = ET.parse(pom_file)
    root = tree.getroot()
    
    # Namespace Maven
    ns = {'maven': 'http://maven.apache.org/POM/4.0.0'}
    
    # Buscar maven-compiler-plugin
    plugins = root.findall('.//maven:plugin[maven:artifactId="maven-compiler-plugin"]', ns)
    
    for plugin in plugins:
        # Actualizar version
        version = plugin.find('maven:version', ns)
        if version is not None:
            version.text = '3.11.0'
        
        # Buscar o crear configuration
        config = plugin.find('maven:configuration', ns)
        if config is None:
            config = ET.SubElement(plugin, 'configuration')
        
        # Limpiar configuration existente
        config.clear()
        
        # Agregar source y target
        ET.SubElement(config, 'source').text = '11'
        ET.SubElement(config, 'target').text = '11'
        
        # Agregar annotationProcessorPaths
        paths = ET.SubElement(config, 'annotationProcessorPaths')
        path = ET.SubElement(paths, 'path')
        ET.SubElement(path, 'groupId').text = 'org.projectlombok'
        ET.SubElement(path, 'artifactId').text = 'lombok'
        ET.SubElement(path, 'version').text = '1.18.24'
    
    # Guardar archivo
    tree.write(pom_file, encoding='utf-8', xml_declaration=True)
    print(f"    ✓ Actualizado {pom_file}")
EOF
        fi
    else
        echo "  ⚠️ $service no encontrado"
    fi
done

# 3. Limpiar builds anteriores
echo "🧹 Limpiando builds anteriores..."
for service in "${LOMBOK_SERVICES[@]}"; do
    if [ -d "$service/target" ]; then
        rm -rf "$service/target"
        echo "  ✓ Limpiado $service/target"
    fi
done

# 4. Verificar cambios
echo "🔍 Verificando cambios aplicados..."
grep -r "lombok.version" . --include="*.xml" | grep -v ".git" | head -5

echo ""
echo "✅ Fix de Lombok aplicado. Principales cambios:"
echo "   • Lombok 1.18.30 → 1.18.24 (compatible con Java 11)"
echo "   • maven-compiler-plugin actualizado a 3.11.0"
echo "   • annotationProcessorPaths configurado correctamente"
echo "   • Targets limpiados para rebuild completo"
echo ""
echo "🚀 Ahora ejecuta el pipeline Jenkins nuevamente."