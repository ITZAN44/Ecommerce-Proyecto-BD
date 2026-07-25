# 🆓 PLAN DEVOPS COMPLETO SIN GASTAR DINERO — Portfolio 85-100%

**Fecha:** Marzo 2026  
**Proyecto:** Ecommerce — Stack DevOps Completo para Portfolio  
**Situación:** AWS Free Tier expirado → Estrategia 100% gratuita  
**Duración estimada:** 6-8 semanas  
**Cobertura estimada del roadmap:** ~88% al finalizar  

---

## 📋 TABLA DE CONTENIDOS

1. [Por qué no necesitas pagar para tener un buen portfolio](#1-por-qué-no-necesitas-pagar)
2. [El secreto: Oracle Cloud Always Free](#2-oracle-cloud-always-free)
3. [Mapa completo de herramientas gratuitas](#3-mapa-de-herramientas-gratuitas)
4. [Cobertura del roadmap por categoría](#4-cobertura-del-roadmap)
5. [Fase 1 — Completar el stack local](#5-fase-1--completar-stack-local)
6. [Fase 2 — Oracle Cloud con Terraform](#6-fase-2--oracle-cloud-con-terraform)
7. [Fase 3 — Serverless y extras](#7-fase-3--serverless-y-extras)
8. [¿Vale para un portfolio profesional?](#8-vale-para-un-portfolio)
9. [Checklist final](#9-checklist-final)

---

## 1. Por qué no necesitas pagar para tener un buen portfolio

La idea de que "necesitas AWS para aprender DevOps" es un mito. Lo que importa en una entrevista técnica **no es qué proveedor usaste**, sino que dominas los conceptos:

- ¿Sabes qué es IaC y puedes escribir Terraform que crea infraestructura real?
- ¿Tienes GitOps funcionando (ArgoCD sincronizando desde GitHub a K8s)?
- ¿Tu pipeline CI/CD despliega automáticamente con rollback?
- ¿Tienes métricas, logs y trazas centralizadas?
- ¿Gestionas secretos de forma segura?

Todo eso se puede demostrar **sin pagar nada**, y la evidencia es este mismo proyecto.

### ¿Qué cambias realmente al ir a la nube?

```
Lo que CAMBIA al pasar a la nube:
- La IP del servidor (192.168.0.119 → IP pública real)
- El proveedor de la VM (VirtualBox → Oracle/AWS/GCP)
- Cómo aprovisiones esa VM (manual → Terraform)

Lo que NO CAMBIA:
- Kubernetes sigue siendo Kubernetes
- Ansible sigue siendo Ansible
- Jenkins sigue siendo Jenkins
- Docker sigue siendo Docker
- ArgoCD sigue siendo ArgoCD
```

La diferencia entre "portfolio local" y "portfolio en la nube" es solo el primer punto — el resto es idéntico.

---

## 2. Oracle Cloud Always Free

### ¿Qué es?

Oracle Cloud tiene una capa gratuita que, a diferencia de AWS (que expira a los 12 meses), **es permanente para siempre**. No tiene fecha de expiración.

### ¿Qué incluye gratuitamente para siempre?

| Recurso | Oracle Always Free | AWS Free Tier (ya expiró) |
|---------|-------------------|--------------------------|
| VMs ARM | **4 VMs Ampere A1 — 4 OCPUs + 24 GB RAM total** | — |
| VMs AMD | 2 micro (1 GB RAM c/u) | 1 t2.micro (1 GB RAM) — solo 12 meses |
| Almacenamiento block | 200 GB | 30 GB — solo 12 meses |
| Object Storage | 10 GB (equivalente a S3) | — |
| Load Balancer | 1 LB flexible (10 Mbps) | — |
| Ancho de banda saliente | 10 TB/mes | 100 GB/mes |
| Expira | **NUNCA** | A los 12 meses |

### El detalle más importante: las VMs ARM

Las 4 VMs ARM de Oracle puedes usarlas como quieras:
- 1 VM con 4 OCPUs + 24 GB RAM (una sola VM enorme)  
- 4 VMs con 1 OCPU + 6 GB RAM cada una
- 2 VMs control plane + 2 VMs worker nodes (cluster K8s real)

Con **24 GB de RAM en la nube real y gratis**, puedes correr todo el stack.

### ¿Pide tarjeta de crédito?

Sí, pide tarjeta para verificar identidad, **pero NO realiza ningún cargo** siempre que solo uses recursos de la capa Always Free. Tiene billing alerts configurables para $0.

---

## 3. Mapa de Herramientas Gratuitas

### Stack completo sin pagar un centavo

```
┌─────────────────────────────────────────────────────────────────┐
│                    LOCAL (VM Ubuntu 24.04)                       │
│                      192.168.0.119                               │
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │  Docker  │  │   K3s    │  │ Jenkins  │  │   Ansible    │   │
│  │ Compose  │  │  K8s     │  │ CI/CD    │  │   4 roles    │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘   │
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │  Nginx   │  │Prometheus│  │ ArgoCD   │  │    Vault     │   │  ← POR AGREGAR
│  │  Proxy   │  │+Grafana  │  │  GitOps  │  │   Secrets    │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘   │
│                                                                  │
│  ┌──────────┐  ┌──────────┐                                    │
│  │   Loki   │  │ Linkerd  │                                    │  ← POR AGREGAR
│  │   Logs   │  │  Mesh    │                                    │
│  └──────────┘  └──────────┘                                    │
└─────────────────────────────────────────────────────────────────┘

              ↕ SSH + Ansible + Terraform

┌─────────────────────────────────────────────────────────────────┐
│               ORACLE CLOUD ALWAYS FREE (nube real)              │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │           4 VMs ARM — 24 GB RAM TOTAL                   │   │
│  │                                                         │   │
│  │  VM1 (Control Plane)    VM2 (Worker)                   │   │
│  │  VM3 (Worker)           VM4 (Monitoring)               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                     │
│  │Terraform │  │   K3s    │  │  ArgoCD  │                     │
│  │  IaC     │  │  Cloud   │  │  Cloud   │                     │
│  └──────────┘  └──────────┘  └──────────┘                     │
│                                                                  │
│  ┌──────────┐  ┌──────────┐                                    │
│  │  Object  │  │  Load    │                                    │
│  │ Storage  │  │ Balancer │                                    │
│  └──────────┘  └──────────┘                                    │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                    SERVICIOS SaaS GRATUITOS                   │
│                                                              │
│  GitHub (repo + Actions 2000 min/mes)                       │
│  Docker Hub (registry público de imágenes)                  │
│  Cloudflare Workers (100K requests/día — Serverless)        │
│  Vercel (deploy automático Astro desde GitHub)              │
└──────────────────────────────────────────────────────────────┘
```

---

## 4. Cobertura del Roadmap

### Por categoría — estado final con este plan

| Categoría del Roadmap | Ahora | Fase 1 (local) | Fase 2 (Oracle) | Final |
|-----------------------|-------|---------------|-----------------|-------|
| OS + Terminal + Scripting | ✅ 100% | — | — | **100%** |
| Git + GitHub | ✅ 100% | — | — | **100%** |
| Docker + Containers | ✅ 100% | — | — | **100%** |
| Web Servers (Nginx) | ✅ 100% | — | — | **100%** |
| Networking + Protocolos | ✅ 85% | — | — | **85%** |
| **Cloud Providers** | ❌ 0% | — | ✅ Oracle | **75%** |
| **Serverless** | ❌ 0% | — | Cloudflare Workers | **70%** |
| Logs Management | ⚠️ 40% | ✅ Loki | — | **95%** |
| Config Management | ✅ 100% | — | — | **100%** |
| **IaC / Terraform** | ⚠️ 20% | — | ✅ Oracle | **100%** |
| CI/CD | ✅ 90% | GitHub Actions | — | **100%** |
| Monitoring | ✅ 90% | — | — | **90%** |
| **Secret Management** | ❌ 0% | ✅ Vault | — | **95%** |
| Container Orchestration | ✅ 95% | — | — | **95%** |
| **GitOps** | ❌ 0% | ✅ ArgoCD | ✅ Multi-cluster | **100%** |
| **Service Mesh** | ❌ 0% | ✅ Linkerd | — | **85%** |
| Cloud Design Patterns | ✅ 70% | ✅ Circuit Breaker | — | **85%** |
| Artifact Management | ⚠️ 30% | Docker Hub | — | **70%** |

### Estimación global

```
AHORA            ░░░░░░░░░░░░░░░░░░░░░░   ~40%
TRAS FASE 1      ████████████████░░░░░░   ~70%
TRAS FASE 2+3    ████████████████████░░   ~88%
```

---

## 5. Fase 1 — Completar Stack Local

**Duración:** 2-3 semanas  
**Costo:** $0  
**Resultado:** K3s local con stack DevOps completo

---

### 5.1 Loki + Promtail (Centralización de Logs)

**¿Qué agrega?** Los logs de todos los pods recolectados y consultables en Grafana.

```bash
# Agregar repo de Grafana (ya lo tienes de Prometheus)
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Instalar Loki stack (Loki + Promtail)
helm install loki grafana/loki-stack \
    --namespace monitoring \
    --set grafana.enabled=false \
    --set prometheus.enabled=false \
    --set loki.persistence.enabled=true \
    --set loki.persistence.size=5Gi

# Verificar
kubectl get pods -n monitoring | grep loki
```

**Agregar Loki como datasource en Grafana:**
1. Grafana UI → Configuration → Data Sources → Add
2. Type: Loki
3. URL: `http://loki:3100`
4. Save & Test

**Query de ejemplo en Grafana/Loki:**
```logql
# Todos los errores del namespace ecommerce
{namespace="ecommerce"} |= "ERROR"

# Logs del pod de la app en los últimos 30 min
{app="ecommerce-app", namespace="ecommerce"}

# Rate de logs de error
rate({namespace="ecommerce"} |= "ERROR" [5m])
```

---

### 5.2 ArgoCD (GitOps)

**¿Qué agrega?** El cluster K8s se sincroniza automáticamente con el repositorio de GitHub. Cualquier cambio en `k8s/` en el repo se aplica solo.

```bash
# Instalar ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Esperar que todos los pods estén ready
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# Exponer la UI via NodePort
kubectl patch svc argocd-server -n argocd \
    -p '{"spec":{"type":"NodePort","ports":[{"port":443,"nodePort":30443}]}}'

# Obtener la contraseña inicial
kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 -d

# Acceder en: https://192.168.0.119:30443
# Usuario: admin
# Password: (el que obtuviste arriba)
```

**Crear la Application que sincroniza el proyecto:**
```yaml
# argocd-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ecommerce
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/ITZAN44/Ecommerce-Proyecto-BD.git
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: ecommerce
  syncPolicy:
    automated:
      prune: true        # Elimina recursos que ya no están en Git
      selfHeal: true     # Revierte cambios manuales en el cluster
    syncOptions:
      - CreateNamespace=true
```

```bash
kubectl apply -f argocd-app.yaml

# Ver estado en CLI
argocd app get ecommerce
argocd app sync ecommerce
```

**Flujo GitOps resultante:**
```
git push origin main  →  GitHub  →  ArgoCD detecta cambio  →  kubectl apply automático
```

---

### 5.3 HashiCorp Vault (Gestión de Secretos)

**¿Qué agrega?** Secretos centralizados, sin passwords hardcodeados en manifiestos ni en código.

```bash
# Instalar Vault con Helm
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

helm install vault hashicorp/vault \
    --namespace vault \
    --create-namespace \
    --set "server.dev.enabled=true" \
    --set "ui.enabled=true" \
    --set "ui.serviceType=NodePort" \
    --set "ui.nodePort=30820"

# Verificar
kubectl get pods -n vault

# Acceder UI: http://192.168.0.119:30820
# Token dev: root
```

**Guardar secretos del proyecto:**
```bash
# Entrar al pod de Vault
kubectl exec -it vault-0 -n vault -- vault login root

# Guardar credenciales de la base de datos
vault kv put secret/ecommerce/database \
    host="postgres-service" \
    port="5432" \
    database="ecommerce_db" \
    username="postgres" \
    password="tu_password_real"

# Guardar credenciales de sesión
vault kv put secret/ecommerce/app \
    session_secret="un_secreto_muy_largo_y_seguro" \
    jwt_secret="otro_secreto_para_jwt"

# Leer un secreto
vault kv get secret/ecommerce/database
```

**Integrar Vault con K8s (Vault Agent Injector):**
```yaml
# Anotaciones en el Deployment para que Vault inyecte secretos automáticamente
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "ecommerce-app"
        vault.hashicorp.com/agent-inject-secret-database: "secret/ecommerce/database"
```

---

### 5.4 Linkerd (Service Mesh)

**¿Qué agrega?** mTLS automático entre todos los pods, métricas de servicio a servicio, circuit breaker.  
**¿Por qué Linkerd y no Istio?** Linkerd usa ~300MB de RAM. Istio necesita >2GB. Con 4GB de RAM local, Linkerd es la elección correcta.

```bash
# Instalar Linkerd CLI
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
export PATH=$PATH:~/.linkerd2/bin

# Verificar prerequisitos del cluster
linkerd check --pre

# Instalar control plane
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -

# Verificar instalación
linkerd check

# Inyectar Linkerd en el namespace ecommerce (mTLS automático)
kubectl annotate namespace ecommerce linkerd.io/inject=enabled
kubectl rollout restart deployment -n ecommerce

# Ver métricas de tráfico en tiempo real
linkerd viz install | kubectl apply -f -
linkerd viz dashboard &
# UI disponible en http://localhost:50750
```

**Resultado:** Todo el tráfico entre pods en el namespace `ecommerce` estará cifrado con mTLS automáticamente.

---

### 5.5 GitHub Actions (Segundo Pipeline CI/CD)

**¿Qué agrega?** Un segundo pipeline paralelo a Jenkins, directamente en GitHub. Demuestra conocimiento de múltiples herramientas CI/CD.

```yaml
# .github/workflows/ci.yml
name: CI — Build & Test

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout código
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Instalar dependencias
        run: npm ci

      - name: Build de la aplicación
        run: npm run build

      - name: Build imagen Docker
        run: docker build -t ecommerce-app:${{ github.sha }} .

      - name: Login a Docker Hub
        if: github.ref == 'refs/heads/main'
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_TOKEN }}

      - name: Push imagen a Docker Hub
        if: github.ref == 'refs/heads/main'
        run: |
          docker tag ecommerce-app:${{ github.sha }} ${{ secrets.DOCKER_USERNAME }}/ecommerce-app:latest
          docker tag ecommerce-app:${{ github.sha }} ${{ secrets.DOCKER_USERNAME }}/ecommerce-app:${{ github.sha }}
          docker push ${{ secrets.DOCKER_USERNAME }}/ecommerce-app:latest
          docker push ${{ secrets.DOCKER_USERNAME }}/ecommerce-app:${{ github.sha }}

      - name: Notificar éxito
        if: success()
        run: echo "✅ Build exitoso — SHA ${{ github.sha }}"
```

**Archivo en el repo:** `.github/workflows/ci.yml`

---

### Checklist Fase 1

```
□ Loki + Promtail instalado → logs visibles en Grafana
□ ArgoCD instalado → app "ecommerce" sincronizando desde GitHub
□ Vault instalado → secretos del proyecto almacenados
□ Linkerd instalado → mTLS activo en namespace ecommerce
□ GitHub Actions configurado → build + push a Docker Hub en cada push
□ Documentación actualizada en devops-local/
```

---

## 6. Fase 2 — Oracle Cloud con Terraform

**Duración:** 3-4 semanas  
**Costo:** $0 (Always Free)  
**Resultado:** Infraestructura real en la nube provisionada con Terraform

---

### 6.1 Crear Cuenta Oracle Cloud

1. Ir a [cloud.oracle.com](https://cloud.oracle.com)
2. Clic en "Start for free"
3. Completar registro (correo, país, nombre)
4. Ingresar tarjeta de crédito — **NO se cobra nada con Always Free**
5. Seleccionar región home — recomendado: `us-ashburn-1` (mayor disponibilidad)
6. Activar cuenta (puede tardar 30 minutos)

**Configurar billing alert en $0:**
```
Oracle Console → Billing → Budgets → Create Budget
Amount: $1 (te alertará si algún recurso de pago aparece)
```

---

### 6.2 Instalar y Configurar Terraform

```bash
# En WSL Ubuntu (donde ya tienes Ansible)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y

# Verificar
terraform version

# Instalar OCI CLI
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Configurar credenciales Oracle
oci setup config
# Te pedirá: User OCID, Tenancy OCID, Region, ruta a clave privada
```

---

### 6.3 Estructura del Proyecto Terraform

```
terraform/
├── main.tf               # Configuración principal y provider
├── variables.tf          # Variables del proyecto
├── outputs.tf            # Outputs (IPs, IDs de recursos)
├── terraform.tfvars      # Valores de las variables (NO subir a Git)
├── .gitignore            # Ignorar .tfstate, .tfvars, .terraform/
└── modules/
    ├── network/          # VCN, subnets, security lists
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── compute/          # VMs ARM
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── k3s/              # Scripts de bootstrap de K3s
        └── install.sh
```

---

### 6.4 Terraform — Código Principal

**`main.tf`:**
```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Módulo de red
module "network" {
  source = "./modules/network"
  
  compartment_id = var.compartment_id
  vcn_cidr       = "10.0.0.0/16"
  project_name   = var.project_name
}

# Módulo de compute (VMs ARM)
module "compute" {
  source = "./modules/compute"
  
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  subnet_id           = module.network.public_subnet_id
  ssh_public_key      = var.ssh_public_key
  project_name        = var.project_name
}
```

**`modules/compute/main.tf`:**
```hcl
# VM ARM 1 — Control Plane de K3s
resource "oci_core_instance" "k3s_server" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.project_name}-k3s-server"
  shape               = "VM.Standard.A1.Flex"   # ARM, Always Free

  shape_config {
    ocpus         = 2    # 2 OCPUs del total de 4
    memory_in_gbs = 12   # 12 GB del total de 24
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id  # Ubuntu 22.04 ARM
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
      k3s_role = "server"
    }))
  }

  tags = {
    Project = var.project_name
    Role    = "k3s-server"
  }
}

# VM ARM 2 — Worker de K3s
resource "oci_core_instance" "k3s_agent" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.project_name}-k3s-agent"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 2
    memory_in_gbs = 12
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}
```

**`outputs.tf`:**
```hcl
output "k3s_server_public_ip" {
  description = "IP pública del K3s control plane"
  value       = module.compute.k3s_server_ip
}

output "k3s_agent_public_ip" {
  description = "IP pública del K3s worker"
  value       = module.compute.k3s_agent_ip
}

output "ssh_command" {
  description = "Comando para conectarse al servidor"
  value       = "ssh -i ~/.ssh/oracle ubuntu@${module.compute.k3s_server_ip}"
}
```

---

### 6.5 Flujo de trabajo Terraform

```bash
# 1. Inicializar (descarga provider OCI)
terraform init

# 2. Previsualizar cambios — qué se va a crear
terraform plan

# 3. Aplicar — crear la infraestructura
terraform apply

# Output esperado:
# Apply complete! Resources: 8 added, 0 changed, 0 destroyed.
# 
# Outputs:
# k3s_server_public_ip = "132.226.X.X"
# ssh_command = "ssh -i ~/.ssh/oracle ubuntu@132.226.X.X"

# 4. Conectarse al servidor
ssh -i ~/.ssh/oracle ubuntu@$(terraform output -raw k3s_server_public_ip)

# 5. Destruir si ya no necesitas los recursos
terraform destroy
```

---

### 6.6 Instalar K3s en Oracle Cloud con Ansible

Una vez Terraform crea las VMs, Ansible las configura (reutilizando los roles que ya tienes):

```bash
# Actualizar inventory con las IPs de Oracle
cat > ~/ecommerce-ansible/ansible/inventory/oracle.ini << EOF
[oracle_servers]
k3s-server ansible_host=$(terraform output -raw k3s_server_public_ip) ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/oracle
k3s-agent  ansible_host=$(terraform output -raw k3s_agent_public_ip)  ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/oracle
EOF

# Ejecutar playbook de K3s en los servidores de Oracle
ansible-playbook -i inventory/oracle.ini playbooks/install-k3s.yml
```

---

### 6.7 ArgoCD Multi-cluster (Local + Oracle)

Una de las cosas más impresionantes para un portfolio: **un solo ArgoCD gestionando dos clusters**.

```bash
# En ArgoCD local, registrar el cluster de Oracle
argocd cluster add oracle-k3s \
    --kubeconfig ~/.kube/oracle-config \
    --name oracle-cloud

# Crear Application que despliega en Oracle
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ecommerce-oracle
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/ITZAN44/Ecommerce-Proyecto-BD.git
    targetRevision: main
    path: k8s
  destination:
    server: https://$(terraform output -raw k3s_server_public_ip):6443
    namespace: ecommerce
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

---

### Checklist Fase 2

```
□ Cuenta Oracle Cloud creada (Always Free activado)
□ OCI CLI configurado y autenticado
□ Terraform instalado en WSL
□ terraform apply exitoso — 2 VMs ARM creadas
□ K3s instalado en Oracle con Ansible
□ Aplicación desplegada en Oracle cluster
□ ArgoCD gestionando ambos clusters (local + Oracle)
□ Object Storage configurado para backups de BD
□ Load Balancer de Oracle exponiendo la app con IP pública
```

---

## 7. Fase 3 — Serverless y Extras

**Duración:** 1-2 semanas  
**Costo:** $0  
**Resultado:** Cobertura de Serverless en el roadmap

---

### 7.1 Cloudflare Workers (Serverless real)

**¿Qué es?** Funciones JavaScript ejecutadas en la red global de Cloudflare. 100,000 requests/día gratis.

```bash
# Instalar Wrangler (CLI de Cloudflare Workers)
npm install -g wrangler

# Autenticarse
wrangler login

# Crear un Worker de ejemplo (health proxy)
mkdir ecommerce-worker && cd ecommerce-worker
wrangler init
```

**`src/index.js` — Worker que hace proxy con headers de seguridad:**
```javascript
export default {
  async fetch(request, env) {
    // Redirigir al servidor Oracle o local
    const BACKEND_URL = env.BACKEND_URL || 'http://132.226.X.X';
    
    const url = new URL(request.url);
    const backendRequest = new Request(`${BACKEND_URL}${url.pathname}`, request);
    
    const response = await fetch(backendRequest);
    
    // Agregar headers de seguridad
    const newHeaders = new Headers(response.headers);
    newHeaders.set('X-Frame-Options', 'DENY');
    newHeaders.set('X-Content-Type-Options', 'nosniff');
    newHeaders.set('Referrer-Policy', 'strict-origin-when-cross-origin');
    newHeaders.set('X-Powered-By', 'Ecommerce DevOps Portfolio');
    
    return new Response(response.body, {
      status: response.status,
      headers: newHeaders
    });
  }
};
```

```bash
# Desplegar
wrangler deploy

# Output:
# Published ecommerce-worker (0.5 sec)
# https://ecommerce-worker.tu-usuario.workers.dev
```

---

### 7.2 Vercel (Frontend Deploy Automático)

**¿Qué es?** Despliega Astro.js automáticamente en cada push a GitHub. HTTPS incluido, CDN global.

```bash
# Instalar Vercel CLI
npm i -g vercel

# En la carpeta del proyecto
vercel

# Seguir el wizard:
# → Set up and deploy: Y
# → Link to existing project: N
# → Project name: ecommerce-portfolio
# → Directory: ./

# Para deploys automáticos: conectar GitHub en vercel.com/dashboard
```

**Esto agrega a tu CI/CD:**
```
git push origin main
    ↓
GitHub Actions (build + Docker Hub)     ← ya lo tienes
    +
Vercel Deploy automático (frontend CDN) ← nuevo
    +
Jenkins + ArgoCD (K8s deploy)           ← ya lo tienes
```

---

## 8. ¿Vale para un Portfolio?

### Comparativa real

| Criterio | Portfolio con AWS | Este portfolio (gratis) | Diferencia |
|----------|------------------|------------------------|------------|
| K8s real funcionando | ✅ | ✅ (K3s) | Ninguna conceptualmente |
| Terraform con nube real | ✅ AWS | ✅ Oracle Cloud | Proveedor diferente, concepto idéntico |
| GitOps con ArgoCD | ✅ | ✅ | Idéntico |
| CI/CD automatizado | ✅ | ✅ Jenkins + GH Actions | Mejor (dos pipelines) |
| Monitoreo completo | ✅ | ✅ Prometheus+Grafana+Loki | Idéntico |
| Secret Management | ✅ | ✅ Vault | Idéntico |
| Service Mesh | ✅ | ✅ Linkerd | Ligero pero válido |
| Serverless demostrado | ✅ Lambda | ✅ Cloudflare Workers | Concepto idéntico |
| **Costo mensual** | **$50-150/mes** | **$0/mes** | ✅ Tú ganas |

### Cómo presentarlo en entrevistas

**Lo que dices (verdad al 100%):**
> "Tengo un proyecto de ecommerce con stack DevOps completo. La infraestructura está provisionada con Terraform sobre Oracle Cloud (Always Free). K3s como plataforma de orquestación con dos clusters — local y nube — gestionados por ArgoCD en modo GitOps. Pipeline CI/CD con Jenkins y GitHub Actions. Observabilidad con Prometheus, Grafana y Loki. Gestión de secretos con Vault. Service mesh con Linkerd para mTLS entre microservicios."

**Cuando pregunten por AWS:**
> "La experiencia en Oracle Cloud cubre los mismos conceptos de cloud computing: VMs, redes virtuales, almacenamiento de objetos, balanceadores. Los comandos cambian pero la arquitectura es idéntica. Terraform abstrae esas diferencias con providers."

---

## 9. Checklist Final

### Stack local completo
```
□ Docker + Compose                     ✅ YA TIENES
□ K3s con 2 réplicas + PVC             ✅ YA TIENES
□ Jenkins CI/CD (9 stages)             ✅ YA TIENES
□ Ansible (4 roles + playbook maestro) ✅ YA TIENES
□ Nginx reverse proxy                  ✅ YA TIENES
□ Prometheus + Grafana                 ✅ YA TIENES
□ Loki + Promtail (logs)               □ FASE 1
□ ArgoCD (GitOps)                      □ FASE 1
□ HashiCorp Vault (secretos)           □ FASE 1
□ Linkerd (service mesh)               □ FASE 1
□ GitHub Actions (segundo pipeline)    □ FASE 1
```

### Nube Oracle Cloud
```
□ Cuenta Oracle Cloud Always Free      □ FASE 2
□ Terraform instalado + OCI CLI        □ FASE 2
□ VMs ARM creadas con Terraform        □ FASE 2
□ K3s cloud con Ansible                □ FASE 2
□ ArgoCD multi-cluster                 □ FASE 2
□ Object Storage para backups          □ FASE 2
```

### Serverless y extras
```
□ Cloudflare Workers desplegado        □ FASE 3
□ Vercel conectado a GitHub            □ FASE 3
```

### Documentación portfolio
```
□ README.md del proyecto actualizado   □ FINAL
□ Diagrama de arquitectura             □ FINAL
□ Video/screenshots de las UIs         □ FINAL
   - ArgoCD mostrando sync automático
   - Grafana con dashboards de K8s
   - Grafana/Loki mostrando logs
   - Vault UI con secretos
   - Jenkins pipeline exitoso
   - Terraform plan + apply output
```

---

## Resumen ejecutivo

| | Detalle |
|-|---------|
| **Costo total** | $0 |
| **Duración estimada** | 6-8 semanas |
| **Cobertura roadmap.sh/devops** | ~88% |
| **Herramientas demostradas** | 20+ |
| **Clusters K8s** | 2 (local + Oracle Cloud) |
| **Pipelines CI/CD** | 2 (Jenkins + GitHub Actions) |
| **Diferencia vs portfolio con AWS** | Solo el proveedor cloud — todo lo demás es idéntico |

---

*Creado: Marzo 2026 — Plan sustituto de migracion.md (AWS) para portfolio DevOps sin costo*
