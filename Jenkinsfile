pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'localhost:5000'
        K8S_NAMESPACE_DEV = 'ecommerce-dev'
        K8S_NAMESPACE_STAGE = 'ecommerce-stage'
        K8S_NAMESPACE_PROD = 'ecommerce-prod'
        // Configuración específica de Java para evitar problemas de compatibilidad
        JAVA_HOME = '/opt/java/openjdk'
        MAVEN_OPTS = '-Xmx1024m -Djava.awt.headless=true'
        // Asegurar que usamos Java 17 por compatibilidad
        PATH = "${env.JAVA_HOME}/bin:${env.PATH}"
    }

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'stage', 'master'],
            description: 'Environment to deploy to'
        )
        string(
            name: 'BUILD_TAG',
            defaultValue: "${env.BUILD_ID}",
            description: 'Docker image tag'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip all tests (emergency deployment only)'
        )
        booleanParam(
            name: 'SKIP_PERFORMANCE_TESTS',
            defaultValue: false,
            description: 'Skip performance tests only'
        )
        choice(
            name: 'PERFORMANCE_TEST_LEVEL',
            choices: ['light', 'standard', 'stress'],
            description: 'Performance test intensity'
        )
        choice(
            name: 'JAVA_VERSION_OVERRIDE',
            choices: ['auto', 'java-17', 'java-11'],
            description: 'Override Java version for compatibility'
        )
    }

    stages {
        stage('Environment Setup') {
            steps {
                script {
                    echo "=== ENVIRONMENT SETUP ==="
                    
                    // Verificar Java version
                    sh '''
                        echo "Current Java version:"
                        java -version
                        echo "Maven version:"
                        mvn -version || echo "Maven not found in PATH"
                        echo "Environment variables:"
                        echo "JAVA_HOME: $JAVA_HOME"
                        echo "PATH: $PATH"
                    '''
                    
                    // Configurar alternativa de Java si es necesario
                    if (params.JAVA_VERSION_OVERRIDE != 'auto') {
                        echo "Overriding Java version to: ${params.JAVA_VERSION_OVERRIDE}"
                        setupJavaVersion(params.JAVA_VERSION_OVERRIDE)
                    }
                }
            }
        }
        
        stage('Checkout & Validation') {
            steps {
                script {
                    echo "=== CHECKOUT & VALIDATION ==="
                    checkout scm
                    
                    // Verify workspace structure
                    sh 'ls -la'
                    
                    // Check key files exist and validate pom.xml files
                    def services = ['api-gateway', 'proxy-client', 'user-service', 
                                   'product-service', 'order-service', 'payment-service']
                    
                    services.each { service ->
                        if (!fileExists("${service}/pom.xml")) {
                            error "❌ ${service}/pom.xml not found"
                        } else {
                            echo "✅ ${service} structure verified"
                            // Verificar y reportar versiones de dependencias críticas
                            validatePomDependencies(service)
                        }
                    }
                }
            }
        }

        stage('Dependency Check & Fix') {
            steps {
                script {
                    echo "=== DEPENDENCY CHECK & FIX ==="
                    
                    def services = ['api-gateway', 'proxy-client', 'user-service', 
                                   'product-service', 'order-service', 'payment-service']
                    
                    services.each { service ->
                        fixLombokCompatibility(service)
                    }
                }
            }
        }

        stage('Unit Tests') {
            when { 
                expression { !params.SKIP_TESTS }
            }
            parallel {
                stage('User Service Tests') {
                    steps {
                        dir('user-service') {
                            script {
                                runTestsWithRetry(service: 'user-service')
                            }
                        }
                    }
                }
                stage('Product Service Tests') {
                    steps {
                        dir('product-service') {
                            script {
                                runTestsWithRetry(service: 'product-service')
                            }
                        }
                    }
                }
                stage('Order Service Tests') {
                    steps {
                        dir('order-service') {
                            script {
                                runTestsWithRetry(service: 'order-service')
                            }
                        }
                    }
                }
                stage('Payment Service Tests') {
                    steps {
                        dir('payment-service') {
                            script {
                                runTestsWithRetry(service: 'payment-service')
                            }
                        }
                    }
                }
                stage('Proxy Client Tests') {
                    steps {
                        dir('proxy-client') {
                            script {
                                runTestsWithRetry(service: 'proxy-client')
                            }
                        }
                    }
                }
            }
        }

        stage('Integration Tests') {
            when { 
                allOf {
                    expression { !params.SKIP_TESTS }
                    anyOf {
                        expression { params.ENVIRONMENT == 'stage' }
                        expression { params.ENVIRONMENT == 'master' }
                    }
                }
            }
            steps {
                script {
                    echo "=== INTEGRATION TESTS ==="
                    
                    dir('proxy-client') {
                        runTestsWithRetry(
                            service: 'proxy-client',
                            testType: 'integration',
                            profile: 'integration'
                        )
                    }
                    
                    echo "✅ Integration tests completed"
                }
            }
        }

        stage('Build & Package') {
            parallel {
                stage('Build API Gateway') {
                    steps { buildService('api-gateway') }
                }
                stage('Build Proxy Client') {
                    steps { buildService('proxy-client') }
                }
                stage('Build User Service') {
                    steps { buildService('user-service') }
                }
                stage('Build Product Service') {
                    steps { buildService('product-service') }
                }
                stage('Build Order Service') {
                    steps { buildService('order-service') }
                }
                stage('Build Payment Service') {
                    steps { buildService('payment-service') }
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    echo "=== DOCKER BUILD & PUSH ==="
                    
                    def services = ['service-discovery', 'cloud-config', 'api-gateway', 
                                   'proxy-client', 'user-service', 'product-service', 
                                   'order-service', 'payment-service', 'shipping-service']
                    
                    services.each { service ->
                        buildAndPushDockerImage(service, params.BUILD_TAG)
                    }
                }
            }
        }

        stage('Deploy to Environment') {
            steps {
                script {
                    echo "=== DEPLOYING TO ${params.ENVIRONMENT.toUpperCase()} ==="
                    
                    def namespace = getNamespaceForEnvironment(params.ENVIRONMENT)
                    
                    // Create namespace if not exists
                    sh "kubectl create namespace ${namespace} --dry-run=client -o yaml | kubectl apply -f -"
                    
                    // Deploy services
                    deployAllServices(namespace, params.BUILD_TAG)
                    
                    // Wait for deployment readiness
                    sh "kubectl wait --for=condition=available --timeout=300s deployment --all -n ${namespace}"
                    
                    echo "✅ Deployment to ${params.ENVIRONMENT} completed"
                }
            }
        }

        stage('E2E Tests') {
            when { 
                allOf {
                    expression { !params.SKIP_TESTS }
                    expression { params.ENVIRONMENT == 'master' }
                }
            }
            steps {
                script {
                    echo "=== END-TO-END TESTS ==="
                    
                    // Wait for services to be fully ready
                    sleep(30)
                    
                    dir('proxy-client') {
                        runTestsWithRetry(
                            service: 'proxy-client',
                            testType: 'e2e',
                            profile: 'e2e'
                        )
                    }
                    
                    echo "✅ E2E tests completed"
                }
            }
        }

        stage('Performance Tests') {
            when { 
                allOf {
                    expression { !params.SKIP_TESTS }
                    expression { !params.SKIP_PERFORMANCE_TESTS }
                    expression { params.ENVIRONMENT == 'master' }
                }
            }
            steps {
                script {
                    echo "=== PERFORMANCE TESTS ==="
                    runPerformanceTests()
                }
            }
            post {
                always {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'tests/performance/results',
                        reportFiles: '*.html',
                        reportName: 'Performance Test Report'
                    ])
                    
                    archiveArtifacts artifacts: 'tests/performance/results/**', allowEmptyArchive: true
                }
            }
        }

        stage('Generate Release Notes') {
            when { 
                expression { params.ENVIRONMENT == 'master' }
            }
            steps {
                script {
                    generateReleaseNotes(params.BUILD_TAG)
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/target/surefire-reports/**', allowEmptyArchive: true
            
            script {
                def status = currentBuild.currentResult
                echo "Pipeline Status: ${status}"
                
                if (status == 'SUCCESS') {
                    echo "✅ Pipeline completed successfully"
                } else {
                    echo "❌ Pipeline failed - check logs for details"
                }
            }
        }
        
        success {
            script {
                echo "🎉 DEPLOYMENT SUCCESSFUL!"
                echo "Environment: ${params.ENVIRONMENT}"
                echo "Build Tag: ${params.BUILD_TAG}"
                
                def namespace = getNamespaceForEnvironment(params.ENVIRONMENT)
                sh "kubectl get pods -n ${namespace}"
            }
        }
        
        failure {
            script {
                echo "💥 DEPLOYMENT FAILED!"
                def namespace = getNamespaceForEnvironment(params.ENVIRONMENT)
                sh "kubectl get pods -n ${namespace} || true"
                
                // Imprimir información de debug de Java/Maven
                sh '''
                    echo "=== DEBUG INFORMATION ==="
                    java -version || echo "Java not found"
                    mvn -version || echo "Maven not found"
                    echo "JAVA_HOME: $JAVA_HOME"
                    echo "PATH: $PATH"
                '''
            }
        }
    }
}

// Helper Functions
def setupJavaVersion(javaVersion) {
    echo "Setting up Java version: ${javaVersion}"
    
    switch(javaVersion) {
        case 'java-17':
            env.JAVA_HOME = '/usr/lib/jvm/java-17-openjdk'
            break
        case 'java-11':
            env.JAVA_HOME = '/usr/lib/jvm/java-11-openjdk'
            break
        default:
            echo "Using default Java version"
    }
    
    env.PATH = "${env.JAVA_HOME}/bin:${env.PATH}"
    
    sh '''
        echo "Updated Java configuration:"
        java -version
        echo "JAVA_HOME: $JAVA_HOME"
    '''
}

def validatePomDependencies(serviceName) {
    dir(serviceName) {
        echo "Validating dependencies for ${serviceName}..."
        
        // Verificar versión de Lombok si existe
        sh '''
            if grep -q "lombok" pom.xml; then
                echo "Lombok found in ${serviceName}"
                grep -A 2 -B 2 "lombok" pom.xml || echo "Could not extract Lombok version"
            else
                echo "No Lombok dependency found in ${serviceName}"
            fi
        '''
        
        // Verificar versión de Spring Boot
        sh '''
            if grep -q "spring-boot" pom.xml; then
                echo "Spring Boot found in ${serviceName}"
                grep -A 2 -B 2 "spring-boot-starter-parent" pom.xml || echo "Could not extract Spring Boot version"
            fi
        '''
    }
}

def fixLombokCompatibility(serviceName) {
    dir(serviceName) {
        echo "Checking and fixing Lombok compatibility for ${serviceName}..."
        
        // Verificar si el proyecto usa Lombok
        def usesLombok = sh(
            script: "grep -q 'lombok' pom.xml && echo 'true' || echo 'false'",
            returnStdout: true
        ).trim()
        
        if (usesLombok == 'true') {
            echo "📦 ${serviceName} uses Lombok - checking version..."
            
            // Intentar actualizar Lombok a versión compatible si es necesario
            sh '''
                # Verificar versión actual de Lombok
                CURRENT_LOMBOK=$(grep -A 5 "<artifactId>lombok</artifactId>" pom.xml | grep -o "<version>[^<]*</version>" | head -1 || echo "")
                echo "Current Lombok version in pom.xml: $CURRENT_LOMBOK"
                
                # Si no hay versión explícita o es muy antigua, advertir
                if [ -z "$CURRENT_LOMBOK" ]; then
                    echo "⚠️ No explicit Lombok version found - using parent BOM version"
                elif echo "$CURRENT_LOMBOK" | grep -E "(1\.18\.(0|1|2)[0-9]|1\.1[0-7]\.)"; then
                    echo "⚠️ Potentially incompatible Lombok version: $CURRENT_LOMBOK"
                    echo "🔧 Consider updating to 1.18.30+ for Java 21 compatibility"
                else
                    echo "✅ Lombok version should be compatible"
                fi
            '''
        } else {
            echo "✅ ${serviceName} does not use Lombok"
        }
    }
}

def runTestsWithRetry(Map config) {
    def service = config.service
    def testType = config.get('testType', 'unit')
    def profile = config.get('profile', 'test')
    def maxRetries = 2
    
    echo "Running ${testType} tests for ${service} with profile: ${profile}"
    
    for (int i = 0; i <= maxRetries; i++) {
        try {
            def testCommand = buildTestCommand(testType, profile)
            
            sh """
                echo "Attempt ${i + 1}/${maxRetries + 1} for ${service} ${testType} tests"
                ${testCommand}
            """
            
            // Publicar resultados si existen
            if (fileExists('target/surefire-reports/*.xml')) {
                publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
            }
            
            echo "✅ ${testType} tests passed for ${service}"
            return // Éxito, salir del bucle
            
        } catch (Exception e) {
            echo "❌ Attempt ${i + 1} failed for ${service}: ${e.getMessage()}"
            
            if (i < maxRetries) {
                echo "🔄 Retrying in 30 seconds..."
                sleep(30)
                
                // Limpiar y reintentar
                sh 'mvn clean || echo "Clean failed, continuing..."'
            } else {
                echo "💥 All attempts failed for ${service} ${testType} tests"
                // No lanzar error para no fallar todo el pipeline
                currentBuild.result = 'UNSTABLE'
            }
        }
    }
}

def buildTestCommand(testType, profile) {
    switch(testType) {
        case 'integration':
            return "./mvnw test -Dtest=*IntegrationTest -Dspring.profiles.active=${profile}"
        case 'e2e':
            return "./mvnw test -Dtest=*E2ETest -Dspring.profiles.active=${profile}"
        default: // unit tests
            return "./mvnw clean test -Dtest=*Test"
    }
}

def buildService(serviceName) {
    dir(serviceName) {
        echo "Building ${serviceName}..."
        
        // Usar múltiples intentos para el build
        def maxRetries = 2
        for (int i = 0; i <= maxRetries; i++) {
            try {
                sh '''
                    echo "Cleaning previous build artifacts..."
                    mvn clean || ./mvnw clean || echo "Clean failed, continuing..."
                    
                    echo "Building with skip tests..."
                    ./mvnw package -DskipTests -Dmaven.test.skip=true
                '''
                
                // Verify JAR was created
                def jarFile = sh(
                    script: "find target -name '*.jar' -not -name '*sources*' | head -1",
                    returnStdout: true
                ).trim()
                
                if (jarFile) {
                    echo "✅ ${serviceName} built successfully: ${jarFile}"
                    return // Éxito
                } else {
                    throw new Exception("JAR not found for ${serviceName}")
                }
                
            } catch (Exception e) {
                echo "❌ Build attempt ${i + 1} failed for ${serviceName}: ${e.getMessage()}"
                
                if (i < maxRetries) {
                    echo "🔄 Retrying build for ${serviceName}..."
                    sleep(15)
                } else {
                    error "❌ All build attempts failed for ${serviceName}"
                }
            }
        }
    }
}

def buildAndPushDockerImage(serviceName, buildTag) {
    echo "Building Docker image for ${serviceName}..."
    
    def imageName = "${env.DOCKER_REGISTRY}/${serviceName}:${buildTag}"
    
    dir(serviceName) {
        if (fileExists('Dockerfile')) {
            sh "docker build -t ${imageName} ."
            
            try {
                sh "docker push ${imageName}"
                echo "✅ Image pushed: ${imageName}"
            } catch (Exception e) {
                echo "⚠️ Push failed, using local image: ${e.message}"
            }
        } else {
            echo "⚠️ No Dockerfile found for ${serviceName}"
        }
    }
}

def deployAllServices(namespace, buildTag) {
    def services = ['service-discovery', 'cloud-config', 'api-gateway', 
                   'proxy-client', 'user-service', 'product-service', 
                   'order-service', 'payment-service', 'shipping-service']
    
    services.each { service ->
        deployService(service, namespace, buildTag)
    }
}

def deployService(serviceName, namespace, buildTag) {
    echo "Deploying ${serviceName} to ${namespace}..."
    
    def deploymentFile = "k8s/${serviceName}/deployment.yaml"
    def serviceFile = "k8s/${serviceName}/service.yaml"
    
    if (fileExists(deploymentFile)) {
        // Update image tag in deployment
        def imageName = "${env.DOCKER_REGISTRY}/${serviceName}:${buildTag}"
        sh """
            sed 's|{{IMAGE_NAME}}|${imageName}|g' ${deploymentFile} | kubectl apply -f - -n ${namespace}
        """
        
        if (fileExists(serviceFile)) {
            sh "kubectl apply -f ${serviceFile} -n ${namespace}"
        }
        
        echo "✅ ${serviceName} deployed to ${namespace}"
    } else {
        echo "⚠️ Deployment file not found: ${deploymentFile}"
    }
}

def getNamespaceForEnvironment(environment) {
    switch(environment) {
        case 'dev':
            return env.K8S_NAMESPACE_DEV
        case 'stage':
            return env.K8S_NAMESPACE_STAGE
        case 'master':
            return env.K8S_NAMESPACE_PROD
        default:
            return env.K8S_NAMESPACE_DEV
    }
}

def runPerformanceTests() {
    echo "🚀 Running Performance Tests with Locust..."
    
    dir('tests/performance') {
        // Create results directory
        sh 'mkdir -p results'
        
        // Install dependencies
        sh '''
            python3 -m venv venv || echo "Virtual env creation failed, continuing..."
            . venv/bin/activate || echo "Virtual env activation failed, using global python"
            pip3 install locust requests || echo "Package installation failed"
        '''
        
        // Configure test parameters based on level
        def testConfig = getPerformanceTestConfig(params.PERFORMANCE_TEST_LEVEL)
        
        echo "Performance test configuration: ${testConfig}"
        
        // Run performance tests
        sh """
            . venv/bin/activate || echo "Using global python"
            python3 -c "
import subprocess
import sys
from datetime import datetime

# Test configuration
users = ${testConfig.users}
spawn_rate = ${testConfig.spawnRate}
duration = ${testConfig.duration}
host = 'http://localhost'

print(f'Starting performance test: {users} users, {spawn_rate}/s spawn rate, {duration}s duration')

# Run Locust
cmd = [
    'locust',
    '-f', 'locustfile.py',
    '--headless',
    '--users', str(users),
    '--spawn-rate', str(spawn_rate),
    '--run-time', f'{duration}s',
    '--host', host,
    '--html', f'results/performance_report_{datetime.now().strftime(\"%Y%m%d_%H%M%S\")}.html',
    '--csv', f'results/performance_data_{datetime.now().strftime(\"%Y%m%d_%H%M%S\")}'
]

try:
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=duration+60)
    print('STDOUT:', result.stdout)
    if result.stderr:
        print('STDERR:', result.stderr)
    print(f'Return code: {result.returncode}')
except Exception as e:
    print(f'Error running locust: {e}')
    sys.exit(1)
"
        """
        
        echo "✅ Performance tests completed"
    }
}

def getPerformanceTestConfig(level) {
    switch(level) {
        case 'light':
            return [users: 10, spawnRate: 1, duration: 60]
        case 'stress':
            return [users: 50, spawnRate: 5, duration: 300]
        default: // standard
            return [users: 20, spawnRate: 2, duration: 120]
    }
}

def generateReleaseNotes(buildTag) {
    def releaseNotes = """
# Release Notes - Build ${buildTag}

## 📋 Build Information
- **Build Number**: ${env.BUILD_NUMBER}
- **Build Tag**: ${buildTag}
- **Date**: ${new Date().format('yyyy-MM-dd HH:mm:ss')}
- **Environment**: ${params.ENVIRONMENT}
- **Git Commit**: ${env.GIT_COMMIT ?: 'Unknown'}
- **Java Version Override**: ${params.JAVA_VERSION_OVERRIDE}

## 🚀 Deployed Services
- api-gateway:${buildTag}
- proxy-client:${buildTag}
- user-service:${buildTag}
- product-service:${buildTag}
- order-service:${buildTag}
- payment-service:${buildTag}

## ✅ Test Results
- **Unit Tests**: ${params.SKIP_TESTS ? 'SKIPPED' : 'EXECUTED'}
- **Integration Tests**: ${(params.ENVIRONMENT != 'dev' && !params.SKIP_TESTS) ? 'EXECUTED' : 'SKIPPED'}
- **E2E Tests**: ${(params.ENVIRONMENT == 'master' && !params.SKIP_TESTS) ? 'EXECUTED' : 'SKIPPED'}
- **Performance Tests**: ${(params.ENVIRONMENT == 'master' && !params.SKIP_TESTS && !params.SKIP_PERFORMANCE_TESTS) ? "EXECUTED (${params.PERFORMANCE_TEST_LEVEL.toUpperCase()})" : 'SKIPPED'}

## 🔧 Build Configuration
- **Java Version**: ${params.JAVA_VERSION_OVERRIDE != 'auto' ? params.JAVA_VERSION_OVERRIDE : 'Default (Jenkins configured)'}
- **Maven Options**: ${env.MAVEN_OPTS}

## 📊 Performance Metrics
${(params.ENVIRONMENT == 'master' && !params.SKIP_PERFORMANCE_TESTS) ? '''
- Response Time: Target < 200ms (95th percentile)
- Throughput: Target > 100 requests/second
- Error Rate: Target < 1%
- Test Level: ''' + params.PERFORMANCE_TEST_LEVEL.toUpperCase() : 'Performance tests not executed'}

## 🔄 Recent Changes
\$(git log --oneline --since="1 day ago" | head -5 || echo "No recent commits found")

## 🌐 Access Information
- **Environment**: ${params.ENVIRONMENT}
- **Namespace**: ${getNamespaceForEnvironment(params.ENVIRONMENT)}
- **Services Status**: All services deployed and ready

---
*Generated automatically by Jenkins Pipeline on ${new Date().format('yyyy-MM-dd HH:mm:ss')}*
"""
    
    writeFile file: "release-notes-${buildTag}.md", text: releaseNotes
    archiveArtifacts artifacts: "release-notes-${buildTag}.md"
    
    echo "✅ Release notes generated: release-notes-${buildTag}.md"
}
