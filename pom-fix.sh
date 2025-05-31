#!/bin/bash
# Script mejorado para arreglar POMs sin duplicar tags

echo "🧹 CLEANING AND FIXING POM FILES"
echo "================================"

# Lista de servicios
SERVICES=("user-service" "product-service" "order-service" "payment-service" "proxy-client")

for service in "${SERVICES[@]}"; do
    if [ -d "$service" ]; then
        echo ""
        echo "🛠️ Cleaning and fixing $service/pom.xml..."
        
        POM_FILE="$service/pom.xml"
        CLEAN_POM="$service/pom.xml.clean"
        BACKUP_FILE="$service/pom.xml.backup-$(date +%Y%m%d-%H%M%S)"
        
        # Hacer backup del POM actual
        cp "$POM_FILE" "$BACKUP_FILE"
        echo "   📁 Backup created: $BACKUP_FILE"
        
        # ESTRATEGIA: Crear POM limpio desde cero basado en payment-service
        echo "   🆕 Creating clean POM..."
        
        cat > "$CLEAN_POM" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>

<project xmlns="http://maven.apache.org/POM/4.0.0"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<parent>
		<groupId>com.selimhorri</groupId>
		<artifactId>ecommerce-microservice-backend</artifactId>
		<version>0.1.0</version>
	</parent>
EOF

        # Extraer el artifactId específico del servicio
        ARTIFACT_ID=$(grep -o '<artifactId>[^<]*</artifactId>' "$POM_FILE" | grep -v 'ecommerce-microservice-backend' | head -1 | sed 's/<[^>]*>//g')
        
        if [ -z "$ARTIFACT_ID" ]; then
            ARTIFACT_ID="$service"
        fi
        
        echo "   🏷️ Using artifactId: $ARTIFACT_ID"
        
        # Continuar construyendo el POM limpio
        cat >> "$CLEAN_POM" << EOF
	<artifactId>$ARTIFACT_ID</artifactId>
	<name>$ARTIFACT_ID</name>
	<description>Spring Boot microservice</description>
	<packaging>jar</packaging>
	
	<properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <maven.compiler.release>11</maven.compiler.release>
        <lombok.version>1.18.30</lombok.version>
		<java.version>11</java.version>
		<spring-cloud.version>2020.0.4</spring-cloud.version>
		<testcontainers.version>1.16.0</testcontainers.version>
	</properties>
	
	<dependencies>
		<dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-starter</artifactId>
		</dependency>
		<dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-starter-config</artifactId>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-data-jpa</artifactId>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-thymeleaf</artifactId>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-validation</artifactId>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-web</artifactId>
		</dependency>
		<dependency>
			<groupId>org.flywaydb</groupId>
			<artifactId>flyway-core</artifactId>
		</dependency>
		<dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
		</dependency>
		<dependency>
			<groupId>com.h2database</groupId>
			<artifactId>h2</artifactId>
			<scope>runtime</scope>
		</dependency>
		<dependency>
			<groupId>mysql</groupId>
			<artifactId>mysql-connector-java</artifactId>
			<scope>runtime</scope>
		</dependency>
		<dependency>
			<groupId>org.projectlombok</groupId>
			<artifactId>lombok</artifactId>
			<optional>true</optional>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-test</artifactId>
			<scope>test</scope>
		</dependency>
		<dependency>
			<groupId>org.testcontainers</groupId>
			<artifactId>mysql</artifactId>
			<scope>test</scope>
		</dependency>
	</dependencies>
	
	<dependencyManagement>
		<dependencies>
			<dependency>
				<groupId>org.springframework.cloud</groupId>
				<artifactId>spring-cloud-dependencies</artifactId>
				<version>\${spring-cloud.version}</version>
				<type>pom</type>
				<scope>import</scope>
			</dependency>
			<dependency>
				<groupId>org.testcontainers</groupId>
				<artifactId>testcontainers-bom</artifactId>
				<version>\${testcontainers.version}</version>
				<type>pom</type>
				<scope>import</scope>
			</dependency>
		</dependencies>
	</dependencyManagement>
	
	<build>
		<plugins>
			<plugin>
				<groupId>org.apache.maven.plugins</groupId>
				<artifactId>maven-surefire-plugin</artifactId>
				<version>2.22.2</version>
				<configuration>
					<useSystemClassLoader>false</useSystemClassLoader>
					<includes>
						<include>**/*Test.java</include>
						<include>**/*Tests.java</include>
					</includes>
				</configuration>
			</plugin>
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
				<configuration>
					<excludes>
						<exclude>
							<groupId>org.projectlombok</groupId>
							<artifactId>lombok</artifactId>
						</exclude>
					</excludes>
				</configuration>
			</plugin>
		</plugins>
		<finalName>$ARTIFACT_ID</finalName>
	</build>
	
</project>
EOF

        # Reemplazar el POM original con el limpio
        mv "$CLEAN_POM" "$POM_FILE"
        echo "   ✅ Clean POM created and installed"
        
        # Validar inmediatamente
        cd "$service"
        if ./mvnw validate -q > /dev/null 2>&1; then
            echo "   ✅ POM validation: SUCCESS"
        else
            echo "   ❌ POM validation: FAILED"
            ./mvnw validate 2>&1 | head -3
        fi
        cd ..
        
    else
        echo "⚠️ $service directory not found"
    fi
done

echo ""
echo "🧪 TESTING ALL SERVICES"
echo "======================"

# Probar cada servicio
for service in "${SERVICES[@]}"; do
    if [ -d "$service" ]; then
        echo ""
        echo "🔨 Testing $service..."
        cd "$service"
        
        # Test compilation
        if ./mvnw clean compile -q > /dev/null 2>&1; then
            echo "   ✅ COMPILE: SUCCESS"
            
            # Test test-compile
            if ./mvnw test-compile -q > /dev/null 2>&1; then
                echo "   ✅ TEST-COMPILE: SUCCESS"
                
                # Test running tests (allow failures but capture reports)
                ./mvnw test -Dmaven.test.failure.ignore=true -q > /dev/null 2>&1
                
                # Check for reports
                if [ -d "target/surefire-reports" ] && [ "$(ls -A target/surefire-reports 2>/dev/null)" ]; then
                    report_count=$(ls target/surefire-reports/*.xml 2>/dev/null | wc -l)
                    echo "   📊 TEST REPORTS: $report_count files"
                    echo "   ✅ TESTS: COMPLETED"
                else
                    echo "   ⚠️ TEST REPORTS: Not found"
                fi
            else
                echo "   ❌ TEST-COMPILE: FAILED"
            fi
        else
            echo "   ❌ COMPILE: FAILED"
            ./mvnw compile 2>&1 | head -2
        fi
        
        cd ..
    fi
done

echo ""
echo "🎉 POM CLEANING COMPLETED!"
echo "========================="
echo "All POMs have been recreated with clean structure"
echo "Backups saved with timestamp"
echo ""
echo "💡 NOTE: If you need specific dependencies that were in original POMs,"
echo "you'll need to add them back manually to the clean POMs"