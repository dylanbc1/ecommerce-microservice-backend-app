#!/bin/bash
# Script para diagnosticar NoSuchMethodError en tests

echo "🔍 DIAGNOSING NoSuchMethodError IN TESTS"
echo "======================================="

SERVICES=("user-service" "product-service" "order-service" "payment-service")

for service in "${SERVICES[@]}"; do
    if [ -d "$service" ]; then
        echo ""
        echo "🔍 Analyzing $service..."
        cd "$service"
        
        echo "   📋 Checking dependency tree for conflicts..."
        ./mvnw dependency:tree -Dverbose 2>/dev/null | grep -E "(spring-boot|spring-cloud|junit)" | head -10
        
        echo ""
        echo "   🧪 Running tests with detailed error output..."
        ./mvnw test -X 2>&1 | grep -A5 -B5 "NoSuchMethodError" | head -15 || echo "   No NoSuchMethodError details found"
        
        echo ""
        echo "   📦 Checking for version conflicts..."
        ./mvnw dependency:analyze 2>/dev/null | grep -E "(WARNING|ERROR)" | head -5 || echo "   No obvious conflicts"
        
        echo ""
        echo "   ☕ Java classpath check..."
        echo "   Java version: $(java -version 2>&1 | head -1)"
        echo "   JAVA_HOME: ${JAVA_HOME:-'Not set'}"
        
        cd ..
    fi
done

echo ""
echo "🔧 COMMON SOLUTIONS FOR NoSuchMethodError:"
echo "========================================="
echo "1. Spring Boot + Spring Cloud version mismatch"
echo "2. JUnit 4 vs JUnit 5 conflicts"
echo "3. Multiple versions of same dependency"
echo "4. Wrong Java version"
echo ""
echo "💡 QUICK FIXES TO TRY:"
echo "====================="
echo "Option 1: Update to compatible versions"
echo "Option 2: Exclude conflicting transitive dependencies"
echo "Option 3: Use Spring Boot BOM properly"
echo "Option 4: Check Java version compatibility"