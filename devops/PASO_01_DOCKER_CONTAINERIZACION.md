# 🚀 INFORME TÉCNICO: Despliegue Docker en Producción - Ecommerce Astro + PostgreSQL

**Fecha:** 16 de Diciembre, 2025  
**Proyecto:** Ecommerce con Astro.js y PostgreSQL  
**Objetivo:** Implementación de containerización profesional con Docker en VM Ubuntu 24.04  
**Estado:** ✅ COMPLETADO CON ÉXITO

---

## 📋 TABLA DE CONTENIDOS

1. [Contexto del Proyecto](#contexto)
2. [Instalación de Docker en Ubuntu 24.04](#instalacion-docker)
3. [Arquitectura Implementada](#arquitectura)
4. [Archivos Creados y Modificados](#archivos)
5. [Proceso de Despliegue Paso a Paso](#despliegue)
6. [Problemas Encontrados y Soluciones](#troubleshooting)
7. [Comandos de Administración](#comandos)
8. [Verificación y Testing](#verificacion)
9. [Próximos Pasos](#proximos-pasos)

---

## 🎯 CONTEXTO DEL PROYECTO {#contexto}

### Aplicación
- **Framework:** Astro v5.15.4 con SSR (Server-Side Rendering)
- **Adapter:** @astrojs/node en modo standalone
- **Base de Datos:** PostgreSQL 16
- **ORM/Cliente:** node-postgres (pg)
- **Estilos:** TailwindCSS 4.1.17
- **Visualización:** Chart.js 4.5.1

### Datos en Producción
- **62 categorías** de productos
- **8 clientes** registrados
- **15 cupones** activos
- **27 pedidos** con historial completo
- **Funciones almacenadas:** Analytics, validaciones, auditoría
- **Triggers:** Control de stock, registro de cambios, timeline
- **Vistas materializadas:** Clientes VIP, top productos
- **Índices optimizados:** Para queries de alta frecuencia

### Infraestructura
- **Entorno:** VirtualBox VM
- **SO:** Ubuntu Linux 24.04 LTS
- **Acceso:** SSH (PuTTY desde Windows)
- **IP VM:** 192.168.0.119
- **Docker:** Docker Engine con Compose V2 (v5.0.0)

---

## 🐳 INSTALACIÓN DE DOCKER EN UBUNTU 24.04 {#instalacion-docker}

### 1. Solución de Problema Inicial: Docker Daemon

**Problema detectado:**
```bash
sudo systemctl status docker
# Error: failed to load listeners: no sockets found via socket activation
```

**Causa:** El socket de Docker no estaba activo antes del daemon.

**Solución aplicada:**
```bash
# Detener docker
sudo systemctl stop docker

# Reiniciar el socket primero
sudo systemctl restart docker.socket

# Verificar que el socket esté activo
sudo systemctl status docker.socket

# Ahora iniciar Docker
sudo systemctl start docker

# Habilitar inicio automático
sudo systemctl enable docker
```

### 2. Configuración de Permisos

```bash
# Agregar usuario al grupo docker (evita usar sudo)
sudo usermod -aG docker clark

# Aplicar cambios de grupo inmediatamente
newgrp docker

# Verificar funcionamiento
docker ps
docker --version
```

**Resultado:**
- Docker Engine instalado correctamente
- Docker Compose V2 (plugin) funcional
- Usuario `clark` con permisos sin sudo

---

## 🏗️ ARQUITECTURA IMPLEMENTADA {#arquitectura}

### Diagrama de Componentes

```
┌─────────────────────────────────────────────────┐
│          WINDOWS (Desarrollo)                   │
│  - VS Code con código fuente                    │
│  - Git para control de versiones                │
│  - Navegador para testing                       │
└──────────────────┬──────────────────────────────┘
                   │ SSH/SCP
                   │ GitHub
                   ▼
┌─────────────────────────────────────────────────┐
│      VM UBUNTU 24.04 (Producción)               │
│                                                  │
│  ┌────────────────────────────────────────┐    │
│  │   Docker Network: ecommerce_network    │    │
│  │                                         │    │
│  │  ┌──────────────────────────────────┐  │    │
│  │  │  ecommerce_db_prod               │  │    │
│  │  │  - postgres:16-alpine            │  │    │
│  │  │  - Puerto: 5432                  │  │    │
│  │  │  - Volumen persistente           │  │    │
│  │  │  - Health checks                 │  │    │
│  │  │  - Secrets management            │  │    │
│  │  └──────────────────────────────────┘  │    │
│  │              ▲                          │    │
│  │              │ Conexión interna         │    │
│  │              ▼                          │    │
│  │  ┌──────────────────────────────────┐  │    │
│  │  │  ecommerce_app_prod              │  │    │
│  │  │  - ecommerce-app:1.0.0           │  │    │
│  │  │  - Node 20-alpine                │  │    │
│  │  │  - Puerto: 4321                  │  │    │
│  │  │  - Multi-stage build             │  │    │
│  │  │  - Usuario no-root (astro)       │  │    │
│  │  └──────────────────────────────────┘  │    │
│  └────────────────────────────────────────┘    │
│                   │                             │
└───────────────────┼─────────────────────────────┘
                    │ Puerto 4321
                    ▼
        http://192.168.0.119:4321
```

### Características de Seguridad Implementadas

1. **Docker Secrets** para passwords (PostgreSQL)
2. **Usuario no-root** en contenedor de aplicación
3. **Variables de entorno** separadas por ambiente
4. **Health checks** automáticos
5. **Resource limits** (CPU y memoria)
6. **Restart policies** configuradas
7. **Network isolation** con bridge privado

---

## 📁 ARCHIVOS CREADOS Y MODIFICADOS {#archivos}

### 1. Dockerfile (Multi-Stage Build)

**Ubicación:** `./Dockerfile`

**Propósito:** Optimizar imagen de producción usando compilación en dos etapas.

**Contenido:**
```dockerfile
# ============================================
# STAGE 1: Build - Compilar la aplicación
# ============================================
FROM node:20-alpine AS builder

WORKDIR /app

# Copiar solo package files primero (aprovecha cache de Docker)
COPY package*.json ./

# Instalar TODAS las dependencias (incluidas devDependencies para build)
RUN npm ci

# Copiar el código fuente
COPY . .

# Compilar la aplicación Astro para producción
RUN npm run build

# ============================================
# STAGE 2: Production - Imagen final ligera
# ============================================
FROM node:20-alpine AS production

# Crear usuario no-root por seguridad
RUN addgroup -g 1001 -S nodejs && \
    adduser -S astro -u 1001

WORKDIR /app

# Copiar solo package files
COPY package*.json ./

# Instalar SOLO dependencias de producción
RUN npm ci --only=production && \
    npm cache clean --force

# Copiar el build desde la etapa anterior
COPY --from=builder --chown=astro:nodejs /app/dist ./dist

# Cambiar a usuario no-root
USER astro

# Exponer puerto
EXPOSE 4321

# Variables de entorno por defecto
ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=4321

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:4321/api/analytics/dashboard', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Comando para producción
CMD ["node", "./dist/server/entry.mjs"]
```

**Ventajas:**
- Tamaño reducido: ~200MB vs ~584MB (65% más ligero)
- Solo dependencias de producción
- Usuario no-root (seguridad)
- Health check integrado

---

### 2. docker-compose.production.yml

**Ubicación:** `./docker-compose.production.yml`

**Propósito:** Orquestación de servicios en producción.

**Contenido completo:**
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: ecommerce_db_prod
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${DB_USER:-postgres}
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
      POSTGRES_DB: ${DB_NAME:-ecommerce_db}
    secrets:
      - db_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data_prod:/var/lib/postgresql/data
      - ./database/backup_bd_real.sql:/docker-entrypoint-initdb.d/01_backup.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-postgres} -d ${DB_NAME:-ecommerce_db}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - ecommerce_network
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M

  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    image: ecommerce-app:${VERSION:-latest}
    container_name: ecommerce_app_prod
    restart: unless-stopped
    ports:
      - "4321:4321"
    environment:
      NODE_ENV: production
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: ${DB_NAME:-ecommerce_db}
      DB_USER: ${DB_USER:-postgres}
      DB_PASSWORD: ${DB_PASSWORD}
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - ecommerce_network
    healthcheck:
      test: ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:4321 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M

networks:
  ecommerce_network:
    driver: bridge

volumes:
  postgres_data_prod:
    driver: local

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

---

### 3. .env.production

**Ubicación:** `./env.production` (NO commitear a Git)

**Contenido:**
```bash
DB_USER=postgres
DB_NAME=ecommerce_db
DB_PASSWORD=12345678
VERSION=1.0.0
```

---

### 4. secrets/db_password.txt

**Ubicación:** `./secrets/db_password.txt`

**Creación:**
```bash
echo -n "12345678" > secrets/db_password.txt
chmod 600 secrets/db_password.txt
```

---

### 5. .gitignore (Actualizado)

**Agregado:**
```gitignore
# Docker secrets (NUNCA commitear)
secrets/
*.secret
*.key
```

---

## 🚀 PROCESO DE DESPLIEGUE PASO A PASO {#despliegue}

### FASE 1: Preparación en Windows

#### 1.1. Crear archivos Docker
```powershell
# Ya realizado:
# - Dockerfile
# - docker-compose.production.yml
# - .env.production.example
# - secrets/README.md
```

#### 1.2. Commit y push a GitHub
```powershell
cd C:\Users\User\Documents\Universidad\BS2\BD_01\Proyecto-BS2\Ecommers-Proyecto

git add Dockerfile docker-compose.production.yml .env.production.example .gitignore
git add -f secrets/README.md
git commit -m "feat: Add production Docker configuration"
git push origin main
```

---

### FASE 2: Configuración en VM Ubuntu

#### 2.1. Clonar repositorio
```bash
cd ~
git clone https://github.com/ITZAN44/Ecommerce-Proyecto-BD.git
cd Ecommerce-Proyecto-BD
```

#### 2.2. Configurar secrets
```bash
# Crear archivo de password
echo -n "12345678" > secrets/db_password.txt
chmod 600 secrets/db_password.txt
```

#### 2.3. Crear .env.production
```bash
cat > .env.production << 'EOF'
DB_USER=postgres
DB_NAME=ecommerce_db
DB_PASSWORD=12345678
VERSION=1.0.0
EOF
```

#### 2.4. Copiar backup de base de datos desde Windows

**En Windows (PowerShell):**
```powershell
scp C:\Users\User\Documents\Universidad\BS2\BD_01\Proyecto-BS2\Ecommers-Proyecto\database\backup_bd_real.sql clark@192.168.0.119:~/Ecommerce-Proyecto-BD/database/
```

**En VM Ubuntu:**
```bash
# Eliminar directorio falso si existe
sudo rm -rf database/backup_bd_real.sql

# Verificar que el archivo se copió correctamente
file database/backup_bd_real.sql
ls -lh database/backup_bd_real.sql
```

---

### FASE 3: Construcción y Despliegue

#### 3.1. Construir imágenes Docker
```bash
docker compose -f docker-compose.production.yml --env-file .env.production build
```

**Tiempo de construcción:** ~5-6 minutos en primera ejecución.

**Salida esperada:**
```
[+] Building 346.4s (14/16)
 => [builder 1/6] FROM docker.io/library/node:20-alpine
 => [builder 4/6] RUN npm ci
 => [builder 6/6] RUN npm run build
 => [production 5/6] RUN npm ci --only=production
✔ Image ecommerce-app:1.0.0 Built
```

#### 3.2. Levantar servicios
```bash
docker compose -f docker-compose.production.yml --env-file .env.production up -d
```

**Salida esperada:**
```
[+] up 4/4
 ✔ Network ecommerce-proyecto-bd_ecommerce_network Created
 ✔ Volume ecommerce-proyecto-bd_postgres_data_prod Created
 ✔ Container ecommerce_db_prod                     Healthy
 ✔ Container ecommerce_app_prod                    Started
```

#### 3.3. Verificar logs
```bash
docker compose -f docker-compose.production.yml logs -f
```

**Mensajes clave a buscar:**
- PostgreSQL: `database system is ready to accept connections`
- PostgreSQL: `COPY 62` (categorías), `COPY 8` (clientes), `COPY 27` (pedidos)
- App: `Server listening on http://localhost:4321`

---

## 🔧 PROBLEMAS ENCONTRADOS Y SOLUCIONES {#troubleshooting}

### Problema 1: Docker Daemon no inicia

**Error:**
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
failed to load listeners: no sockets found via socket activation
```

**Causa:** El socket de systemd no estaba activo antes del daemon.

**Solución:**
```bash
sudo systemctl stop docker
sudo systemctl restart docker.socket
sudo systemctl start docker
sudo systemctl enable docker
```

---

### Problema 2: docker-compose antiguo (v1) incompatible

**Error:**
```
ModuleNotFoundError: No module named 'distutils'
```

**Causa:** Ubuntu 24.04 con Python 3.12 no soporta docker-compose v1.

**Solución:** Usar Docker Compose V2 (plugin):
```bash
# Comando correcto (con espacio):
docker compose version

# NO usar (con guion):
docker-compose version
```

---

### Problema 3: backup_bd_real.sql es un directorio

**Error:**
```
psql: error: could not read from input file: Is a directory
```

**Causa:** Git no rastreó el archivo grande (10MB), creó directorio vacío.

**Solución:** Copiar archivo manualmente con SCP desde Windows.

---

### Problema 4: Error de autenticación PostgreSQL

**Error:**
```json
{"error":"SASL: SCRAM-SERVER-FIRST-MESSAGE: client password must be a string"}
```

**Causa:** El cliente `pg` de Node.js no soporta `DB_PASSWORD_FILE`, solo PostgreSQL server lo soporta.

**Solución:** Cambiar configuración en `docker-compose.production.yml`:

**Antes (no funciona para app):**
```yaml
app:
  environment:
    DB_PASSWORD_FILE: /run/secrets/db_password
  secrets:
    - db_password
```

**Después (correcto):**
```yaml
app:
  environment:
    DB_PASSWORD: ${DB_PASSWORD}
  # secrets eliminado del servicio app
```

---

## 📋 COMANDOS DE ADMINISTRACIÓN {#comandos}

### Gestión de Contenedores

```bash
# Ver contenedores corriendo
docker ps

# Ver todos los contenedores (incluyendo detenidos)
docker ps -a

# Ver logs en tiempo real
docker compose -f docker-compose.production.yml logs -f

# Ver logs solo de la app
docker compose -f docker-compose.production.yml logs -f app

# Ver logs solo de PostgreSQL
docker compose -f docker-compose.production.yml logs -f postgres

# Reiniciar solo la aplicación (sin tocar DB)
docker compose -f docker-compose.production.yml restart app

# Detener todos los servicios
docker compose -f docker-compose.production.yml down

# Detener y eliminar volúmenes (⚠️ BORRA DATOS)
docker compose -f docker-compose.production.yml down -v

# Recrear un servicio específico
docker compose -f docker-compose.production.yml up -d --force-recreate app
```

### Monitoreo de Recursos

```bash
# Ver uso de CPU, RAM, red en tiempo real
docker stats

# Ver uso de disco por Docker
docker system df

# Ver detalles de un contenedor
docker inspect ecommerce_app_prod
```

### Acceso a Contenedores

```bash
# Ejecutar bash en contenedor de app (si está disponible)
docker exec -it ecommerce_app_prod sh

# Conectar a PostgreSQL con psql
docker exec -it ecommerce_db_prod psql -U postgres -d ecommerce_db

# Ejecutar query SQL directamente
docker exec -it ecommerce_db_prod psql -U postgres -d ecommerce_db -c "SELECT COUNT(*) FROM categorias;"
```

### Limpieza

```bash
# Eliminar imágenes huérfanas
docker image prune

# Eliminar contenedores detenidos
docker container prune

# Limpieza profunda (⚠️ cuidado)
docker system prune -a
```

---

## ✅ VERIFICACIÓN Y TESTING {#verificacion}

### Tests desde VM Ubuntu

```bash
# 1. Verificar que contenedores estén corriendo y saludables
docker ps
# Debe mostrar:
# - ecommerce_db_prod con estado "healthy"
# - ecommerce_app_prod con estado "Up"

# 2. Probar API de analytics
curl http://localhost:4321/api/analytics/dashboard

# Salida esperada (JSON con datos):
# {"totalVentas": XXX, "totalPedidos": 27, ...}

# 3. Probar endpoint de productos
curl http://localhost:4321/api/productos

# 4. Verificar datos en PostgreSQL
docker exec -it ecommerce_db_prod psql -U postgres -d ecommerce_db -c "
SELECT 
  (SELECT COUNT(*) FROM categorias) as categorias,
  (SELECT COUNT(*) FROM clientes) as clientes,
  (SELECT COUNT(*) FROM cupones) as cupones,
  (SELECT COUNT(*) FROM pedidos) as pedidos;
"

# Salida esperada:
#  categorias | clientes | cupones | pedidos
# ------------+----------+---------+---------
#          62 |        8 |      15 |      27
```

### Tests desde Windows

**Navegador:** `http://192.168.0.119:4321`

**Verificaciones visuales:**
- ✅ Página principal carga correctamente
- ✅ Menú de navegación funcional
- ✅ Gráficos Chart.js se renderizan
- ✅ Datos de productos visibles
- ✅ Timeline de pedidos funcional

**PowerShell:**
```powershell
# Probar desde Windows
Invoke-WebRequest -Uri "http://192.168.0.119:4321/api/analytics/dashboard"
```

---

## 🎯 PRÓXIMOS PASOS (ROADMAP DEVOPS) {#proximos-pasos}

### PASO 2: Nginx como Reverse Proxy ⏭️ SIGUIENTE

**Objetivos:**
- Configurar Nginx en Ubuntu
- Proxy pass a puerto 4321
- Servir en puerto 80 (HTTP estándar)
- Configurar SSL/TLS con Let's Encrypt (HTTPS)
- Agregar compresión gzip
- Configurar cache de assets estáticos

**Archivos a crear:**
```nginx
# /etc/nginx/sites-available/ecommerce
server {
    listen 80;
    server_name ecommerce.local;

    location / {
        proxy_pass http://localhost:4321;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

### PASO 3: Orquestación con Kubernetes (K3s)

**Objetivos:**
- Instalar K3s en VM Ubuntu
- Migrar de Docker Compose a Kubernetes
- Crear Deployments, Services, ConfigMaps
- Implementar escalado horizontal (replicas)
- Configurar Ingress Controller

**Archivos a crear:**
- `k8s/deployment-postgres.yaml`
- `k8s/deployment-app.yaml`
- `k8s/service-postgres.yaml`
- `k8s/service-app.yaml`
- `k8s/configmap.yaml`
- `k8s/secrets.yaml`
- `k8s/ingress.yaml`

---

### PASO 4: CI/CD con Jenkins

**Objetivos:**
- Instalar Jenkins en contenedor Docker
- Crear pipeline Jenkinsfile
- Automatizar: git push → build → test → deploy
- Integrar con GitHub webhooks
- Notificaciones de deployment

**Pipeline básico:**
```groovy
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/ITZAN44/Ecommerce-Proyecto-BD.git'
            }
        }
        stage('Build') {
            steps {
                sh 'docker compose -f docker-compose.production.yml build'
            }
        }
        stage('Deploy') {
            steps {
                sh 'docker compose -f docker-compose.production.yml up -d'
            }
        }
    }
}
```

---

### PASO 5: IaC con Ansible

**Objetivos:**
- Crear playbooks Ansible
- Automatizar configuración de VM desde cero
- Instalar Docker, Nginx, dependencias
- Deployar aplicación completa
- Idempotencia y reusabilidad

**Estructura:**
```yaml
# playbook.yml
- hosts: production
  become: yes
  roles:
    - docker
    - nginx
    - ecommerce-app
```

---

### PASO 6: Monitoreo con Prometheus + Grafana

**Objetivos:**
- Instalar Prometheus en contenedor
- Configurar exporters (node_exporter, postgres_exporter)
- Desplegar Grafana
- Crear dashboards de monitoreo
- Configurar alertas (CPU, RAM, disco)

**Métricas a monitorear:**
- CPU y RAM de contenedores
- Conexiones activas a PostgreSQL
- Tiempo de respuesta de endpoints
- Tasa de errores HTTP
- Espacio en disco

---

## 📊 RESUMEN DE LOGROS

### ✅ Completado

| # | Tarea | Estado | Fecha |
|---|-------|--------|-------|
| 1 | Instalación Docker en Ubuntu | ✅ | 16/12/2025 |
| 2 | Dockerfile multi-stage | ✅ | 16/12/2025 |
| 3 | docker-compose.production.yml | ✅ | 16/12/2025 |
| 4 | Gestión de secrets | ✅ | 16/12/2025 |
| 5 | Carga de datos reales (62 cat, 8 cli, 27 ped) | ✅ | 16/12/2025 |
| 6 | Health checks configurados | ✅ | 16/12/2025 |
| 7 | Resource limits (CPU/RAM) | ✅ | 16/12/2025 |
| 8 | Aplicación accesible en red | ✅ | 16/12/2025 |

### 🔄 En Progreso

| # | Tarea | Estado |
|---|-------|--------|
| 9 | Nginx Reverse Proxy | ⏭️ Siguiente |
| 10 | SSL/TLS (Let's Encrypt) | 📋 Planeado |

### 📅 Pendiente

| # | Tarea | Prioridad |
|---|-------|-----------|
| 11 | Kubernetes (K3s) | Alta |
| 12 | CI/CD Jenkins | Alta |
| 13 | IaC Ansible | Media |
| 14 | Monitoreo Prometheus/Grafana | Media |

---

## 🔐 INFORMACIÓN SENSIBLE (NO COMPARTIR)

### Credenciales

```
VM Ubuntu:
- Usuario: clark
- IP: 192.168.0.119
- Puerto SSH: 22

PostgreSQL:
- Usuario: postgres
- Password: 12345678
- Base de datos: ecommerce_db
- Puerto: 5432

Docker Registry:
- No configurado aún
```

---

## 📖 REFERENCIAS Y DOCUMENTACIÓN

### Enlaces Útiles

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [Astro Documentation](https://docs.astro.build/)
- [PostgreSQL Docker Official Image](https://hub.docker.com/_/postgres)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)

### Archivos de Configuración en Repositorio

```
├── Dockerfile                          # Multi-stage build optimizado
├── docker-compose.yml                  # Desarrollo local
├── docker-compose.production.yml       # Producción
├── .dockerignore                       # Exclusiones de build
├── .env.production.example             # Template de variables
├── secrets/
│   └── README.md                       # Instrucciones de secrets
└── database/
    ├── backup_bd_real.sql             # Datos completos (10MB)
    ├── schema.sql                     # Estructura de tablas
    ├── functions_procedures_LIMPIO.sql # Funciones almacenadas
    └── seed.sql                       # Datos de prueba
```

---

## 👨‍💻 AUTORES Y CONTRIBUTORS

**Implementado por:** ITZAN44 con asistencia de GitHub Copilot  
**Fecha de inicio:** Diciembre 2025  
**Repositorio:** https://github.com/ITZAN44/Ecommerce-Proyecto-BD

---

**FIN DEL INFORME**

*Documento generado automáticamente el 16/12/2025*  
*Versión: 1.0.0*
