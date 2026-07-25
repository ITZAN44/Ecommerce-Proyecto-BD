# 📊 PASO 6: Monitoreo con Prometheus + Grafana en K3s

**Fecha:** 24-25 de Diciembre, 2025  
**Proyecto:** Ecommerce - Sistema de Monitoreo  
**Objetivo:** Implementar stack de monitoreo production-grade con Prometheus + Grafana en K3s  
**Estado:** ✅ COMPLETADO CON ÉXITO

---

## 📋 TABLA DE CONTENIDOS

1. [Contexto del Proyecto](#contexto)
2. [Arquitectura de Monitoreo](#arquitectura)
3. [Instalación de Helm](#instalacion-helm)
4. [Despliegue de kube-prometheus-stack](#despliegue)
5. [Configuración del Stack](#configuracion)
6. [Problemas Encontrados y Soluciones](#troubleshooting)
7. [Verificación y Testing](#verificacion)
8. [Guía de Dashboards](#dashboards)
9. [Comandos de Administración](#comandos)
10. [Próximos Pasos](#proximos-pasos)

---

## 🎯 CONTEXTO DEL PROYECTO {#contexto}

### Objetivo
Implementar monitoreo completo del cluster K3s para:
- Visualizar métricas de CPU, RAM, red de todos los pods
- Monitorear salud del cluster Kubernetes
- Detectar problemas de recursos antes de que causen caídas
- Tener dashboards en tiempo real accesibles desde navegador

### Infraestructura Existente
- **VM Ubuntu 24.04:** IP 192.168.0.119
- **K3s v1.33.6+k3s1:** Cluster con 3 namespaces (ecommerce, kube-system, monitoring)
- **RAM:** 4GB (actualizada desde 3GB durante este paso)
- **Aplicaciones corriendo:**
  - Ecommerce app (2 pods)
  - PostgreSQL (1 pod)
  - Traefik Ingress Controller

### Componentes a Instalar
- **Helm v3:** Gestor de paquetes para Kubernetes
- **Prometheus:** Sistema de recolección y almacenamiento de métricas
- **Grafana:** Plataforma de visualización con dashboards
- **AlertManager:** Sistema de gestión de alertas
- **Node Exporter:** Exportador de métricas del sistema operativo
- **Kube State Metrics:** Exportador de métricas de objetos Kubernetes
- **Prometheus Operator:** Automatización de configuración de Prometheus

---

## 🏗️ ARQUITECTURA DE MONITOREO {#arquitectura}

### Diagrama de Componentes

```
┌──────────────────────────────────────────────────────────────┐
│                    WINDOWS (Cliente)                         │
│  - Navegador accediendo a Grafana                            │
│    http://192.168.0.119:30080                                │
└─────────────────────────┬────────────────────────────────────┘
                          │ HTTP
                          ▼
┌──────────────────────────────────────────────────────────────┐
│         VM UBUNTU 24.04 - K3s Cluster (4GB RAM)              │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │           Namespace: monitoring                        │  │
│  │                                                         │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │  Grafana (NodePort 30080)                       │  │  │
│  │  │  - UI de visualización                          │  │  │
│  │  │  - Dashboards preconfigurados                   │  │  │
│  │  │  - Queries a Prometheus                         │  │  │
│  │  └──────────────────┬──────────────────────────────┘  │  │
│  │                     │ HTTP :9090                       │  │
│  │  ┌──────────────────▼──────────────────────────────┐  │  │
│  │  │  Prometheus Server                              │  │  │
│  │  │  - Scraping cada 30s                            │  │  │
│  │  │  - Retención: 15 días                           │  │  │
│  │  │  - Storage: 10Gi PersistentVolume               │  │  │
│  │  └───┬───────────┬───────────┬──────────┬──────────┘  │  │
│  │      │           │           │          │              │  │
│  │      │ Scrape    │ Scrape    │ Scrape   │ Scrape       │  │
│  │      ▼           ▼           ▼          ▼              │  │
│  │  ┌───────┐  ┌───────┐  ┌─────────┐ ┌──────────┐      │  │
│  │  │ Node  │  │ Kube  │  │ Alert   │ │Prometheus│      │  │
│  │  │Export.│  │ State │  │ Manager │ │ Operator │      │  │
│  │  └───────┘  └───────┘  └─────────┘ └──────────┘      │  │
│  │      │           │                                     │  │
│  │      │ Metrics   │ Metrics                            │  │
│  └──────┼───────────┼─────────────────────────────────────┘  │
│         │           │                                         │
│         ▼           ▼                                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Kubelet (todos los pods)                            │   │
│  │  - Métricas de CPU, RAM, red                         │   │
│  │  - Métricas de contenedores                          │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Sistema Operativo (Ubuntu)                          │   │
│  │  - Métricas de CPU, RAM, disco, red                  │   │
│  └──────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────┘
```

### Flujo de Datos

1. **Recolección:**
   - Node Exporter recolecta métricas del SO cada 30s
   - Kube State Metrics expone estado de objetos K8s
   - Kubelet expone métricas de pods y contenedores
   - AlertManager recibe alertas de Prometheus

2. **Scraping:**
   - Prometheus hace scraping de todos los endpoints cada 30s
   - Descubre automáticamente targets vía ServiceMonitors
   - Almacena datos en PersistentVolume

3. **Visualización:**
   - Grafana consulta datos de Prometheus vía HTTP
   - Renderiza dashboards en tiempo real
   - Usuario accede vía navegador en puerto 30080

---

## ⚙️ INSTALACIÓN DE HELM {#instalacion-helm}

### ¿Qué es Helm?
Helm es el "gestor de paquetes" de Kubernetes, como `apt` para Ubuntu o `npm` para Node.js.
Permite instalar aplicaciones complejas (charts) con un solo comando.

### Paso 1: Descargar e Instalar Helm

```bash
# En VM Ubuntu
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Salida esperada:**
```
Downloading https://get.helm.sh/helm-v3.19.4-linux-amd64.tar.gz
Verifying checksum... Done.
Preparing to install helm into /usr/local/bin
helm installed into /usr/local/bin/helm
```

### Paso 2: Verificar Instalación

```bash
helm version
```

**Salida:**
```
version.BuildInfo{Version:"v3.19.4", GitCommit:"...", GoVersion:"go1.23.6"}
```

---

## 🚀 DESPLIEGUE DE KUBE-PROMETHEUS-STACK {#despliegue}

### FASE 1: Preparación

#### 1.1. Arreglar Permisos de kubectl

```bash
# K3s crea kubeconfig con permisos 600 (solo root)
sudo chmod 644 /etc/rancher/k3s/k3s.yaml

# Verificar que funciona sin sudo
kubectl get nodes
```

#### 1.2. Agregar Repositorio de Helm

```bash
# Agregar repo prometheus-community
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Actualizar índice de charts
helm repo update
```

**Salida:**
```
"prometheus-community" has been added to your repositories
Update Complete. ⎈Happy Helming!⎈
```

#### 1.3. Crear Namespace

```bash
kubectl create namespace monitoring
```

---

### FASE 2: Crear Archivo de Configuración

#### 2.1. Crear `k8s/prometheus-values.yaml`

**Ubicación:** `./k8s/prometheus-values.yaml`

**Contenido completo:**

```yaml
# ============================================
# GRAFANA CONFIGURATION
# ============================================
grafana:
  # Configuración de acceso
  adminPassword: "admin123"
  
  # Exponer vía NodePort para acceso externo
  service:
    type: NodePort
    nodePort: 30080  # Puerto fijo para acceder desde Windows
  
  # Almacenamiento persistente para dashboards
  persistence:
    enabled: true
    size: 5Gi
    storageClassName: local-path  # Storage provider de K3s
  
  # Límites de recursos para evitar OOMKilled
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi

# ============================================
# PROMETHEUS CONFIGURATION
# ============================================
prometheus:
  prometheusSpec:
    # Retención de datos (15 días)
    retention: 15d
    
    # Almacenamiento persistente
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: local-path
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi
    
    # Límites de recursos
    resources:
      limits:
        cpu: 1000m
        memory: 2Gi
      requests:
        cpu: 500m
        memory: 1Gi
    
    # Scraping configuration
    scrapeInterval: 30s
    evaluationInterval: 30s
    
    # ⚠️ IMPORTANTE: Permitir descubrir ServiceMonitors en todos los namespaces
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false

# ============================================
# ALERTMANAGER CONFIGURATION
# ============================================
alertmanager:
  alertmanagerSpec:
    # Almacenamiento para alertas
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: local-path
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 5Gi
```

#### 2.2. Commitear a GitHub

```bash
# En Windows PowerShell
cd C:\Users\User\Documents\Universidad\BS2\BD_01\Proyecto-BS2\Ecommers-Proyecto

git add k8s/prometheus-values.yaml
git commit -m "feat: Add Prometheus monitoring configuration for K3s"
git push origin main
```

---

### FASE 3: Instalación del Chart

```bash
# En VM Ubuntu
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values k8s/prometheus-values.yaml \
  --timeout 10m
```

**Tiempo de instalación:** ~5-10 minutos (descarga imágenes Docker)

**Salida esperada:**
```
NAME: prometheus
LAST DEPLOYED: Wed Dec 24 20:15:32 2025
NAMESPACE: monitoring
STATUS: deployed
REVISION: 1
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace monitoring get pods -l "release=prometheus"
```

---

### FASE 4: Verificar Instalación

```bash
# Ver todos los pods del monitoring
kubectl get pods -n monitoring
```

**Salida esperada (después de 2-3 minutos):**
```
NAME                                                     READY   STATUS    RESTARTS   AGE
alertmanager-prometheus-kube-prometheus-alertmanager-0   2/2     Running   0          2m
prometheus-grafana-xxxxx                                 3/3     Running   0          2m
prometheus-kube-prometheus-operator-xxxxx                1/1     Running   0          2m
prometheus-kube-state-metrics-xxxxx                      1/1     Running   0          2m
prometheus-prometheus-kube-prometheus-prometheus-0       2/2     Running   0          2m
prometheus-prometheus-node-exporter-xxxxx                1/1     Running   0          2m
```

**Componentes instalados:**
- ✅ **Grafana:** 3 contenedores (grafana, sidecar-dashboards, sidecar-datasources)
- ✅ **Prometheus:** 2 contenedores (prometheus, config-reloader)
- ✅ **AlertManager:** 2 contenedores (alertmanager, config-reloader)
- ✅ **Operator:** 1 contenedor (gestiona configuración)
- ✅ **Kube State Metrics:** 1 contenedor (métricas de K8s)
- ✅ **Node Exporter:** 1 contenedor (métricas del SO)

---

## 🔧 PROBLEMAS ENCONTRADOS Y SOLUCIONES {#troubleshooting}

### Problema 1: Dashboards Muestran "No Data"

**Error observado:**
- Grafana accesible en http://192.168.0.119:30080 ✅
- Login exitoso con admin/admin123 ✅
- Dashboards cargan pero paneles vacíos ❌
- Mensaje: "No data"

**Diagnóstico paso a paso:**

```bash
# 1. Verificar que Prometheus está corriendo
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus

# 2. Revisar logs de Prometheus
kubectl logs -n monitoring prometheus-prometheus-kube-prometheus-prometheus-0 -c prometheus

# 3. Verificar targets de scraping
kubectl exec -n monitoring prometheus-prometheus-kube-prometheus-prometheus-0 -c prometheus -- \
  wget -qO- localhost:9090/api/v1/targets | grep activeTargets
```

**Resultado:** 0 targets activos ❌

**Causa raíz:**
Helm configura por defecto un selector restrictivo:
```yaml
serviceMonitorSelector:
  matchLabels:
    release: prometheus  # Solo ServiceMonitors con esta label
```

Esto filtra TODOS los ServiceMonitors que no tienen esa label exacta.

**Solución aplicada:**

```bash
# Upgrade del chart para remover el filtro
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --reuse-values \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false
```

**Verificación de la solución:**

```bash
# Ver configuración actualizada
kubectl get prometheuses.monitoring.coreos.com -n monitoring prometheus-kube-prometheus-prometheus -o yaml | grep -A2 serviceMonitorSelector
```

**Salida correcta:**
```yaml
serviceMonitorSelector: {}  # Acepta TODOS los ServiceMonitors
serviceMonitorNamespaceSelector: {}  # En TODOS los namespaces
```

**Resultado:** REVISION 2 del chart, configuración corregida ✅

---

### Problema 2: Cero Targets Después del Upgrade

**Error observado:**
Después del helm upgrade, seguía mostrando 0 targets.

**Causa:**
ServiceMonitor discovery tiene un delay de 5-10 minutos.

**Verificación correcta:**

```bash
# Port-forward para acceder a Prometheus UI directamente
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &

# Esperar 2 segundos
sleep 2

# Consultar targets vía API
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length'
```

**Salida:** `13` ✅

**Targets descubiertos (13 en total):**
1. `prometheus/prometheus-grafana/0` - Grafana metrics
2. `prometheus/prometheus-kube-prometheus-alertmanager/0` - AlertManager metrics
3. `prometheus/prometheus-kube-prometheus-alertmanager/1` - AlertManager cluster
4. `prometheus/prometheus-kube-prometheus-apiserver/0` - Kubernetes API server
5. `prometheus/prometheus-kube-prometheus-coredns/0` - CoreDNS
6. `prometheus/prometheus-kube-prometheus-kube-controller-manager/0`
7. `prometheus/prometheus-kube-prometheus-kube-etcd/0`
8. `prometheus/prometheus-kube-prometheus-kube-proxy/0`
9. `prometheus/prometheus-kube-prometheus-kube-scheduler/0`
10. `prometheus/prometheus-kube-prometheus-kubelet/0` - Kubelet metrics
11. `prometheus/prometheus-kube-prometheus-kubelet/1` - cAdvisor
12. `prometheus/prometheus-kube-prometheus-kubelet/2` - Probes
13. `prometheus/prometheus-kube-state-metrics/0` - Kube state

**Verificar que todos están "up":**

```bash
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'
```

**Salida:** (vacío) = todos saludables ✅

---

### Problema 3: Grafana Timeout (ERR_CONNECTION_TIMED_OUT)

**Error observado:**
- http://192.168.0.119:30080 dejó de responder
- Browser: "ERR_CONNECTION_TIMED_OUT"

**Diagnóstico:**

```bash
# Ver estado de pods
kubectl get pods -n monitoring

# Ver detalles del pod de Grafana
kubectl describe pod -n monitoring prometheus-grafana-xxxxx
```

**Salida:**
```
NAME                          READY   STATUS    RESTARTS   AGE
prometheus-grafana-xxxxx      2/3     Running   0          30m

Events:
  Readiness probe failed: Get http://10.42.0.45:3000/api/health: 
    context deadline exceeded (Client.Timeout exceeded)
```

**Causa raíz: RAM EXHAUSTION**

```bash
free -h
```

**Salida:**
```
              total        used        free      shared  buff/cache   available
Mem:          3.1Gi       2.3Gi       109Mi       120Mi       698Mi       787Mi
Swap:         975Mi       210Mi       765Mi
```

**🚨 CRÍTICO:** Solo **109Mi libres** de RAM, usando SWAP intensamente.

**Verificación de recursos:**
```bash
kubectl top nodes
```

**Síntomas adicionales:**
- Node Exporter: `CrashLoopBackOff`
- Prometheus Operator: 12 restarts
- Nuevos pods quedan en `Pending` (no hay RAM)

**Solución aplicada:**

**PASO 1:** Apagar VM
```bash
sudo poweroff
```

**PASO 2:** Aumentar RAM en VirtualBox
- Sistema → Memoria Base: 3072 MB → **4096 MB**

**PASO 3:** Reiniciar VM

**PASO 4:** Verificar mejora
```bash
free -h
```

**Resultado:**
```
              total        used        free      shared  buff/cache   available
Mem:          3.8Gi       1.3Gi       1.7Gi        80Mi       768Mi       2.5Gi
```

**Mejora:** de **787Mi available** → **2.5Gi available** (+218%) ✅

---

### Problema 4: K3s No Inicia Después del Reboot

**Error observado:**
```bash
kubectl get pods -n monitoring
# The connection to the server 127.0.0.1:6443 was refused
```

**Diagnóstico:**

```bash
sudo systemctl status k3s
```

**Salida:**
```
● k3s.service - Lightweight Kubernetes
     Active: activating (start) since Wed 2025-12-24 23:35:02 -04; 7s ago
...
k3s.service: Failed with result 'protocol'.
```

**Ver logs detallados:**
```bash
sudo journalctl -xeu k3s.service --no-pager -n 100
```

**Error clave encontrado:**
```
msg="Shutdown request received: containerd exited: exit status 1"
```

**Ver log de containerd:**
```bash
sudo cat /var/lib/rancher/k3s/agent/containerd/containerd.log | tail -n 100
```

**ERROR RAÍZ:**
```
containerd: failed to get listener for main endpoint: 
  failed to create unix socket on /run/k3s/containerd/containerd.sock: 
  is a directory
```

**Causa:**
Después del reboot, el directorio `/run/k3s/containerd/` quedó corrupto.
Containerd esperaba crear un archivo socket, pero encontró un directorio.

**Solución completa:**

```bash
# 1. Detener K3s completamente
sudo systemctl stop k3s

# 2. Eliminar directorios corruptos de runtime
sudo rm -rf /run/k3s/containerd/
sudo rm -rf /run/k3s/

# 3. Reiniciar K3s (recreará todo limpio)
sudo systemctl start k3s

# 4. Esperar 30 segundos para inicialización
sleep 30

# 5. Arreglar permisos de kubectl
sudo chmod 644 /etc/rancher/k3s/k3s.yaml

# 6. Verificar que arrancó
sudo systemctl status k3s
```

**Resultado:**
```
● k3s.service - Lightweight Kubernetes
     Active: active (running) since Wed 2025-12-24 23:43:29 -04; 1min 14s ago
     Memory: 717.0M (peak: 756.2M swap: 74.8M swap peak: 88.8M)
```

**Verificar pods recuperados:**
```bash
kubectl get pods -n monitoring
```

**Salida:**
```
NAME                                                     READY   STATUS    RESTARTS       AGE
alertmanager-prometheus-kube-prometheus-alertmanager-0   2/2     Running   4 (89s ago)    98m
prometheus-grafana-f7966c597-rwcsb                       3/3     Running   6 (89s ago)    30m
prometheus-kube-prometheus-operator-77f7f577cd-lnfsv     1/1     Running   14 (14m ago)   99m
prometheus-kube-state-metrics-79d5566f5d-4bc9p           1/1     Running   12 (89s ago)   99m
prometheus-prometheus-kube-prometheus-prometheus-0       2/2     Running   7 (89s ago)    98m
prometheus-prometheus-node-exporter-w7k8l                1/1     Running   11 (89s ago)   99m
```

**✅ TODOS los pods Running con datos persistentes intactos (PersistentVolumes preservados)**

---

### Problema 5: Configuración Permanente Post-Reboot (SOLUCIONADO ✅)

**Objetivo:**
Evitar tener que ejecutar comandos manuales después de cada reboot de la VM.

**Problemas recurrentes:**
1. K3s no arrancaba automáticamente en boot
2. kubectl requería `sudo chmod 644` en cada reboot

**Solución permanente aplicada:**

```bash
# 1. Habilitar auto-start de K3s en boot
sudo systemctl enable k3s

# 2. Verificar que quedó habilitado
sudo systemctl is-enabled k3s
# Salida: enabled ✅

# 3. Crear directorio para kubeconfig de usuario
mkdir -p ~/.kube

# 4. Copiar kubeconfig a directorio de usuario
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

# 5. Cambiar ownership al usuario clark
sudo chown clark:clark ~/.kube/config

# 6. Configurar variable de entorno permanentemente
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc

# 7. Aplicar cambios inmediatamente
source ~/.bashrc

# 8. Verificar que kubectl funciona sin sudo
kubectl get nodes
```

**Salida de verificación:**
```bash
clark@clark-VirtualBox:~$ kubectl get nodes
NAME               STATUS   ROLES                  AGE    VERSION
clark-virtualbox   Ready    control-plane,master   6d8h   v1.33.6+k3s1
```

**Resultado:**
✅ **K3s se inicia automáticamente** en cada boot  
✅ **kubectl funciona sin sudo** permanentemente  
✅ **No se requieren comandos manuales** después de reboots  

**Beneficios:**
- La VM puede reiniciarse sin intervención manual
- Todo el stack de monitoreo arranca automáticamente
- Grafana accesible en http://192.168.0.119:30080 después del boot
- PersistentVolumes preservan datos entre reinicios

---

## ✅ VERIFICACIÓN Y TESTING {#verificacion}

### Test 1: Verificar Servicio de Grafana

```bash
kubectl get svc -n monitoring prometheus-grafana
```

**Salida esperada:**
```
NAME                 TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
prometheus-grafana   NodePort   10.43.241.170   <none>        80:30080/TCP   101m
```

✅ NodePort 30080 activo

---

### Test 2: Verificar Targets de Prometheus

```bash
# Port-forward temporal
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &

# Consultar número de targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length'

# Matar port-forward
pkill -f "port-forward.*prometheus"
```

**Salida esperada:** `13`

✅ 13 targets scraping correctamente

---

### Test 3: Verificar Métricas en Prometheus

```bash
# Port-forward
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &

# Query para ver todos los targets up
curl -s http://localhost:9090/api/v1/query?query=up | jq '.data.result | length'
# Resultado: 13

# Query para métricas de CPU
curl -s http://localhost:9090/api/v1/query?query=node_cpu_seconds_total | jq '.data.result | length'
# Resultado: 24 (4 cores × 6 modos de CPU)

# Query para métricas de pods
curl -s http://localhost:9090/api/v1/query?query=kube_pod_info | jq '.data.result | length'
# Resultado: 16 (todos los pods del cluster)

# Cleanup
pkill -f "port-forward.*prometheus"
```

✅ Métricas fluyendo correctamente

---

### Test 4: Acceso a Grafana desde Windows

**URL:** http://192.168.0.119:30080

**Credenciales:**
- **Usuario:** `admin`
- **Password:** `admin123`

**Verificaciones visuales:**
1. ✅ Login exitoso
2. ✅ Dashboards disponibles en ☰ → Dashboards → Browse
3. ✅ Al menos 20+ dashboards preconfigurados
4. ✅ Dashboard "Kubernetes / Compute Resources / Cluster" muestra datos

---

### Test 5: Verificar Datos en Dashboard

**Navegar a:** Dashboards → Kubernetes / Compute Resources / Cluster

**Ajustar tiempo:** Top-right → "Last 1 hour"

**Verificar paneles:**
- ✅ **CPU Utilisation:** Muestra ~9%
- ✅ **Memory Utilisation:** Muestra ~70%
- ✅ **CPU Usage Graph:** Líneas de ecommerce, kube-system, monitoring
- ✅ **Memory Graph:** Líneas de los 3 namespaces
- ✅ **CPU Quota Table:** Datos de los 3 namespaces
- ✅ **Network I/O:** Gráficos con tráfico

✅ **TODOS los paneles muestran datos reales**

---

## 📊 GUÍA DE DASHBOARDS {#dashboards}

### Dashboard: Kubernetes / Compute Resources / Cluster

**Ubicación:** Dashboards → Browse → "Kubernetes / Compute Resources / Cluster"

#### Paneles Superiores (Métricas Globales)

1. **CPU Utilisation: 8.98%**
   - **Significado:** Porcentaje REAL de CPU usado por TODO el cluster
   - **Interpretación:** Solo 9% usado = 91% disponible (excelente)
   - **Valores normales:** <50% (bien), 50-80% (aceptable), >80% (crítico)

2. **CPU Requests Commitment: 45%**
   - **Significado:** CPU garantizada que los pods reservaron
   - **Viene de:** `resources.requests.cpu` en tus deployments
   - **Ejemplo:** Grafana pidió 250m (0.25 cores), Prometheus 500m (0.5 cores)
   - **Interpretación:** 45% reservado, 55% libre para nuevos pods

3. **CPU Limits Commitment: 85%**
   - **Significado:** CPU MÁXIMA que los pods pueden usar si la necesitan
   - **Viene de:** `resources.limits.cpu` en tus deployments
   - **⚠️ Advertencia:** Si todos usan su límite a la vez = 85% usado
   - **Interpretación:** Tienes 15% de margen

4. **Memory Utilisation: 69.8%**
   - **Significado:** Porcentaje REAL de RAM usado ahora
   - **Cálculo:** ~2.8GB de 4GB ocupados
   - **Interpretación:** Saludable (antes del upgrade estaba en 96%)
   - **Valores críticos:** >90% (peligro de OOMKilled)

5. **Memory Requests Commitment: 62.4%**
   - **Significado:** RAM garantizada reservada
   - **Ejemplo:** Grafana 256Mi, Prometheus 1Gi
   - **Total:** ~2.5GB reservados

6. **Memory Limits Commitment: 122%** ⚠️
   - **Significado:** RAM MÁXIMA que pods pueden intentar usar
   - **🚨 OVERCOMMIT:** Los pods pueden pedir MÁS de lo que tienes
   - **¿Es peligroso?** No, porque rara vez usan todo a la vez
   - **Protección:** Kubernetes mata pods si realmente se queda sin RAM

#### Gráfico: CPU Usage (Líneas de Tiempo)

**Muestra:** Uso de CPU por namespace en tiempo real

**Líneas:**
- 🔵 **monitoring (azul):** Picos de ~0.14 cores (Prometheus scraping cada 30s)
- 🟡 **kube-system (amarillo):** ~0.04 cores (CoreDNS, Traefik)
- 🟢 **ecommerce (verde):** ~0.02 cores (app + PostgreSQL casi sin carga)

**Eje X:** Tiempo (últimos 60 minutos)
**Eje Y:** Cores de CPU

#### Tabla: CPU Quota

| Columna | Explicación |
|---------|-------------|
| **Namespace** | Agrupación lógica de pods |
| **Pods** | Cantidad de pods corriendo |
| **Workloads** | Cantidad de Deployments/StatefulSets |
| **CPU Usage** | CPU REAL usada ahora |
| **CPU Requests** | CPU garantizada pedida |
| **CPU Requests %** | % de requests vs total cluster |
| **CPU Limits** | CPU máxima permitida |
| **CPU Limits %** | % de límites vs total cluster |

**Datos de ejemplo:**

**monitoring:**
- 6 pods, 6 workloads
- Usando: 0.112 cores (11.2% de 1 core)
- Pidieron: 0.950 cores garantizados
- Límites: 1.90 cores máximo
- **Interpretación:** Usando 11.8% de lo que pidieron (normal, están ociosos)

#### Gráfico: Memory (Parte Inferior)

**Muestra:** Uso de RAM por namespace

**Valores en leyenda:**
- **ecommerce:** 59.2 MiB (app Node.js muy eficiente)
- **kube-system:** 63.6 MiB (pods de sistema)
- **monitoring:** 1.10 GiB (Prometheus guardando métricas = normal)

**Total:** ~1.22 GiB de 4GB

---

### Otros Dashboards Útiles

#### Kubernetes / Compute Resources / Namespace (Pods)
**Uso:** Ver uso de recursos por cada pod individual
- Filtrar por namespace: `monitoring`, `ecommerce`, `kube-system`
- Ver qué pod consume más CPU/RAM
- Detectar memory leaks (RAM creciendo constantemente)

#### Kubernetes / Compute Resources / Node (Pods)
**Uso:** Ver recursos del nodo (tu VM)
- CPU total del host
- RAM total del host
- Disk I/O
- Network I/O

#### Kubernetes / Networking / Cluster
**Uso:** Ver tráfico de red
- Bandwidth por namespace
- Paquetes enviados/recibidos
- Errores de red

---

## 📋 COMANDOS DE ADMINISTRACIÓN {#comandos}

### Gestión de Helm

```bash
# Ver releases instalados
helm list -n monitoring

# Ver valores configurados del chart
helm get values prometheus -n monitoring

# Actualizar configuración
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values k8s/prometheus-values.yaml

# Ver historial de releases
helm history prometheus -n monitoring

# Rollback a versión anterior
helm rollback prometheus 1 -n monitoring

# Desinstalar completamente (⚠️ BORRA DATOS)
helm uninstall prometheus -n monitoring
```

---

### Gestión de Pods

```bash
# Ver todos los pods del monitoring
kubectl get pods -n monitoring

# Ver logs de Prometheus
kubectl logs -n monitoring prometheus-prometheus-kube-prometheus-prometheus-0 -c prometheus -f

# Ver logs de Grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana -c grafana -f

# Reiniciar Grafana (borra el pod, se recrea automáticamente)
kubectl delete pod -n monitoring -l app.kubernetes.io/name=grafana

# Ver eventos del namespace
kubectl get events -n monitoring --sort-by='.lastTimestamp'
```

---

### Acceso Temporal a UIs

```bash
# Prometheus UI (http://localhost:9090)
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# AlertManager UI (http://localhost:9093)
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093

# Grafana (alternativa al NodePort)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

---

### Verificación de Recursos

```bash
# Ver uso de CPU/RAM de pods
kubectl top pods -n monitoring

# Ver uso del nodo
kubectl top nodes

# Ver PersistentVolumes
kubectl get pvc -n monitoring

# Ver tamaño usado de volúmenes
kubectl exec -n monitoring prometheus-prometheus-kube-prometheus-prometheus-0 -c prometheus -- \
  df -h /prometheus
```

---

### Queries Útiles de Prometheus

Acceder vía: http://192.168.0.119:30080 → Explore → Metrics browser

```promql
# CPU usado por namespace
sum(rate(container_cpu_usage_seconds_total[5m])) by (namespace)

# RAM usada por namespace
sum(container_memory_working_set_bytes) by (namespace) / 1024 / 1024 / 1024

# Pods corriendo por namespace
count(kube_pod_info) by (namespace)

# Pods con restarts recientes
kube_pod_container_status_restarts_total > 5

# Targets de Prometheus activos
up == 1

# Uso de disco de Prometheus
prometheus_tsdb_storage_blocks_bytes / 1024 / 1024 / 1024
```

---

## 🎯 PRÓXIMOS PASOS (OPCIONAL) {#proximos-pasos}

### FASE 2: PostgreSQL Exporter (Opcional)

**Objetivo:** Monitorear la base de datos del ecommerce.

```bash
# Instalar postgres-exporter
helm install postgres-exporter prometheus-community/prometheus-postgres-exporter \
  --namespace ecommerce \
  --set config.datasource.host=ecommerce-postgres \
  --set config.datasource.user=postgres \
  --set config.datasource.password=12345678 \
  --set config.datasource.database=ecommerce_db
```

**Métricas a obtener:**
- `pg_stat_database_numbackends` - Conexiones activas
- `pg_locks_count` - Locks en tablas
- `pg_stat_bgwriter` - Writes al disco

---

### FASE 3: Importar Dashboards Predefinidos

**Navegar a:** Grafana → Dashboards → Import

**Dashboards recomendados por ID:**

1. **ID 1860:** Node Exporter Full
   - Métricas detalladas del sistema operativo
   - CPU, RAM, disco, red por core/interfaz

2. **ID 9628:** PostgreSQL Database
   - Requiere postgres-exporter instalado
   - Queries, locks, connections, cache hit ratio

3. **ID 7249:** Kubernetes Cluster Monitoring
   - Vista ejecutiva del cluster
   - Health score, availability, resource distribution

**Proceso de import:**
1. Click en "Import dashboard"
2. Escribir ID (ejemplo: 1860)
3. Click "Load"
4. Seleccionar datasource: `Prometheus`
5. Click "Import"

---

### FASE 4: Configurar Alertas

**Crear archivo:** `k8s/prometheus-rules.yaml`

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: ecommerce-alerts
  namespace: monitoring
  labels:
    prometheus: kube-prometheus
spec:
  groups:
  - name: infrastructure
    interval: 30s
    rules:
    # Alerta si CPU >80% por 5 minutos
    - alert: HighCPUUsage
      expr: |
        (100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)) > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage on {{ $labels.instance }}"
        description: "CPU usage is {{ $value }}%"
    
    # Alerta si RAM >90%
    - alert: HighMemoryUsage
      expr: |
        (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "High memory usage on {{ $labels.instance }}"
    
    # Alerta si pod reinicia mucho
    - alert: PodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} is crash looping"
```

**Aplicar:**
```bash
kubectl apply -f k8s/prometheus-rules.yaml
```

---

### FASE 5: Métricas Custom de la Aplicación

**Si tu app expusiera métricas** en `/metrics`:

```javascript
// En tu aplicación Astro/Node.js
import promClient from 'prom-client';

const register = new promClient.Registry();

// Métrica de ejemplo: contador de pedidos
const ordersCounter = new promClient.Counter({
  name: 'ecommerce_orders_total',
  help: 'Total number of orders created',
  registers: [register]
});

// Endpoint /metrics
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});
```

**ServiceMonitor para tu app:**

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ecommerce-app
  namespace: ecommerce
spec:
  selector:
    matchLabels:
      app: ecommerce-app
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
```

---

## 📊 RESUMEN DE LOGROS

### ✅ Completado - PASO 6: Monitoreo

| # | Tarea | Estado | Fecha |
|---|-------|--------|-------|
| 1 | Instalación de Helm v3.19.4 | ✅ | 24/12/2025 |
| 2 | Agregado repo prometheus-community | ✅ | 24/12/2025 |
| 3 | Creación de namespace monitoring | ✅ | 24/12/2025 |
| 4 | Configuración prometheus-values.yaml | ✅ | 24/12/2025 |
| 5 | Instalación kube-prometheus-stack | ✅ | 24/12/2025 |
| 6 | Pods Running (6 componentes) | ✅ | 24/12/2025 |
| 7 | Acceso a Grafana :30080 | ✅ | 24/12/2025 |
| 8 | Fix serviceMonitorSelector (REVISION 2) | ✅ | 24/12/2025 |
| 9 | Verificación 13 targets scraping | ✅ | 24/12/2025 |
| 10 | Fix RAM exhaustion (3GB → 4GB) | ✅ | 24/12/2025 |
| 11 | Fix containerd socket post-reboot | ✅ | 25/12/2025 |
| 12 | Dashboards mostrando datos | ✅ | 25/12/2025 |

---

### 🎓 Lecciones Aprendidas

1. **kube-prometheus-stack usa selectors restrictivos por defecto**
   - Helm configura `serviceMonitorSelectorNilUsesHelmValues=true`
   - Esto filtra ServiceMonitors sin label `release=prometheus`
   - **Solución:** Configurar `false` para aceptar todos

2. **ServiceMonitor discovery no es instantáneo**
   - Prometheus puede tardar 5-10 minutos en descubrir nuevos targets
   - No entrar en pánico si targets=0 inmediatamente después de cambios
   - **Verificación:** Usar port-forward y consultar API directamente

3. **3GB de RAM es INSUFICIENTE para K3s + monitoring completo**
   - Prometheus + Grafana + app = ~3.5GB mínimo necesario
   - Con 3GB: OOMKilled, CrashLoopBackOff, pods Pending
   - **Mínimo recomendado:** 4GB para desarrollo, 8GB para producción

4. **Containerd sockets se corrompen si /run se limpia mal**
   - Después de reboot, `/run/k3s/containerd/` puede quedar como directorio
   - Containerd espera crear un socket file
   - **Solución:** `sudo rm -rf /run/k3s/` y reiniciar K3s

5. **PersistentVolumes sobreviven a reinicios de pods**
   - Datos de Prometheus se preservaron después del reboot
   - Dashboards de Grafana persistieron
   - **Ventaja:** No se pierde histórico de métricas

6. **kubectl permissions se resetean en cada reboot**
   - K3s crea `/etc/rancher/k3s/k3s.yaml` con permisos 600
   - Hay que hacer `chmod 644` después de cada reboot
   - **Solución permanente:** Configurar K3s con `--write-kubeconfig-mode 644`

---

## 🔐 INFORMACIÓN DE ACCESO

### Grafana
- **URL:** http://192.168.0.119:30080
- **Usuario:** `admin`
- **Password:** `admin123`
- **Tipo:** NodePort en puerto 30080

### Prometheus (vía port-forward)
- **URL:** http://localhost:9090
- **Comando:** `kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090`
- **API:** http://localhost:9090/api/v1/

### AlertManager (vía port-forward)
- **URL:** http://localhost:9093
- **Comando:** `kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093`

---

## 📖 REFERENCIAS Y DOCUMENTACIÓN

### Enlaces Útiles

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [kube-prometheus-stack Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [PromQL (Prometheus Query Language)](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Helm Documentation](https://helm.sh/docs/)

### Archivos de Configuración en Repositorio

```
k8s/
├── prometheus-values.yaml          # Configuración del stack (99 líneas)
└── grafana-patch.yaml              # Patch de readiness (no usado, RAM fue la solución)

devops/
└── PASO_06_MONITOREO.md           # Esta documentación
```

---

## 👨‍💻 AUTORES Y ESTADO

**Implementado por:** ITZAN44 con asistencia de GitHub Copilot  
**Fecha de inicio:** 24 de Diciembre, 2025  
**Fecha de finalización:** 25 de Diciembre, 2025  
**Repositorio:** https://github.com/ITZAN44/Ecommerce-Proyecto-BD  
**Branch:** main  
**Commits clave:**
- `2d01e32` - feat: Add Prometheus monitoring configuration for K3s

---

**ROADMAP DEVOPS - ESTADO ACTUAL:**

| Paso | Descripción | Estado | Fecha |
|------|-------------|--------|-------|
| 1 | Docker Containerization | ✅ COMPLETADO | 16/12/2025 |
| 2 | Nginx Reverse Proxy | ✅ COMPLETADO | 23/12/2025 |
| 3 | K3s Kubernetes | ✅ COMPLETADO | 23/12/2025 |
| 4 | Jenkins CI/CD | ✅ COMPLETADO | 23/12/2025 |
| 5 | Ansible IaC | ✅ COMPLETADO | 24/12/2025 |
| **6** | **Prometheus + Grafana** | **✅ COMPLETADO** | **24-25/12/2025** |

---

**FIN DEL INFORME - PASO 6**

*Documento generado el 25/12/2025*  
*Versión: 1.0.0*  
*🎄 ¡Feliz Navidad y Feliz Monitoreo! 🎄*
