# ROADMAP DEVOPS — Guía de Estudio Completa

> Basado en el roadmap oficial de roadmap.sh/devops  
> Cada sección incluye: **¿Qué es?**, **¿Para qué sirve?**, **Ejemplo práctico**

---

## ÍNDICE

1. [Aprender un Lenguaje de Programación](#1-aprender-un-lenguaje-de-programación)
2. [Sistema Operativo](#2-sistema-operativo)
3. [Scripting](#3-scripting)
4. [Conocimiento de Terminal](#4-conocimiento-de-terminal)
5. [Editores de Texto en Terminal](#5-editores-de-texto-en-terminal)
6. [Control de Versiones](#6-control-de-versiones)
7. [Hosting VCS](#7-hosting-vcs-github-gitlab-bitbucket)
8. [Contenedores](#8-contenedores)
9. [Servidores Web y Proxies](#9-servidores-web-y-proxies)
10. [Redes y Protocolos](#10-redes-y-protocolos)
11. [Cloud Providers](#11-cloud-providers)
12. [Serverless](#12-serverless)
13. [Gestión de Logs](#13-gestión-de-logs)
14. [Gestión de Configuración](#14-gestión-de-configuración)
15. [Provisionamiento / IaC](#15-provisionamiento--iac)
16. [CI/CD Tools](#16-cicd-tools)
17. [Monitoreo de Infraestructura](#17-monitoreo-de-infraestructura)
18. [Gestión de Secretos](#18-gestión-de-secretos)
19. [Orquestación de Contenedores](#19-orquestación-de-contenedores)
20. [Observabilidad](#20-observabilidad)
21. [Gestión de Artefactos](#21-gestión-de-artefactos)
22. [GitOps](#22-gitops)
23. [Service Mesh](#23-service-mesh)
24. [Cloud Design Patterns](#24-cloud-design-patterns)

---

## 1. Aprender un Lenguaje de Programación

En DevOps no necesitas ser desarrollador senior, pero SÍ necesitas leer, escribir y modificar código para automatizar tareas, crear scripts, pipelines y herramientas.

---

### Python

**¿Qué es?**  
Lenguaje interpretado, de alto nivel, con sintaxis sencilla. Es el lenguaje más popular en DevOps hoy en día.

**¿Para qué sirve en DevOps?**
- Automatización de tareas repetitivas
- Scripts de despliegue
- Interactuar con APIs REST (AWS SDK = Boto3)
- Parsear logs, procesar JSON/YAML
- Escribir pruebas de infraestructura (pytest)

**Ejemplo práctico:**
```python
import boto3  # SDK de AWS para Python

# Listar todas las instancias EC2 en AWS
ec2 = boto3.client('ec2', region_name='us-east-1')
response = ec2.describe_instances()

for reservation in response['Reservations']:
    for instance in reservation['Instances']:
        print(f"ID: {instance['InstanceId']} | Estado: {instance['State']['Name']}")
```

---

### Go (Golang)

**¿Qué es?**  
Lenguaje compilado creado por Google. Produce binarios estáticos y tiene rendimiento cercano a C.

**¿Para qué sirve en DevOps?**
- Muchas herramientas DevOps están escritas en Go: Docker, Kubernetes, Terraform, Prometheus, Consul
- Crear CLIs (herramientas de línea de comandos) de alto rendimiento
- Microservicios y herramientas de infraestructura

**Ejemplo práctico:**
```go
package main

import (
    "fmt"
    "os/exec"
)

func main() {
    // Ejecutar un comando del sistema desde Go
    out, err := exec.Command("kubectl", "get", "pods", "-n", "ecommerce").Output()
    if err != nil {
        fmt.Printf("Error: %v\n", err)
        return
    }
    fmt.Printf("Pods activos:\n%s\n", out)
}
```

---

### Ruby

**¿Qué es?**  
Lenguaje interpretado orientado a objetos. Fue muy popular en DevOps con la herramienta Chef.

**¿Para qué sirve en DevOps?**
- Recetas de Chef (Configuration Management)
- Capistrano (despliegue de apps Rails)
- Scripts de automatización de servidores

---

### Rust

**¿Qué es?**  
Lenguaje de sistemas de muy alto rendimiento y seguridad de memoria. Está ganando terreno como alternativa a C++ y Go.

**¿Para qué sirve en DevOps?**
- Herramientas CLI de alto rendimiento
- Proxies y componentes de red (Linkerd2-proxy está escrito en Rust)
- Alternativa a Go para herramientas internas

---

### JavaScript / Node.js

**¿Qué es?**  
JavaScript en el servidor (Node.js). Permite usar el mismo lenguaje en frontend y backend.

**¿Para qué sirve en DevOps?**
- Serverless Functions (AWS Lambda, Vercel, Cloudflare Workers)
- Scripts de automatización con npm
- Herramientas como `pm2` para gestión de procesos
- CDK de AWS (define infraestructura con JS/TS)

**Ejemplo práctico:**
```javascript
// Lambda function simple en Node.js
exports.handler = async (event) => {
    const nombre = event.queryStringParameters?.nombre || 'Mundo';
    return {
        statusCode: 200,
        body: JSON.stringify({ mensaje: `Hola, ${nombre}!` })
    };
};
```

---

## 2. Sistema Operativo

Un DevOps Engineer necesita dominar profundamente los sistemas operativos donde vive la infraestructura.

---

### Windows

**¿Qué es?**  
Sistema operativo de Microsoft. Relevante en entornos empresariales.

**¿Para qué sirve en DevOps?**
- PowerShell para automatización
- Gestión de IIS (servidor web de Microsoft)
- Active Directory y políticas de grupo
- Entornos .NET y Azure DevOps
- WSL2 (Windows Subsystem for Linux) para usar herramientas Linux en Windows

**Ejemplo — WSL2:**
```powershell
# Instalar WSL2 con Ubuntu
wsl --install -d Ubuntu

# Verificar versión
wsl --list --verbose
```

---

### Linux — Ubuntu / Debian

**¿Qué es?**  
La distribución Linux más popular en servidores y contenedores. Usa `apt` como gestor de paquetes.

**¿Para qué sirve en DevOps?**
- Base de la mayoría de imágenes Docker (`ubuntu:24.04`, `debian:slim`)
- Servidores web, bases de datos, microservicios
- Fácil de automatizar con scripts Bash

**Comandos esenciales:**
```bash
# Actualizar el sistema
apt update && apt upgrade -y

# Instalar Docker
apt install docker.io -y

# Ver servicios activos
systemctl list-units --type=service --state=running

# Ver espacio en disco
df -h

# Ver memoria
free -h
```

---

### Linux — RHEL / CentOS / Derivatives (Fedora, AlmaLinux, Rocky)

**¿Qué es?**  
Red Hat Enterprise Linux y sus derivados. Usa `dnf/yum` como gestor de paquetes. Muy común en entornos corporativos y bancarios.

**¿Para qué sirve en DevOps?**
- Entornos enterprise donde se requiere soporte oficial (Red Hat)
- SELinux para seguridad avanzada
- OpenShift corre sobre RHEL/CoreOS

---

### Linux — SUSE Linux

**¿Qué es?**  
Distribución empresarial de SUSE. Usa `zypper` como gestor de paquetes.

**¿Para qué sirve en DevOps?**
- SAP HANA típicamente corre en SUSE
- Rancher (K8s) fue creado por SUSE

---

### Unix — FreeBSD / OpenBSD / NetBSD

**¿Qué es?**  
Sistemas operativos tipo Unix. No son Linux pero comparten filosofía POSIX.

**¿Para qué sirve en DevOps?**
- FreeBSD: muy usado en firewalls (pfSense) y almacenamiento (TrueNAS)
- OpenBSD: famoso por seguridad extrema, usado en routers y firewalls
- NetBSD: alta portabilidad (corre en casi cualquier hardware)

---

## 3. Scripting

El scripting es la base de la automatización. Un DevOps sin scripting no puede automatizar nada.

---

### Bash

**¿Qué es?**  
Bourne Again Shell. El intérprete de comandos estándar en sistemas Linux/Unix.

**¿Para qué sirve en DevOps?**
- Scripts de despliegue y startup
- Automatizar tareas repetitivas en Linux
- CI/CD pipelines (los pasos del pipeline son comandos Bash)
- Cron jobs

**Ejemplo práctico — Script de backup:**
```bash
#!/bin/bash
# Script que hace backup de la base de datos y lo sube a S3

set -euo pipefail  # Detener ante errores

FECHA=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backup_${FECHA}.sql"
S3_BUCKET="s3://mi-bucket-backups"

echo "=== Iniciando backup: $FECHA ==="

# Hacer dump de PostgreSQL
pg_dump -U postgres ecommerce_db > "/tmp/${BACKUP_FILE}"

# Comprimir
gzip "/tmp/${BACKUP_FILE}"

# Subir a S3
aws s3 cp "/tmp/${BACKUP_FILE}.gz" "${S3_BUCKET}/${BACKUP_FILE}.gz"

echo "=== Backup completado: ${BACKUP_FILE}.gz ==="

# Limpiar archivo local
rm -f "/tmp/${BACKUP_FILE}.gz"
```

**Conceptos clave de Bash:**
```bash
# Variables
NOMBRE="DevOps"
echo "Hola $NOMBRE"

# Condicionales
if [ -f "/etc/nginx/nginx.conf" ]; then
    echo "Nginx está instalado"
else
    echo "Nginx NO está instalado"
fi

# Bucles
for SERVIDOR in web1 web2 web3; do
    echo "Desplegando en $SERVIDOR..."
    ssh $SERVIDOR "docker pull mi-imagen:latest"
done

# Funciones
verificar_servicio() {
    local servicio=$1
    if systemctl is-active --quiet $servicio; then
        echo "$servicio: ACTIVO ✓"
    else
        echo "$servicio: INACTIVO ✗"
    fi
}

verificar_servicio nginx
verificar_servicio docker
verificar_servicio k3s
```

---

### PowerShell

**¿Qué es?**  
Shell y lenguaje de scripting de Microsoft. Basado en objetos .NET (no en texto como Bash).

**¿Para qué sirve en DevOps?**
- Automatización en Windows Server
- Azure CLI y Azure PowerShell (gestionar recursos Azure)
- Active Directory y gestión de usuarios Windows
- Pipelines en Azure DevOps
- Gestión de IIS y servicios Windows

**Ejemplo práctico:**
```powershell
# Obtener todos los servicios detenidos y reiniciarlos
Get-Service | Where-Object {$_.Status -eq 'Stopped'} | 
    Select-Object Name, Status |
    Format-Table -AutoSize

# Crear múltiples usuarios en Active Directory
$usuarios = @("juan.perez", "maria.garcia", "carlos.lopez")
foreach ($usuario in $usuarios) {
    New-ADUser -Name $usuario -AccountPassword (ConvertTo-SecureString "Pass@123" -AsPlainText -Force) -Enabled $true
    Write-Host "Usuario creado: $usuario"
}

# Monitorear uso de CPU cada 5 segundos
while ($true) {
    $cpu = Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average
    Write-Host "CPU: $($cpu.Average)% - $(Get-Date -Format 'HH:mm:ss')"
    Start-Sleep -Seconds 5
}
```

---

## 4. Conocimiento de Terminal

El terminal es tu herramienta principal como DevOps. Debes dominar estas áreas:

---

### Process Monitoring (Monitoreo de Procesos)

**¿Para qué sirve?**  
Ver qué procesos consumen recursos, matar procesos problemáticos, diagnosticar rendimiento.

```bash
# Herramientas principales:

# top — monitor básico de procesos
top

# htop — versión mejorada con colores e interactividad
htop

# ps — listar procesos
ps aux                          # Todos los procesos
ps aux | grep nginx             # Filtrar por nombre
ps aux --sort=-%cpu | head -10  # Los 10 que más CPU consumen

# kill — terminar procesos
kill -15 <PID>   # Señal SIGTERM (graceful)
kill -9 <PID>    # Señal SIGKILL (forzado)
pkill nginx      # Matar por nombre

# Monitoreo de procesos en tiempo real
watch -n 2 "ps aux | grep node"
```

---

### Performance Monitoring (Monitoreo de Rendimiento)

**¿Para qué sirve?**  
Diagnosticar cuellos de botella en CPU, RAM, disco, red.

```bash
# vmstat — estadísticas del sistema
vmstat 1 5  # Cada 1 segundo, 5 muestras

# iostat — estadísticas de I/O de disco
iostat -x 1

# sar — histórico de rendimiento (requiere sysstat)
sar -u 1 5    # CPU
sar -r 1 5    # Memoria
sar -d 1 5    # Disco

# free — uso de memoria
free -h

# df — uso de disco
df -h

# du — uso por directorio
du -sh /var/log/*
```

---

### Networking Tools (Herramientas de Red)

**¿Para qué sirve?**  
Diagnosticar conectividad, DNS, puertos, tráfico de red.

```bash
# ping — verificar conectividad básica
ping -c 4 google.com

# curl — hacer peticiones HTTP
curl -I https://mi-api.com/health          # Solo headers
curl -X POST -H "Content-Type: application/json" \
     -d '{"user":"test"}' http://localhost:3000/api/login

# wget — descargar archivos
wget https://example.com/archivo.tar.gz

# netstat / ss — ver puertos y conexiones
ss -tlnp                    # Puertos TCP escuchando
ss -tlnp | grep :80         # Filtrar puerto 80

# traceroute — ruta de paquetes
traceroute google.com

# dig / nslookup — consultas DNS
dig google.com
dig @8.8.8.8 mi-dominio.com MX  # Registros de correo

# nmap — escaneo de puertos
nmap -p 80,443,8080 192.168.0.119
nmap -sV 192.168.0.0/24    # Escanear toda la subred

# tcpdump — capturar tráfico de red
tcpdump -i eth0 port 80
tcpdump -i eth0 host 192.168.0.119
```

---

### Text Manipulation (Manipulación de Texto)

**¿Para qué sirve?**  
Parsear logs, procesar archivos de configuración, filtrar outputs de comandos.

```bash
# grep — buscar patrones en texto
grep "ERROR" /var/log/app.log
grep -r "database" /etc/nginx/   # Recursivo
grep -v "DEBUG" app.log          # Excluir línea

# sed — editor de flujo (buscar y reemplazar)
sed 's/localhost/192.168.0.119/g' nginx.conf
sed -n '10,20p' archivo.log      # Imprimir líneas 10-20

# awk — procesamiento de columnas
awk '{print $1, $4}' access.log                # Columnas 1 y 4
awk '/ERROR/ {count++} END {print count}' log   # Contar errores
awk -F: '{print $1}' /etc/passwd                # Usuarios del sistema

# cut — cortar columnas
cat /etc/passwd | cut -d: -f1   # Solo nombres de usuario

# sort y uniq — ordenar y deduplicar
sort archivo.txt | uniq          # Eliminar duplicados
sort -rn numeros.txt             # Orden numérico descendente

# Ejemplo real — analizar logs de Nginx:
cat /var/log/nginx/access.log | \
    awk '{print $1}' | \            # Extraer IPs
    sort | \
    uniq -c | \                     # Contar accesos por IP
    sort -rn | \
    head -10                        # Top 10 IPs
```

---

## 5. Editores de Texto en Terminal

---

### Vim

**¿Qué es?**  
Editor de texto modal que opera íntegramente desde el teclado. Preinstalado en prácticamente todo servidor Linux.

**¿Para qué sirve en DevOps?**  
Editar archivos de configuración directamente en servidores remotos (sin GUI).

**Modos principales:**
```
NORMAL mode  → Para navegar y comandos (modo por defecto, presiona ESC)
INSERT mode  → Para escribir texto (presiona i)
VISUAL mode  → Para seleccionar texto (presiona v)
COMMAND mode → Para guardar, salir, buscar (presiona :)
```

**Comandos esenciales:**
```vim
i           → Entrar a modo INSERT (escribir)
ESC         → Volver a modo NORMAL

:w          → Guardar
:q          → Salir
:wq         → Guardar y salir
:q!         → Salir sin guardar (forzado)

/texto      → Buscar "texto"
n           → Siguiente resultado
:%s/viejo/nuevo/g  → Reemplazar en todo el archivo

dd          → Borrar línea
yy          → Copiar línea
p           → Pegar
u           → Deshacer
Ctrl+r      → Rehacer

gg          → Ir al inicio
G           → Ir al final
:50         → Ir a línea 50
```

---

### Nano

**¿Qué es?**  
Editor más simple y amigable que Vim. Los controles se muestran en pantalla.

```bash
nano /etc/nginx/nginx.conf   # Abrir archivo

# Atajos clave (^ = Ctrl):
Ctrl+O   → Guardar
Ctrl+X   → Salir
Ctrl+W   → Buscar
Ctrl+\   → Buscar y reemplazar
Ctrl+K   → Cortar línea
Ctrl+U   → Pegar
```

---

### Emacs

**¿Qué es?**  
Editor muy poderoso, más que un editor (tiene terminal, gestor de archivos, cliente de email). Curva de aprendizaje alta.

```bash
emacs archivo.conf   # Abrir

# Atajos (C = Ctrl, M = Alt):
C-x C-s   → Guardar
C-x C-c   → Salir
C-s       → Buscar
M-%       → Buscar y reemplazar
```

---

## 6. Control de Versiones

---

### Git

**¿Qué es?**  
Sistema de control de versiones distribuido. Creado por Linus Torvalds en 2005 para gestionar el código del kernel Linux.

**¿Para qué sirve en DevOps?**
- Versionar código fuente, infraestructura (IaC), configuraciones
- Colaboración entre equipos
- Base de cualquier pipeline CI/CD (el trigger es siempre un push de Git)
- GitOps: la infraestructura se define en Git y se aplica automáticamente

**Flujo básico:**
```bash
# Configuración inicial
git config --global user.name "Clark"
git config --global user.email "clark@ejemplo.com"

# Iniciar repositorio
git init                    # Nuevo repo local
git clone <URL>             # Clonar repo existente

# Ciclo de trabajo básico
git status                  # Ver estado actual
git add .                   # Stage todos los cambios
git add src/archivo.ts      # Stage un archivo específico
git commit -m "feat: agregar endpoint de pagos"
git push origin main        # Subir cambios

# Ramas (branches)
git branch                  # Listar ramas
git branch feature/login    # Crear rama
git checkout feature/login  # Cambiar a rama
git checkout -b hotfix/bug  # Crear Y cambiar en un comando
git merge feature/login     # Fusionar rama

# Ver historial
git log --oneline --graph --all   # Historial visual
git diff HEAD~1 HEAD              # Ver cambios del último commit
```

**Conceptos clave:**
```
Working Directory → Staging Area (git add) → Local Repo (git commit) → Remote (git push)
```

**Git Flow (flujo de trabajo profesional):**
```
main/master   → Código en producción (siempre estable)
develop       → Integración de features
feature/*     → Nuevas funcionalidades
hotfix/*      → Correcciones urgentes en producción
release/*     → Preparación de versiones
```

---

## 7. Hosting VCS (GitHub, GitLab, Bitbucket)

---

### GitHub

**¿Qué es?**  
La plataforma de hospedaje de repositorios Git más grande del mundo (propiedad de Microsoft). También ofrece GitHub Actions para CI/CD.

**¿Para qué sirve en DevOps?**
- Hospedar código fuente (es nuestro repo: `github.com/ITZAN44/Ecommerce-Proyecto-BD`)
- GitHub Actions: CI/CD integrado
- GitHub Packages: registro de imágenes Docker
- GitHub Dependabot: actualizaciones automáticas de dependencias
- GitHub Pages: hosting de sitios estáticos

**GitHub Actions básico:**
```yaml
# .github/workflows/deploy.yml
name: Deploy to K3s

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build Docker image
        run: docker build -t mi-app:${{ github.sha }} .
      
      - name: Push to registry
        run: |
          echo ${{ secrets.DOCKER_TOKEN }} | docker login -u ${{ secrets.DOCKER_USER }} --password-stdin
          docker push mi-app:${{ github.sha }}
      
      - name: Deploy to K3s
        run: |
          kubectl set image deployment/ecommerce-app ecommerce-app=mi-app:${{ github.sha }}
```

---

### GitLab

**¿Qué es?**  
Plataforma DevOps completa y autoalojable (self-hosted). Incluye Git hosting + CI/CD + registry + monitoreo + seguridad en un solo producto.

**¿Para qué sirve en DevOps?**
- GitLab CI/CD: pipeline integrado muy potente
- GitLab Container Registry: imágenes Docker
- GitLab Runner: ejecuta los jobs del pipeline
- Ideal para empresas que quieren todo on-premise

**gitlab-ci.yml básico:**
```yaml
stages:
  - build
  - test
  - deploy

build:
  stage: build
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

deploy_production:
  stage: deploy
  only:
    - main
  script:
    - kubectl apply -f k8s/
```

---

### Bitbucket

**¿Qué es?**  
Plataforma de Atlassian (misma empresa que Jira y Confluence). Muy integrado con el ecosistema Atlassian.

**¿Para qué sirve en DevOps?**
- Bitbucket Pipelines: CI/CD
- Integración nativa con Jira para gestión de proyectos
- Soporte para Mercurial (aunque ahora solo Git)

---

## 8. Contenedores

---

### Docker

**¿Qué es?**  
Plataforma de contenedores que empaqueta una aplicación con todas sus dependencias en una unidad portable llamada **imagen**. Un contenedor es una instancia ejecutable de una imagen.

**¿Por qué es esencial en DevOps?**  
"Funciona en mi máquina" → Con Docker funciona en TODAS las máquinas.

**Conceptos fundamentales:**
```
Dockerfile   → Receta para construir una imagen
Image        → Plantilla inmutable (como una clase)
Container    → Instancia ejecutable de una imagen (como un objeto)
Registry     → Repositorio de imágenes (Docker Hub, ECR, GCR)
Volume       → Almacenamiento persistente para contenedores
Network      → Red virtual entre contenedores
```

**Comandos esenciales:**
```bash
# Imágenes
docker build -t mi-app:1.0 .        # Construir imagen
docker images                        # Listar imágenes
docker pull nginx:alpine             # Descargar imagen
docker push mi-usuario/mi-app:1.0   # Subir al registry

# Contenedores
docker run -d -p 80:3000 --name app mi-app:1.0   # Ejecutar en background
docker ps                                          # Ver contenedores activos
docker ps -a                                       # Todos (incluye detenidos)
docker logs app                                    # Ver logs
docker logs -f app                                 # Seguir logs en tiempo real
docker exec -it app bash                           # Entrar al contenedor
docker stop app && docker rm app                   # Detener y eliminar

# Volúmenes
docker volume create mi-datos
docker run -v mi-datos:/app/data mi-app:1.0
docker run -v $(pwd)/config:/app/config:ro mi-app:1.0  # Read-only

# Redes
docker network create mi-red
docker run --network mi-red --name db postgres:16
docker run --network mi-red --name app mi-app:1.0
```

**Dockerfile multi-stage (nuestro proyecto):**
```dockerfile
# ─── Stage 1: Builder ───────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

# ─── Stage 2: Production ────────────────────────────────────
FROM node:20-alpine AS production

# Usuario no-root por seguridad
RUN addgroup -g 1001 appgroup && \
    adduser -u 1001 -G appgroup -s /bin/sh -D astro

WORKDIR /app

# Copiar solo lo necesario del builder
COPY --from=builder --chown=astro:appgroup /app/dist ./dist
COPY --from=builder --chown=astro:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=astro:appgroup /app/package.json ./

USER astro

EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD wget -q --spider http://localhost:3000/api/analytics/dashboard || exit 1

CMD ["node", "./dist/server/entry.mjs"]
```

**Docker Compose:**
```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/ecommerce
    depends_on:
      db:
        condition: service_healthy
    networks:
      - ecommerce_network

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ecommerce
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - ecommerce_network

volumes:
  postgres_data:

networks:
  ecommerce_network:
    driver: bridge
```

---

### LXC (Linux Containers)

**¿Qué es?**  
Tecnología de virtualización a nivel de sistema operativo. Más ligero que VMs pero más pesado que Docker.

**Diferencia con Docker:**
```
LXC     → Contenedor de sistema completo (como una VM ligera, tiene init, systemd, etc.)
Docker  → Contenedor de aplicación (un proceso principal, inmutable, efímero)
```

**¿Para qué sirve?**
- Aislar entornos de desarrollo completos
- Proxmox VE usa LXC para sus contenedores
- Alternativa a VMs en servidores físicos con muchos recursos

---

## 9. Servidores Web y Proxies

---

### Nginx

**¿Qué es?**  
Servidor web de alto rendimiento, y también reverse proxy, load balancer y cache HTTP. Creado por Igor Sysoev en 2004 para manejar el problema C10K (10,000 conexiones concurrentes).

**¿Para qué sirve en DevOps?**
- Reverse proxy para proteger y redirigir tráfico al backend
- Terminación SSL/TLS
- Load balancing entre múltiples instancias
- Servir archivos estáticos muy eficientemente
- Compresión gzip

**Configuración básica (nuestro proyecto):**
```nginx
# /etc/nginx/sites-available/ecommerce
upstream ecommerce_backend {
    server 10.43.7.181:80;  # ClusterIP del servicio K3s
    keepalive 32;
}

server {
    listen 80;
    server_name 192.168.0.119;

    # Compresión gzip
    gzip on;
    gzip_types text/css application/javascript application/json;
    gzip_min_length 1000;

    # Archivos estáticos con caché de 1 año
    location /_astro/ {
        proxy_pass http://ecommerce_backend;
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    # Proxy hacia la aplicación
    location / {
        proxy_pass http://ecommerce_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Endpoint de salud de Nginx
    location /nginx-health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
```

---

### Apache

**¿Qué es?**  
El servidor web más utilizado históricamente. Más antiguo que Nginx, con arquitectura basada en procesos/hilos.

**¿Para qué sirve?**
- Hosting de aplicaciones PHP (WordPress, Laravel)
- `.htaccess` para configuración por directorio
- Módulos dinámicos extensibles

```apache
# Ejemplo .htaccess para redirigir HTTP a HTTPS
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
```

---

### Caddy

**¿Qué es?**  
Servidor web moderno escrito en Go. Gestiona HTTPS automáticamente con Let's Encrypt.

**¿Para qué sirve?**
- HTTPS automático sin configuración (genera y renueva certificados solo)
- Configuración mucho más simple que Nginx
- Ideal para proyectos personales y startups

```
# Caddyfile — equivale a decenas de líneas de Nginx
mi-dominio.com {
    reverse_proxy localhost:3000
    encode gzip
}
```

---

### Tomcat

**¿Qué es?**  
Servidor de aplicaciones Java. Implementa las especificaciones Java Servlet y JSP.

**¿Para qué sirve?**
- Desplegar aplicaciones Java (.war, .jar)
- Entornos empresariales con Java EE
- Backend de sistemas bancarios y gubernamentales

---

### IIS (Internet Information Services)

**¿Qué es?**  
Servidor web de Microsoft para Windows Server.

**¿Para qué sirve?**
- Hospedar aplicaciones .NET/ASP.NET
- Entornos Windows Server corporativos
- Integración con Active Directory

---

### Reverse Proxy

**¿Qué es?**  
Un servidor que recibe peticiones de clientes y las reenvía a servidores backend. El cliente no sabe a qué servidor habla.

```
Internet → [Reverse Proxy: Nginx] → [App Server 1]
                                   → [App Server 2]
                                   → [App Server 3]
```

**Beneficios:**
- Oculta la arquitectura interna
- Centraliza SSL/TLS
- Permite load balancing
- Caché de respuestas

---

### Forward Proxy

**¿Qué es?**  
Un servidor que actúa en nombre de CLIENTES para acceder a Internet.

```
[Cliente] → [Forward Proxy: Squid] → Internet
```

**Usos:**
- Filtrar acceso a sitios web en corporaciones
- Cachear contenido para ahorrar ancho de banda
- Anonymización de requests

---

### Caching Server

**¿Qué es?**  
Servidor que almacena respuestas para no volver a generarlas.

**Herramientas:**
- **Varnish**: caché HTTP de alto rendimiento  
- **Redis**: caché en memoria para sesiones y datos frecuentes
- **Squid**: proxy con caché

```bash
# Redis como caché de sesiones
docker run -d --name redis -p 6379:6379 redis:7-alpine

# En la app (Node.js)
const redis = require('redis');
const client = redis.createClient({ url: 'redis://localhost:6379' });

// Guardar en caché por 5 minutos
await client.setEx(`usuario:${id}`, 300, JSON.stringify(usuario));

// Leer de caché
const cached = await client.get(`usuario:${id}`);
```

---

### Firewall

**¿Qué es?**  
Sistema que controla el tráfico de red aplicando reglas de allow/deny.

**UFW (Uncomplicated Firewall) en Ubuntu:**
```bash
# Habilitar UFW
ufw enable

# Permitir puertos
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 8080/tcp  # Jenkins

# Denegar todo lo demás (regla por defecto)
ufw default deny incoming
ufw default allow outgoing

# Ver reglas activas
ufw status verbose
```

---

### Load Balancer

**¿Qué es?**  
Distribuye el tráfico entre múltiples instancias de una aplicación para evitar sobrecargas.

**Algoritmos de balanceo:**
```
Round Robin        → Distribuye en orden secuencial (1,2,3,1,2,3...)
Least Connections  → Envía al servidor con menos conexiones activas
IP Hash            → Misma IP siempre va al mismo servidor (session affinity)
Weighted           → Servidores más potentes reciben más tráfico
```

**Nginx como load balancer:**
```nginx
upstream backend {
    least_conn;  # Algoritmo: menor conexiones
    server backend1:3000 weight=3;
    server backend2:3000 weight=1;
    server backend3:3000 backup;    # Solo si los otros caen
}
```

---

## 10. Redes y Protocolos

---

### HTTP / HTTPS

**¿Qué es?**  
HyperText Transfer Protocol. Protocolo de comunicación de la web. HTTPS es HTTP con cifrado SSL/TLS.

```bash
# Métodos HTTP
GET     → Obtener recurso
POST    → Crear recurso
PUT     → Reemplazar recurso completo
PATCH   → Modificar parte del recurso
DELETE  → Eliminar recurso

# Códigos de estado importantes
200 OK              → Éxito
201 Created         → Recurso creado
301 Moved Permanently → Redirección permanente
400 Bad Request     → Error del cliente
401 Unauthorized    → No autenticado
403 Forbidden       → Sin permisos
404 Not Found       → Recurso no existe
500 Internal Server Error → Error del servidor
503 Service Unavailable  → Servidor no disponible
```

---

### SSL/TLS

**¿Qué es?**  
Protocolo de cifrado que protege la comunicación en redes. TLS es la versión moderna de SSL.

**¿Cómo funciona?**
```
1. Cliente → "Hola, soporto TLS 1.3" → Servidor
2. Servidor → Envía certificado SSL → Cliente
3. Cliente verifica certificado (CA trusted?)
4. Se establece clave de sesión simétrica
5. Comunicación cifrada ✓
```

**Let's Encrypt (certificados gratis):**
```bash
# Instalar certbot
apt install certbot python3-certbot-nginx

# Generar certificado
certbot --nginx -d mi-dominio.com -d www.mi-dominio.com

# Renovación automática (cron job)
echo "0 0 * * * certbot renew --quiet" | crontab -
```

---

### SSH

**¿Qué es?**  
Secure Shell. Protocolo para conectarse de forma segura a servidores remotos.

```bash
# Conexión básica
ssh usuario@192.168.0.119
ssh -p 2222 clark@servidor.com    # Puerto personalizado

# Generar par de claves (autenticación sin password)
ssh-keygen -t ed25519 -C "mi@email.com"

# Copiar clave pública al servidor
ssh-copy-id clark@192.168.0.119

# SSH tunneling (reenviar puerto remoto a local)
ssh -L 5432:localhost:5432 clark@192.168.0.119
# Ahora: psql -h localhost -p 5432 (conecta a la BD remota)

# SSH config para simplificar conexiones (~/.ssh/config)
Host vm-local
    HostName 192.168.0.119
    User clark
    IdentityFile ~/.ssh/id_ed25519
    Port 22

# Ahora solo: ssh vm-local
```

---

### DNS

**¿Qué es?**  
Domain Name System. Traduce nombres de dominio a IPs (la "guía telefónica" de Internet).

```bash
# Tipos de registros DNS
A        → dominio → IPv4 (ej: example.com → 93.184.216.34)
AAAA     → dominio → IPv6
CNAME    → alias a otro dominio (www → example.com)
MX       → servidor de correo del dominio
TXT      → texto libre (verificación, SPF, DKIM)
NS       → nameserver del dominio

# Consultas DNS con dig
dig example.com           # Registro A
dig example.com MX        # Servidores de correo
dig example.com TXT       # Registros de texto
dig @8.8.8.8 example.com  # Consultar DNS de Google

# Ver caché DNS local (Windows)
ipconfig /displaydns
ipconfig /flushdns  # Limpiar caché
```

---

### FTP / SFTP

**¿Qué es?**  
File Transfer Protocol. Protocolo para transferir archivos entre equipos.

- **FTP**: Protocolo viejo, sin cifrado. NO usar en producción.
- **SFTP**: FTP sobre SSH. Seguro y cifrado. Usar SIEMPRE este.

```bash
# Conexión SFTP
sftp clark@192.168.0.119

sftp> get archivo-remoto.txt    # Descargar
sftp> put archivo-local.txt     # Subir
sftp> ls                        # Listar directorio remoto
sftp> exit

# Con rsync (más eficiente, solo sincroniza cambios)
rsync -avz --progress ./dist/ clark@192.168.0.119:/app/dist/
```

---

### Protocolos de Email

**¿Por qué los necesita un DevOps?**  
Para configurar alertas, notificaciones de pipelines, y sistemas de monitoreo.

```
SMTP    → Enviar correos (Puerto 587 con STARTTLS, 465 con SSL)
IMAP    → Recibir/sincronizar correos desde múltiples dispositivos
POP3    → Recibir correos (descarga y elimina del servidor)

SPF     → Indica qué servidores pueden enviar email en tu nombre
DKIM    → Firma digital de los emails
DMARC   → Política de qué hacer con emails que fallan SPF/DKIM
```

---

### Modelo OSI

**¿Qué es?**  
Marco de referencia de 7 capas que describe cómo viajan los datos en una red.

```
Capa 7 - Aplicación    → HTTP, FTP, DNS, SMTP (lo que usa el usuario)
Capa 6 - Presentación  → SSL/TLS, cifrado, compresión
Capa 5 - Sesión        → Establece y mantiene sesiones de comunicación
Capa 4 - Transporte    → TCP (confiable), UDP (rápido)
Capa 3 - Red           → IP, routing, direccionamiento lógico
Capa 2 - Enlace        → Ethernet, MAC addresses, switches
Capa 1 - Física        → Cables, señales eléctricas, WiFi
```

---

## 11. Cloud Providers

La nube permite consumir infraestructura como servicio sin comprar servidores físicos.

---

### AWS (Amazon Web Services)

**¿Qué es?**  
El proveedor de nube más grande del mundo (~32% del mercado). Lanzado en 2006.

**Servicios principales:**
```
EC2            → Máquinas virtuales (como tu VM local, pero en la nube)
S3             → Almacenamiento de objetos (archivos, backups, assets)
RDS            → Base de datos administrada (PostgreSQL, MySQL, etc.)
EKS            → Kubernetes administrado
ECR            → Registry de imágenes Docker
Lambda         → Serverless functions
VPC            → Red privada virtual
IAM            → Gestión de identidad y acceso
CloudWatch     → Monitoreo y logs
ALB/NLB        → Load Balancers
Route53        → DNS administrado
```

---

### Azure (Microsoft Azure)

**¿Qué es?**  
La plataforma cloud de Microsoft (~22% del mercado). Muy popular en empresas .NET y para integración con Active Directory.

**Servicios equivalentes a AWS:**
```
EC2 → Azure Virtual Machines
S3  → Azure Blob Storage
RDS → Azure SQL / Azure Database for PostgreSQL
EKS → AKS (Azure Kubernetes Service)
ECR → Azure Container Registry
IAM → Azure Active Directory (Entra ID)
```

---

### Google Cloud Platform (GCP)

**¿Qué es?**  
La plataforma cloud de Google (~10% del mercado). Líder en Machine Learning y Big Data.

```
EC2     → Google Compute Engine
S3      → Google Cloud Storage
EKS     → GKE (Google Kubernetes Engine) — el K8s original
Lambda  → Cloud Run / Cloud Functions
RDS     → Cloud SQL
ECR     → Artifact Registry
```

---

### Digital Ocean

**¿Qué es?**  
Cloud enfocado en simplicidad y precio. Muy popular entre desarrolladores independientes y startups.

```
Droplets    → VMs simples desde $4/mes
App Platform → PaaS (despliegue automático desde GitHub)
Managed K8s → Kubernetes sin el dolor de gestión
Spaces      → Almacenamiento compatible con S3
```

---

### Hetzner / Contabo

**¿Qué es?**  
Proveedores europeos con precios mucho más económicos. Populares en Europa y latinoamérica.

- **Hetzner**: VMs desde €3.29/mes, excelente rendimiento/precio
- **Contabo**: VPS baratos, mucha RAM por el precio

---

### Heroku

**¿Qué es?**  
PaaS (Platform as a Service). Desplegas con un `git push` y Heroku gestiona todo.

```bash
# Desplegar app en Heroku
heroku login
heroku create mi-app
git push heroku main  # ¡Listo! App desplegada
```

---

## 12. Serverless

**¿Qué es Serverless?**  
Modelo donde ejecutas código sin gestionar servidores. Pagas por ejecución (no por servidor activo 24/7).

```
Sin Serverless → Tienes un servidor siempre encendido (pagas 24/7)
Con Serverless → El código se ejecuta solo cuando hay una petición (pagas por llamada)
```

---

### AWS Lambda

**¿Para qué sirve?**  
Funciones que se ejecutan en respuesta a eventos (HTTP request, upload a S3, cambio en DynamoDB).

```javascript
// Lambda que procesa imágenes subidas a S3
exports.handler = async (event) => {
    const bucket = event.Records[0].s3.bucket.name;
    const key = event.Records[0].s3.object.key;
    
    console.log(`Nueva imagen subida: ${key} en bucket ${bucket}`);
    
    // Procesar imagen, generar thumbnail, etc.
    return { statusCode: 200, body: 'OK' };
};
```

---

### Cloudflare Workers

**¿Para qué sirve?**  
código JavaScript ejecutado en la edge de la red de Cloudflare (muy baja latencia worldwide).

```javascript
// Worker que agrega headers de seguridad
addEventListener('fetch', event => {
    event.respondWith(handle(event.request));
});

async function handle(request) {
    const response = await fetch(request);
    const newHeaders = new Headers(response.headers);
    newHeaders.set('X-Frame-Options', 'DENY');
    newHeaders.set('X-Content-Type-Options', 'nosniff');
    return new Response(response.body, { headers: newHeaders });
}
```

---

### Vercel / Netlify

**¿Para qué sirve?**  
Plataformas especializadas en desplegar frontends (React, Astro, Next.js) con serverless functions. Conexión directa con GitHub.

```bash
# Desplegar con Vercel
npm i -g vercel
vercel --prod  # ¡Desplegado con HTTPS y CDN global!
```

---

## 13. Gestión de Logs

Los logs son el registro de todo lo que pasa en tu sistema. Sin logs estás ciego.

---

### Loki (Grafana Loki)

**¿Qué es?**  
Sistema de agregación de logs de Grafana Labs. "Prometheus, pero para logs". Muy eficiente en almacenamiento.

**¿Para qué sirve?**
- Centralizar logs de todos tus contenedores/pods K8s
- Buscar en logs con LogQL (lenguaje similar a PromQL)
- Ver logs en Grafana junto a métricas

```yaml
# Instalar con Helm
helm repo add grafana https://grafana.github.io/helm-charts
helm install loki grafana/loki-stack -n monitoring

# Query en LogQL
{namespace="ecommerce"} |= "ERROR"               # Todos los errores
{app="ecommerce-app"} | json | status >= 500      # HTTP 5xx
rate({namespace="ecommerce"}[5m])                 # Rate de logs
```

---

### Elastic Stack (ELK)

**¿Qué es?**  
Suite completa: **E**lasticsearch + **L**ogstash + **K**ibana.

```
Logstash/Filebeat  → Recolectar y procesar logs
Elasticsearch      → Almacenar y buscar logs (motor de búsqueda)
Kibana             → Visualizar y explorar logs
```

**¿Para qué sirve?**
- Análisis de logs en tiempo real
- Búsqueda full-text en millones de logs
- Dashboards y alertas

---

### Splunk

**¿Qué es?**  
Plataforma enterprise de análisis de máquina de datos. La opción más potente (y cara).

**¿Para qué sirve?**
- SIEM (Security Information and Event Management)
- Correlación de eventos de seguridad
- Muy usado en bancos, gobierno, enterprises

---

### Papertrail

**¿Qué es?**  
SaaS de gestión de logs. Simple de configurar.

```bash
# Enviar logs de syslog a Papertrail
echo "*.* @logs.papertrailapp.com:XXXXX" >> /etc/rsyslog.conf
```

---

### Graylog

**¿Qué es?**  
Plataforma open source de gestión de logs. Alternativa self-hosted al ELK Stack.

---

## 14. Gestión de Configuración

IaC (Infrastructure as Code) para configurar y mantener el estado de tus servidores.

---

### Ansible

**¿Qué es?**  
Herramienta de automatización y Configuration Management basada en YAML y SSH. Sin agentes (agentless). Creada por Red Hat.

**¿Para qué sirve en DevOps?**
- Instalar y configurar software en servidores
- Mantener el estado deseado de la infraestructura
- Idempotente: ejecutar 10 veces = mismo resultado que ejecutar 1 vez

**Ejemplo de Playbook (nuestro proyecto):**
```yaml
# ansible/roles/docker/tasks/main.yml
---
- name: Actualizar apt cache
  apt:
    update_cache: yes
    cache_valid_time: 3600

- name: Instalar dependencias de Docker
  apt:
    name:
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg
    state: present

- name: Agregar GPG key de Docker
  apt_key:
    url: https://download.docker.com/linux/ubuntu/gpg
    state: present

- name: Agregar repositorio de Docker
  apt_repository:
    repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
    state: present

- name: Instalar Docker Engine
  apt:
    name:
      - docker-ce
      - docker-ce-cli
      - docker-compose-plugin
    state: present
    update_cache: yes

- name: Asegurar que Docker esté activo
  systemd:
    name: docker
    state: started
    enabled: yes
```

**Estructura de un proyecto Ansible:**
```
ansible/
├── inventory/
│   └── hosts.ini          # Servidores objetivo
├── roles/
│   ├── docker/
│   │   ├── tasks/main.yml
│   │   ├── templates/
│   │   └── vars/main.yml
│   ├── nginx/
│   ├── k3s/
│   └── jenkins/
├── playbooks/
│   ├── install-docker.yml
│   └── deploy-all.yml     # Playbook maestro
└── ansible.cfg
```

---

### Chef

**¿Qué es?**  
Framework de Configuration Management basado en Ruby. Arquitectura cliente-servidor. Más complejo que Ansible.

```ruby
# Recipe de Chef para instalar Nginx
package 'nginx' do
  action :install
end

service 'nginx' do
  action [:enable, :start]
end

template '/etc/nginx/sites-available/mi-app' do
  source 'nginx.conf.erb'
  notifies :restart, 'service[nginx]'
end
```

---

### Puppet

**¿Qué es?**  
Herramienta de Configuration Management con lenguaje declarativo propio (Puppet DSL). Arquitectura agente-maestro.

```puppet
# Manifest de Puppet para instalar y configurar Nginx
class nginx {
  package { 'nginx':
    ensure => installed,
  }
  service { 'nginx':
    ensure  => running,
    enable  => true,
    require => Package['nginx'],
  }
}
```

**Comparativa rápida:**
```
Ansible → Sin agentes, YAML, fácil de aprender. MEJOR para empezar.
Chef    → Requiere agente, Ruby. Flexible pero complejo.
Puppet  → Requiere agente, DSL propio. Muy maduro, enfocado en compliance.
Salt    → Arquitectura similar a Chef pero más rápido (ZeroMQ).
```

---

### Salt (SaltStack)

**¿Qué es?**  
Sistema de gestión de configuración y orquestación. Muy veloz gracias a su sistema de mensajería ZeroMQ.

---

## 15. Provisionamiento / IaC

Crear y gestionar infraestructura (VMs, redes, bases de datos) mediante código en lugar de consolas web.

---

### Terraform

**¿Qué es?**  
La herramienta de IaC más popular. Crea y gestiona infraestructura en cualquier cloud usando un lenguaje declarativo (HCL).

**¿Para qué sirve?**
- Crear VPCs, VMs, RDS, S3, EKS, etc. con código
- Infraestructura reproducible: el mismo código → misma infraestructura
- Plan de cambios antes de aplicar
- State: sabe qué recursos ya existen

**Ejemplo básico (crear EC2 en AWS):**
```hcl
# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Guardar estado en S3 (para trabajo en equipo)
  backend "s3" {
    bucket = "mi-terraform-state"
    key    = "ecommerce/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "ecommerce-vpc" }
}

# Instancia EC2
resource "aws_instance" "app_server" {
  ami           = "ami-0c7217cdde317cfec"  # Ubuntu 24.04
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.public.id
  
  tags = {
    Name        = "ecommerce-app"
    Environment = "production"
  }
}

# Base de datos RDS
resource "aws_db_instance" "postgres" {
  identifier        = "ecommerce-db"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  db_name           = "ecommerce"
  username          = "postgres"
  password          = var.db_password  # Variable sensible
}
```

**Comandos Terraform:**
```bash
terraform init      # Inicializar directorio y descargar providers
terraform plan      # Previsualizar cambios (no aplica nada)
terraform apply     # Aplicar cambios
terraform destroy   # Destruir toda la infraestructura
terraform output    # Ver outputs definidos
terraform state list  # Ver recursos en el state
```

---

### AWS CDK (Cloud Development Kit)

**¿Qué es?**  
Define infraestructura AWS usando lenguajes de programación reales (TypeScript, Python, Java, C#).

```typescript
// CDK en TypeScript
import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';

export class EcommerceStack extends cdk.Stack {
  constructor(scope: cdk.App, id: string) {
    super(scope, id);

    const vpc = new ec2.Vpc(this, 'EcommerceVPC', { maxAzs: 2 });
    
    const cluster = new ecs.Cluster(this, 'EcommerceCluster', { vpc });
    
    new ecs.FargateService(this, 'EcommerceService', {
      cluster,
      taskDefinition: new ecs.FargateTaskDefinition(this, 'TaskDef'),
    });
  }
}
```

---

### AWS CloudFormation

**¿Qué es?**  
Servicio nativo de AWS para IaC. Usa JSON o YAML. Es el servicio en el que se basa CDK.

```yaml
# template.yaml
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  MiEC2:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: ami-0c7217cdde317cfec
      InstanceType: t3.micro
      Tags:
        - Key: Name
          Value: EcommerceServer
```

---

### Pulumi

**¿Qué es?**  
Alternativa a Terraform que usa lenguajes de programación (Python, TypeScript, Go) en lugar de HCL. Multi-cloud.

```python
# Pulumi en Python
import pulumi_aws as aws

# Crear bucket S3
bucket = aws.s3.Bucket("mi-bucket",
    acl="private",
    tags={"Environment": "production"}
)
```

---

## 16. CI/CD Tools

**CI/CD = Continuous Integration / Continuous Delivery/Deployment**

```
CI (Integración Continua)    → Automatizar build y tests en cada push
CD (Entrega Continua)        → Generar artefacto listo para producción
CD (Despliegue Continuo)     → Desplegar automáticamente a producción
```

---

### Jenkins

**¿Qué es?**  
El servidor de automatización open source más popular. Altamente extensible con +1800 plugins.

**Nuestro Jenkinsfile (9 stages):**
```groovy
pipeline {
    agent any
    
    environment {
        IMAGE_NAME = "ecommerce-app"
        K3S_NAMESPACE = "ecommerce"
    }
    
    stages {
        stage('1. Verify Tools') {
            steps {
                sh 'docker --version'
                sh 'kubectl version --client'
            }
        }
        
        stage('2. Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/ITZAN44/Ecommerce-Proyecto-BD.git'
            }
        }
        
        stage('3. Build Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} ."
                sh "docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${IMAGE_NAME}:latest"
            }
        }
        
        stage('4. Import to K3s') {
            steps {
                sh "docker save ${IMAGE_NAME}:latest | k3s ctr images import -"
            }
        }
        
        stage('5. Deploy') {
            steps {
                sh "kubectl set image deployment/ecommerce-app ecommerce-app=${IMAGE_NAME}:latest -n ${K3S_NAMESPACE}"
            }
        }
        
        stage('6. Rollout Status') {
            steps {
                sh "kubectl rollout status deployment/ecommerce-app -n ${K3S_NAMESPACE} --timeout=120s"
            }
        }
        
        stage('7. Verify Pods') {
            steps {
                sh "kubectl get pods -n ${K3S_NAMESPACE}"
            }
        }
        
        stage('8. Health Check') {
            steps {
                sh "curl -f http://192.168.0.119/api/analytics/dashboard"
            }
        }
        
        stage('9. History') {
            steps {
                sh "kubectl rollout history deployment/ecommerce-app -n ${K3S_NAMESPACE}"
            }
        }
    }
    
    post {
        failure {
            sh "kubectl rollout undo deployment/ecommerce-app -n ${K3S_NAMESPACE}"
        }
    }
}
```

---

### GitHub Actions

**¿Qué es?**  
CI/CD integrado directamente en GitHub. No necesitas infraestructura adicional.

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npm test

  build-push:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_TOKEN }}
      - name: Build & Push
        uses: docker/build-push-action@v5
        with:
          push: true
          tags: miusuario/ecommerce:latest,${{ github.sha }}
```

---

### GitLab CI

**¿Qué es?**  
CI/CD integrado en GitLab. Definido en `.gitlab-ci.yml`.

```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy

variables:
  IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

test:
  stage: test
  image: node:20-alpine
  script:
    - npm ci
    - npm test

build:
  stage: build
  image: docker:24
  services:
    - docker:dind
  script:
    - docker build -t $IMAGE .
    - docker push $IMAGE

deploy:
  stage: deploy
  environment: production
  only:
    - main
  script:
    - kubectl set image deployment/app app=$IMAGE
```

---

### CircleCI

**¿Qué es?**  
Plataforma SaaS de CI/CD. Rápida y fácil de configurar.

---

### TeamCity

**¿Qué es?**  
Servidor CI/CD de JetBrains. Popular en entornos Java/.NET.

---

### Octopus Deploy

**¿Qué es?**  
Herramienta especializada en CD (Continuous Deployment). Gestión avanzada de releases y entornos.

---

## 17. Monitoreo de Infraestructura

**¿Por qué monitorear?**  
Sin monitoreo no sabes cuándo algo falla hasta que el usuario te llama. Con monitoreo sabes ANTES que el usuario.

```
Métricas   → Números a lo largo del tiempo (CPU 85%, req/s, latencia)
Alertas    → Notificaciones cuando una métrica supera un umbral
Dashboards → Visualización en tiempo real de las métricas
```

---

### Prometheus

**¿Qué es?**  
Sistema de monitoreo y base de datos de series temporales (time series). Recolecta métricas mediante "scraping" (polling HTTP).

**¿Para qué sirve?**
- Recolectar métricas de K8s, apps, bases de datos
- Almacenar métricas (por defecto 15 días)
- PromQL: lenguaje de consulta de métricas
- Base de alertas con Alertmanager

**Ejemplo PromQL:**
```promql
# CPU usage por pod
100 - (avg by(pod) (rate(container_cpu_usage_seconds_total[5m])) * 100)

# Memoria usada
container_memory_working_set_bytes{namespace="ecommerce"}

# Rate de requests HTTP 5xx en últimos 5 minutos
rate(http_requests_total{status=~"5.."}[5m])

# Alertar si CPU > 80% por más de 5 minutos
- alert: HighCPU
  expr: cpu_usage > 80
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "CPU alta en {{ $labels.instance }}"
```

---

### Grafana

**¿Qué es?**  
Plataforma de visualización y dashboards. Se conecta a múltiples fuentes (Prometheus, Loki, Elasticsearch, etc.)

**Nuestro setup (nuestro proyecto):**
```yaml
# Instalado con Helm: kube-prometheus-stack
# URL: http://192.168.0.119:30080
# Credenciales: admin / admin123

# prometheus-values.yaml
grafana:
  adminPassword: admin123
  service:
    type: NodePort
    nodePort: 30080

prometheus:
  prometheusSpec:
    retention: 15d
    storageSpec:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 10Gi
```

---

### Zabbix

**¿Qué es?**  
Solución de monitoreo enterprise open source. Usa agentes instalados en los servidores.

**¿Para qué sirve?**
- Monitoreo de servidores físicos y VMs
- SNMP para monitoreo de dispositivos de red (routers, switches)
- Muy maduro y estable, muchas empresas lo usan

---

### Datadog

**¿Qué es?**  
Plataforma SaaS de monitoreo (APM, infrastructure, logs, synthetic). Muy completa pero cara.

```yaml
# Instalar agente de Datadog en K8s
helm install datadog-agent datadog/datadog \
    --set datadog.apiKey=<TU_API_KEY> \
    --set datadog.site='datadoghq.com'
```

---

## 18. Gestión de Secretos

Los secretos (passwords, API keys, certificados) nunca deben estar en el código fuente.

---

### HashiCorp Vault

**¿Qué es?**  
La solución líder para gestión de secretos. Almacena y controla acceso a tokens, passwords, certificados, y claves de cifrado.

**¿Para qué sirve?**
- Centralizar todos los secretos de la organización
- Rotación automática de credenciales de DB
- PKI dinámico (genera certificados a demanda)
- Integración con K8s para inyectar secretos en pods

```bash
# Guardar un secreto
vault kv put secret/ecommerce/db \
    username="postgres" \
    password="SuperSecreta123!"

# Leer un secreto
vault kv get secret/ecommerce/db

# En una app (SDK de Vault)
import hvac
client = hvac.Client(url='http://vault:8200', token='...')
secret = client.secrets.kv.v2.read_secret_version(path='ecommerce/db')
db_password = secret['data']['data']['password']
```

---

### Sealed Secrets (Bitnami)

**¿Qué es?**  
Solución para K8s que cifra los Secrets de Kubernetes de forma que pueden guardarse de forma segura en Git.

```bash
# Cifrar un secret con kubeseal
kubectl create secret generic db-secret \
    --from-literal=password=MiPassword123 \
    --dry-run=client -o yaml | \
    kubeseal --controller-name=sealed-secrets --format yaml > sealed-secret.yaml

# Este archivo YA SE PUEDE subir a Git (está cifrado)
git add sealed-secret.yaml
git commit -m "Add sealed DB secret"
```

---

### ESO (External Secrets Operator)

**¿Qué es?**  
Operador K8s que sincroniza secretos desde proveedores externos (AWS Secrets Manager, Vault, GCP Secret Manager) a Kubernetes Secrets.

```yaml
# ExternalSecret que lee de AWS Secrets Manager
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: db-secret
  data:
    - secretKey: DB_PASSWORD
      remoteRef:
        key: production/ecommerce/db
        property: password
```

---

### SOPS (Secrets OPerationS)

**¿Qué es?**  
Herramienta de Mozilla para cifrar archivos de secretos con PGP, AWS KMS, o age.

```bash
# Cifrar archivo con age
sops --encrypt --age age1... secrets.yaml > secrets.enc.yaml

# Descifrar
sops --decrypt secrets.enc.yaml
```

---

## 19. Orquestación de Contenedores

Cuando tienes muchos contenedores, necesitas un sistema para gestionarlos todos.

---

### Kubernetes (K8s)

**¿Qué es?**  
El sistema de orquestación de contenedores más usado. Originado en Google, ahora gestionado por la CNCF.

**Conceptos clave:**
```
Pod          → Unidad mínima (uno o más contenedores)
Deployment   → Gestiona réplicas de Pods, rolling updates
Service      → Expone Pods con IP estable (ClusterIP, NodePort, LoadBalancer)
Ingress      → Reglas HTTP para exponer Services al exterior
ConfigMap    → Configuraión no sensible (variables de entorno)
Secret       → Datos sensibles cifrados en base64
PVC          → Disco persistente para Pods con estado
Namespace    → Aislamiento lógico de recursos
```

**Nuestro setup (K3s):**
```yaml
# k8s/app-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ecommerce-app
  namespace: ecommerce
spec:
  replicas: 2              # 2 instancias corriendo simultáneamente
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
        image: ecommerce-app:latest
        ports:
        - containerPort: 3000
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        livenessProbe:
          httpGet:
            path: /api/analytics/dashboard
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
```

**Comandos K8s esenciales:**
```bash
# Pods
kubectl get pods -n ecommerce
kubectl describe pod <nombre> -n ecommerce
kubectl logs <pod> -n ecommerce
kubectl exec -it <pod> -n ecommerce -- bash

# Deployments
kubectl get deployments -n ecommerce
kubectl rollout status deployment/ecommerce-app -n ecommerce
kubectl rollout undo deployment/ecommerce-app -n ecommerce    # Rollback
kubectl scale deployment/ecommerce-app --replicas=5 -n ecommerce

# Services
kubectl get svc -n ecommerce
kubectl port-forward svc/ecommerce-app 3000:80 -n ecommerce

# Ver todo
kubectl get all -n ecommerce
```

---

### K3s

**¿Qué es?**  
Distribución ligera de Kubernetes. Certificada pero con todo en un binario de menos de 100MB. Ideal para edge, IoT, y VMs con recursos limitados.

```bash
# Instalar K3s
curl -sfL https://get.k3s.io | sh -

# Verificar
kubectl get nodes
kubectl get pods -n kube-system
```

---

### GKE / EKS / AKS

**¿Qué son?**  
Kubernetes administrado en la nube. El proveedor gestiona el control plane (masters), tú solo manejas los worker nodes.

```
GKE → Google Kubernetes Engine (el original, mejor integración con GCP)
EKS → Elastic Kubernetes Service (AWS, muy popular en enterprises)
AKS → Azure Kubernetes Service (Microsoft, integración con Azure AD)
```

---

### AWS ECS / Fargate

**¿Qué es?**  
Servicio de orquestación de contenedores de AWS. ECS es la alternativa a K8s de AWS, Fargate es ECS sin gestión de VMs.

```
ECS + EC2    → Tú gestionas las VMs workers
ECS + Fargate → AWS gestiona todo, pagas por tarea (serverless)
```

---

### Docker Swarm

**¿Qué es?**  
Modo nativo de clustering de Docker. Más simple que K8s pero menos potente.

```bash
# Iniciar swarm
docker swarm init --advertise-addr 192.168.0.119

# Desplegar servicio con 3 réplicas
docker service create --name ecommerce --replicas 3 -p 3000:3000 mi-app:latest

# Escalar
docker service scale ecommerce=5
```

---

### OpenShift

**¿Qué es?**  
Plataforma K8s enterprise de Red Hat. K8s + seguridad adicional + developer tools + soporte comercial.

---

## 20. Observabilidad

Observabilidad va más allá del monitoreo. Son los 3 pilares:

```
Métricas  → ¿QUÉ está mal? (números: CPU, latencia, error rate)
Logs      → ¿QUÉ PASÓ? (registro textual de eventos)
Trazas    → ¿DÓNDE está el problema? (seguir una petición por todos los microservicios)
```

---

### Jaeger

**¿Qué es?**  
Sistema de distributed tracing open source. Originado en Uber.

**¿Para qué sirve?**
- Seguir una petición a través de múltiples microservicios
- Identificar cuellos de botella (¿qué servicio es lento?)
- Análisis de dependencias entre servicios

```javascript
// Instrumentar un microservicio Node.js con OpenTelemetry → Jaeger
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { JaegerExporter } = require('@opentelemetry/exporter-jaeger');

const sdk = new NodeSDK({
  traceExporter: new JaegerExporter({ endpoint: 'http://jaeger:14268/api/traces' }),
  serviceName: 'ecommerce-api',
});
sdk.start();
```

---

### OpenTelemetry

**¿Qué es?**  
Estándar abierto e instrumentación para generar y recolectar métricas, logs y trazas. Un SDK para múltiples backends.

---

### New Relic

**¿Qué es?**  
Plataforma APM (Application Performance Monitoring) SaaS. Muy fácil de integrar, muestra rendimiento de la app en producción.

---

### Dynatrace

**¿Qué es?**  
Plataforma de observabilidad con IA integrada. Detecta problemas automáticamente sin configurar alertas manualmente.

---

## 21. Gestión de Artefactos

Un artefacto es cualquier archivo de construcción: imágenes Docker, paquetes npm, JARs, etc.

---

### JFrog Artifactory

**¿Qué es?**  
Registry universal que soporta casi cualquier formato de paquetes (Docker, npm, Maven, pip, Helm, etc.)

**¿Para qué sirve?**
- Proxy y caché de repositorios públicos (npm, Docker Hub)
- Almacenar artefactos internos seguros
- Control de acceso granular por artefacto
- Escaneo de vulnerabilidades

---

### Nexus Repository

**¿Qué es?**  
Alternativa open source a Artifactory de Sonatype. Muy popular en entornos Java.

```bash
# Publicar imagen Docker al registry privado de Nexus
docker tag mi-app:latest nexus.empresa.com:5000/mi-app:latest
docker push nexus.empresa.com:5000/mi-app:latest
```

---

### Cloud Smithy

**¿Qué es?**  
Registry SaaS para paquetes y contenedores. Más simple que Artifactory.

---

## 22. GitOps

**¿Qué es GitOps?**  
Modelo operacional donde **Git es la única fuente de verdad** para la infraestructura y las aplicaciones. Todo cambio se hace mediante un PR, no ejecutando comandos manuales.

```
Desarrollo → Git Push → PR Review → Merge → GitOps Operator → K8s Cluster
```

**Principios GitOps:**
1. El sistema deseado está declarado en Git
2. Git es la única forma de cambiar el estado del sistema
3. Un operador compara el estado deseado (Git) vs actual (cluster) y lo reconcilia
4. Si hay drift (alguien hace cambios manuales), el operador los revierte

---

### ArgoCD

**¿Qué es?**  
El operador GitOps más popular para Kubernetes.

**¿Para qué sirve?**
- Sincroniza automáticamente tu repositorio Git con el cluster K8s
- UI visual del estado del cluster
- Rollbacks con un clic
- Multi-cluster: un ArgoCD puede gestionar múltiples clusters

```yaml
# Application en ArgoCD
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
    path: k8s                  # Carpeta con los manifiestos
  destination:
    server: https://kubernetes.default.svc
    namespace: ecommerce
  syncPolicy:
    automated:
      prune: true              # Eliminar recursos que ya no están en Git
      selfHeal: true           # Auto-reparar si alguien modifica manualmente
```

---

### FluxCD

**¿Qué es?**  
Alternativa a ArgoCD. Más orientado a CLI, sin tanto énfasis en UI. Nativo de GitOps Toolkit.

```bash
# Instalar Flux y conectar al repo
flux bootstrap github \
    --owner=ITZAN44 \
    --repository=Ecommerce-Proyecto-BD \
    --branch=main \
    --path=./k8s
```

---

## 23. Service Mesh

**¿Qué es un Service Mesh?**  
Capa de infraestructura dedicada a gestionar la comunicación entre microservicios. Añade: observabilidad, seguridad mTLS, tráfico controlado, sin cambiar el código de las apps.

```
Sin Service Mesh:  Microservicio A → (HTTP sin cifrar) → Microservicio B
Con Service Mesh:  Microservicio A → [Sidecar Proxy] → (mTLS) → [Sidecar Proxy] → Microservicio B
```

---

### Istio

**¿Qué es?**  
El service mesh más completo y popular. Inyecta un sidecar proxy (Envoy) en cada pod automáticamente.

**¿Para qué sirve?**
- **mTLS**: Comunicación cifrada y autenticada entre todos los microservicios
- **Traffic Management**: Canary deployments, A/B testing, circuit breaker
- **Observabilidad**: Métricas, trazas y logs automáticos sin código

```yaml
# Virtual Service para canary deployment (10% al nuevo, 90% al viejo)
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ecommerce-canary
spec:
  hosts:
  - ecommerce
  http:
  - route:
    - destination:
        host: ecommerce
        subset: stable
      weight: 90
    - destination:
        host: ecommerce
        subset: canary
      weight: 10
```

---

### Linkerd

**¿Qué es?**  
Service mesh más ligero y simple que Istio. Proxy escrito en Rust (ultraligero).

---

### Consul (HashiCorp)

**¿Qué es?**  
Service discovery + service mesh + key-value store. Más flexible, funciona también fuera de K8s.

---

### Envoy

**¿Qué es?**  
Proxy de alto rendimiento escrito en C++. Es el proxy que usa Istio como sidecar y Linkerd como data plane.

---

## 24. Cloud Design Patterns

Patrones arquitectónicos para construir sistemas robustos, escalables y disponibles en la nube.

---

### Availability (Disponibilidad)

**Patrones para alta disponibilidad:**

**Circuit Breaker:**
```
Si un microservicio falla repetidamente → "abrir el circuito" y devolver respuesta de fallback
Evita cascada de fallos (un servicio caído arrastra a todos los demás)

CLOSED → peticiones pasan normalmente
OPEN   → peticiones bloqueadas (fallback inmediato)
HALF-OPEN → se deja pasar una petición de prueba para ver si recuperó
```

**Health Endpoint:**
```bash
# Nuestro healthcheck
curl http://192.168.0.119/api/analytics/dashboard
# → 200 OK: sistema sano
# → 503: degradado
```

**Retry Pattern:**
```javascript
async function fetchWithRetry(url, maxRetries = 3) {
    for (let i = 0; i < maxRetries; i++) {
        try {
            return await fetch(url);
        } catch (error) {
            if (i === maxRetries - 1) throw error;
            await new Promise(r => setTimeout(r, 1000 * Math.pow(2, i))); // Backoff exponencial
        }
    }
}
```

---

### Data Management

**Patrones para gestión de datos:**

**Event Sourcing:**  
Guardar todos los eventos (acciones) en lugar del estado final. El estado actual se recalcula reproduciendo los eventos.

**CQRS (Command Query Responsibility Segregation):**  
Separar las operaciones de lectura (Query) de las de escritura (Command). Permite optimizar cada lado por separado.

```
API de escritura → Base de datos de escritura (optimizada para writes)
API de lectura   → Base de datos de lectura (replica, optimizada para reads)
```

---

### Design and Implementation

**Patrones de diseño:**

**Strangler Fig (Strangler Pattern):**  
Migrar gradualmente un monolito a microservicios. La nueva funcionalidad se hace en microservicio, la vieja se reemplaza poco a poco.

**Sidecar Pattern:**  
Agregar funcionalidades a un contenedor principal con un contenedor auxiliar (sidecar). Ej: Istio inyecta Envoy como sidecar automáticamente.

**Ambassador Pattern:**  
Proxy especializado que gestiona requests salientes (retry, circuit breaker, logging).

---

### Management and Monitoring

**Patrones de gestión:**

**Health Check Pattern:**
```yaml
# K8s liveness y readiness probes
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 5
```

**Bulkhead Pattern:**  
Aislar recursos para que un componente fallido no afecte a los demás. Como los compartimentos estancos de un barco.

```
Thread pool separado por microservicio → Si uno se satura, no afecta a los otros
```

---

## RESUMEN — Mapa de Tecnologías

| Categoría | Herramientas que conocemos |
|-----------|---------------------------|
| Programming | Python, Go, JavaScript/Node.js |
| OS | Linux (Ubuntu 24.04), Windows + WSL2 |
| Scripting | Bash, PowerShell |
| VCS | Git, GitHub |
| Containers | Docker, Docker Compose |
| Web Server | Nginx (✓ implementado) |
| Networking | HTTP/S, SSH, DNS |
| Cloud | AWS (pendiente), Hetzner/Contabo |
| Configuration Management | Ansible (✓ implementado — 4 roles) |
| IaC / Provisioning | Terraform (pendiente AWS) |
| CI/CD | Jenkins (✓ implementado — 9 stages) |
| Container Orchestration | Kubernetes / K3s (✓ implementado) |
| Monitoring | Prometheus + Grafana (✓ implementado) |
| Logs | Loki (pendiente) |
| Secret Management | Vault (pendiente), Docker Secrets (✓) |
| GitOps | ArgoCD (pendiente) |
| Service Mesh | Istio (pendiente) |
| Cloud Patterns | Health Check (✓), Circuit Breaker (pendiente) |

---

## ESTADO ACTUAL EN EL ROADMAP

```
✅ COMPLETADO
├── Operating System (Ubuntu 24.04 + Windows + WSL2)
├── Terminal & Scripting (Bash + PowerShell)
├── Git & GitHub
├── Docker (multi-stage, compose, secrets)
├── Nginx (reverse proxy, gzip, cache)
├── Kubernetes / K3s (2 replicas, PVC, Traefik)
├── Jenkins CI/CD (9-stage pipeline, Poll SCM)
├── Ansible (4 roles, playbook maestro)
└── Prometheus + Grafana (13 targets, 15d retention)

🔄 EN PROGRESO / PRÓXIMOS
├── AWS (EC2, RDS, EKS, ECR, S3, ALB) — Fase 1
├── Terraform (VPC, RDS, EKS modules) — Fase 2
├── Loki (centralización de logs) — Fase 3
├── Alertmanager (Slack/Email) — Fase 3
├── ArgoCD (GitOps) — Fase 4
├── Vault (gestión de secretos) — Fase 4
├── cert-manager (HTTPS automático) — Fase 4
└── Istio (Service Mesh) — Fase 5
```

---

*Archivo generado para estudio del Roadmap DevOps — Proyecto Ecommerce BD*  
*Fecha: Marzo 2026*
