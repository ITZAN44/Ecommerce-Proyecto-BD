# 🧠 CONTEXTO COMPLETO DEL PROYECTO ECOMMERCE — PARA AGENTE IA

> **Propósito de este documento:** Dar contexto total a un agente IA sobre todo lo que se ha construido e implementado en este proyecto. Todo lo documentado aquí está **funcionando en producción** (VM local).

---

## 1. DESCRIPCIÓN GENERAL DEL PROYECTO

### Aplicación

- **Nombre:** Ecommerce Proyecto BD
- **Framework:** Astro.js v5.15.4 con SSR (Server-Side Rendering)
- **Adapter:** `@astrojs/node` modo `standalone`
- **Base de datos:** PostgreSQL 16
- **Cliente DB:** `node-postgres` (pg)
- **Estilos:** TailwindCSS 4.1.17
- **Gráficos:** Chart.js 4.5.1
- **Repositorio GitHub:** `https://github.com/ITZAN44/Ecommerce-Proyecto-BD.git`
- **Branch principal:** `main`

### Datos en la base de datos (producción)

- 62 categorías de productos
- 8 clientes registrados
- 15 cupones activos
- 27 pedidos con historial completo
- Funciones almacenadas de analytics, validaciones y auditoría
- Triggers para control de stock, registro de cambios y timeline
- Vistas materializadas: clientes VIP, top productos
- Índices optimizados para queries de alta frecuencia

### Infraestructura física

| Parámetro | Valor |
|-----------|-------|
| Tipo | VM VirtualBox |
| SO | Ubuntu 24.04 LTS |
| IP | `192.168.0.119` |
| RAM | 4 GB (ampliada de 3 GB durante el Paso 6) |
| Usuario | `clark` |
| Acceso | SSH desde Windows con PuTTY |
| Hostname | `clark-VirtualBox` |

---

## 2. STACK DEVOPS IMPLEMENTADO (RESUMEN EJECUTIVO)

Se completaron **6 pasos** de DevOps, todos funcionales y documentados en `devops.md/devops-local/`:

| Paso | Tecnología | Fecha | Estado |
|------|-----------|-------|--------|
| 01 | Docker + Docker Compose | 16 Dic 2025 | ✅ Completado |
| 02 | Nginx Reverse Proxy | 18 Dic 2025 | ✅ Completado |
| 03 | Kubernetes K3s | 18 Dic 2025 | ✅ Completado |
| 04 | CI/CD con Jenkins | ~20 Dic 2025 | ✅ Completado |
| 05 | IaC con Ansible | 24 Dic 2025 | ✅ Completado |
| 06 | Monitoreo Prometheus + Grafana | 24-25 Dic 2025 | ✅ Completado |

---

## 3. DETALLE DE CADA PASO

---

### PASO 01 — DOCKER

**Archivo:** `devops.md/devops-local/PASO_01_DOCKER_CONTAINERIZACION.md` (909 líneas)

#### Qué se implementó

- Docker Engine instalado en Ubuntu 24.04
- Imagen propia con **multi-stage build** (Node.js 20-alpine)
  - Stage 1 `builder`: instala deps + compila Astro
  - Stage 2 `production`: solo deps de producción + usuario no-root
  - Resultado: imagen de ~200 MB vs ~584 MB sin multi-stage
- `docker-compose.production.yml` con PostgreSQL + App
- Docker Secrets para la contraseña de la DB (`secrets/db_password.txt`)
- Health checks en ambos servicios
- Resource limits (CPU `1`, memoria `512M`)
- Red bridge privada `ecommerce_network`
- Usuario no-root `astro` (UID 1001) dentro del contenedor

#### Archivos clave en el repo

| Archivo | Descripción |
|---------|-------------|
| `Dockerfile` | Multi-stage build, health check, usuario no-root |
| `docker-compose.production.yml` | Orquestación producción con secrets |
| `docker-compose.yml` | Para desarrollo local |
| `secrets/db_password.txt` | Password de DB (NO en git) |
| `.env.production` | Variables de entorno (NO en git) |

#### Dockerfile (resumen técnico)

```dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Production
FROM node:20-alpine AS production
RUN addgroup -g 1001 -S nodejs && adduser -S astro -u 1001
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY --from=builder --chown=astro:nodejs /app/dist ./dist
USER astro
EXPOSE 4321
ENV NODE_ENV=production HOST=0.0.0.0 PORT=4321
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:4321/api/analytics/dashboard', ...)"
CMD ["node", "./dist/server/entry.mjs"]
```

#### Solución de problema conocido: Docker daemon

```bash
# Si Docker no arranca:
sudo systemctl stop docker
sudo systemctl restart docker.socket
sudo systemctl start docker
sudo systemctl enable docker
```

---

### PASO 02 — NGINX REVERSE PROXY

**Archivo:** `devops.md/devops-local/PASO_02_NGINX_REVERSE_PROXY.md` (1458 líneas)

#### Qué se implementó

- Nginx instalado directamente en la VM (no en Docker)
- Configurado como **reverse proxy** frente al puerto `4321` de la app
- Acceso externo en **puerto 80** estándar (sin especificar puerto)
- Compresión **gzip** habilitada (~70% reducción de respuestas)
- **Cache de assets estáticos** por 1 año (imágenes, CSS, JS)
- Headers de seguridad: `X-Forwarded-*`, `X-Real-IP`
- Logs centralizados en `/var/log/nginx/`
- Health check endpoint `/health` → retorna `200 OK`
- Preparación para SSL/TLS

#### Arquitectura

```
Usuarios → Nginx (:80) → Docker/K3s (app)
            ↑
     [gzip, cache, headers, logs]
```

#### Configuración activa (`/etc/nginx/sites-enabled/ecommerce`)

```nginx
upstream ecommerce_backend {
    server 10.43.7.181:80;  # ClusterIP del service de K3s
    keepalive 32;
}

server {
    listen 80;
    server_name _;

    gzip on;
    gzip_types text/plain text/css application/json application/javascript;
    gzip_min_length 1000;

    location / {
        proxy_pass http://ecommerce_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

> **Nota importante:** Cuando K3s está activo, el backend de Nginx apunta a la **ClusterIP del Service de Kubernetes** (`10.43.7.181:80`), NO al puerto `4321` de Docker directamente.

---

### PASO 03 — KUBERNETES (K3s)

**Archivo:** `devops.md/devops-local/PASO_03_KUBERNETES_K3S.md` (388 líneas)

#### Qué se implementó

- **K3s v1.33.6+k3s1** instalado en la VM (Kubernetes ligero)
- Namespace dedicado `ecommerce`
- **PostgreSQL** en K8s con PVC (almacenamiento persistente `local-path`)
- **Aplicación Astro** con **2 réplicas** (alta disponibilidad)
- **Traefik Ingress Controller** (incluido en K3s) exponiendo HTTP en puerto 80
- Base de datos restaurada desde `database/backup_bd_real.sql`
- Nginx del Paso 02 **deshabilitado** al activar K3s (conflicto en puerto 80)

#### Estado actual de pods

```
Namespace: ecommerce
- ecommerce-app-xxx   1/1  Running  (2 réplicas)
- postgres-xxx        1/1  Running  (1 réplica)

Namespace: monitoring
- [6 pods del stack Prometheus+Grafana]

Namespace: kube-system
- traefik, coredns, local-path-provisioner
```

#### Archivos de manifiestos K8s (carpeta `k8s/`)

| Archivo | Recurso |
|---------|---------|
| `namespace.yaml` | Namespace `ecommerce` |
| `postgres-secret.yaml` | Secret con credenciales de DB |
| `postgres-pvc.yaml` | PersistentVolumeClaim 1Gi |
| `postgres-deployment.yaml` | Deployment de PostgreSQL |
| `postgres-service.yaml` | ClusterIP service para PostgreSQL |
| `app-configmap.yaml` | ConfigMap con vars de la app |
| `app-deployment.yaml` | Deployment app (2 réplicas) |
| `app-service.yaml` | ClusterIP service app → puerto 80 |
| `ingress.yaml` | Traefik Ingress → `/` |

#### Cómo se importa la imagen al containerd de K3s

```bash
# 1. Buildear con Docker
docker build -t ecommerce-app:1.0.0 -f Dockerfile .

# 2. Exportar imagen a .tar
docker save ecommerce-app:1.0.0 -o /tmp/ecommerce-app.tar

# 3. Importar en containerd de K3s
sudo k3s ctr images import /tmp/ecommerce-app.tar

# 4. Verificar
sudo k3s ctr images ls | grep ecommerce
```

#### Solución de problema conocido: socket corrupto post-reboot

```bash
# Error: "is a directory" en containerd.sock
sudo systemctl stop k3s
sudo rm -rf /run/k3s/containerd/
sudo rm -rf /run/k3s/
sudo systemctl start k3s
sleep 30
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
```

#### Comandos útiles de operación

```bash
# Alias configurado en .bashrc
alias k="sudo k3s kubectl"

# Ver todo el namespace
k get all -n ecommerce

# Logs de la app
k logs -n ecommerce -l app=ecommerce-app --tail=100 -f

# Rolling restart
k rollout restart deployment ecommerce-app -n ecommerce

# Escalar
k scale deployment ecommerce-app -n ecommerce --replicas=3

# Eventos de debug
k get events -n ecommerce --sort-by='.lastTimestamp' | tail -50
```

---

### PASO 04 — CI/CD CON JENKINS

**Archivo:** `devops.md/devops-local/PASO_04_CI_CD_JENKINS.md` (729 líneas)

#### Qué se implementó

- **Jenkins LTS** corriendo en Docker (`docker-compose.jenkins.yml`)
- Gestionado por **systemd** (`jenkins-docker.service`) para auto-start
- Se monta el socket de Docker y los binarios de K3s/kubectl dentro del contenedor
- `network_mode: host` para acceder al API de K3s en `localhost:6443`
- Pipeline completo en `Jenkinsfile` en el repo

#### Acceso

- **URL:** `http://192.168.0.119:8080`
- **Usuario:** `Clark`
- **Password:** `Clark@Main!1234`

#### Pipeline (Jenkinsfile — 9 stages)

```
1. Verificar entorno     → docker, kubectl, git
2. Checkout código       → clonar repo de GitHub
3. Build imagen Docker   → tag = primeros 7 chars del commit SHA
4. Importar a K3s        → docker save + k3s ctr images import
5. Deploy a K3s          → kubectl set image deployment/...
6. Esperar rollout        → kubectl rollout status (timeout 5 min)
7. Verificar pods        → kubectl get pods -n ecommerce
8. Health check          → curl http://localhost/api/analytics/dashboard → HTTP 200
9. Historial             → kubectl rollout history
```

#### Trigger: Poll SCM

- Schedule: `H/2 * * * *` (revisa GitHub cada 2 minutos)
- Si detecta nuevo commit → dispara automáticamente el pipeline
- No requiere IP pública (vs webhooks)

#### Flujo completo

```
git push → Jenkins detecta (≤2 min) → build imagen → 
import a containerd → rolling update → health check → ✅
```

#### Rollback

```bash
# Ver historial
kubectl rollout history deployment/ecommerce-app -n ecommerce

# Rollback a revisión anterior
kubectl rollout undo deployment/ecommerce-app -n ecommerce

# Rollback a revisión específica
kubectl rollout undo deployment/ecommerce-app -n ecommerce --to-revision=2
```

#### Archivos clave

| Archivo | Descripción |
|---------|-------------|
| `Jenkinsfile` | Pipeline declarativo (en root del repo) |
| `docker-compose.jenkins.yml` | Definición del contenedor Jenkins |
| `jenkins/kubeconfig` | Kubeconfig apuntando a `127.0.0.1:6443` |

---

### PASO 05 — IAC CON ANSIBLE

**Archivo:** `devops.md/devops-local/PASO_05_IAC_ANSIBLE.md` (1233 líneas)

#### Qué se implementó

- **Ansible** instalado en **WSL Ubuntu** (Windows Subsystem for Linux)
- Proyecto completo en `~/ecommerce-ansible/ansible/` dentro de WSL
- **4 roles** modulares que automatizan todo el stack
- **1 playbook maestro** que despliega todo con un solo comando
- **Check mode** funcionando (simulación sin cambios reales)
- **Idempotencia** verificada en todos los roles

#### Conexión

- Ansible en WSL → SSH sin contraseña → VM `192.168.0.119` (usuario `clark`)
- `clark` tiene sudo sin contraseña (`NOPASSWD:ALL` en sudoers)

#### Estructura del proyecto Ansible

```
ansible/
├── ansible.cfg                     # inventory, roles_path, callback=yaml
├── inventory/
│   ├── hosts.ini                   # [production] vm-ubuntu 192.168.0.119
│   └── group_vars/
│       ├── all.yml                 # Variables globales
│       └── production.yml          # Variables sensibles (db_password, etc.)
├── playbooks/
│   ├── deploy-all.yml              # 🌟 PLAYBOOK MAESTRO
│   ├── destroy-all.yml             # Limpieza completa
│   ├── ping-test.yml               # Test conectividad
│   ├── deploy-docker.yml           # Solo Docker
│   ├── deploy-nginx.yml            # Solo Nginx
│   ├── deploy-k3s.yml              # Solo K3s
│   └── deploy-jenkins.yml          # Solo Jenkins
└── roles/
    ├── docker/    (15 tareas)
    ├── nginx/     (11 tareas)  ← incluye template Jinja2
    ├── k3s/       (24 tareas)  ← incluye 8 manifiestos K8s
    └── jenkins/   (19 tareas)  ← incluye systemd service
```

#### Variables globales clave (`all.yml`)

```yaml
project_name: "ecommerce"
docker_version: "24.0.7"
nginx_backend_host: "10.43.7.181"   # ClusterIP del service K3s
nginx_backend_port: 80
nginx_port: 80
k3s_version: "v1.33.6+k3s1"
db_name: "ecommerce_db"
db_user: "ecommerce_user"
firewall_allowed_ports: [22, 80, 443, 8080]
```

#### Roles: resumen de tareas

**Rol `docker` (15 tareas):**
Instala Docker Engine, agrega GPG key y repositorio oficial, configura usuario en grupo docker, tests con `hello-world`.

**Rol `nginx` (11 tareas):**
Instala Nginx, elimina default site, despliega config via template Jinja2, valida sintaxis, recarga.

**Rol `k3s` (24 tareas):**
Instala K3s, copia los 8 manifiestos de K8s, aplica en orden secuencial (namespace → secret → PVC → postgres → configmap → app), espera readiness de pods.

**Rol `jenkins` (19 tareas):**
Copia docker-compose desde template, genera kubeconfig para Jenkins, crea servicio systemd para auto-start, inicia Jenkins, muestra password inicial.

#### Playbook maestro: ejecución

```bash
# Desde WSL (no desde /mnt/c/)
cd ~/ecommerce-ansible/ansible/

# Simulación (no hace cambios)
ansible-playbook playbooks/deploy-all.yml --check

# Ejecución real
ansible-playbook playbooks/deploy-all.yml

# Solo un rol
ansible-playbook playbooks/deploy-docker.yml
```

#### Estadísticas del proyecto Ansible

| Categoría | Cantidad | Líneas aprox. |
|-----------|----------|---------------|
| Playbooks | 7 | ~800 |
| Roles | 4 | ~600 |
| Templates | 3 | ~150 |
| Variables | 3 | ~100 |
| **Total** | **23 archivos** | **~2,150 líneas** |

---

### PASO 06 — MONITOREO (Prometheus + Grafana)

**Archivo:** `devops.md/devops-local/PASO_06_MONITOREO.md` (1297 líneas)

#### Qué se implementó

- **Helm v3.19.4** instalado en la VM
- **kube-prometheus-stack** (chart de `prometheus-community`) desplegado en namespace `monitoring`
- Stack completo con 6 componentes

#### Componentes del stack de monitoreo

| Componente | Descripción | Pods |
|-----------|-------------|------|
| **Grafana** | UI de dashboards, NodePort 30080 | 3 containers |
| **Prometheus** | Scraping + almacenamiento métrica | 2 containers |
| **AlertManager** | Gestión de alertas | 2 containers |
| **Prometheus Operator** | Automatización de configuración | 1 container |
| **Kube State Metrics** | Métricas de objetos K8s | 1 container |
| **Node Exporter** | Métricas del SO (CPU, RAM, disco) | 1 container |

#### Acceso a Grafana

- **URL:** `http://192.168.0.119:30080`
- **Usuario:** `admin`
- **Password:** `admin123`

#### Configuración clave (`k8s/prometheus-values.yaml`)

```yaml
grafana:
  adminPassword: "admin123"
  service:
    type: NodePort
    nodePort: 30080
  persistence:
    enabled: true
    size: 5Gi
    storageClassName: local-path

prometheus:
  prometheusSpec:
    retention: 15d               # 15 días de datos
    scrapeInterval: 30s
    evaluationInterval: 30s
    serviceMonitorSelectorNilUsesHelmValues: false  # Descubre todos los namespaces
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: local-path
          resources:
            requests:
              storage: 10Gi
    resources:
      limits:
        cpu: 1000m
        memory: 2Gi
```

#### Targets activos (13 en total)

1. Grafana metrics
2. AlertManager metrics
3. AlertManager cluster
4. Kubernetes API server
5. CoreDNS
6. Kube Controller Manager
7. Kube ETCD
8. Kube Proxy
9. Kube Scheduler
10. Kubelet (node metrics)
11. cAdvisor (container metrics)
12. Kubelet Probes
13. Kube State Metrics

Verificación:
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length'
# → 13
```

#### Dashboards disponibles (20+ preconfigurados)

Dashboards más importantes:
- **Kubernetes / Compute Resources / Cluster** → visión global
- **Kubernetes / Compute Resources / Namespace (Pods)** → por pod
- **Kubernetes / Compute Resources / Node (Pods)** → recursos VM
- **Node Exporter Full** (ID Grafana: 1860) ← importar manualmente

#### Métricas en tiempo real (valores de referencia)

| Métrica | Valor |
|---------|-------|
| CPU Utilisation (cluster) | ~9% |
| CPU Requests Commitment | ~45% |
| CPU Limits Commitment | ~85% |
| Memory Utilisation | ~70% |
| RAM disponible | ~2.5 GB de 4 GB |
| Namespace ecommerce RAM | ~59 MiB |
| Namespace monitoring RAM | ~1.1 GiB |

#### Problemas resueltos durante este paso

1. **"No Data" en dashboards** → `serviceMonitorSelectorNilUsesHelmValues: false`
2. **Grafana timeout / OOMKilled** → Aumentar RAM VM de 3GB a 4GB
3. **K3s no inicia post-reboot** → `rm -rf /run/k3s/` + `systemctl start k3s`
4. **kubectl requiere sudo** → Configurar `~/.kube/config` permanente

#### Configuración permanente post-reboot (ya aplicada)

```bash
sudo systemctl enable k3s              # K3s inicia automáticamente
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown clark:clark ~/.kube/config
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
```

---

## 4. ARQUITECTURA COMPLETA (ESTADO FINAL)

```
┌──────────────────────────────────────────────────────────────┐
│                 VM Ubuntu 24.04 (192.168.0.119)               │
│                                                               │
│  ┌────────────┐                                              │
│  │   Nginx    │◄── Puerto 80 (HTTP externo)                 │
│  │ (host)     │    reverse proxy con gzip + cache           │
│  └─────┬──────┘                                              │
│        │ proxy_pass → 10.43.7.181:80                        │
│        ▼                                                      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │            K3s Kubernetes (v1.33.6+k3s1)             │    │
│  │                                                       │    │
│  │  Namespace: ecommerce                                │    │
│  │  ┌────────────────────┐  ┌────────────────────────┐  │    │
│  │  │  ecommerce-app     │  │  postgres              │  │    │
│  │  │  - 2 réplicas      │  │  - 1 réplica           │  │    │
│  │  │  - image: 1.0.0    │  │  - PVC 1Gi             │  │    │
│  │  │  - port: 4321      │  │  - port: 5432          │  │    │
│  │  │  - health checks   │  │  - PostgreSQL 16       │  │    │
│  │  └────────────────────┘  └────────────────────────┘  │    │
│  │                                                       │    │
│  │  Namespace: monitoring                               │    │
│  │  ┌───────────────────────────────────────────────┐  │    │
│  │  │  Grafana (NodePort 30080) + Prometheus        │  │    │
│  │  │  + AlertManager + Node Exporter               │  │    │
│  │  │  + Kube State Metrics + Prometheus Operator   │  │    │
│  │  │  → 13 targets, retención 15d, PVC 10Gi        │  │    │
│  │  └───────────────────────────────────────────────┘  │    │
│  │                                                       │    │
│  │  Ingress: Traefik (puerto 80) → ecommerce-app        │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                               │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Jenkins (Docker, puerto 8080)                     │     │
│  │  - Gestionado por systemd (auto-start)             │     │
│  │  - Poll SCM: revisa GitHub c/2 min                 │     │
│  │  - Pipeline: build → import → deploy → health      │     │
│  └────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────┘

CI/CD Flow:
git push → Jenkins Poll SCM → docker build → k3s import → 
kubectl rolling update → health check HTTP 200 → ✅

IaC:
WSL Ubuntu → Ansible → SSH → VM (4 roles: docker/nginx/k3s/jenkins)
```

---

## 5. ENDPOINTS FUNCIONALES

| Endpoint | Resultado |
|----------|-----------|
| `http://192.168.0.119/` | Aplicación Ecommerce |
| `http://192.168.0.119/health` | `OK` (Nginx health) |
| `http://192.168.0.119/api/analytics/dashboard` | JSON con estadísticas |
| `http://192.168.0.119:8080` | Jenkins CI/CD |
| `http://192.168.0.119:30080` | Grafana Dashboards |

---

## 6. ESTRUCTURA DE ARCHIVOS DEL REPOSITORIO

```
Ecommers-Proyecto/
├── Dockerfile                      # Multi-stage, non-root, health check
├── docker-compose.production.yml   # PostgreSQL + App con secrets
├── docker-compose.yml              # Para desarrollo local
├── docker-compose.jenkins.yml      # Jenkins con acceso a K3s
├── Jenkinsfile                     # Pipeline CI/CD (9 stages)
├── astro.config.mjs
├── package.json
├── tsconfig.json
│
├── k8s/                            # Manifiestos Kubernetes
│   ├── namespace.yaml
│   ├── postgres-secret.yaml        # Credenciales DB encryptadas
│   ├── postgres-pvc.yaml           # PersistentVolumeClaim 1Gi
│   ├── postgres-deployment.yaml
│   ├── postgres-service.yaml
│   ├── app-configmap.yaml
│   ├── app-deployment.yaml         # 2 réplicas
│   ├── app-service.yaml
│   ├── ingress.yaml                # Traefik
│   └── prometheus-values.yaml      # Config Helm para monitoreo
│
├── database/
│   ├── backup_bd_real.sql          # Backup completo con datos reales
│   ├── schema.sql
│   ├── seed.sql
│   ├── init.sql
│   ├── functions_procedures_LIMPIO.sql
│   ├── fase1/                      # Mejoras de auditoría
│   ├── fase2/                      # Gráficos
│   └── fase3/                      # Timeline
│
├── src/
│   ├── components/
│   │   ├── charts/                 # BarChart, DoughnutChart, LineChart
│   │   └── timeline/
│   ├── layouts/
│   ├── lib/
│   │   ├── db.ts                   # Conexión a PostgreSQL
│   │   └── types.ts
│   └── pages/
│       ├── index.astro
│       └── api/                    # Rutas REST a PostgreSQL
│           ├── analytics/          # dashboard, ventas, productos TOP
│           ├── pedidos/
│           ├── productos/
│           ├── clientes/
│           ├── cupones/
│           ├── devoluciones/
│           ├── envios/
│           ├── pagos/
│           └── auditoria/
│
├── secrets/
│   ├── db_password.txt             # NO en git
│   └── README.md
│
├── jenkins/
│   └── kubeconfig                  # Kubeconfig para Jenkins (server: 127.0.0.1:6443)
│
└── devops.md/
    ├── FLUJO_DEVOPS_COMPLETO_1_A_6.md
    ├── devops-local/               # Documentación de lo implementado
    │   ├── PASO_01_DOCKER_CONTAINERIZACION.md
    │   ├── PASO_02_NGINX_REVERSE_PROXY.md
    │   ├── PASO_03_KUBERNETES_K3S.md
    │   ├── PASO_04_CI_CD_JENKINS.md
    │   ├── PASO_05_IAC_ANSIBLE.md
    │   └── PASO_06_MONITOREO.md
    └── nube-devops/                # Plan de migración a AWS
        └── migracion.md
```

---

## 7. CREDENCIALES Y ACCESOS (ENTORNO LOCAL)

> ⚠️ Solo válidos para el entorno de laboratorio (VM local).

| Servicio | URL/Host | Usuario | Password |
|---------|---------|---------|---------|
| VM Ubuntu | `192.168.0.119` (SSH) | `clark` | — (SSH key) |
| PostgreSQL | `localhost:5432` | `ecommerce_user` | `12345678` |
| Jenkins | `http://192.168.0.119:8080` | `Clark` | `Clark@Main!1234` |
| Grafana | `http://192.168.0.119:30080` | `admin` | `admin123` |
| App Ecommerce | `http://192.168.0.119` | — | — |

---

## 8. TECNOLOGÍAS Y VERSIONES

| Tecnología | Versión |
|-----------|---------|
| Ubuntu | 24.04 LTS |
| Docker Engine | 24.0.7 |
| Docker Compose | V2 v5.0.0 (plugin) |
| K3s (Kubernetes) | v1.33.6+k3s1 |
| Node.js (en contenedor) | 20-alpine |
| Astro.js | 5.15.4 |
| PostgreSQL | 16-alpine |
| Nginx | 1.24.0 |
| Jenkins | LTS (latest) |
| Helm | v3.19.4 |
| kube-prometheus-stack | latest estable |
| Ansible | core 2.16.3 |
| Python (en WSL) | 3.12.3 |

---

## 9. PROBLEMAS RECURRENTES Y SUS SOLUCIONES (REFERENCIA RÁPIDA)

| Problema | Diagnóstico | Solución |
|---------|------------|---------|
| Docker daemon no inicia | `systemctl status docker` | Reiniciar `docker.socket` primero |
| K3s socket corrupto post-reboot | `is a directory` en containerd.sock | `rm -rf /run/k3s/` + `systemctl start k3s` |
| kubectl requiere sudo | KUBECONFIG apunta a `/etc/rancher/k3s/` | `cp k3s.yaml ~/.kube/config` + `chown clark` |
| Grafana "No Data" | 0 targets en Prometheus | `helm upgrade` con `serviceMonitorSelectorNilUsesHelmValues: false` |
| Grafana OOMKilled | RAM < 2 GB disponible | Aumentar RAM de VM (de 3 GB a 4 GB) |
| Nginx 502 after reboot | Backend erróneo o K3s no listo | Actualizar `upstream` con nueva ClusterIP de K3s |
| Jenkins pipeline falla en deploy | kubeconfig apunta a IP incorrecta | Actualizar `jenkins/kubeconfig` con `server: https://127.0.0.1:6443` |

---

## 10. CONTEXTO DE LO QUE VIENE (PENDIENTE / PRÓXIMOS PASOS)

El plan de migración completo está en `devops.md/nube-devops/migracion.md`. Resumen:

### 5 Fases planificadas (aún NO implementadas)

| Fase | Tecnología | Duración | Estado |
|------|-----------|---------|--------|
| 1 | AWS Cloud (EC2, RDS, ECR, EKS, ALB) | 1-2 meses | ⏳ Pendiente |
| 2 | Terraform IaC | 2-3 semanas | ⏳ Pendiente |
| 3 | Logging centralizado (Loki/ELK) + Alertmanager Slack | 2-3 semanas | ⏳ Pendiente |
| 4 | GitOps (ArgoCD) + Vault + cert-manager (HTTPS) | 1 mes | ⏳ Pendiente |
| 5 | K8s Avanzado (RBAC, Network Policies, Helm own chart, Istio) | 2 semanas | ⏳ Pendiente |

### Cobertura actual vs roadmap.sh/devops
- **Actual:** ~35-40% del roadmap
- **Estimado después de 5 fases:** ~85-90%
- **Gap principal:** Cloud providers (0% actualmente)

---

**Fin del documento de contexto**  
*Generado el 4 de Marzo, 2026*
