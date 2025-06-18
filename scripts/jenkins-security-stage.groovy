stage('Enhanced Security & Change Management') {
    parallel {
        stage('Security Scanning') {
            steps {
                script {
                    echo "🔒 === ENHANCED SECURITY SCANNING ==="
                    
                    // Ejecutar script de seguridad
                    sh '''
                        chmod +x scripts/security-scan.sh
                        ./scripts/security-scan.sh
                    '''
                    
                    // Archivar reportes de seguridad
                    archiveArtifacts artifacts: 'security/reports/**', allowEmptyArchive: true
                }
            }
        }
        
        stage('Change Management') {
            steps {
                script {
                    echo "📋 === CHANGE MANAGEMENT ==="
                    
                    // Generar release notes
                    sh """
                        chmod +x scripts/generate-release-notes.sh
                        ./scripts/generate-release-notes.sh ${params.IMAGE_TAG} ${params.TARGET_ENV} ${env.BUILD_NUMBER}
                    """
                    
                    // Archivar release notes
                    archiveArtifacts artifacts: 'change-management/releases/**', allowEmptyArchive: true
                }
            }
        }
    }
}
