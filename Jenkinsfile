pipeline {
    agent any
    
    environment {
        // Nombre de la imagen Docker
        IMAGE_NAME = 'ecommerce-app'
        // Tag con hash del commit
        IMAGE_TAG = "${env.GIT_COMMIT.take(7)}"
        // Namespace de Kubernetes
        K8S_NAMESPACE = 'ecommerce'
        // Nombre del deployment
        DEPLOYMENT_NAME = 'ecommerce-app'
    }
    
    stages {
        stage('🔍 Verificar entorno') {
            steps {
                echo '=== Verificando herramientas ==='
                sh 'docker --version'
                sh 'kubectl version --client'
                sh 'git --version'
            }
        }
        
        stage('📥 Checkout código') {
            steps {
                echo '=== Clonando repositorio ==='
                checkout scm
            }
        }
        
        stage('🐳 Build imagen Docker') {
            steps {
                echo "=== Construyendo imagen ${IMAGE_NAME}:${IMAGE_TAG} ==="
                sh """
                    docker build \
                        -t ${IMAGE_NAME}:${IMAGE_TAG} \
                        -t ${IMAGE_NAME}:latest \
                        -f Dockerfile .
                """
            }
        }
        
        stage('📦 Importar imagen a K3s') {
            steps {
                echo '=== Exportando imagen Docker ==='
                sh """
                    docker save ${IMAGE_NAME}:${IMAGE_TAG} -o /tmp/${IMAGE_NAME}-${IMAGE_TAG}.tar
                """
                
                echo '=== Importando a containerd de K3s ==='
                sh """
                    sudo k3s ctr images import /tmp/${IMAGE_NAME}-${IMAGE_TAG}.tar
                """
                
                echo '=== Limpiando archivo temporal ==='
                sh """
                    rm /tmp/${IMAGE_NAME}-${IMAGE_TAG}.tar
                """
                
                echo '=== Verificando imagen en K3s ==='
                sh """
                    sudo k3s ctr images ls | grep ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
        
        stage('🚀 Deploy a K3s') {
            steps {
                echo '=== Actualizando Deployment en Kubernetes ==='
                sh """
                    sudo kubectl set image deployment/${DEPLOYMENT_NAME} \
                        ${DEPLOYMENT_NAME}=docker.io/library/${IMAGE_NAME}:${IMAGE_TAG} \
                        -n ${K8S_NAMESPACE}
                """
                
                echo '=== Anotando el deployment con el commit ==='
                sh """
                    sudo kubectl annotate deployment/${DEPLOYMENT_NAME} \
                        kubernetes.io/change-cause="Jenkins build #${BUILD_NUMBER} - commit ${IMAGE_TAG}" \
                        -n ${K8S_NAMESPACE} --overwrite
                """
            }
        }
        
        stage('⏳ Esperar rollout') {
            steps {
                echo '=== Esperando a que el deployment se complete ==='
                sh """
                    sudo kubectl rollout status deployment/${DEPLOYMENT_NAME} \
                        -n ${K8S_NAMESPACE} \
                        --timeout=300s
                """
            }
        }
        
        stage('🔍 Verificar Pods') {
            steps {
                echo '=== Estado de los Pods ==='
                sh """
                    sudo kubectl get pods -n ${K8S_NAMESPACE} -l app=${DEPLOYMENT_NAME}
                """
            }
        }
        
        stage('🏥 Health check') {
            steps {
                echo '=== Probando endpoint de la aplicación ==='
                script {
                    sleep(10) // Esperar a que los Pods estén completamente listos
                    
                    def response = sh(
                        script: 'curl -s -o /dev/null -w "%{http_code}" http://localhost/api/analytics/dashboard',
                        returnStdout: true
                    ).trim()
                    
                    if (response == '200') {
                        echo "✅ Health check exitoso (HTTP ${response})"
                    } else {
                        error "❌ Health check falló (HTTP ${response})"
                    }
                }
            }
        }
        
        stage('📜 Historial de rollouts') {
            steps {
                echo '=== Historial de deployments ==='
                sh """
                    sudo kubectl rollout history deployment/${DEPLOYMENT_NAME} -n ${K8S_NAMESPACE}
                """
            }
        }
    }
    
    post {
        success {
            echo '======================================'
            echo '✅ DEPLOYMENT COMPLETADO CON ÉXITO'
            echo "Versión: ${IMAGE_TAG}"
            echo "Build: #${BUILD_NUMBER}"
            echo '======================================'
        }
        failure {
            echo '======================================'
            echo '❌ DEPLOYMENT FALLÓ'
            echo "Build: #${BUILD_NUMBER}"
            echo '======================================'
            
            // Opcional: Rollback automático en caso de fallo
            // sh "sudo kubectl rollout undo deployment/${DEPLOYMENT_NAME} -n ${K8S_NAMESPACE}"
        }
        always {
            echo '=== Limpiando workspace ==='
            cleanWs()
        }
    }
}
