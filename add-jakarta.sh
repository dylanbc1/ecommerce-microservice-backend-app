#!/bin/bash
# Agregar jakarta.validation dependency a todos los POMs

echo "📦 ADDING JAKARTA VALIDATION TO POMS"
echo "===================================="

SERVICES=("user-service" "product-service" "order-service" "payment-service")

for service in "${SERVICES[@]}"; do
    if [ -d "$service" ]; then
        echo ""
        echo "📦 Adding jakarta.validation to $service..."
        
        cd "$service"
        
        # Check if dependency already exists
        if grep -q "jakarta.validation" pom.xml; then
            echo "   ℹ️ jakarta.validation already in POM"
        else
            echo "   📝 Adding jakarta.validation dependency..."
            
            # Add validation dependency before the lombok dependency
            sed -i '/<groupId>org\.projectlombok<\/groupId>/i \
\t\t<dependency>\
\t\t\t<groupId>jakarta.validation</groupId>\
\t\t\t<artifactId>jakarta.validation-api</artifactId>\
\t\t</dependency>\
\t\t<dependency>\
\t\t\t<groupId>org.hibernate.validator</groupId>\
\t\t\t<artifactId>hibernate-validator</artifactId>\
\t\t</dependency>' pom.xml
            
            echo "   ✅ Added jakarta.validation dependencies"
        fi
        
        # Verify POM is valid
        if ./mvnw validate -q > /dev/null 2>&1; then
            echo "   ✅ POM validation: SUCCESS"
        else
            echo "   ❌ POM validation: FAILED"
            ./mvnw validate 2>&1 | head -3
        fi
        
        cd ..
    fi
done

echo ""
echo "📋 DEPENDENCIES ADDED:"
echo "====================="
echo "✅ jakarta.validation-api (validation annotations)"
echo "✅ hibernate-validator (validation implementation)"
echo ""
echo "🔄 THESE PROVIDE:"
echo "================"
echo "@Valid, @NotNull, @NotEmpty, @NotBlank, @Size, @Min, @Max, etc."