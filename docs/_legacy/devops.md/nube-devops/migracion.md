# 🚀 ROADMAP DE MIGRACIÓN A AWS & COMPLETAR STACK DEVOPS

**Fecha de creación:** 19 de Febrero, 2026  
**Proyecto:** Ecommerce - Migración a Cloud Native (AWS)  
**Estado actual:** Local VM (Ubuntu 24.04) → **Destino:** AWS Cloud + DevOps Completo  
**Duración estimada:** 4-6 meses  

---

## 📋 TABLA DE CONTENIDOS

1. [Contexto y Justificación](#contexto)
2. [Estado Actual vs Estado Objetivo](#estado-actual)
3. [Fase 1: Cloud Fundamentals (1-2 meses)](#fase1)
4. [Fase 2: IaC con Terraform (2-3 semanas)](#fase2)
5. [Fase 3: Completar Observabilidad (2-3 semanas)](#fase3)
6. [Fase 4: GitOps & Seguridad (1 mes)](#fase4)
7. [Fase 5: Kubernetes Avanzado (Opcional)](#fase5)
8. [Cronograma y Recursos](#cronograma)
9. [Costos Estimados](#costos)
10. [Checklist de Validación](#checklist)

---

## 🎯 CONTEXTO Y JUSTIFICACIÓN {#contexto}

### ¿Por qué migrar a AWS?

**Limitaciones actuales (VM local):**
- ❌ No escalable (1 VM con recursos fijos)
- ❌ No hay alta disponibilidad (single point of failure)
- ❌ Mantenimiento manual de infraestructura
- ❌ Backup y disaster recovery limitados
- ❌ Sin experiencia cloud (requerida en 80%+ trabajos DevOps)

**Beneficios de AWS:**
- ✅ Escalabilidad automática (horizontal y vertical)
- ✅ Alta disponibilidad (multi-AZ)
- ✅ Servicios gestionados (RDS, EKS, ALB)
- ✅ Infraestructura como código (Terraform)
- ✅ Pay-as-you-go (optimización de costos)
- ✅ Experiencia cloud real para portfolio

### Trabajo actual reutilizable

| Componente | Reutilización | Ajustes necesarios |
|------------|---------------|-------------------|
| Código Astro.js | 100% | Ninguno |
| Dockerfile | 95% | Registry URL (ECR) |
| Manifiestos K8s | 90% | Ingress annotations, image URIs |
| Jenkinsfile | 80% | Comandos AWS CLI |
| Ansible roles | 70% | Complementar con Terraform |
| SQL schemas/functions | 100% | Ninguno |
| Prometheus/Grafana configs | 60% | Data sources AWS |

---

## 📊 ESTADO ACTUAL VS ESTADO OBJETIVO {#estado-actual}

### Estado Actual (Local)

```
┌─────────────────────────────────────┐
│   VM Ubuntu 24.04 (192.168.0.119)  │
│                                     │
│  ┌─────────────────────────────┐   │
│  │   K3s Kubernetes            │   │
│  │   - 2 replicas app          │   │
│  │   - 1 PostgreSQL pod        │   │
│  │   - Traefik Ingress         │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │   Jenkins (Docker)          │   │
│  │   - Poll SCM cada 2 min     │   │
│  │   - Build + Deploy          │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │   Prometheus + Grafana      │   │
│  │   - 13 targets              │   │
│  │   - NodePort 30080          │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### Estado Objetivo (AWS)

```
┌──────────────────────────────────────────────────────────────────┐
│                        AWS Cloud (us-east-1)                      │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                     VPC (10.0.0.0/16)                     │   │
│  │                                                            │   │
│  │  ┌─────────────────┐  ┌─────────────────┐               │   │
│  │  │  Public Subnet  │  │  Public Subnet  │               │   │
│  │  │  (us-east-1a)   │  │  (us-east-1b)   │               │   │
│  │  │                 │  │                 │               │   │
│  │  │  ┌───────────┐  │  │  ┌───────────┐  │               │   │
│  │  │  │    ALB    │◄─┼──┼──►   ALB     │  │               │   │
│  │  │  └─────┬─────┘  │  │  └─────┬─────┘  │               │   │
│  │  └────────┼────────┘  └────────┼────────┘               │   │
│  │           │                    │                         │   │
│  │  ┌────────┼────────────────────┼────────┐               │   │
│  │  │        ▼  Private Subnet    ▼        │               │   │
│  │  │  ┌────────────────────────────────┐  │               │   │
│  │  │  │   EKS Cluster (K8s managed)    │  │               │   │
│  │  │  │                                 │  │               │   │
│  │  │  │  ┌──────────────────────────┐  │  │               │   │
│  │  │  │  │  Ecommerce Deployment    │  │  │               │   │
│  │  │  │  │  - 3 replicas (auto)     │  │  │               │   │
│  │  │  │  │  - Images from ECR       │  │  │               │   │
│  │  │  │  └──────────────────────────┘  │  │               │   │
│  │  │  │                                 │  │               │   │
│  │  │  │  ┌──────────────────────────┐  │  │               │   │
│  │  │  │  │  Prometheus + Grafana    │  │  │               │   │
│  │  │  │  │  + Loki (logs)           │  │  │               │   │
│  │  │  │  └──────────────────────────┘  │  │               │   │
│  │  │  │                                 │  │               │   │
│  │  │  │  ┌──────────────────────────┐  │  │               │   │
│  │  │  │  │  ArgoCD (GitOps)         │  │  │               │   │
│  │  │  │  │  - Sync from GitHub      │  │  │               │   │
│  │  │  │  └──────────────────────────┘  │  │               │   │
│  │  │  └─────────────────────────────────┘  │               │   │
│  │  └────────────────────────────────────────┘               │   │
│  │                                                            │   │
│  │  ┌────────────────────────────────────────┐               │   │
│  │  │  RDS PostgreSQL (Multi-AZ)             │               │   │
│  │  │  - db.t3.micro (production: t3.medium)  │               │   │
│  │  │  - Automated backups                    │               │   │
│  │  └────────────────────────────────────────┘               │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Servicios Gestionados AWS                                │   │
│  │  - ECR (Docker registry)                                  │   │
│  │  - Secrets Manager (credenciales)                         │   │
│  │  - CloudWatch (logs + métricas)                           │   │
│  │  - S3 (backups + Terraform state)                         │   │
│  │  - IAM (usuarios, roles, policies)                        │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  CI/CD Pipeline                                            │   │
│  │  GitHub → GitHub Actions → ECR → ArgoCD → EKS            │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

---

## 🌩️ FASE 1: CLOUD FUNDAMENTALS (1-2 MESES) - CRÍTICO {#fase1}

**Objetivo:** Familiarización con AWS y migración lift-and-shift

### Semana 1-2: AWS Basics & Cuenta

#### 1.1. Crear cuenta AWS Free Tier

**Pasos:**
1. Ir a https://aws.amazon.com/free/
2. Crear cuenta con email
3. Verificar tarjeta (no se cobra si solo usas free tier)
4. Habilitar MFA (Multi-Factor Authentication) para seguridad
5. Crear presupuesto (Budget) de $10/mes para alertas

**Recursos gratuitos primer año:**
- EC2: 750 hrs/mes t2.micro o t3.micro
- RDS: 750 hrs/mes db.t2.micro o db.t3.micro
- S3: 5 GB storage
- ALB: 750 hrs/mes (primeros 15 GB de datos)
- CloudWatch: 10 métricas personalizadas

**Documentación:**
```bash
# Crear archivo de seguimiento
touch aws-account-setup.md

# Anotar:
# - Account ID: 123456789012
# - Root email: tu-email@example.com
# - MFA habilitado: [✅]
# - Billing alerts: [✅]
```

#### 1.2. Configurar AWS CLI

**Instalación en Windows:**
```powershell
# Descargar instalador desde:
# https://aws.amazon.com/cli/

# Verificar instalación
aws --version
# Salida esperada: aws-cli/2.x.x Python/3.x.x Windows/10
```

**Instalación en VM Ubuntu:**
```bash
# Método recomendado (binario oficial)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verificar
aws --version
```

**Configuración de credenciales:**
```bash
# Crear usuario IAM con acceso programático
# AWS Console → IAM → Users → Add User
# - User name: devops-admin
# - Access type: Programmatic access
# - Attach policy: AdministratorAccess (solo para aprendizaje)

# Configurar localmente
aws configure
# AWS Access Key ID: AKIAIOSFODNN7EXAMPLE
# AWS Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
# Default region name: us-east-1
# Default output format: json

# Probar conexión
aws sts get-caller-identity
# Debe mostrar tu Account ID y User ARN
```

#### 1.3. IAM (Identity and Access Management)

**Conceptos clave:**
- **User:** Identidad para personas
- **Role:** Identidad para servicios AWS (EC2, EKS, Lambda)
- **Policy:** Documento JSON con permisos
- **Group:** Conjunto de usuarios con mismos permisos

**Crear estructura IAM:**

```bash
# 1. Crear grupo para DevOps
aws iam create-group --group-name DevOps

# 2. Adjuntar políticas
aws iam attach-group-policy \
  --group-name DevOps \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# 3. Crear usuario y agregarlo al grupo
aws iam create-user --user-name devops-admin
aws iam add-user-to-group --user-name devops-admin --group-name DevOps

# 4. Crear access key
aws iam create-access-key --user-name devops-admin > devops-admin-keys.json
```

**Política personalizada para EKS (ejemplo):**

Crear archivo `eks-admin-policy.json`:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*",
        "ec2:DescribeInstances",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    }
  ]
}
```

```bash
# Crear política
aws iam create-policy \
  --policy-name EKSAdminPolicy \
  --policy-document file://eks-admin-policy.json
```

#### 1.4. VPC (Virtual Private Cloud)

**Concepto:** Red virtual aislada en AWS, equivalente a tu red local 192.168.0.0/24

**Arquitectura objetivo:**
```
VPC: 10.0.0.0/16 (65,536 IPs)
├── Public Subnet 1 (us-east-1a): 10.0.1.0/24
├── Public Subnet 2 (us-east-1b): 10.0.2.0/24
├── Private Subnet 1 (us-east-1a): 10.0.10.0/24
└── Private Subnet 2 (us-east-1b): 10.0.11.0/24
```

**Crear VPC con la consola (método visual):**

1. AWS Console → VPC → Create VPC
2. Seleccionar "VPC and more" (crea todo automáticamente)
3. Configuración:
   - Name: `ecommerce-vpc`
   - IPv4 CIDR: `10.0.0.0/16`
   - Availability Zones: 2
   - Public subnets: 2
   - Private subnets: 2
   - NAT gateways: 0 (para ahorrar, usar 1 en producción)
   - VPC endpoints: None

**Crear VPC con AWS CLI (método avanzado):**

```bash
# 1. Crear VPC
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=ecommerce-vpc}]' \
  --query 'Vpc.VpcId' \
  --output text)

echo "VPC ID: $VPC_ID"

# 2. Habilitar DNS
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames

# 3. Crear Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=ecommerce-igw}]' \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)

aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID

# 4. Crear subnets públicas
PUBLIC_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=ecommerce-public-1a}]' \
  --query 'Subnet.SubnetId' \
  --output text)

PUBLIC_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=ecommerce-public-1b}]' \
  --query 'Subnet.SubnetId' \
  --output text)

# 5. Crear subnets privadas
PRIVATE_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.10.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=ecommerce-private-1a}]' \
  --query 'Subnet.SubnetId' \
  --output text)

PRIVATE_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.11.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=ecommerce-private-1b}]' \
  --query 'Subnet.SubnetId' \
  --output text)

# 6. Crear tabla de rutas pública
PUBLIC_RT=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=ecommerce-public-rt}]' \
  --query 'RouteTable.RouteTableId' \
  --output text)

aws ec2 create-route --route-table-id $PUBLIC_RT \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID

# 7. Asociar subnets públicas a la tabla de rutas
aws ec2 associate-route-table \
  --subnet-id $PUBLIC_SUBNET_1 \
  --route-table-id $PUBLIC_RT

aws ec2 associate-route-table \
  --subnet-id $PUBLIC_SUBNET_2 \
  --route-table-id $PUBLIC_RT

# 8. Guardar IDs para uso posterior
cat > vpc-config.env << EOF
VPC_ID=$VPC_ID
IGW_ID=$IGW_ID
PUBLIC_SUBNET_1=$PUBLIC_SUBNET_1
PUBLIC_SUBNET_2=$PUBLIC_SUBNET_2
PRIVATE_SUBNET_1=$PRIVATE_SUBNET_1
PRIVATE_SUBNET_2=$PRIVATE_SUBNET_2
PUBLIC_RT=$PUBLIC_RT
EOF
```

### Semana 3-4: EC2 y S3

#### 1.5. EC2 (Elastic Compute Cloud)

**Concepto:** Máquinas virtuales en la nube (equivalente a tu VM Ubuntu local)

**Lanzar instancia EC2 básica:**

```bash
# 1. Crear key pair para SSH
aws ec2 create-key-pair \
  --key-name ecommerce-key \
  --query 'KeyMaterial' \
  --output text > ecommerce-key.pem

chmod 400 ecommerce-key.pem

# 2. Crear Security Group (firewall)
SG_ID=$(aws ec2 create-security-group \
  --group-name ecommerce-sg \
  --description "Security group for ecommerce app" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)

# 3. Permitir SSH (puerto 22)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# 4. Permitir HTTP (puerto 80)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

# 5. Lanzar instancia Ubuntu
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.micro \
  --key-name ecommerce-key \
  --security-group-ids $SG_ID \
  --subnet-id $PUBLIC_SUBNET_1 \
  --associate-public-ip-address \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ecommerce-ec2}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance ID: $INSTANCE_ID"

# 6. Obtener IP pública
aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text

# 7. Conectar por SSH
ssh -i ecommerce-key.pem ubuntu@<PUBLIC_IP>
```

**Instalar Docker en EC2 (igual que VM local):**

```bash
# Una vez conectado a la instancia
sudo apt update
sudo apt install -y docker.io docker-compose
sudo usermod -aG docker ubuntu
newgrp docker
```

#### 1.6. S3 (Simple Storage Service)

**Concepto:** Almacenamiento de objetos (archivos), similar a Google Drive pero para aplicaciones

**Usos en este proyecto:**
- Backups de base de datos
- Assets estáticos (imágenes, CSS, JS)
- Terraform state files
- Logs históricos

**Crear bucket S3:**

```bash
# 1. Crear bucket (nombre debe ser único globalmente)
aws s3 mb s3://ecommerce-backups-$(date +%s)

# O con nombre específico
BUCKET_NAME="ecommerce-backups-itzan44"
aws s3 mb s3://$BUCKET_NAME --region us-east-1

# 2. Habilitar versionado (mantiene versiones antiguas)
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# 3. Subir backup de PostgreSQL
aws s3 cp database/backup_bd_real.sql s3://$BUCKET_NAME/backups/

# 4. Listar archivos
aws s3 ls s3://$BUCKET_NAME/backups/

# 5. Descargar backup
aws s3 cp s3://$BUCKET_NAME/backups/backup_bd_real.sql ./restore.sql
```

**Política de lifecycle (eliminar backups viejos):**

Crear archivo `lifecycle-policy.json`:
```json
{
  "Rules": [
    {
      "Id": "DeleteOldBackups",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "backups/"
      },
      "Expiration": {
        "Days": 30
      }
    }
  ]
}
```

```bash
aws s3api put-bucket-lifecycle-configuration \
  --bucket $BUCKET_NAME \
  --lifecycle-configuration file://lifecycle-policy.json
```

#### 1.7. RDS (Relational Database Service)

**Concepto:** PostgreSQL gestionado (no necesitas instalar/mantener, AWS lo hace)

**Ventajas vs PostgreSQL en K3s:**
- ✅ Backups automáticos
- ✅ Multi-AZ (alta disponibilidad)
- ✅ Réplicas de lectura
- ✅ Actualizaciones automáticas
- ✅ Monitoreo integrado

**Crear instancia RDS PostgreSQL:**

```bash
# 1. Crear subnet group (RDS necesita mínimo 2 subnets en AZs diferentes)
aws rds create-db-subnet-group \
  --db-subnet-group-name ecommerce-db-subnet \
  --db-subnet-group-description "Subnet group for ecommerce DB" \
  --subnet-ids $PRIVATE_SUBNET_1 $PRIVATE_SUBNET_2

# 2. Crear security group para RDS
RDS_SG=$(aws ec2 create-security-group \
  --group-name ecommerce-rds-sg \
  --description "Security group for RDS PostgreSQL" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)

# 3. Permitir conexiones desde pods de EKS (usar CIDR de VPC)
aws ec2 authorize-security-group-ingress \
  --group-id $RDS_SG \
  --protocol tcp \
  --port 5432 \
  --cidr 10.0.0.0/16

# 4. Crear instancia RDS (FREE TIER)
aws rds create-db-instance \
  --db-instance-identifier ecommerce-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 16.1 \
  --master-username postgres \
  --master-user-password "TU_PASSWORD_SEGURO_AQUI" \
  --allocated-storage 20 \
  --vpc-security-group-ids $RDS_SG \
  --db-subnet-group-name ecommerce-db-subnet \
  --backup-retention-period 7 \
  --preferred-backup-window "03:00-04:00" \
  --preferred-maintenance-window "Mon:04:00-Mon:05:00" \
  --publicly-accessible false \
  --storage-encrypted \
  --no-multi-az \
  --db-name ecommerce_db

# 5. Esperar a que esté disponible (tarda ~10 minutos)
aws rds wait db-instance-available \
  --db-instance-identifier ecommerce-db

# 6. Obtener endpoint
DB_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier ecommerce-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

echo "DB Endpoint: $DB_ENDPOINT"
# ecommerce-db.abc123.us-east-1.rds.amazonaws.com
```

**Restaurar backup en RDS:**

```bash
# Desde EC2 o tu máquina local con psql instalado
psql -h $DB_ENDPOINT \
     -U postgres \
     -d ecommerce_db \
     -f database/backup_bd_real.sql
```

### Semana 5-6: ECR y migración de imágenes

#### 1.8. ECR (Elastic Container Registry)

**Concepto:** Docker Hub privado de AWS

**Crear repositorio ECR:**

```bash
# 1. Crear repositorio
aws ecr create-repository \
  --repository-name ecommerce-app \
  --image-scanning-configuration scanOnPush=true \
  --region us-east-1

# 2. Obtener URI del repositorio
ECR_URI=$(aws ecr describe-repositories \
  --repository-names ecommerce-app \
  --query 'repositories[0].repositoryUri' \
  --output text)

echo "ECR URI: $ECR_URI"
# 123456789012.dkr.ecr.us-east-1.amazonaws.com/ecommerce-app

# 3. Login a ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_URI

# 4. Construir imagen (igual que antes)
docker build -t ecommerce-app:1.0.0 -f Dockerfile .

# 5. Tag para ECR
docker tag ecommerce-app:1.0.0 $ECR_URI:1.0.0
docker tag ecommerce-app:1.0.0 $ECR_URI:latest

# 6. Push a ECR
docker push $ECR_URI:1.0.0
docker push $ECR_URI:latest

# 7. Verificar
aws ecr list-images --repository-name ecommerce-app
```

**Modificar Dockerfile para usar ECR (opcional):**

```dockerfile
# Cambio menor - solo si quieres usar ECR Public Registry
# Línea 5 del Dockerfile original
FROM public.ecr.aws/docker/library/node:20-alpine AS builder

# El resto del Dockerfile NO cambia
```

### Semana 7-8: EKS (Elastic Kubernetes Service)

#### 1.9. Migrar de K3s a EKS

**Concepto:** Kubernetes gestionado por AWS (no instalas/mantienes control plane)

**Instalación de herramientas:**

```bash
# 1. Instalar eksctl (CLI para EKS)
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

eksctl version

# 2. Actualizar kubectl (si es necesario)
kubectl version --client

# 3. Instalar aws-iam-authenticator
curl -Lo aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.6.14/aws-iam-authenticator_0.6.14_linux_amd64
chmod +x aws-iam-authenticator
sudo mv aws-iam-authenticator /usr/local/bin/
```

**Crear cluster EKS (método rápido):**

```bash
# Crear archivo de configuración
cat > eks-cluster-config.yaml << 'EOF'
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ecommerce-cluster
  region: us-east-1
  version: "1.28"

vpc:
  id: "vpc-0123456789abcdef0"  # Reemplazar con tu VPC_ID
  subnets:
    private:
      us-east-1a: { id: "subnet-xxx" }  # PRIVATE_SUBNET_1
      us-east-1b: { id: "subnet-yyy" }  # PRIVATE_SUBNET_2
    public:
      us-east-1a: { id: "subnet-www" }  # PUBLIC_SUBNET_1
      us-east-1b: { id: "subnet-zzz" }  # PUBLIC_SUBNET_2

managedNodeGroups:
  - name: workers
    instanceType: t3.medium
    desiredCapacity: 2
    minSize: 2
    maxSize: 4
    volumeSize: 20
    ssh:
      publicKeyName: ecommerce-key
    labels:
      role: worker
    tags:
      Environment: production
      Project: ecommerce

addons:
  - name: vpc-cni
  - name: coredns
  - name: kube-proxy

cloudWatch:
  clusterLogging:
    enableTypes: ["all"]
EOF

# Crear cluster (tarda ~15-20 minutos)
eksctl create cluster -f eks-cluster-config.yaml

# Verificar
kubectl get nodes
# Debe mostrar 2 nodos en Ready
```

**Configurar kubectl para EKS:**

```bash
# eksctl ya configuró kubectl automáticamente
# Verificar contexto
kubectl config current-context

# Manualmente (si es necesario)
aws eks update-kubeconfig \
  --region us-east-1 \
  --name ecommerce-cluster
```

**Migrar manifiestos K8s de K3s a EKS:**

Los manifiestos son casi idénticos, solo cambios menores:

**Antes (K3s - k8s/app-deployment.yaml):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ecommerce-app
  namespace: ecommerce
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ecommerce-app
  template:
    metadata:
      labels:
        app: ecommerce-app
    spec:
      containers:
      - name: ecommerce-app
        image: ecommerce-app:1.0.0  # ← CAMBIAR ESTO
        ports:
        - containerPort: 4321
        env:
        - name: DB_HOST
          value: postgres  # ← CAMBIAR ESTO
```

**Después (EKS - k8s/app-deployment.yaml):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ecommerce-app
  namespace: ecommerce
spec:
  replicas: 3  # Aumentamos a 3 en cloud
  selector:
    matchLabels:
      app: ecommerce-app
  template:
    metadata:
      labels:
        app: ecommerce-app
    spec:
      containers:
      - name: ecommerce-app
        image: 123456789012.dkr.ecr.us-east-1.amazonaws.com/ecommerce-app:1.0.0  # ← ECR
        ports:
        - containerPort: 4321
        env:
        - name: DB_HOST
          value: ecommerce-db.abc123.us-east-1.rds.amazonaws.com  # ← RDS
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: ecommerce_db
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
```

**Antes (K3s - k8s/ingress.yaml):**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ecommerce-ingress
  namespace: ecommerce
  annotations:
    kubernetes.io/ingress.class: traefik  # ← CAMBIAR
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ecommerce-app
            port:
              number: 80
```

**Después (EKS - k8s/ingress.yaml):**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ecommerce-ingress
  namespace: ecommerce
  annotations:
    kubernetes.io/ingress.class: alb  # ← ALB en vez de Traefik
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /api/analytics/dashboard
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ecommerce-app
            port:
              number: 80
```

**Instalar AWS Load Balancer Controller:**

```bash
# 1. Crear IAM policy para el controller
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.0/docs/install/iam_policy.json

aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam-policy.json

# 2. Crear service account
eksctl create iamserviceaccount \
  --cluster=ecommerce-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::123456789012:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# 3. Instalar con Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=ecommerce-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Verificar
kubectl get deployment -n kube-system aws-load-balancer-controller
```

**Desplegar aplicación en EKS:**

```bash
# 1. Crear namespace
kubectl create namespace ecommerce

# 2. Crear secret para DB
kubectl create secret generic db-credentials \
  --from-literal=username=postgres \
  --from-literal=password=TU_PASSWORD_RDS \
  -n ecommerce

# 3. Aplicar manifiestos
kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/app-service.yaml
kubectl apply -f k8s/ingress.yaml

# 4. Esperar a que esté listo
kubectl rollout status deployment/ecommerce-app -n ecommerce

# 5. Obtener URL del ALB (tarda ~2-3 minutos en crear)
kubectl get ingress -n ecommerce
# NAME                 CLASS    HOSTS   ADDRESS                                           PORTS   AGE
# ecommerce-ingress    <none>   *       k8s-ecommerce-xyz-123.us-east-1.elb.amazonaws.com   80      3m

# 6. Probar
curl http://k8s-ecommerce-xyz-123.us-east-1.elb.amazonaws.com/api/analytics/dashboard
```

### Validación Fase 1

**Checklist de completado:**

- [ ] Cuenta AWS creada con MFA habilitado
- [ ] AWS CLI configurado en Windows y Ubuntu
- [ ] IAM configurado (usuario, grupo, políticas)
- [ ] VPC creada con 2 subnets públicas y 2 privadas
- [ ] EC2 lanzada y accesible por SSH
- [ ] S3 bucket creado con backup de DB
- [ ] RDS PostgreSQL creado y datos restaurados
- [ ] ECR repository creado e imagen subida
- [ ] EKS cluster funcionando con 2+ nodos
- [ ] Aplicación desplegada en EKS y accesible via ALB

**Comandos de verificación:**

```bash
# Verificar todo el stack
aws sts get-caller-identity  # IAM
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=ecommerce-vpc"  # VPC
aws rds describe-db-instances --db-instance-identifier ecommerce-db  # RDS
aws ecr list-images --repository-name ecommerce-app  # ECR
eksctl get cluster --name ecommerce-cluster  # EKS
kubectl get all -n ecommerce  # Pods corriendo
```

**Documentación a crear:**

Archivo `fase1-completado.md`:
```markdown
# Fase 1 Completada - Cloud Fundamentals

## Recursos creados

### VPC
- VPC ID: vpc-0123456789abcdef0
- CIDR: 10.0.0.0/16
- Subnets: 4 (2 públicas, 2 privadas)

### RDS
- Endpoint: ecommerce-db.abc123.us-east-1.rds.amazonaws.com
- Engine: PostgreSQL 16.1
- Instance class: db.t3.micro
- Backup retention: 7 días

### EKS
- Cluster name: ecommerce-cluster
- Version: 1.28
- Nodes: 2 t3.medium
- ALB URL: k8s-ecommerce-xyz-123.us-east-1.elb.amazonaws.com

### Costos actuales
- EC2: $0 (free tier)
- RDS: $0 (free tier)
- EKS: $72/mes (control plane)
- Total: ~$72/mes

## Próximos pasos
- Fase 2: Terraform para IaC
```

---

## 🏗️ FASE 2: IaC CON TERRAFORM (2-3 SEMANAS) {#fase2}

**Objetivo:** Automatizar creación de infraestructura con código

### Semana 1: Terraform Basics

#### 2.1. Instalación de Terraform

**En Windows:**
```powershell
# Descargar desde https://www.terraform.io/downloads
# O con chocolatey:
choco install terraform

# Verificar
terraform version
```

**En Ubuntu:**
```bash
# Método oficial
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verificar
terraform version
```

#### 2.2. Estructura de proyecto Terraform

```bash
# Crear estructura
mkdir -p terraform/{modules/{vpc,eks,rds,ecr},environments/{dev,prod}}

# Estructura final:
terraform/
├── main.tf                 # Configuración principal
├── variables.tf            # Variables de entrada
├── outputs.tf              # Outputs que otros pueden usar
├── terraform.tfvars        # Valores de variables (NO commitear)
├── backend.tf              # Configuración de state remoto
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── eks/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── rds/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ecr/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── dev/
    │   ├── main.tf
    │   └── terraform.tfvars
    └── prod/
        ├── main.tf
        └── terraform.tfvars
```

#### 2.3. Provider AWS

**terraform/main.tf:**
```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Ecommerce"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
```

**terraform/variables.tf:**
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ecommerce"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}
```

**terraform/terraform.tfvars:**
```hcl
aws_region   = "us-east-1"
environment  = "dev"
project_name = "ecommerce"
vpc_cidr     = "10.0.0.0/16"
```

#### 2.4. Módulo VPC

**terraform/modules/vpc/main.tf:**
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                           = "${var.project_name}-public-${var.azs[count.index]}"
    "kubernetes.io/role/elb"                       = "1"
    "kubernetes.io/cluster/${var.cluster_name}"    = "shared"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name                                           = "${var.project_name}-private-${var.azs[count.index]}"
    "kubernetes.io/role/internal-elb"              = "1"
    "kubernetes.io/cluster/${var.cluster_name}"    = "shared"
  }
}

# NAT Gateway (para subnets privadas)
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway ? 1 : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = var.enable_nat_gateway ? length(aws_subnet.private) : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}
```

**terraform/modules/vpc/variables.tf:**
```hcl
variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "cluster_name" {
  description = "EKS cluster name (for subnet tags)"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = false
}
```

**terraform/modules/vpc/outputs.tf:**
```hcl
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}
```

#### 2.5. Módulo RDS

**terraform/modules/rds/main.tf:**
```hcl
# Security Group para RDS
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# Subnet Group para RDS
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = var.postgres_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = true

  db_name  = var.database_name
  username = var.master_username
  password = var.master_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  multi_az               = var.multi_az
  publicly_accessible    = false
  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Name = "${var.project_name}-db"
  }
}
```

**terraform/modules/rds/variables.tf:**
```hcl
variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for RDS"
  type        = list(string)
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "16.1"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Max allocated storage for autoscaling"
  type        = number
  default     = 100
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "ecommerce_db"
}

variable "master_username" {
  description = "Master username"
  type        = string
  default     = "postgres"
}

variable "master_password" {
  description = "Master password"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = false
}
```

**terraform/modules/rds/outputs.tf:**
```hcl
output "endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
}

output "address" {
  description = "RDS address"
  value       = aws_db_instance.main.address
}

output "port" {
  description = "RDS port"
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}
```

#### 2.6. State Management con S3 + DynamoDB

**terraform/backend.tf:**
```hcl
terraform {
  backend "s3" {
    bucket         = "ecommerce-terraform-state-itzan44"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

**Crear recursos para backend (ejecutar una sola vez):**

```bash
# 1. Crear bucket S3 para state
aws s3 mb s3://ecommerce-terraform-state-itzan44 --region us-east-1

# 2. Habilitar versionado
aws s3api put-bucket-versioning \
  --bucket ecommerce-terraform-state-itzan44 \
  --versioning-configuration Status=Enabled

# 3. Habilitar encriptación
aws s3api put-bucket-encryption \
  --bucket ecommerce-terraform-state-itzan44 \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# 4. Crear tabla DynamoDB para locks
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

#### 2.7. Uso de Terraform

**Comandos básicos:**

```bash
cd terraform/

# 1. Inicializar (primera vez)
terraform init

# 2. Formatear código
terraform fmt -recursive

# 3. Validar sintaxis
terraform validate

# 4. Plan (ver qué va a crear)
terraform plan

# 5. Aplicar cambios
terraform apply

# 6. Ver outputs
terraform output

# 7. Destruir (CUIDADO)
terraform destroy

# 8. Ver estado
terraform state list
terraform state show aws_vpc.main
```

**terraform/main.tf (usando módulos):**
```hcl
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  cluster_name       = "${var.project_name}-cluster"
  enable_nat_gateway = false  # false para ahorrar $$$
}

module "rds" {
  source = "./modules/rds"

  project_name    = var.project_name
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = module.vpc.vpc_cidr
  subnet_ids      = module.vpc.private_subnet_ids
  master_password = var.db_password
  multi_az        = false  # false para free tier
}

# ... más módulos
```

**terraform/outputs.tf:**
```hcl
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.endpoint
  sensitive   = true
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}
```

### Validación Fase 2

**Checklist:**

- [ ] Terraform instalado y configurado
- [ ] Backend remoto (S3 + DynamoDB) funcionando
- [ ] Módulo VPC creado y probado
- [ ] Módulo RDS creado y probado
- [ ] Módulo EKS creado (similar a VPC/RDS)
- [ ] `terraform plan` sin errores
- [ ] Infraestructura recreada con `terraform apply`
- [ ] Documentación de módulos creada

**Comandos de verificación:**
```bash
terraform state list
terraform output vpc_id
terraform output rds_endpoint
```

---

## 📊 FASE 3: COMPLETAR OBSERVABILIDAD (2-3 SEMANAS) {#fase3}

**Objetivo:** Logging, alerting y dashboards avanzados

### Semana 1: Logging Centralizado

#### 3.1. Opción 1: Grafana Loki (Recomendado - más ligero)

**Instalar Loki con Helm:**

```bash
# 1. Agregar repo de Grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# 2. Crear namespace
kubectl create namespace monitoring

# 3. Crear valores personalizados
cat > loki-values.yaml << 'EOF'
loki:
  auth_enabled: false
  commonConfig:
    replication_factor: 1
  storage:
    bucketNames:
      chunks: loki-chunks
      ruler: loki-ruler
    type: filesystem

singleBinary:
  replicas: 1
  persistence:
    enabled: true
    size: 10Gi

# Desactivar componentes no necesarios para single-binary
ingester:
  enabled: false
distributor:
  enabled: false
querier:
  enabled: false
queryFrontend:
  enabled: false
queryScheduler:
  enabled: false
compactor:
  enabled: false
indexGateway:
  enabled: false
bloomCompactor:
  enabled: false
bloomGateway:
  enabled: false
EOF

# 4. Instalar Loki
helm install loki grafana/loki \
  -n monitoring \
  -f loki-values.yaml

# 5. Instalar Promtail (agente para enviar logs)
cat > promtail-values.yaml << 'EOF'
config:
  clients:
    - url: http://loki:3100/loki/api/v1/push

# Montar logs de pods
daemonset:
  enabled: true
EOF

helm install promtail grafana/promtail \
  -n monitoring \
  -f promtail-values.yaml

# 6. Verificar
kubectl get pods -n monitoring -l app.kubernetes.io/name=loki
kubectl get pods -n monitoring -l app.kubernetes.io/name=promtail
```

**Integrar Loki con Grafana:**

```bash
# 1. Acceder a Grafana (ya instalado en Fase 1)
kubectl port-forward -n monitoring svc/grafana 30080:80

# 2. Ir a Configuration → Data Sources → Add data source → Loki
# URL: http://loki:3100
# Save & Test

# 3. Crear dashboard para logs
# Ir a Explore → Seleccionar Loki
# Usar consulta LogQL:
# {namespace="ecommerce", app="ecommerce-app"}
```

**Queries útiles en Loki:**

```logql
# Todos los logs de la app
{namespace="ecommerce", app="ecommerce-app"}

# Solo errores
{namespace="ecommerce", app="ecommerce-app"} |= "error"

# Logs de PostgreSQL
{namespace="ecommerce", app="postgres"}

# Rate de errores
sum(rate({namespace="ecommerce"} |= "error" [5m]))
```

#### 3.2. Opción 2: ELK Stack (Elasticsearch, Logstash, Kibana)

**Instalar con Helm (más pesado, para producción):**

```bash
# 1. Agregar repo Elastic
helm repo add elastic https://helm.elastic.co
helm repo update

# 2. Instalar Elasticsearch
helm install elasticsearch elastic/elasticsearch \
  -n monitoring \
  --set replicas=1 \
  --set resources.requests.memory=2Gi \
  --set persistence.enabled=true

# 3. Instalar Kibana
helm install kibana elastic/kibana \
  -n monitoring \
  --set service.type=NodePort \
  --set service.nodePort=30081

# 4. Instalar Filebeat (agente de logs)
helm install filebeat elastic/filebeat \
  -n monitoring

# Acceder a Kibana: http://<NODE_IP>:30081
```

### Semana 2: Alerting

#### 3.3. Alertmanager (Prometheus)

**Configurar alertas en kube-prometheus-stack:**

Crear archivo `prometheus-alerts.yaml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-alerts
  namespace: monitoring
data:
  alerts.yaml: |
    groups:
    - name: ecommerce-alerts
      interval: 30s
      rules:
      # Alerta de CPU alta
      - alert: HighCPUUsage
        expr: |
          sum(rate(container_cpu_usage_seconds_total{namespace="ecommerce"}[5m])) by (pod) > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Pod {{ $labels.pod }} tiene CPU alta"
          description: "CPU: {{ $value | humanizePercentage }}"

      # Alerta de memoria alta
      - alert: HighMemoryUsage
        expr: |
          sum(container_memory_working_set_bytes{namespace="ecommerce"}) by (pod) / 
          sum(container_spec_memory_limit_bytes{namespace="ecommerce"}) by (pod) > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Pod {{ $labels.pod }} tiene memoria alta"
          description: "Memoria: {{ $value | humanizePercentage }}"

      # Alerta de pod caído
      - alert: PodDown
        expr: |
          kube_pod_status_phase{namespace="ecommerce", phase="Running"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Pod {{ $labels.pod }} no está corriendo"

      # Alerta de errores HTTP 500
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m])) by (service) > 10
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Servicio {{ $labels.service }} tiene errores altos"
          description: "Rate: {{ $value }} errors/sec"

      # Alerta de base de datos inaccesible
      - alert: DatabaseDown
        expr: |
          pg_up{namespace="ecommerce"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "PostgreSQL no está accesible"

      # Alerta de disco lleno
      - alert: DiskSpaceRunningOut
        expr: |
          (node_filesystem_avail_bytes{mountpoint="/"} / 
           node_filesystem_size_bytes{mountpoint="/"}) < 0.15
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Disco casi lleno en {{ $labels.instance }}"
          description: "Solo {{ $value | humanizePercentage }} disponible"
```

```bash
# Aplicar alerts
kubectl apply -f prometheus-alerts.yaml
```

#### 3.4. Notificaciones (Slack/Email)

**Configurar Alertmanager para Slack:**

```yaml
# alertmanager-config.yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-config
  namespace: monitoring
stringData:
  alertmanager.yaml: |
    global:
      resolve_timeout: 5m
      slack_api_url: 'https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX'

    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'slack-notifications'
      routes:
      - match:
          severity: critical
        receiver: 'slack-critical'
        continue: true
      - match:
          severity: warning
        receiver: 'slack-warnings'

    receivers:
    - name: 'slack-notifications'
      slack_configs:
      - channel: '#devops-alerts'
        title: 'Alerta: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}\n{{ end }}'

    - name: 'slack-critical'
      slack_configs:
      - channel: '#devops-critical'
        title: '🔴 CRÍTICO: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}\n{{ .Annotations.description }}\n{{ end }}'
        color: 'danger'

    - name: 'slack-warnings'
      slack_configs:
      - channel: '#devops-alerts'
        title: '⚠️ WARNING: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}\n{{ end }}'
        color: 'warning'
```

```bash
# Aplicar configuración
kubectl apply -f alertmanager-config.yaml

# Reiniciar Alertmanager
kubectl rollout restart statefulset/alertmanager-prometheus-kube-prometheus-alertmanager -n monitoring
```

**Configurar notificaciones por Email:**

```yaml
receivers:
- name: 'email-notifications'
  email_configs:
  - to: 'devops@example.com'
    from: 'alertmanager@example.com'
    smarthost: 'smtp.gmail.com:587'
    auth_username: 'your-email@gmail.com'
    auth_password: 'your-app-password'
    headers:
      Subject: '[Alerta] {{ .GroupLabels.alertname }}'
```

### Semana 3: Dashboards Avanzados

#### 3.5. Dashboards de Grafana

**Importar dashboards comunitarios:**

```bash
# En Grafana UI:
# 1. Ir a Dashboards → Import
# 2. Usar estos IDs:

# Kubernetes Cluster Monitoring
# ID: 7249

# Node Exporter Full
# ID: 1860

# PostgreSQL Database
# ID: 9628

# Nginx Ingress Controller
# ID: 9614
```

**Crear dashboard personalizado para Ecommerce:**

JSON para importar en Grafana:
```json
{
  "dashboard": {
    "title": "Ecommerce Metrics",
    "panels": [
      {
        "title": "Total de Pedidos (últimas 24h)",
        "targets": [
          {
            "expr": "sum(increase(ecommerce_orders_total[24h]))"
          }
        ]
      },
      {
        "title": "Tiempo de respuesta API",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"
          }
        ]
      },
      {
        "title": "Queries PostgreSQL por segundo",
        "targets": [
          {
            "expr": "rate(pg_stat_database_xact_commit{datname=\"ecommerce_db\"}[5m])"
          }
        ]
      }
    ]
  }
}
```

### Validación Fase 3

**Checklist:**

- [ ] Loki instalado y recibiendo logs
- [ ] Grafana mostrando logs de pods
- [ ] Alertas de Prometheus configuradas
- [ ] Notificaciones a Slack/Email funcionando
- [ ] Dashboards importados y funcionando
- [ ] Test de alerta (simular CPU alta)

**Comandos de prueba:**

```bash
# Simular CPU alta
kubectl run cpu-stress -n ecommerce --image=containerstack/cpustress -- --cpu 2 --timeout 300s

# Ver logs en Grafana
# Explore → Loki → {namespace="ecommerce"}

# Verificar alertas
kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093
# http://localhost:9093/#/alerts
```

---

## 🔐 FASE 4: GitOps & SEGURIDAD (1 MES) {#fase4}

**Objetivo:** Deployment declarativo y gestión segura de secretos

### Semana 1-2: ArgoCD (GitOps)

#### 4.1. Instalación de ArgoCD

```bash
# 1. Crear namespace
kubectl create namespace argocd

# 2. Instalar ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Esperar a que esté listo
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# 4. Cambiar servicio a NodePort
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

# 5. Obtener password inicial
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Password: $ARGOCD_PASSWORD"

# 6. Acceder a UI
# http://<NODE_IP>:$(kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[0].nodePort}')
# Usuario: admin
# Password: (el obtenido arriba)
```

#### 4.2. Configurar repositorio Git

**Estructura del repo para GitOps:**

```
ecommerce-k8s-gitops/
├── apps/
│   └── ecommerce/
│       ├── base/
│       │   ├── kustomization.yaml
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   └── ingress.yaml
│       └── overlays/
│           ├── dev/
│           │   └── kustomization.yaml
│           ├── staging/
│           │   └── kustomization.yaml
│           └── prod/
│               └── kustomization.yaml
└── argocd/
    └── applications/
        ├── ecommerce-dev.yaml
        ├── ecommerce-staging.yaml
        └── ecommerce-prod.yaml
```

**apps/ecommerce/base/kustomization.yaml:**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - ingress.yaml

commonLabels:
  app: ecommerce
  managed-by: argocd
```

**apps/ecommerce/overlays/dev/kustomization.yaml:**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

namespace: ecommerce-dev

replicas:
  - name: ecommerce-app
    count: 2

images:
  - name: ecommerce-app
    newName: 123456789012.dkr.ecr.us-east-1.amazonaws.com/ecommerce-app
    newTag: dev-latest
```

**argocd/applications/ecommerce-dev.yaml:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ecommerce-dev
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/ITZAN44/ecommerce-k8s-gitops
    targetRevision: HEAD
    path: apps/ecommerce/overlays/dev
  
  destination:
    server: https://kubernetes.default.svc
    namespace: ecommerce-dev
  
  syncPolicy:
    automated:
      prune: true       # Elimina recursos no en Git
      selfHeal: true    # Revierte cambios manuales
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

**Aplicar aplicación en ArgoCD:**

```bash
# Método 1: Por UI
# ArgoCD UI → New App → Rellenar formulario

# Método 2: Por CLI
kubectl apply -f argocd/applications/ecommerce-dev.yaml

# Verificar sync
kubectl get applications -n argocd
argocd app get ecommerce-dev
```

#### 4.3. Pipeline GitOps completo

**Flujo con GitHub Actions + ArgoCD:**

**.github/workflows/deploy.yaml:**
```yaml
name: Deploy to EKS

on:
  push:
    branches: [main]

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: ecommerce-app
  EKS_CLUSTER: ecommerce-cluster

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}
    
    - name: Login to ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1
    
    - name: Build and push image
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        IMAGE_TAG: ${{ github.sha }}
      run: |
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
    
    - name: Update K8s manifests
      env:
        IMAGE_TAG: ${{ github.sha }}
      run: |
        # Clonar repo de GitOps
        git clone https://github.com/ITZAN44/ecommerce-k8s-gitops.git
        cd ecommerce-k8s-gitops
        
        # Actualizar tag de imagen
        cd apps/ecommerce/overlays/dev
        kustomize edit set image ecommerce-app=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        
        # Commit y push
        git config user.email "github-actions@example.com"
        git config user.name "GitHub Actions"
        git add .
        git commit -m "Update image to $IMAGE_TAG"
        git push
    
    # ArgoCD detecta el cambio automáticamente y despliega
```

### Semana 3: HashiCorp Vault

#### 4.4. Instalación de Vault

```bash
# 1. Agregar repo Helm
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# 2. Instalar Vault
helm install vault hashicorp/vault \
  -n vault --create-namespace \
  --set "server.dev.enabled=true" \
  --set "injector.enabled=true"

# 3. Esperar a que esté listo
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n vault --timeout=300s

# 4. Inicializar Vault (en producción, modo HA)
kubectl exec -n vault vault-0 -- vault operator init -key-shares=1 -key-threshold=1

# 5. Desbloquear Vault
kubectl exec -n vault vault-0 -- vault operator unseal <UNSEAL_KEY>

# 6. Login con root token
kubectl exec -n vault vault-0 -- vault login <ROOT_TOKEN>
```

#### 4.5. Configurar secrets en Vault

```bash
# 1. Habilitar secrets engine
kubectl exec -n vault vault-0 -- vault secrets enable -path=secret kv-v2

# 2. Crear secrets para ecommerce
kubectl exec -n vault vault-0 -- vault kv put secret/ecommerce/db \
  username=postgres \
  password=TU_PASSWORD_RDS \
  host=ecommerce-db.abc123.us-east-1.rds.amazonaws.com \
  port=5432 \
  database=ecommerce_db

# 3. Crear política de acceso
kubectl exec -n vault vault-0 -- vault policy write ecommerce - <<EOF
path "secret/data/ecommerce/*" {
  capabilities = ["read"]
}
EOF

# 4. Habilitar autenticación Kubernetes
kubectl exec -n vault vault-0 -- vault auth enable kubernetes

kubectl exec -n vault vault-0 -- vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc:443"

# 5. Crear role para la app
kubectl exec -n vault vault-0 -- vault write auth/kubernetes/role/ecommerce \
  bound_service_account_names=ecommerce-sa \
  bound_service_account_namespaces=ecommerce \
  policies=ecommerce \
  ttl=24h
```

#### 4.6. Inyectar secrets en pods

**Modificar deployment para usar Vault:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ecommerce-app
  namespace: ecommerce
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "ecommerce"
        vault.hashicorp.com/agent-inject-secret-db-config: "secret/data/ecommerce/db"
        vault.hashicorp.com/agent-inject-template-db-config: |
          {{- with secret "secret/data/ecommerce/db" -}}
          export DB_HOST="{{ .Data.data.host }}"
          export DB_PORT="{{ .Data.data.port }}"
          export DB_NAME="{{ .Data.data.database }}"
          export DB_USER="{{ .Data.data.username }}"
          export DB_PASSWORD="{{ .Data.data.password }}"
          {{- end }}
    spec:
      serviceAccountName: ecommerce-sa
      containers:
      - name: ecommerce-app
        image: ecommerce-app:latest
        command: ["/bin/sh", "-c"]
        args:
        - source /vault/secrets/db-config && node ./dist/server/entry.mjs
```

**Crear ServiceAccount:**

```bash
kubectl create serviceaccount ecommerce-sa -n ecommerce
```

### Semana 4: HTTPS/TLS con cert-manager

#### 4.7. Instalación de cert-manager

```bash
# 1. Instalar cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# 2. Verificar
kubectl get pods -n cert-manager

# 3. Crear ClusterIssuer para Let's Encrypt
cat > letsencrypt-issuer.yaml << 'EOF'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: tu-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: alb
EOF

kubectl apply -f letsencrypt-issuer.yaml
```

#### 4.8. Configurar HTTPS en Ingress

**Modificar ingress.yaml:**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ecommerce-ingress
  namespace: ecommerce
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - ecommerce.tu-dominio.com
    secretName: ecommerce-tls
  rules:
  - host: ecommerce.tu-dominio.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ecommerce-app
            port:
              number: 80
```

**Configurar DNS:**

```bash
# 1. Obtener ALB hostname
kubectl get ingress -n ecommerce

# 2. Crear registro DNS (Route 53 o tu proveedor)
# Tipo: CNAME
# Nombre: ecommerce.tu-dominio.com
# Valor: k8s-ecommerce-xyz.us-east-1.elb.amazonaws.com
```

### Validación Fase 4

**Checklist:**

- [ ] ArgoCD instalado y accesible
- [ ] Aplicación desplegada via ArgoCD
- [ ] Auto-sync funcionando (cambios en Git → EKS)
- [ ] Vault instalado y desbloqueado
- [ ] Secrets almacenados en Vault
- [ ] Pods obteniendo secrets de Vault
- [ ] cert-manager instalado
- [ ] Certificado TLS emitido por Let's Encrypt
- [ ] HTTPS funcionando (https://ecommerce.tu-dominio.com)

**Comandos de validación:**

```bash
# ArgoCD
argocd app list
argocd app get ecommerce-dev

# Vault
kubectl exec -n vault vault-0 -- vault kv get secret/ecommerce/db

# Certificados
kubectl get certificate -n ecommerce
kubectl describe certificate ecommerce-tls -n ecommerce

# HTTPS
curl -I https://ecommerce.tu-dominio.com
```

---

## 🚀 FASE 5: KUBERNETES AVANZADO (OPCIONAL) {#fase5}

**Objetivo:** Profundizar en conceptos avanzados de K8s

### 5.1. RBAC (Role-Based Access Control)

**Crear roles para diferentes equipos:**

```yaml
# developer-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: ecommerce
rules:
- apiGroups: ["", "apps", "batch"]
  resources: ["pods", "deployments", "services", "jobs", "cronjobs"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log", "pods/exec"]
  verbs: ["get", "create"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: ecommerce
subjects:
- kind: User
  name: developer@example.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
```

**Crear usuario con certificado:**

```bash
# Generar clave privada
openssl genrsa -out developer.key 2048

# Generar CSR
openssl req -new -key developer.key -out developer.csr -subj "/CN=developer@example.com/O=developers"

# Firmar con CA de Kubernetes
sudo openssl x509 -req -in developer.csr -CA /etc/kubernetes/pki/ca.crt \
  -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial \
  -out developer.crt -days 365

# Crear kubeconfig para developer
kubectl config set-credentials developer@example.com \
  --client-certificate=developer.crt \
  --client-key=developer.key

kubectl config set-context developer-context \
  --cluster=ecommerce-cluster \
  --namespace=ecommerce \
  --user=developer@example.com
```

### 5.2. Network Policies

**Aislar tráfico entre pods:**

```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ecommerce-network-policy
  namespace: ecommerce
spec:
  podSelector:
    matchLabels:
      app: ecommerce-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Permitir tráfico desde Ingress Controller
  - from:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: TCP
      port: 4321
  egress:
  # Permitir DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  # Permitir conexión a RDS
  - to:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 5432
```

### 5.3. Helm Charts Propios

**Crear chart para ecommerce:**

```bash
helm create ecommerce-chart

# Estructura generada:
ecommerce-chart/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── _helpers.tpl
│   └── NOTES.txt
└── .helmignore
```

**Chart.yaml:**
```yaml
apiVersion: v2
name: ecommerce
description: Ecommerce application Helm chart
type: application
version: 1.0.0
appVersion: "1.0.0"
```

**values.yaml:**
```yaml
replicaCount: 3

image:
  repository: 123456789012.dkr.ecr.us-east-1.amazonaws.com/ecommerce-app
  pullPolicy: IfNotPresent
  tag: "latest"

service:
  type: ClusterIP
  port: 80
  targetPort: 4321

ingress:
  enabled: true
  className: alb
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
  hosts:
    - host: ecommerce.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: ecommerce-tls
      hosts:
        - ecommerce.example.com

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

database:
  host: ecommerce-db.abc123.us-east-1.rds.amazonaws.com
  port: 5432
  name: ecommerce_db
```

**Instalar chart:**

```bash
# Empaquetar
helm package ecommerce-chart/

# Instalar
helm install ecommerce ./ecommerce-chart-1.0.0.tgz -n ecommerce

# Actualizar
helm upgrade ecommerce ./ecommerce-chart-1.0.0.tgz -n ecommerce

# Ver historial
helm history ecommerce -n ecommerce

# Rollback
helm rollback ecommerce 1 -n ecommerce
```

### 5.4. StatefulSets vs Deployments

**Cuándo usar StatefulSet (ejemplo: PostgreSQL en K8s):**

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: ecommerce
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

### 5.5. Service Mesh (Istio) - Opcional

**Instalación básica:**

```bash
# Descargar Istio
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.20.0
export PATH=$PWD/bin:$PATH

# Instalar con perfil demo
istioctl install --set profile=demo -y

# Habilitar inyección automática
kubectl label namespace ecommerce istio-injection=enabled

# Verificar
kubectl get pods -n istio-system
```

**Ventajas de Istio (avanzado):**
- Tráfico encriptado entre pods (mTLS)
- Circuit breaking
- Canary deployments
- Telemetría avanzada
- Políticas de retry automático

### Validación Fase 5

**Checklist:**

- [ ] RBAC configurado con diferentes roles
- [ ] Network Policies implementadas
- [ ] Helm chart propio creado
- [ ] StatefulSet vs Deployment entendido
- [ ] Istio instalado (opcional)

---

## 📅 CRONOGRAMA Y RECURSOS {#cronograma}

### Timeline consolidado

| Fase | Duración | Horas/semana | Total horas |
|------|----------|--------------|-------------|
| Fase 1: Cloud Fundamentals | 8 semanas | 10-15h | 80-120h |
| Fase 2: Terraform | 3 semanas | 10-12h | 30-36h |
| Fase 3: Observabilidad | 3 semanas | 8-10h | 24-30h |
| Fase 4: GitOps & Seguridad | 4 semanas | 10-12h | 40-48h |
| Fase 5: K8s Avanzado | 2 semanas | 5-8h | 10-16h |
| **TOTAL** | **20 semanas (~5 meses)** | **10-12h** | **184-250h** |

### Plan semanal sugerido

**Lunes-Miércoles:** Aprendizaje teórico (2-3h/día)
- Ver videos, leer docs, tutoriales

**Jueves-Viernes:** Práctica hands-on (2-3h/día)
- Implementar en AWS, probar comandos

**Sábado:** Proyecto (4-6h)
- Avanzar en migración real del ecommerce

**Domingo:** Revisión y documentación (2h)
- Escribir apuntes, crear diagramas

### Recursos de aprendizaje

**Cursos recomendados:**
- AWS Certified Solutions Architect Associate (Stephane Maarek - Udemy)
- Terraform for Beginners (HashiCorp Learn)
- Kubernetes Mastery (KodeKloud)
- ArgoCD Course (TechWorld with Nana - YouTube)

**Documentación oficial:**
- https://docs.aws.amazon.com/
- https://learn.hashicorp.com/terraform
- https://kubernetes.io/docs/
- https://argo-cd.readthedocs.io/

**Canales YouTube:**
- TechWorld with Nana
- That DevOps Guy
- AWS Online Tech Talks

---

## 💰 COSTOS ESTIMADOS {#costos}

### Opción 1: Free Tier (primer año)

| Servicio | Costo mensual | Notas |
|----------|---------------|-------|
| EKS Control Plane | $72 | No hay free tier |
| EC2 (2 t3.medium nodes) | $60 | 750h free tier solo para t2/t3.micro |
| RDS (db.t3.micro) | $0 | Free tier 750h/mes |
| ALB | $20 | Free tier 750h/mes |
| S3 | $0-2 | 5GB free |
| CloudWatch | $0-5 | 10 métricas free |
| Data Transfer | $5-10 | Primeros 100GB/mes gratis |
| **TOTAL** | **$157-169/mes** | Con EKS |

### Opción 2: Sin EKS (más económico)

| Servicio | Costo mensual | Notas |
|----------|---------------|-------|
| EC2 (1 t3.medium con K3s) | $0 | Free tier t3.micro |
| RDS (db.t3.micro) | $0 | Free tier |
| ALB o Nginx en EC2 | $0 | Free tier |
| S3 | $0-2 | Free tier |
| **TOTAL** | **$0-5/mes** | Primer año |

### Recomendación para aprendizaje:

**Mes 1-2 (Fase 1):**
- Usar solo free tier (EC2 t3.micro + RDS t3.micro)
- **Costo: $0**

**Mes 3-4 (Fases 2-3):**
- Agregar EKS solo 1 mes para probar
- **Costo: ~$160**

**Mes 5-6 (Fases 4-5):**
- Volver a EC2 con K3s si el presupuesto es limitado
- O continuar con EKS si vas a aplicar a trabajos
- **Costo: $0-160**

**Total 6 meses: $160-480**

---

## ✅ CHECKLIST DE VALIDACIÓN {#checklist}

### Al completar TODAS las fases

**Infraestructura:**
- [ ] VPC con subnets públicas y privadas
- [ ] EKS cluster funcionando
- [ ] RDS PostgreSQL con datos migrados
- [ ] ECR con imágenes
- [ ] ALB exponiendo aplicación
- [ ] Todo creado con Terraform

**Aplicación:**
- [ ] Código Astro.js corriendo en EKS
- [ ] Conectado a RDS exitosamente
- [ ] HTTPS funcionando con cert-manager
- [ ] 3+ réplicas con auto-scaling

**CI/CD:**
- [ ] GitHub Actions building imágenes
- [ ] ArgoCD sincronizando desde Git
- [ ] Deployments automáticos al hacer push

**Observabilidad:**
- [ ] Prometheus recolectando métricas
- [ ] Grafana con dashboards
- [ ] Loki agregando logs
- [ ] Alertas configuradas en Slack/Email

**Seguridad:**
- [ ] Secrets en Vault
- [ ] RBAC configurado
- [ ] Network Policies activas
- [ ] TLS en todos los endpoints

**Documentación:**
- [ ] README con arquitectura
- [ ] Diagramas de infraestructura
- [ ] Runbooks de troubleshooting
- [ ] Costos documentados

---

## 🎓 CERTIFICACIONES RECOMENDADAS POST-MIGRACIÓN

Una vez completadas las 5 fases:

1. **AWS Certified Solutions Architect - Associate**
   - Duración estudio: 1 mes
   - Costo: $150
   - Validez: 3 años

2. **Certified Kubernetes Administrator (CKA)**
   - Duración estudio: 1-2 meses
   - Costo: $395
   - Validez: 3 años

3. **HashiCorp Terraform Associate**
   - Duración estudio: 2-3 semanas
   - Costo: $70
   - Validez: 2 años

**Orden recomendado:**
1. AWS SAA (más demandada)
2. Terraform (más fácil)
3. CKA (más difícil, pero ya tienes experiencia)

---

## 📚 RECURSOS ADICIONALES

### Scripts de automatización

Todos los scripts mencionados en este documento estarán en:
```
nube-devops/
├── scripts/
│   ├── aws-setup.sh          # Setup inicial AWS
│   ├── vpc-create.sh         # Crear VPC con CLI
│   ├── eks-deploy.sh         # Desplegar EKS
│   ├── rds-backup.sh         # Backup de RDS
│   └── cleanup.sh            # Destruir todo (ahorrar $$)
└── terraform/
    └── (módulos mencionados en Fase 2)
```

### Troubleshooting común

**Problema: EKS muy caro**
- Usar K3s en EC2 t3.medium ($30/mes vs $72)

**Problema: RDS read replicas caras**
- Usar solo 1 instancia en free tier

**Problema: Logs de Loki llenando disco**
- Configurar retención de 7 días

---

## 🏁 CONCLUSIÓN

Al completar estas 5 fases:

**Habrás cubierto del roadmap DevOps:**
- ✅ 100% Cloud Providers (AWS)
- ✅ 100% IaC Provisioning (Terraform)
- ✅ 100% Container Orchestration (EKS)
- ✅ 100% CI/CD (GitHub Actions + ArgoCD)
- ✅ 100% GitOps (ArgoCD)
- ✅ 90% Observabilidad (Prometheus, Grafana, Loki, Alertmanager)
- ✅ 80% Secret Management (Vault)
- ✅ 80% Kubernetes Avanzado (RBAC, Network Policies, Helm)
- ✅ 70% Service Mesh (Istio opcional)

**Total coverage: ~85-90% del roadmap completo**

**Lo que faltaría (10-15%):**
- Otros clouds (Azure, GCP) - elige 1 primero
- Otros CI/CD (GitLab CI, CircleCI) - con GitHub Actions es suficiente
- Service mesh completo (Istio) - avanzado, no crítico
- Serverless (Lambda) - diferente paradigma
- Multi-cloud - avanzado

**Estarás listo para:**
- Posiciones Mid-level DevOps Engineer
- Cloud Engineer
- Platform Engineer
- Senior DevOps Engineer (con 1-2 años experiencia adicional)

---

**Última actualización:** 19 de Febrero, 2026  
**Autor:** Plan generado para proyecto Ecommerce  
**Repositorio:** https://github.com/ITZAN44/Ecommerce-Proyecto-BD

---

**FIN DEL ROADMAP DE MIGRACIÓN**
