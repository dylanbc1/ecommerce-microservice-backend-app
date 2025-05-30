pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'stage', 'master'],
            description: 'Environment to deploy'
        )
        string(
            name: 'BUILD_TAG',
            defaultValue: "${env.BUILD_ID}",
            description: 'Docker image tag'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip tests for emergency deployment'
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "✅ Source code checked out"
            }
        }
        
        stage('Build Services') {
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
        
        stage('Deploy to Dev') {
            when { params.ENVIRONMENT == 'dev' }
            steps {
                script {
                    sh "kubectl apply -f k8s/namespace.yaml"
                    ['api-gateway', 'proxy-client', 'user-service', 
                     'product-service', 'order-service', 'payment-service'].each { service ->
                        deployService(service, params.BUILD_TAG)
                    }
                }
            }
        }
    }
}

def buildService(serviceName) {
    dir(serviceName) {
        sh "./mvnw clean package -DskipTests"
        sh "docker build -t ${serviceName}:${params.BUILD_TAG} ."
    }
}

def deployService(serviceName, tag) {
    sh """
        sed 's/{{BUILD_TAG}}/${tag}/g' k8s/${serviceName}/deployment.yaml | kubectl apply -f -
        kubectl apply -f k8s/${serviceName}/service.yaml
    """
}