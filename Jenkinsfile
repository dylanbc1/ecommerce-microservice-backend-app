pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'localhost:5000'
        K8S_NAMESPACE_DEV = 'ecommerce-dev'
        K8S_NAMESPACE_STAGE = 'ecommerce-stage'
        K8S_NAMESPACE_PROD = 'ecommerce-prod'
        JAVA_HOME = '/opt/java/openjdk'
        MAVEN_OPTS = '-Xmx1024m'
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
    }

    stages {
        stage('Checkout & Validation') {
            steps {
                script {
                    echo "=== CHECKOUT & VALIDATION ==="
                    checkout scm
                    
                    // Verify workspace structure
                    sh 'ls -la'
                    
                    // Check key files exist
                    def services = ['api-gateway', 'proxy-client', 'user-service', 
                                   'product-service', 'order-service', 'payment-service']
                    
                    services.each { service ->
                        if (!fileExists("${service}/pom.xml")) {
                            error "❌ ${service}/pom.xml not found"
                        } else {
                            echo "✅ ${service} structure verified"
                        }
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
                            sh './mvnw clean test -Dtest=*Test'
                            publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                        }
                    }
                }
                stage('Product Service Tests') {
                    steps {
                        dir('product-service') {
                            sh './mvnw clean test -Dtest=*Test'
                            publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                        }
                    }
                }
                stage('Order Service Tests') {
                    steps {
                        dir('order-service') {
                            sh './mvnw clean test -Dtest=*Test'
                            publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                        }
                    }
                }
                stage('Payment Service Tests') {
                    steps {
                        dir('payment-service') {
                            sh './mvnw clean test -Dtest=*Test'
                            publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                        }
                    }
                }
                stage('Proxy Client Tests') {
                    steps {
                        dir('proxy-client') {
                            sh './mvnw clean test -Dtest=*Test'
                            publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
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
                        sh './mvnw test -Dtest=*IntegrationTest -Dspring.profiles.active=integration'
                        publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
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
                        sh './mvnw test -Dtest=*E2ETest -Dspring.profiles.active=e2e'
                        publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
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
            }
        }
    }
}

// Helper Functions
def buildService(serviceName) {
    dir(serviceName) {
        echo "Building ${serviceName}..."
        sh './mvnw clean package -DskipTests'
        
        // Verify JAR was created
        def jarFile = sh(
            script: "find target -name '*.jar' -not -name '*sources*' | head -1",
            returnStdout: true
        ).trim()
        
        if (jarFile) {
            echo "✅ ${serviceName} built successfully: ${jarFile}"
        } else {
            error "❌ JAR not found for ${serviceName}"
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
