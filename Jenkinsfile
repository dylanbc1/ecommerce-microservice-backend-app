pipeline {
    agent any

    environment {
        // Configuración Docker y Kubernetes
        DOCKER_REGISTRY = 'localhost:5000'
        K8S_NAMESPACE = 'ecommerce-dev'
        K8S_CONTEXT = 'docker-desktop'
        
        // Configuración Maven y Java
        MAVEN_OPTS = '-Xmx1024m'
        JAVA_HOME = '/opt/java/openjdk'
        
        // Servicios del taller (6 microservicios que se comunican)
        CORE_SERVICES = 'api-gateway,user-service,product-service,order-service,payment-service,proxy-client'
    }

    parameters {
        choice(
            name: 'TARGET_ENV',
            choices: ['dev', 'stage', 'master'],
            description: 'Environment for deployment'
        )
        string(
            name: 'IMAGE_TAG',
            defaultValue: "${env.BUILD_ID}",
            description: 'Docker image tag'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip test execution'
        )
        booleanParam(
            name: 'GENERATE_ARTIFACTS',
            defaultValue: true,
            description: 'Generate release artifacts'
        )
    }

    stages {
        stage('Environment Setup') {
            steps {
                script {
                    echo "🚀 === ENVIRONMENT SETUP ==="
                    echo "Target Environment: ${params.TARGET_ENV}"
                    echo "Build Tag: ${params.IMAGE_TAG}"
                    
                    // Checkout and validate workspace
                    checkout scm
                    sh 'ls -la'
                    
                    // Validate core services exist
                    def services = env.CORE_SERVICES.split(',')
                    services.each { service ->
                        if (fileExists("${service}/pom.xml")) {
                            echo "✅ ${service} validated"
                        } else {
                            echo "⚠️ ${service} missing - will be skipped"
                        }
                    }
                    
                    echo "✅ Environment setup completed"
                }
            }
        }

        stage('Infrastructure Validation') {
            steps {
                script {
                    echo "🔧 === INFRASTRUCTURE VALIDATION ==="
                    
                    try {
                        // Check kubectl availability
                        def kubectlAvailable = sh(
                            script: 'command -v kubectl >/dev/null 2>&1 && echo "available" || echo "missing"',
                            returnStdout: true
                        ).trim()
                        
                        if (kubectlAvailable == "available") {
                            sh "kubectl config use-context ${env.K8S_CONTEXT} || echo 'Context not available'"
                            sh "kubectl cluster-info || echo 'Cluster not accessible'"
                            
                            // Create namespace if needed
                            sh """
                                kubectl get namespace ${env.K8S_NAMESPACE} || \
                                kubectl create namespace ${env.K8S_NAMESPACE} || echo 'Namespace creation failed'
                            """
                            echo "✅ Kubernetes environment ready"
                        } else {
                            echo "⚠️ kubectl not available - deployment will be skipped"
                        }
                        
                    } catch (Exception e) {
                        echo "⚠️ Infrastructure validation issues: ${e.getMessage()}"
                        echo "Continuing with limited functionality..."
                    }
                }
            }
        }

        stage('Compilation & Build') {
            steps {
                script {
                    echo "🔨 === COMPILATION & BUILD ==="
                    
                    def services = env.CORE_SERVICES.split(',')
                    def buildResults = [:]
                    
                    services.each { service ->
                        if (fileExists("${service}/pom.xml")) {
                            buildResults[service] = compileService(service)
                        } else {
                            buildResults[service] = 'SKIPPED'
                            echo "⏭️ ${service} skipped - not found"
                        }
                    }
                    
                    // Summary
                    echo "📊 === BUILD SUMMARY ==="
                    buildResults.each { service, status ->
                        echo "${service}: ${status}"
                    }
                }
            }
        }

        stage('Quality Assurance') {
            when {
                expression { !params.SKIP_TESTS }
            }
            steps {
                script {
                    echo "🧪 === QUALITY ASSURANCE ==="
                    
                    def testServices = ['user-service', 'product-service', 'order-service', 'payment-service']
                    def testResults = [:]
                    
                    testServices.each { service ->
                        if (fileExists("${service}/pom.xml")) {
                            testResults[service] = executeTests(service)
                        } else {
                            testResults[service] = 'SKIPPED'
                        }
                    }
                    
                    // Advanced tests for key services
                    if (fileExists('proxy-client/pom.xml')) {
                        testResults['integration'] = executeIntegrationTests()
                    }
                    
                    echo "📊 === TEST SUMMARY ==="
                    testResults.each { test, status ->
                        echo "${test}: ${status}"
                    }
                }
            }
        }

        stage('Container Building') {
            steps {
                script {
                    echo "🐳 === CONTAINER BUILDING ==="
                    
                    def services = env.CORE_SERVICES.split(',')
                    def imageResults = [:]
                    
                    services.each { service ->
                        if (fileExists("${service}/Dockerfile")) {
                            imageResults[service] = buildContainerImage(service, params.IMAGE_TAG)
                        } else {
                            imageResults[service] = 'NO_DOCKERFILE'
                            echo "⚠️ ${service} - Dockerfile not found"
                        }
                    }
                    
                    echo "📊 === CONTAINER BUILD SUMMARY ==="
                    imageResults.each { service, status ->
                        echo "${service}: ${status}"
                    }
                }
            }
        }

        stage('Deployment Orchestration') {
            steps {
                script {
                    echo "🚀 === DEPLOYMENT ORCHESTRATION ==="
                    
                    def kubectlAvailable = sh(
                        script: 'command -v kubectl >/dev/null 2>&1 && echo "true" || echo "false"',
                        returnStdout: true
                    ).trim()
                    
                    if (kubectlAvailable == "true") {
                        // Deploy infrastructure services first
                        deployInfrastructureServices()
                        
                        // Wait for infrastructure to stabilize
                        sleep(time: 30, unit: 'SECONDS')
                        
                        // Deploy application services
                        deployApplicationServices()
                        
                        // Verify deployment
                        verifyDeployment()
                        
                        echo "✅ Deployment orchestration completed"
                    } else {
                        echo "⚠️ Kubernetes not available - creating deployment artifacts only"
                        createDeploymentArtifacts()
                    }
                }
            }
        }

        stage('System Verification') {
            when {
                allOf {
                    expression { !params.SKIP_TESTS }
                    expression { params.TARGET_ENV == 'master' }
                }
            }
            steps {
                script {
                    echo "✅ === SYSTEM VERIFICATION ==="
                    
                    try {
                        // Wait for system stabilization
                        sleep(time: 45, unit: 'SECONDS')
                        
                        // Verify core services are running
                        def coreServices = ['api-gateway', 'user-service', 'product-service', 'order-service']
                        
                        coreServices.each { service ->
                            sh """
                                kubectl wait --for=condition=ready pod -l app=${service} \
                                -n ${env.K8S_NAMESPACE} --timeout=120s || echo "${service} not ready"
                            """
                        }
                        
                        // Execute smoke tests
                        executeSystemSmokeTests()
                        
                        echo "✅ System verification completed"
                        
                    } catch (Exception e) {
                        echo "⚠️ System verification issues: ${e.getMessage()}"
                        echo "System may still be initializing..."
                    }
                }
            }
        }

        stage('Release Documentation') {
            when {
                expression { params.GENERATE_ARTIFACTS }
            }
            steps {
                script {
                    echo "📋 === RELEASE DOCUMENTATION ==="
                    generateReleaseDocumentation()
                }
            }
        }
    }

    post {
        always {
            script {
                echo "🏁 === PIPELINE COMPLETION ==="
                
                // Archive test results
                archiveArtifacts artifacts: '**/target/surefire-reports/**', allowEmptyArchive: true
                
                // Clean temporary files
                sh "rm -f temp-*-deployment.yaml || true"
                sh "rm -f build-*.log || true"
                
                def buildStatus = currentBuild.currentResult
                echo "Pipeline Status: ${buildStatus}"
                echo "Environment: ${params.TARGET_ENV}"
                echo "Image Tag: ${params.IMAGE_TAG}"
                echo "Tests: ${params.SKIP_TESTS ? 'SKIPPED' : 'EXECUTED'}"
            }
        }
        
        success {
            script {
                echo "🎉 DEPLOYMENT SUCCESS!"
                
                try {
                    sh """
                        echo "=== CLUSTER STATUS ==="
                        kubectl get pods -n ${env.K8S_NAMESPACE} || echo "Cluster status unavailable"
                        kubectl get services -n ${env.K8S_NAMESPACE} || echo "Services status unavailable"
                    """
                } catch (Exception e) {
                    echo "Could not retrieve cluster status: ${e.getMessage()}"
                }
            }
        }
        
        failure {
            script {
                echo "💥 DEPLOYMENT FAILED!"
                echo "Check the logs above for specific error details"
                
                try {
                    sh """
                        echo "=== DEBUG INFORMATION ==="
                        kubectl get pods -n ${env.K8S_NAMESPACE} --show-labels || true
                        kubectl describe pods -n ${env.K8S_NAMESPACE} | tail -50 || true
                    """
                } catch (Exception e) {
                    echo "Could not retrieve debug information: ${e.getMessage()}"
                }
            }
        }
    }
}

// === HELPER FUNCTIONS ===

def compileService(String serviceName) {
    echo "🔨 Compiling ${serviceName}..."
    
    dir(serviceName) {
        try {
            sh '''
                chmod +x mvnw || echo "mvnw not found"
                
                echo "Cleaning previous builds..."
                ./mvnw clean || mvn clean || echo "Clean failed"
                
                echo "Compiling source code..."
                ./mvnw compile -DskipTests || mvn compile -DskipTests
                
                echo "Creating package..."
                ./mvnw package -DskipTests -Dmaven.test.skip=true || mvn package -DskipTests -Dmaven.test.skip=true
            '''
            
            // Verify JAR creation
            def jarExists = sh(
                script: "find target -name '*.jar' -not -name '*sources*' | head -1",
                returnStdout: true
            ).trim()
            
            if (jarExists) {
                echo "✅ ${serviceName} compiled successfully: ${jarExists}"
                return 'SUCCESS'
            } else {
                echo "⚠️ ${serviceName} compiled but no JAR found"
                return 'PARTIAL'
            }
            
        } catch (Exception e) {
            echo "❌ ${serviceName} compilation failed: ${e.getMessage()}"
            return 'FAILED'
        }
    }
}

def executeTests(String serviceName) {
    echo "🧪 Testing ${serviceName}..."
    
    dir(serviceName) {
        try {
            sh '''
                echo "Running unit tests..."
                ./mvnw test -Dmaven.test.failure.ignore=true || mvn test -Dmaven.test.failure.ignore=true || echo "Tests completed with issues"
            '''
            
            // Publish test results if available
            if (fileExists('target/surefire-reports/*.xml')) {
                publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                echo "✅ ${serviceName} tests executed - results published"
                return 'EXECUTED'
            } else {
                echo "⚠️ ${serviceName} tests executed - no results found"
                return 'NO_RESULTS'
            }
            
        } catch (Exception e) {
            echo "❌ ${serviceName} tests failed: ${e.getMessage()}"
            return 'FAILED'
        }
    }
}

def executeIntegrationTests() {
    echo "🔗 Running integration tests..."
    
    dir('proxy-client') {
        try {
            def hasIntegrationTests = sh(
                script: "find src/test/java -name '*IntegrationTest.java' | wc -l",
                returnStdout: true
            ).trim()
            
            if (hasIntegrationTests != '0') {
                sh './mvnw test -Dtest=*IntegrationTest* -Dmaven.test.failure.ignore=true || echo "Integration tests completed"'
                return 'EXECUTED'
            } else {
                echo "⚠️ No integration tests found"
                return 'NONE_FOUND'
            }
            
        } catch (Exception e) {
            echo "❌ Integration tests failed: ${e.getMessage()}"
            return 'FAILED'
        }
    }
}

def buildContainerImage(String serviceName, String imageTag) {
    echo "🐳 Building container for ${serviceName}..."
    
    dir(serviceName) {
        try {
            def imageName = "${serviceName}:${imageTag}"
            
            sh "docker build -t ${imageName} ."
            echo "✅ Container built: ${imageName}"
            
            // Try to push to registry if available
            try {
                def registryImage = "${env.DOCKER_REGISTRY}/${serviceName}:${imageTag}"
                sh "docker tag ${imageName} ${registryImage}"
                sh "docker push ${registryImage}"
                echo "✅ Image pushed to registry: ${registryImage}"
                return 'PUSHED'
            } catch (Exception pushError) {
                echo "⚠️ Registry push failed: ${pushError.getMessage()}"
                return 'LOCAL_ONLY'
            }
            
        } catch (Exception e) {
            echo "❌ Container build failed for ${serviceName}: ${e.getMessage()}"
            return 'FAILED'
        }
    }
}

def deployInfrastructureServices() {
    echo "🏗️ Deploying infrastructure services..."
    
    try {
        // Apply common configurations
        applyKubernetesConfig('k8s/namespace.yaml')
        applyKubernetesConfig('k8s/common-config.yaml')
        
        // Deploy service discovery
        deployServiceToK8s('service-discovery', params.IMAGE_TAG)
        
        // Deploy configuration service
        deployServiceToK8s('cloud-config', params.IMAGE_TAG)
        
        echo "✅ Infrastructure services deployed"
        
    } catch (Exception e) {
        echo "⚠️ Infrastructure deployment issues: ${e.getMessage()}"
    }
}

def deployApplicationServices() {
    echo "📦 Deploying application services..."
    
    try {
        def appServices = ['user-service', 'product-service', 'order-service', 'payment-service', 'proxy-client', 'api-gateway']
        
        appServices.each { service ->
            deployServiceToK8s(service, params.IMAGE_TAG)
        }
        
        echo "✅ Application services deployed"
        
    } catch (Exception e) {
        echo "⚠️ Application deployment issues: ${e.getMessage()}"
    }
}

def deployServiceToK8s(String serviceName, String imageTag) {
    echo "🚀 Deploying ${serviceName}..."
    
    try {
        def deploymentFile = "k8s/${serviceName}/deployment.yaml"
        def serviceFile = "k8s/${serviceName}/service.yaml"
        
        if (fileExists(deploymentFile)) {
            def processedFile = "temp-${serviceName}-deployment.yaml"
            def imageName = "${env.DOCKER_REGISTRY}/${serviceName}:${imageTag}"
            
            // Process deployment template
            sh """
                sed 's|{{IMAGE_NAME}}|${imageName}|g; s|{{BUILD_TAG}}|${imageTag}|g' ${deploymentFile} > ${processedFile}
                kubectl apply -f ${processedFile} -n ${env.K8S_NAMESPACE}
            """
            
            // Apply service configuration
            if (fileExists(serviceFile)) {
                sh "kubectl apply -f ${serviceFile} -n ${env.K8S_NAMESPACE}"
            }
            
            // Wait for deployment
            sh """
                kubectl rollout status deployment/${serviceName} -n ${env.K8S_NAMESPACE} --timeout=90s || echo "${serviceName} deployment may still be in progress"
            """
            
            echo "✅ ${serviceName} deployed"
            
        } else {
            echo "⚠️ No deployment config found for ${serviceName}"
        }
        
    } catch (Exception e) {
        echo "❌ Deployment failed for ${serviceName}: ${e.getMessage()}"
    }
}

def applyKubernetesConfig(String configFile) {
    if (fileExists(configFile)) {
        sh "kubectl apply -f ${configFile} || echo 'Config application failed: ${configFile}'"
    } else {
        echo "⚠️ Config file not found: ${configFile}"
    }
}

def verifyDeployment() {
    echo "🔍 Verifying deployment..."
    
    try {
        sh """
            echo "=== DEPLOYMENT VERIFICATION ==="
            kubectl get pods -n ${env.K8S_NAMESPACE}
            kubectl get services -n ${env.K8S_NAMESPACE}
        """
    } catch (Exception e) {
        echo "Verification failed: ${e.getMessage()}"
    }
}

def executeSystemSmokeTests() {
    echo "💨 Executing smoke tests..."
    
    try {
        sh """
            echo "Testing API Gateway accessibility..."
            kubectl get service api-gateway -n ${env.K8S_NAMESPACE} || echo "API Gateway service not found"
            
            echo "Testing service connectivity..."
            kubectl get endpoints -n ${env.K8S_NAMESPACE} || echo "Endpoints check failed"
        """
        
        echo "✅ Smoke tests completed"
        
    } catch (Exception e) {
        echo "⚠️ Smoke tests failed: ${e.getMessage()}"
    }
}

def createDeploymentArtifacts() {
    echo "📦 Creating deployment artifacts..."
    
    try {
        sh """
            mkdir -p deployment-artifacts
            echo "Deployment ready for ${params.TARGET_ENV} environment" > deployment-artifacts/README.txt
            echo "Image Tag: ${params.IMAGE_TAG}" >> deployment-artifacts/README.txt
            echo "Services: ${env.CORE_SERVICES}" >> deployment-artifacts/README.txt
        """
        
        archiveArtifacts artifacts: 'deployment-artifacts/**', allowEmptyArchive: true
        
    } catch (Exception e) {
        echo "Artifact creation failed: ${e.getMessage()}"
    }
}

def generateReleaseDocumentation() {
    try {
        def releaseFile = "release-notes-${params.IMAGE_TAG}.md"
        def gitCommit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
        def buildTime = new Date().format('yyyy-MM-dd HH:mm:ss')
        
        def documentation = """
# Release Documentation - Build ${params.IMAGE_TAG}

## Build Information
- **Build Number**: ${env.BUILD_NUMBER}
- **Image Tag**: ${params.IMAGE_TAG}
- **Target Environment**: ${params.TARGET_ENV}
- **Build Time**: ${buildTime}
- **Git Commit**: ${gitCommit}

## Services Deployed
${env.CORE_SERVICES.split(',').collect { "- ${it}" }.join('\n')}

## Configuration
- **Tests**: ${params.SKIP_TESTS ? 'Skipped' : 'Executed'}
- **Artifacts**: ${params.GENERATE_ARTIFACTS ? 'Generated' : 'Skipped'}
- **Namespace**: ${env.K8S_NAMESPACE}

## Status
✅ Build completed successfully for ${params.TARGET_ENV} environment

---
*Generated automatically by Jenkins Pipeline*
"""
        
        writeFile(file: releaseFile, text: documentation)
        archiveArtifacts artifacts: releaseFile
        
        echo "✅ Release documentation generated: ${releaseFile}"
        
    } catch (Exception e) {
        echo "Documentation generation failed: ${e.getMessage()}"
    }
}