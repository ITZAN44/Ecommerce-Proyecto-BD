# PASO 04: CI/CD con Jenkins

Este documento detalla la implementación de un pipeline de CI/CD con Jenkins para automatizar el despliegue de la aplicación ecommerce en Kubernetes (K3s).

## 📋 Tabla de Contenidos

- [Objetivo](#objetivo)
- [Arquitectura](#arquitectura)
- [Requisitos Previos](#requisitos-previos)
- [Instalación de Jenkins](#instalación-de-jenkins)
- [Configuración del Pipeline](#configuración-del-pipeline)
- [Flujo de Deployment](#flujo-de-deployment)
- [Automatización con Poll SCM](#automatización-con-poll-scm)
- [Comandos Útiles](#comandos-útiles)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Objetivo

Implementar un pipeline automatizado que:
- Construya imágenes Docker al detectar cambios en el código
- Importe las imágenes al containerd de K3s
- Ejecute rolling updates en Kubernetes
- Verifique la salud de la aplicación desplegada
- Mantenga historial de deployments

---

## 🏗️ Arquitectura

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│   GitHub     │─────▶│   Jenkins    │─────▶│     K3s      │
│  Repository  │      │   (Docker)   │      │  Kubernetes  │
└──────────────┘      └──────────────┘      └──────────────┘
                             │
                             ▼
                      ┌──────────────┐
                      │    Docker    │
                      │    Engine    │
                      └──────────────┘
```

**Flujo del Pipeline:**
1. Poll SCM detecta cambios en GitHub cada 2 minutos
2. Jenkins clona el repositorio
3. Construye imagen Docker con tag del commit
4. Exporta imagen a archivo tar
5. Importa imagen a containerd de K3s
6. Actualiza deployment en Kubernetes
7. Espera a que el rollout complete
8. Verifica health del endpoint
9. Documenta el deployment en historial

---

## ✅ Requisitos Previos

Antes de comenzar, asegúrate de tener completado:

- ✅ **Paso 01:** Aplicación Dockerizada
- ✅ **Paso 02:** Nginx Reverse Proxy configurado
- ✅ **Paso 03:** K3s Kubernetes funcionando
- ✅ Docker instalado en la VM
- ✅ Repositorio Git publicado en GitHub

---

## 🚀 Instalación de Jenkins

### 1. Crear docker-compose para Jenkins

Archivo: `docker-compose.jenkins.yml`

```yaml
version: '3.8'

services:
  jenkins:
    image: jenkins/jenkins:lts
    container_name: jenkins_server
    restart: unless-stopped
    privileged: true
    user: root
    network_mode: host
    environment:
      - KUBECONFIG=/root/.kube/config
    volumes:
      # Datos de Jenkins persistentes
      - jenkins_home:/var/jenkins_home
      # Socket de Docker para que Jenkins pueda ejecutar comandos docker
      - /var/run/docker.sock:/var/run/docker.sock
      # Binario de docker (para usar docker dentro de Jenkins)
      - /usr/bin/docker:/usr/bin/docker
      # Binarios de K3s
      - /usr/local/bin/k3s:/usr/local/bin/k3s
      - /usr/local/bin/kubectl:/usr/local/bin/kubectl
      # Configuración de K3s (modificada para usar IP del host)
      - ./jenkins/kubeconfig:/root/.kube/config
      # Socket de containerd de K3s (necesario para k3s ctr commands)
      - /run/k3s/containerd/containerd.sock:/run/k3s/containerd/containerd.sock

volumes:
  jenkins_home:
    driver: local
```

**Características clave:**
- `network_mode: host`: Permite que Jenkins acceda al K3s API en localhost:6443
- `privileged: true`: Necesario para ejecutar comandos de Docker y K3s
- `user: root`: Evita problemas de permisos con sockets
- Monta binarios de docker, k3s, kubectl desde el host

### 2. Configurar kubeconfig para Jenkins

Jenkins necesita un kubeconfig que apunte a `127.0.0.1` (porque usa network_mode: host):

```bash
# Crear directorio para archivos de Jenkins
mkdir -p jenkins

# Generar kubeconfig con localhost en lugar de IP del cluster
sed 's/127.0.0.1/127.0.0.1/g' /etc/rancher/k3s/k3s.yaml > jenkins/kubeconfig

# Verificar que quedó bien
grep "server:" jenkins/kubeconfig
# Debe mostrar: server: https://127.0.0.1:6443
```

### 3. Configurar permisos de K3s

```bash
# Permitir que Jenkins lea el kubeconfig de K3s
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
```

### 4. Configurar firewall

```bash
# Permitir puerto 8080 (Jenkins UI)
sudo ufw allow 8080/tcp

# Permitir puerto 6443 (K3s API)
sudo ufw allow 6443/tcp

# Verificar reglas
sudo ufw status
```

### 5. Levantar Jenkins

```bash
# Levantar el contenedor
docker compose -f docker-compose.jenkins.yml up -d

# Esperar ~40 segundos a que Jenkins arranque
sleep 40

# Verificar que está corriendo
docker ps | grep jenkins

# Ver logs
docker logs jenkins_server --tail 50
```

### 6. Acceder a Jenkins

1. Abre en navegador: **http://192.168.0.119:8080**

2. Obtén la contraseña inicial:
```bash
docker exec jenkins_server cat /var/jenkins_home/secrets/initialAdminPassword
```

3. Instala los **plugins sugeridos**

4. Crea un usuario administrador:
   - Username: `Clark`
   - Password: `Clark@Main!1234`
   - Email: `itzan.mateo@gmail.com`

---

## ⚙️ Configuración del Pipeline

### 1. Crear el Jenkinsfile

Archivo: `Jenkinsfile`

```groovy
pipeline {
    agent any
    
    environment {
        IMAGE_NAME = 'ecommerce-app'
        IMAGE_TAG = "${env.GIT_COMMIT.take(7)}"
        K8S_NAMESPACE = 'ecommerce'
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
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} \
                                 -t ${IMAGE_NAME}:latest \
                                 -f Dockerfile .
                """
            }
        }
        
        stage('📦 Importar imagen a K3s') {
            steps {
                echo '=== Exportando imagen Docker ==='
                sh "docker save ${IMAGE_NAME}:${IMAGE_TAG} -o /tmp/${IMAGE_NAME}-${IMAGE_TAG}.tar"
                
                echo '=== Importando a containerd de K3s ==='
                sh "k3s ctr images import /tmp/${IMAGE_NAME}-${IMAGE_TAG}.tar"
                
                echo '=== Limpiando archivo temporal ==='
                sh "rm /tmp/${IMAGE_NAME}-${IMAGE_TAG}.tar"
                
                echo '=== Verificando imagen en K3s ==='
                sh "k3s ctr images ls | grep ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
        
        stage('🚀 Deploy a K3s') {
            steps {
                echo '=== Actualizando Deployment en Kubernetes ==='
                sh """
                    kubectl set image deployment/${DEPLOYMENT_NAME} \
                        ${DEPLOYMENT_NAME}=docker.io/library/${IMAGE_NAME}:${IMAGE_TAG} \
                        -n ${K8S_NAMESPACE}
                """
                
                echo '=== Anotando el deployment con el commit ==='
                sh """
                    kubectl annotate deployment/${DEPLOYMENT_NAME} \
                        kubernetes.io/change-cause="Jenkins build #${BUILD_NUMBER} - commit ${IMAGE_TAG}" \
                        -n ${K8S_NAMESPACE} --overwrite
                """
            }
        }
        
        stage('⏳ Esperar rollout') {
            steps {
                echo '=== Esperando a que el deployment se complete ==='
                sh """
                    kubectl rollout status deployment/${DEPLOYMENT_NAME} \
                        -n ${K8S_NAMESPACE} --timeout=300s
                """
            }
        }
        
        stage('🔍 Verificar Pods') {
            steps {
                echo '=== Estado de los Pods ==='
                sh "kubectl get pods -n ${K8S_NAMESPACE} -l app=${DEPLOYMENT_NAME}"
            }
        }
        
        stage('🏥 Health check') {
            steps {
                echo '=== Probando endpoint de la aplicación ==='
                script {
                    sleep 10
                    def response = sh(
                        script: 'curl -s -o /dev/null -w "%{http_code}" http://localhost/api/analytics/dashboard',
                        returnStdout: true
                    ).trim()
                    
                    if (response == '200') {
                        echo '✅ Health check exitoso (HTTP 200)'
                    } else {
                        error "❌ Health check falló (HTTP ${response})"
                    }
                }
            }
        }
        
        stage('📜 Historial de rollouts') {
            steps {
                echo '=== Historial de deployments ==='
                sh "kubectl rollout history deployment/${DEPLOYMENT_NAME} -n ${K8S_NAMESPACE}"
            }
        }
    }
    
    post {
        always {
            echo '=== Limpiando workspace ==='
            cleanWs()
        }
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
        }
    }
}
```

### 2. Crear el job en Jenkins

1. En Jenkins, click en **Nueva Tarea**
2. Nombre: `Ecommerce-Deploy`
3. Tipo: **Pipeline**
4. Click en **OK**

**Configuración del Pipeline:**
- **General → Descripción:** "Pipeline CI/CD para ecommerce con K3s"
- **Build Triggers:**
  - ✅ Marcar **Consultar repositorio (SCM)**
  - Schedule: `H/2 * * * *` (revisa cada 2 minutos)
- **Pipeline:**
  - Definition: **Pipeline script from SCM**
  - SCM: **Git**
  - Repository URL: `https://github.com/ITZAN44/Ecommerce-Proyecto-BD.git`
  - Branch Specifier: `*/main`
  - Script Path: `Jenkinsfile`

5. Click en **Guardar**

---

## 🔄 Flujo de Deployment

### Proceso Completo

```
1. Desarrollador hace git push
          ↓
2. Poll SCM detecta cambio (máximo 2 min de espera)
          ↓
3. Jenkins clona repo
          ↓
4. Build imagen Docker (tag = commit SHA)
          ↓
5. Export imagen a /tmp/ecommerce-app-{commit}.tar
          ↓
6. Import imagen a K3s containerd
          ↓
7. kubectl set image deployment
          ↓
8. Rolling update (2 pods nuevos, terminan 2 viejos)
          ↓
9. kubectl rollout status (espera hasta 5 min)
          ↓
10. Verificar pods corriendo
          ↓
11. Health check HTTP 200
          ↓
12. ✅ Deployment exitoso
```

### Rollback Manual

Si un deployment falla y necesitas volver a la versión anterior:

```bash
# Ver historial de deployments
kubectl rollout history deployment/ecommerce-app -n ecommerce

# Volver a la revisión anterior
kubectl rollout undo deployment/ecommerce-app -n ecommerce

# Volver a una revisión específica
kubectl rollout undo deployment/ecommerce-app -n ecommerce --to-revision=1

# Verificar que el rollback completó
kubectl rollout status deployment/ecommerce-app -n ecommerce
```

---

## 🤖 Automatización con Poll SCM

### ¿Qué es Poll SCM?

**Poll SCM** hace que Jenkins revise periódicamente el repositorio de GitHub para detectar nuevos commits. Si encuentra cambios, dispara automáticamente el build.

### Configuración

**Schedule:** `H/2 * * * *`

**Significado:**
- `H/2` = cada 2 minutos
- `H` = distribución automática para evitar picos de carga
- Los 4 asteriscos = todo el tiempo (todas las horas, días, meses)

**Alternativas:**
- `H/5 * * * *` = cada 5 minutos
- `H/10 * * * *` = cada 10 minutos
- `H/15 * * * *` = cada 15 minutos

### Comportamiento

- **Sin cambios:** Jenkins hace un `git fetch` rápido y no ejecuta el pipeline
- **Con nuevo commit:** Jenkins detecta el cambio y dispara el build automáticamente

### Limitaciones

**Poll SCM** es ideal para desarrollo local porque:
- ✅ No requiere IP pública
- ✅ Funciona detrás de NAT/routers
- ✅ Simple de configurar
- ❌ Tiene un retraso de hasta 2 minutos
- ❌ Hace polling constante (más carga que webhooks)

**Para producción** se recomienda usar GitHub Webhooks (requiere IP pública o ngrok).

---

## 📝 Comandos Útiles

### Jenkins

```bash
# Levantar Jenkins
docker compose -f docker-compose.jenkins.yml up -d

# Detener Jenkins
docker compose -f docker-compose.jenkins.yml down

# Ver logs de Jenkins
docker logs jenkins_server -f

# Reiniciar Jenkins
docker compose -f docker-compose.jenkins.yml restart

# Obtener password inicial
docker exec jenkins_server cat /var/jenkins_home/secrets/initialAdminPassword

# Acceso al contenedor
docker exec -it jenkins_server bash
```

### Verificar Pipeline

```bash
# Ver estado del deployment
kubectl get deployments -n ecommerce

# Ver pods en ejecución
kubectl get pods -n ecommerce

# Ver historial de rollouts
kubectl rollout history deployment/ecommerce-app -n ecommerce

# Ver logs de un pod
kubectl logs -f <pod-name> -n ecommerce

# Verificar imágenes en K3s
sudo k3s ctr images ls | grep ecommerce-app
```

### Debugging

```bash
# Verificar que Jenkins puede usar docker
docker exec jenkins_server docker ps

# Verificar que Jenkins puede usar kubectl
docker exec jenkins_server kubectl get nodes

# Verificar que Jenkins puede usar k3s ctr
docker exec jenkins_server k3s ctr version

# Ver configuración de kubeconfig
cat jenkins/kubeconfig
```

---

## 🔧 Troubleshooting

### Problema: Jenkins no puede conectar a K3s API

**Error:**
```
Unable to connect to the server: dial tcp 127.0.0.1:6443: connect: connection refused
```

**Solución:**
1. Verificar que usas `network_mode: host` en docker-compose
2. Verificar que el kubeconfig apunta a `127.0.0.1:6443`
3. Verificar que K3s está corriendo: `sudo systemctl status k3s`

### Problema: Permission denied en socket de Docker

**Error:**
```
permission denied while trying to connect to the Docker daemon socket
```

**Solución:**
```bash
# Dar permisos al socket de Docker
sudo chmod 666 /var/run/docker.sock
```

### Problema: k3s ctr command not found

**Error:**
```
k3s: not found
```

**Solución:**
Verificar que el binario está montado en docker-compose.jenkins.yml:
```yaml
volumes:
  - /usr/local/bin/k3s:/usr/local/bin/k3s
```

### Problema: Images not importing to K3s

**Error:**
```
ctr: cannot access socket /run/k3s/containerd/containerd.sock
```

**Solución:**
Verificar que el socket de containerd está montado:
```yaml
volumes:
  - /run/k3s/containerd/containerd.sock:/run/k3s/containerd/containerd.sock
```

### Problema: Build falla pero no muestra error claro

**Solución:**
1. Ve al build en Jenkins
2. Click en **Console Output**
3. Busca el primer error (líneas en rojo)
4. Ejecuta el comando manualmente en la VM para debug:
```bash
# Entrar al contenedor Jenkins
docker exec -it jenkins_server bash

# Ejecutar comandos uno por uno
docker --version
kubectl get nodes
k3s ctr version
```

---

## 📊 Resultados Esperados

### Build Exitoso

Al ejecutar un build manualmente o detectar un cambio, deberías ver:

```
✅ Stage 1: Verificar entorno (5s)
✅ Stage 2: Checkout código (10s)
✅ Stage 3: Build imagen Docker (3-5 min)
✅ Stage 4: Importar imagen a K3s (30-45s)
✅ Stage 5: Deploy a K3s (5s)
✅ Stage 6: Esperar rollout (30-60s)
✅ Stage 7: Verificar Pods (2s)
✅ Stage 8: Health check (12s)
✅ Stage 9: Historial de rollouts (2s)

Total: ~5-7 minutos
```

### Verificación Final

1. **Jenkins UI:** http://192.168.0.119:8080
   - Build #X: SUCCESS ✅

2. **Aplicación:** http://192.168.0.119/
   - Frontend carga correctamente

3. **API:** http://192.168.0.119/api/analytics/dashboard
   - Devuelve JSON con datos

4. **Kubernetes:**
```bash
kubectl get pods -n ecommerce
# NAME                             READY   STATUS    RESTARTS   AGE
# ecommerce-app-xxxxxx-yyyyy       1/1     Running   0          2m
# ecommerce-app-xxxxxx-zzzzz       1/1     Running   0          2m
```

---

## 🎯 Próximos Pasos

Con el CI/CD funcionando, puedes:

1. **Optimizar el Pipeline:**
   - Agregar tests automatizados
   - Implementar análisis de código estático
   - Agregar notificaciones (Slack, email)

2. **Mejorar Seguridad:**
   - Escaneo de vulnerabilidades en imágenes
   - Firma de imágenes Docker
   - Secrets management con Vault

3. **Monitoreo:**
   - Integrar Prometheus + Grafana
   - Agregar alertas de fallos de deployment
   - Logs centralizados con ELK/Loki

4. **Ambientes Múltiples:**
   - Pipeline con stages: dev → staging → production
   - Aprobaciones manuales para producción
   - Feature flags

---

## � Estado Post-Reboot (23/12/2025)

### Recuperación y Sincronización de Jenkins

**Contexto:** Después del reinicio de la VM (23/12/2025), Jenkins requirió sincronización con systemd para garantizar auto-start correcto.

**Problema inicial:**
- `jenkins-docker.service` mostraba estado "failed"
- Contenedores Jenkins ya estaban corriendo (iniciados manualmente)
- Conflicto: systemd intentaba iniciar contenedores ya existentes

**Solución aplicada:**
```bash
# 1. Detener contenedores manuales
docker compose -f docker-compose.jenkins.yml down

# 2. Iniciar vía systemd (toma control del lifecycle)
sudo systemctl start jenkins-docker.service

# 3. Verificar estado
sudo systemctl status jenkins-docker.service
# Estado: active (exited) - correcto para servicio oneshot

# 4. Verificar contenedores
docker ps
# jenkins_server (jenkins/jenkins:lts) - Running
# jenkins_docker (docker:dind) - Running

# 5. Test de acceso
curl -I http://localhost:8080
# HTTP/1.1 403 Forbidden (normal, requiere autenticación)
```

**Configuración systemd actual:**
```ini
# /etc/systemd/system/jenkins-docker.service
[Unit]
Description=Jenkins Docker Container
After=docker.service k3s.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/clark/Ecommerce-Proyecto-BD
ExecStart=/usr/bin/docker compose -f docker-compose.jenkins.yml up -d
ExecStop=/usr/bin/docker compose -f docker-compose.jenkins.yml down

[Install]
WantedBy=multi-user.target
```

**Estado actual:**
- ✅ Jenkins accessible en http://192.168.0.119:8080
- ✅ Pipeline "ecommerce-k8s-deploy" funcional
- ✅ Auto-start configurado (systemd enabled)
- ✅ Contenedores gestionados por systemd
- ✅ kubeconfig regenerado para acceso a K3s

**Últimos builds:**
- Build #9 (22/12/2025): ✅ SUCCESS - Deployment completo K3s
- Post-reboot: Jenkins operacional sin re-builds necesarios

**Verificación de conectividad K3s:**
```bash
# Desde contenedor Jenkins
docker exec jenkins_server kubectl --kubeconfig=/var/jenkins_home/kubeconfig get pods -n ecommerce
# STATUS: All Running
```

---

## 📚 Referencias

- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [K3s Documentation](https://docs.k3s.io/)
- [Docker Build Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [systemd Service Units](https://www.freedesktop.org/software/systemd/man/systemd.service.html)

---

**Documentación creada:** Diciembre 22, 2025  
**Última actualización:** Diciembre 23, 2025  
**Autor:** Clark / Itzan Valdivia

