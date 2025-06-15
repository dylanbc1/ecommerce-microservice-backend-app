#!/bin/bash

echo "🧪 Ejecutando COVERAGE completo del proyecto..."

# Servicios con tests (orden actualizado)
SERVICES=(
    "user-service"
    "product-service" 
    "order-service"
    "payment-service"
    "shipping-service"
    "favourite-service"
    "proxy-client"
    "api-gateway"
    "service-discovery"
    "cloud-config"
)

# Crear directorio para reportes consolidados
mkdir -p coverage-reports
echo "📁 Directorio coverage-reports creado"

# Función para ejecutar tests con coverage en un servicio
run_service_coverage() {
    local service=$1
    echo ""
    echo "🔍 Ejecutando coverage para $service..."
    
    if [ -d "$service" ] && [ -f "$service/pom.xml" ]; then
        cd "$service"
        
        echo "   📦 Compilando $service..."
        # Usar mvn en lugar de ./mvnw (más compatible)
        mvn clean compile -q || {
            echo "   ⚠️ Compilación falló para $service, intentando con wrapper..."
            if [ -f "./mvnw" ]; then
                ./mvnw clean compile -q || {
                    echo "   ❌ Compilación falló definitivamente para $service"
                    cd ..
                    return 1
                }
            else
                echo "   ❌ No se encontró Maven ni wrapper para $service"
                cd ..
                return 1
            fi
        }
        
        echo "   🧪 Ejecutando tests con JaCoCo coverage..."
        # Primero intentar con mvn, luego con wrapper
        mvn test jacoco:report -Dmaven.test.failure.ignore=true || {
            echo "   ⚠️ Intentando con wrapper..."
            if [ -f "./mvnw" ]; then
                ./mvnw test jacoco:report -Dmaven.test.failure.ignore=true || {
                    echo "   ⚠️ Tests fallaron para $service"
                }
            fi
        }
        
        # Verificar si se generó el reporte
        if [ -f "target/site/jacoco/index.html" ]; then
            echo "   ✅ Coverage generado para $service"
            
            # Copiar reporte al directorio consolidado
            mkdir -p "../coverage-reports/$service"
            cp -r target/site/jacoco/* "../coverage-reports/$service/"
            
            # Extraer métricas básicas
            if [ -f "target/site/jacoco/jacoco.csv" ]; then
                echo "   📊 Extrayendo métricas..."
                tail -1 "target/site/jacoco/jacoco.csv" > "../coverage-reports/${service}-summary.csv"
            fi
            
            # Extraer métricas del XML para el reporte
            if [ -f "target/site/jacoco/jacoco.xml" ]; then
                echo "   📈 Procesando métricas XML..."
                # Extraer coverage de líneas
                line_coverage=$(grep '<counter type="LINE"' target/site/jacoco/jacoco.xml | head -1 | sed 's/.*covered="\([^"]*\)".*missed="\([^"]*\)".*/\1 \2/')
                if [ ! -z "$line_coverage" ]; then
                    covered=$(echo $line_coverage | cut -d' ' -f1)
                    missed=$(echo $line_coverage | cut -d' ' -f2)
                    total=$((covered + missed))
                    if [ $total -gt 0 ]; then
                        percentage=$(echo "scale=2; ($covered * 100) / $total" | bc -l 2>/dev/null || echo "N/A")
                        echo "   📊 Line Coverage: $percentage% ($covered/$total lines)"
                        echo "$service,$percentage,$covered,$total" >> "../coverage-reports/summary-metrics.csv"
                    fi
                fi
            fi
            
        else
            echo "   ❌ No se generó reporte de coverage para $service"
            echo "$service,0,0,0" >> "../coverage-reports/summary-metrics.csv"
        fi
        
        cd ..
    else
        echo "   ⏭️ $service no encontrado o sin pom.xml"
    fi
}

# Inicializar archivo de métricas
echo "Service,Coverage%,CoveredLines,TotalLines" > coverage-reports/summary-metrics.csv

# Ejecutar coverage para cada servicio
echo "🚀 Iniciando coverage para todos los servicios..."
for service in "${SERVICES[@]}"; do
    run_service_coverage "$service"
done

# Ejecutar también coverage agregado del proyecto principal
echo ""
echo "📊 Ejecutando coverage agregado del proyecto..."
mvn test jacoco:report-aggregate -Dmaven.test.failure.ignore=true || {
    echo "⚠️ Coverage agregado falló, pero continuamos..."
}

# Si existe el reporte agregado, copiarlo también
if [ -f "target/site/jacoco-aggregate/index.html" ]; then
    echo "✅ Coverage agregado generado"
    mkdir -p "coverage-reports/aggregate"
    cp -r target/site/jacoco-aggregate/* "coverage-reports/aggregate/"
fi

# Generar reporte consolidado mejorado
echo ""
echo "📊 Generando reporte consolidado..."

cat > coverage-reports/coverage-summary.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Coverage Report - Ecommerce Microservices</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #2c3e50; color: white; }
        .high { background-color: #d4edda; }
        .medium { background-color: #fff3cd; }
        .low { background-color: #f8d7da; }
        .header { text-align: center; color: #2c3e50; }
        .summary { background: #e8f4f8; padding: 15px; border-radius: 5px; margin: 15px 0; }
        .metric { display: inline-block; margin: 10px 20px; text-align: center; }
        .metric-value { font-size: 24px; font-weight: bold; color: #2c3e50; }
        .metric-label { font-size: 12px; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">🧪 Coverage Report - Ecommerce Microservices</h1>
        <p class="header">Generado el: $(date)</p>
        
        <div class="summary">
            <h3>📈 Resumen General</h3>
            <p>Este reporte muestra el coverage de tests para todos los microservicios del proyecto.</p>
        </div>
        
        <h2>📋 Servicios Analizados</h2>
        <table>
            <tr>
                <th>Servicio</th>
                <th>Estado</th>
                <th>Coverage</th>
                <th>Reporte Detallado</th>
                <th>Prioridad</th>
            </tr>
EOF

# Agregar cada servicio al reporte HTML con métricas si están disponibles
for service in "${SERVICES[@]}"; do
    if [ -f "coverage-reports/$service/index.html" ]; then
        # Intentar leer el coverage del CSV
        coverage_line=$(grep "^$service," coverage-reports/summary-metrics.csv 2>/dev/null)
        if [ ! -z "$coverage_line" ]; then
            coverage_pct=$(echo "$coverage_line" | cut -d',' -f2)
            covered=$(echo "$coverage_line" | cut -d',' -f3)
            total=$(echo "$coverage_line" | cut -d',' -f4)
            
            # Determinar clase CSS basada en coverage
            if (( $(echo "$coverage_pct >= 80" | bc -l 2>/dev/null || echo 0) )); then
                css_class="high"
                status_icon="🟢"
            elif (( $(echo "$coverage_pct >= 60" | bc -l 2>/dev/null || echo 0) )); then
                css_class="medium" 
                status_icon="🟡"
            else
                css_class="low"
                status_icon="🔴"
            fi
            
            # Determinar prioridad basada en el tipo de servicio
            case $service in
                "payment-service"|"order-service") priority="🔥 Alta" ;;
                "user-service"|"product-service") priority="⚡ Media" ;;
                *) priority="📋 Normal" ;;
            esac
            
            cat >> coverage-reports/coverage-summary.html << EOF
            <tr class="$css_class">
                <td><strong>$service</strong></td>
                <td>$status_icon Coverage Generado</td>
                <td><strong>${coverage_pct}%</strong> ($covered/$total líneas)</td>
                <td><a href="$service/index.html" target="_blank">Ver Reporte Detallado</a></td>
                <td>$priority</td>
            </tr>
EOF
        else
            cat >> coverage-reports/coverage-summary.html << EOF
            <tr class="high">
                <td><strong>$service</strong></td>
                <td>✅ Coverage Generado</td>
                <td>Ver reporte</td>
                <td><a href="$service/index.html" target="_blank">Ver Reporte Detallado</a></td>
                <td>📋 Normal</td>
            </tr>
EOF
        fi
    else
        cat >> coverage-reports/coverage-summary.html << EOF
        <tr class="low">
            <td><strong>$service</strong></td>
            <td>❌ Sin Coverage</td>
            <td>0%</td>
            <td>-</td>
            <td>🔧 Requiere tests</td>
        </tr>
EOF
    fi
done

# Agregar reporte agregado si existe
if [ -f "coverage-reports/aggregate/index.html" ]; then
    cat >> coverage-reports/coverage-summary.html << EOF
        <tr style="background-color: #e3f2fd; font-weight: bold;">
            <td>📊 <strong>REPORTE AGREGADO</strong></td>
            <td>✅ Generado</td>
            <td>Ver reporte</td>
            <td><a href="aggregate/index.html" target="_blank">🎯 Ver Coverage Total</a></td>
            <td>🏆 Principal</td>
        </tr>
EOF
fi

cat >> coverage-reports/coverage-summary.html << 'EOF'
        </table>
        
        <div class="summary">
            <h2>📊 Guía de Interpretación</h2>
            <ul>
                <li><strong>🟢 Coverage >= 80%:</strong> Excelente cobertura de tests</li>
                <li><strong>🟡 Coverage 60-79%:</strong> Buena cobertura, puede mejorarse</li>
                <li><strong>🔴 Coverage < 60%:</strong> Cobertura insuficiente, requiere más tests</li>
            </ul>
        </div>
        
        <div class="summary">
            <h2>🎯 Recomendaciones</h2>
            <ul>
                <li><strong>Prioridad Alta (🔥):</strong> payment-service y order-service son críticos</li>
                <li><strong>Prioridad Media (⚡):</strong> user-service y product-service son importantes</li>
                <li>Enfócate primero en servicios con coverage < 60%</li>
                <li>Revisa métodos y clases sin coverage en los reportes detallados</li>
            </ul>
        </div>
        
        <div class="summary">
            <h2>🔍 Cómo usar los reportes</h2>
            <ol>
                <li>Haz clic en "Ver Reporte Detallado" para cada servicio</li>
                <li>En el reporte detallado, busca líneas/métodos en rojo (sin coverage)</li>
                <li>Escribe tests para cubrir esas áreas</li>
                <li>Vuelve a ejecutar este script para ver mejoras</li>
            </ol>
        </div>
    </div>
</body>
</html>
EOF

echo ""
echo "🎉 COVERAGE COMPLETADO!"
echo "📊 Reporte principal: coverage-reports/coverage-summary.html"
echo "📁 Reportes individuales en: coverage-reports/[servicio]/index.html"
if [ -f "coverage-reports/aggregate/index.html" ]; then
    echo "🎯 Reporte agregado: coverage-reports/aggregate/index.html"
fi
echo ""
echo "🌐 Para ver el reporte:"
echo "   # En Linux/Mac:"
echo "   open coverage-reports/coverage-summary.html"
echo "   # En Windows:"
echo "   start coverage-reports/coverage-summary.html"
echo ""
echo "📈 Métricas guardadas en: coverage-reports/summary-metrics.csv"
