# 🔀 PASO 2: NGINX COMO REVERSE PROXY

**Fecha de implementación:** 18 de Diciembre, 2025
**Duración:** ~25 minutos
**Nivel:** DevOps Intermedio
**Estado:** ✅ COMPLETADO CON ÉXITO

---

## 📋 ÍNDICE

1. [Objetivo del Paso](#objetivo)
2. [Prerrequisitos](#prerrequisitos)
3. [Conceptos Clave DevOps](#conceptos)
4. [Arquitectura Before/After](#arquitectura)
5. [Proceso de Implementación](#implementacion)
6. [Configuración Detallada](#configuracion)
7. [Validación y Testing](#testing)
8. [Troubleshooting](#troubleshooting)
9. [Comandos de Administración](#comandos)
10. [Métricas y Monitoreo](#metricas)
11. [Mejores Prácticas](#best-practices)
12. [Próximos Pasos](#next-steps)

---

## 🎯 OBJETIVO DEL PASO

### ¿Qué logramos?

Implementar **Nginx como Reverse Proxy** para servir nuestra aplicación Ecommerce en el **puerto estándar HTTP (80)**, agregando:

- ✅ **Acceso simplificado** sin especificar puerto (http://IP en lugar de http://IP:4321)
- ✅ **Compresión gzip** para reducir tamaño de respuestas en ~70%
- ✅ **Cache de assets estáticos** (imágenes, CSS, JS) por 1 año
- ✅ **Headers de seguridad** (X-Forwarded-*, X-Real-IP)
- ✅ **Logs centralizados** para análisis y debugging
- ✅ **Health check endpoint** (/health) para monitoreo
- ✅ **Preparación para SSL/TLS** (HTTPS en el futuro)

### ¿Por qué es importante en DevOps?

En producción real, **NUNCA expones directamente** tu aplicación. Nginx actúa como:

1. **Gateway de entrada** único para todo el tráfico
2. **Load balancer** (para múltiples instancias de la app)
3. **SSL termination** (maneja HTTPS, app solo HTTP)
4. **Cache layer** (reduce carga en backend)
5. **Security layer** (rate limiting, IP filtering, WAF)
6. **Observability point** (logs, métricas centralizadas)

---

## ✅ PRERREQUISITOS

### Estado Inicial (del Paso 1)

```bash
# Contenedores Docker corriendo
docker ps
# CONTAINER ID   IMAGE                 STATUS
# 7763e781fb4c   ecommerce-app:1.0.0   Up 5 minutes (healthy)
# c9d760b5c91f   postgres:16-alpine    Up 5 minutes (healthy)

# Aplicación accesible en puerto 4321
curl http://localhost:4321/api/analytics/dashboard
# {"total_pedidos_hoy":0,...}
```

### Herramientas Necesarias

| Herramienta      | Versión | Verificación        |
| ---------------- | -------- | -------------------- |
| **Nginx**  | 1.24.0+  | `nginx -v`         |
| **Docker** | 20.10+   | `docker --version` |
| **UFW**    | -        | `sudo ufw status`  |
| **curl**   | -        | `curl --version`   |

---

## 🧠 CONCEPTOS CLAVE DEVOPS

### 1. Reverse Proxy vs Forward Proxy

```
FORWARD PROXY (Cliente → Proxy → Internet):
Cliente oculta su IP usando proxy para navegar

REVERSE PROXY (Cliente → Proxy → Servidor):
Servidor oculta sus backends usando proxy como gateway
```

**Reverse Proxy** es lo que implementamos:

```
Usuario → Nginx (192.168.0.119:80) → Docker (localhost:4321)
```

### 2. Upstream

Grupo de servidores backend que Nginx puede balancear:

```nginx
upstream backend_app {
    server localhost:4321;
    # Podrías agregar más:
    # server localhost:4322;
    # server localhost:4323;
    keepalive 32;  # Conexiones persistentes
}
```

### 3. Proxy Pass

Directiva que redirige requests al backend:

```nginx
location / {
    proxy_pass http://backend_app;
}
```

### 4. Headers HTTP

**Sin Nginx:**

```http
GET / HTTP/1.1
Host: 192.168.0.119:4321
```

**Con Nginx (headers adicionales):**

```http
GET / HTTP/1.1
Host: 192.168.0.119
X-Real-IP: 192.168.0.100
X-Forwarded-For: 192.168.0.100
X-Forwarded-Proto: http
```

---

## 🏗️ ARQUITECTURA BEFORE/AFTER

### ANTES (Solo Docker - Paso 1)

```
┌─────────────────────────────────────────┐
│   Cliente (Navegador Windows)          │
│   http://192.168.0.119:4321             │
└──────────────┬──────────────────────────┘
               │ Puerto 4321 expuesto
               │ Conexión directa
               ▼
┌─────────────────────────────────────────┐
│   VM Ubuntu                             │
│                                         │
│   ┌───────────────────────────────┐    │
│   │ Docker Container              │    │
│   │ ecommerce_app_prod            │    │
│   │ Astro App (Node 20)           │    │
│   │ 0.0.0.0:4321 → 4321           │    │
│   └───────────┬───────────────────┘    │
│               │                         │
│   ┌───────────▼───────────────────┐    │
│   │ Docker Container              │    │
│   │ ecommerce_db_prod             │    │
│   │ PostgreSQL 16                 │    │
│   └───────────────────────────────┘    │
└─────────────────────────────────────────┘

⚠️ Problemas:
- Puerto no estándar (4321)
- Sin compresión
- Sin cache
- Logs solo en Docker
- Difícil escalar
```

### DESPUÉS (Docker + Nginx - Paso 2)

```
┌─────────────────────────────────────────┐
│   Cliente (Navegador Windows)          │
│   http://192.168.0.119 ← Puerto 80     │
└──────────────┬──────────────────────────┘
               │ HTTP estándar
               │ 
               ▼
┌─────────────────────────────────────────┐
│   VM Ubuntu                             │
│                                         │
│   ┌───────────────────────────────┐    │
│   │ Nginx (Reverse Proxy)         │    │
│   │ - Puerto 80 → localhost:4321  │    │
│   │ - Compresión gzip ✅          │    │
│   │ - Cache assets ✅             │    │
│   │ - Logs centralizados ✅       │    │
│   │ - Security headers ✅         │    │
│   └───────────┬───────────────────┘    │
│               │ proxy_pass            │
│               ▼                         │
│   ┌───────────────────────────────┐    │
│   │ Docker Container              │    │
│   │ ecommerce_app_prod            │    │
│   │ Astro App (Node 20)           │    │
│   │ localhost:4321 (interno)      │    │
│   └───────────┬───────────────────┘    │
│               │                         │
│   ┌───────────▼───────────────────┐    │
│   │ Docker Container              │    │
│   │ ecommerce_db_prod             │    │
│   │ PostgreSQL 16                 │    │
│   └───────────────────────────────┘    │
└─────────────────────────────────────────┘

✅ Ventajas:
- Puerto estándar (80)
- Compresión activa
- Cache inteligente
- Logs profesionales
- Listo para escalar
- Preparado para HTTPS
```

---

## 🚀 PROCESO DE IMPLEMENTACIÓN

### Paso 2.1: Verificar Estado Inicial

**Objetivo:** Confirmar que Docker está corriendo tras reinicio de VM.

```bash
# Verificar Docker daemon
sudo systemctl status docker
# Expected: ● docker.service - Active: active (running)

# Ver contenedores
docker ps
# Expected:
# CONTAINER ID   IMAGE                 STATUS
# 7763e781fb4c   ecommerce-app:1.0.0   Up X minutes (healthy)
# c9d760b5c91f   postgres:16-alpine    Up X minutes (healthy)

# Probar API
curl http://localhost:4321/api/analytics/dashboard
# Expected: JSON con datos
```

**Resultado:**

```
✅ Docker: active (running)
✅ PostgreSQL: Up 5 minutes (healthy)
✅ App: Up 5 minutes (unhealthy temporal, pero API responde)
✅ Datos cargados correctamente
```

**Lección DevOps:**
Los contenedores con `restart: unless-stopped` **arrancan automáticamente** al reiniciar la VM. Esto es comportamiento de producción real.

---

### Paso 2.2: Instalar Nginx

**Objetivo:** Obtener servidor web Nginx listo para configurar.

```bash
# Actualizar repositorios
sudo apt update

# Instalar Nginx
sudo apt install nginx -y

# Habilitar inicio automático
sudo systemctl enable nginx

# Iniciar servicio
sudo systemctl start nginx

# Verificar estado
sudo systemctl status nginx

# Ver versión
nginx -v
```

**Resultado:**

```bash
nginx version: nginx/1.24.0 (Ubuntu)
● nginx.service - Active: active (running)
```

**Nota:** En nuestro caso, Nginx ya estaba instalado desde la instalación de Ubuntu.

**Lección DevOps:**
Nginx es el servidor web #1 para reverse proxy en producción por su:

- Alta performance (10K+ conexiones simultáneas)
- Bajo consumo de memoria (~10MB en idle)
- Configuración declarativa simple
- Reload sin downtime

---

### Paso 2.3: Crear Configuración de Reverse Proxy

**Objetivo:** Definir cómo Nginx debe manejar requests y redirigirlos a Docker.

```bash
# Crear archivo de configuración
sudo nano /etc/nginx/sites-available/ecommerce
```

**Contenido completo del archivo:**

```nginx
# Configuración Reverse Proxy - Ecommerce Astro
upstream backend_app {
    server localhost:4321;
    keepalive 32;
}

server {
    listen 80;
    listen [::]:80;
  
    server_name ecommerce.local 192.168.0.119;
  
    # Logs
    access_log /var/log/nginx/ecommerce-access.log;
    error_log /var/log/nginx/ecommerce-error.log warn;
  
    # Client body size (para uploads)
    client_max_body_size 10M;
  
    # Timeouts
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
  
    # Compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;
  
    # Proxy to Docker container
    location / {
        proxy_pass http://backend_app;
        proxy_http_version 1.1;
      
        # Headers importantes
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
      
        # WebSocket support (si lo usas en el futuro)
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass $http_upgrade;
      
        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
  
    # Cache para assets estáticos
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://backend_app;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
      
        # Cache por 1 año
        expires 1y;
        add_header Cache-Control "public, immutable";
      
        # Compresión
        gzip_static on;
    }
  
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
```

**Guardar:** `Ctrl+O` → Enter → `Ctrl+X`

**Validar sintaxis:**

```bash
sudo nginx -t
# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# nginx: configuration file /etc/nginx/nginx.conf test is successful
```

**Lección DevOps:**
**SIEMPRE** valida con `nginx -t` antes de recargar. Un error de sintaxis puede tumbar el servicio.

---

### Paso 2.4: Habilitar Sitio y Aplicar Configuración

**Objetivo:** Activar nuestra configuración y desactivar el sitio default.

```bash
# 1. Deshabilitar sitio por defecto
sudo rm /etc/nginx/sites-enabled/default

# 2. Crear symlink (habilitar nuestro sitio)
sudo ln -s /etc/nginx/sites-available/ecommerce /etc/nginx/sites-enabled/

# 3. Verificar symlink
ls -la /etc/nginx/sites-enabled/
# lrwxrwxrwx 1 root root 34 ... ecommerce -> /etc/nginx/sites-available/ecommerce

# 4. Validar sintaxis final
sudo nginx -t

# 5. Recargar Nginx (sin downtime)
sudo systemctl reload nginx

# 6. Verificar que recargó bien
sudo systemctl status nginx
```

**Resultado:**

```
dic 18 15:59:07 systemd[1]: Reloading nginx.service...
dic 18 15:59:07 nginx[10071]: signal process started
dic 18 15:59:07 systemd[1]: Reloaded nginx.service
```

**Lección DevOps:**

- `reload` → Sin downtime (workers se recrean gradualmente)
- `restart` → Downtime breve (todo se detiene y reinicia)

En producción, **SIEMPRE usa reload**.

---

### Paso 2.5: Configurar Firewall

**Objetivo:** Permitir tráfico HTTP (puerto 80) sin bloquear SSH.

```bash
# Verificar estado
sudo ufw status

# Habilitar firewall si está inactivo
sudo ufw enable

# Permitir HTTP (puerto 80)
sudo ufw allow 80/tcp

# Permitir SSH (puerto 22) - CRÍTICO
sudo ufw allow 22/tcp

# Verificar reglas
sudo ufw status numbered
```

**Resultado:**

```
Estado: activo

     Hasta                      Acción      Desde
     -----                      ------      -----
[ 1] 80/tcp                     ALLOW IN    Anywhere
[ 2] 22/tcp                     ALLOW IN    Anywhere
[ 3] 80/tcp (v6)                ALLOW IN    Anywhere (v6)
[ 4] 22/tcp (v6)                ALLOW IN    Anywhere (v6)
```

**Lección DevOps:**
⚠️ **NUNCA habilites UFW sin permitir SSH primero**. Te quedarías sin acceso remoto.

---

### Paso 2.6: Testing y Validación

**Objetivo:** Confirmar que todo funciona correctamente.

#### Test 1: Desde la VM (localhost)

```bash
# Probar página principal
curl http://localhost

# Probar API
curl http://localhost/api/analytics/dashboard

# Ver headers de respuesta
curl -I http://localhost
```

**Resultado API:**

```json
{
  "total_pedidos_hoy": 0,
  "total_pedidos_pendientes": 0,
  "total_pedidos_completados": 15,
  "ventas_hoy": "0",
  "ventas_mes": "549.69",
  "total_clientes_activos": 15,
  "total_productos_activos": 13,
  "productos_stock_bajo": 3
}
```

**Resultado Headers:**

```http
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Date: Thu, 18 Dec 2025 20:08:10 GMT
Content-Type: text/html
Connection: keep-alive
Vary: Accept-Encoding
```

✅ **Headers importantes:**

- `Server: nginx` → Confirmación de que Nginx está respondiendo
- `Vary: Accept-Encoding` → Compresión gzip configurada
- `Connection: keep-alive` → Keepalive activo

#### Test 2: Desde Windows (navegador)

**URL probada:**

```
http://192.168.0.119
```

**Resultado:** ✅ Página carga correctamente sin especificar puerto.

#### Test 3: Verificar compresión gzip

```bash
curl -H "Accept-Encoding: gzip" -I http://localhost
```

**Esperado:**

```http
Content-Encoding: gzip
```

---

## ⚙️ CONFIGURACIÓN DETALLADA

### Estructura de Archivos Nginx

```
/etc/nginx/
├── nginx.conf                    # Configuración principal
├── sites-available/
│   └── ecommerce                 # Nuestra configuración
├── sites-enabled/
│   └── ecommerce -> ../sites-available/ecommerce  # Symlink activo
├── conf.d/
│   └── *.conf                    # Configs adicionales
└── snippets/
    └── *.conf                    # Fragmentos reusables

/var/log/nginx/
├── ecommerce-access.log          # Logs de acceso
├── ecommerce-error.log           # Logs de errores
├── access.log                    # Log general
└── error.log                     # Errores generales
```

### Directivas Clave Explicadas

#### 1. upstream

```nginx
upstream backend_app {
    server localhost:4321;
    keepalive 32;  # Mantiene 32 conexiones abiertas reutilizables
}
```

**Beneficios:**

- Reduce latencia (no reabre conexiones TCP)
- Permite load balancing futuro
- Mejora throughput en ~20-30%

#### 2. gzip Compression

```nginx
gzip on;                     # Habilitar compresión
gzip_vary on;                # Agrega header Vary: Accept-Encoding
gzip_proxied any;            # Comprimir respuestas proxied
gzip_comp_level 6;           # Nivel 1-9 (6 es óptimo)
gzip_types text/plain...;    # Tipos MIME a comprimir
```

**Impacto real:**

- HTML: ~70% reducción
- CSS: ~80% reducción
- JSON: ~60% reducción
- JS: ~75% reducción

**Ejemplo:**

```
Sin gzip: index.html → 150 KB
Con gzip: index.html → 45 KB (70% ahorro)
```

#### 3. Caching de Assets

```nginx
location ~* \.(jpg|jpeg|png|...)$ {
    expires 1y;                              # Cache por 1 año
    add_header Cache-Control "public, immutable";
}
```

**Headers resultantes:**

```http
Cache-Control: public, immutable
Expires: Fri, 18 Dec 2026 20:00:00 GMT
```

**Beneficios:**

- Navegador NO vuelve a pedir el archivo por 1 año
- Reduce carga en servidor en ~80%
- Mejora velocidad de carga para usuarios recurrentes

#### 4. Proxy Headers

```nginx
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

**¿Por qué son importantes?**

Sin estos headers, tu app Astro solo vería:

```
Request from: 127.0.0.1 (localhost)
```

Con headers:

```
Request from: 192.168.0.100 (IP real del cliente)
X-Forwarded-For: 192.168.0.100, 192.168.0.119
```

Esto es **CRÍTICO** para:

- Analytics (saber de dónde vienen usuarios)
- Rate limiting por IP
- Geolocalización
- Logs de auditoría

---

## 🧪 VALIDACIÓN Y TESTING

### Test Suite Completo

#### 1. Health Check

```bash
curl http://localhost/health
# Expected: OK
```

#### 2. API Endpoints

```bash
# Dashboard analytics
curl http://localhost/api/analytics/dashboard | jq

# Productos
curl http://localhost/api/productos | jq

# Clientes
curl http://localhost/api/clientes | jq
```

#### 3. Compresión Gzip

```bash
# Sin compresión
curl http://localhost > /tmp/sin_gzip.html
ls -lh /tmp/sin_gzip.html

# Con compresión
curl -H "Accept-Encoding: gzip" http://localhost --compressed > /tmp/con_gzip.html
ls -lh /tmp/con_gzip.html

# Comparar tamaños
du -h /tmp/sin_gzip.html /tmp/con_gzip.html
```

#### 4. Headers de Seguridad

```bash
curl -I http://localhost | grep -E "(X-|Vary|Cache)"
```

Expected:

```
Vary: Accept-Encoding
```

#### 5. Performance Test

```bash
# Instalar Apache Bench (si no está)
sudo apt install apache2-utils -y

# Test con 1000 requests, 100 concurrentes
ab -n 1000 -c 100 http://localhost/

# Ver resultados:
# Requests per second
# Time per request
# Transfer rate
```

#### 6. Load Test con wrk

```bash
# Instalar wrk
sudo apt install wrk -y

# Test de 30 segundos, 10 threads, 100 conexiones
wrk -t10 -c100 -d30s http://localhost/
```

---

## 🔧 TROUBLESHOOTING

### Problema 1: Nginx no inicia

**Síntoma:**

```bash
sudo systemctl start nginx
Job for nginx.service failed
```

**Diagnóstico:**

```bash
sudo nginx -t
sudo journalctl -xeu nginx.service
```

**Causas comunes:**

1. Error de sintaxis en config
2. Puerto 80 ya en uso
3. Permisos incorrectos

**Solución:**

```bash
# Ver qué usa puerto 80
sudo lsof -i :80

# Si Apache está corriendo:
sudo systemctl stop apache2
sudo systemctl disable apache2

# Reintentar Nginx
sudo systemctl start nginx
```

---

### Problema 2: 502 Bad Gateway

**Síntoma:**

```
HTTP/1.1 502 Bad Gateway
```

**Causa:** Nginx no puede conectar a backend (Docker).

**Diagnóstico:**

```bash
# Verificar que Docker está corriendo
docker ps

# Ver logs de Nginx
sudo tail -f /var/log/nginx/ecommerce-error.log

# Probar conexión directa
curl http://localhost:4321
```

**Solución:**

```bash
# Levantar Docker si está caído
cd ~/Ecommerce-Proyecto-BD
docker compose -f docker-compose.production.yml up -d

# Verificar conectividad
curl http://localhost:4321/api/analytics/dashboard
```

---

### Problema 3: Compresión no funciona

**Síntoma:**

```bash
curl -I http://localhost | grep "Content-Encoding"
# (No aparece)
```

**Diagnóstico:**

```bash
# Ver configuración de gzip
sudo nginx -T | grep gzip
```

**Solución:**

Verificar que `gzip_types` incluya el Content-Type que estás probando:

```nginx
gzip_types text/html text/plain text/css application/json;
```

**Nota:** gzip para `text/html` está SIEMPRE habilitado por defecto.

---

### Problema 4: Firewall bloquea tráfico

**Síntoma:**
Desde Windows no carga, pero desde VM sí.

**Diagnóstico:**

```bash
# Ver reglas UFW
sudo ufw status

# Ver si puerto 80 está escuchando
sudo netstat -tlnp | grep :80
```

**Solución:**

```bash
# Permitir HTTP
sudo ufw allow 80/tcp

# Recargar firewall
sudo ufw reload

# Verificar
sudo ufw status numbered
```

---

## 📋 COMANDOS DE ADMINISTRACIÓN

### Gestión del Servicio

```bash
# Estado del servicio
sudo systemctl status nginx

# Iniciar
sudo systemctl start nginx

# Detener
sudo systemctl stop nginx

# Reiniciar (con downtime breve)
sudo systemctl restart nginx

# Recargar configuración (sin downtime)
sudo systemctl reload nginx

# Habilitar inicio automático
sudo systemctl enable nginx

# Deshabilitar inicio automático
sudo systemctl disable nginx
```

### Configuración

```bash
# Validar sintaxis sin aplicar
sudo nginx -t

# Ver configuración completa compilada
sudo nginx -T

# Ver solo directivas activas
sudo nginx -T | grep -v "^#"

# Editar configuración del sitio
sudo nano /etc/nginx/sites-available/ecommerce

# Verificar módulos compilados
nginx -V
```

### Logs

```bash
# Ver logs de acceso en tiempo real
sudo tail -f /var/log/nginx/ecommerce-access.log

# Ver logs de error
sudo tail -f /var/log/nginx/ecommerce-error.log

# Ver últimas 100 líneas
sudo tail -100 /var/log/nginx/ecommerce-access.log

# Buscar errores específicos
sudo grep "error" /var/log/nginx/ecommerce-error.log

# Ver estadísticas de access log
sudo cat /var/log/nginx/ecommerce-access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head -10

# Limpiar logs (cuidado en producción)
sudo truncate -s 0 /var/log/nginx/ecommerce-access.log
```

### Debugging

```bash
# Ver qué procesos Nginx están corriendo
ps aux | grep nginx

# Ver sockets abiertos
sudo lsof -i :80

# Ver conexiones activas
sudo netstat -anp | grep :80

# Verificar uso de recursos
sudo systemctl status nginx | grep -E "Memory|CPU"

# Ver errores recientes de systemd
sudo journalctl -u nginx -n 50
```

---

## 📊 MÉTRICAS Y MONITOREO

### Análisis de Logs

#### Requests por Segundo

```bash
# Última hora
sudo cat /var/log/nginx/ecommerce-access.log | \
  awk '{print $4}' | \
  cut -d: -f1-2 | \
  uniq -c | \
  tail -60
```

#### Top 10 IPs

```bash
sudo awk '{print $1}' /var/log/nginx/ecommerce-access.log | \
  sort | uniq -c | sort -nr | head -10
```

#### Top 10 URLs Más Visitadas

```bash
sudo awk '{print $7}' /var/log/nginx/ecommerce-access.log | \
  sort | uniq -c | sort -nr | head -10
```

#### Códigos de Respuesta HTTP

```bash
sudo awk '{print $9}' /var/log/nginx/ecommerce-access.log | \
  sort | uniq -c | sort -nr
```

Ejemplo de salida:

```
    850 200   # Exitosos
     45 304   # Not Modified (cache)
     12 404   # Not Found
      3 500   # Server Error
```

#### Tiempo de Respuesta Promedio

```bash
# Si tienes $request_time en log format
sudo awk '{print $10}' /var/log/nginx/ecommerce-access.log | \
  awk '{sum+=$1; count++} END {print sum/count}'
```

### Métricas en Tiempo Real

#### Stub Status (requiere configuración adicional)

Agregar a `/etc/nginx/sites-available/ecommerce`:

```nginx
location /nginx_status {
    stub_status;
    allow 127.0.0.1;  # Solo localhost
    deny all;
}
```

Luego:

```bash
curl http://localhost/nginx_status
```

Salida:

```
Active connections: 5
server accepts handled requests
 1000 1000 3520
Reading: 0 Writing: 2 Waiting: 3
```

---

## ✨ MEJORES PRÁCTICAS

### 1. Seguridad

```nginx
# Ocultar versión de Nginx
server_tokens off;

# Prevenir clickjacking
add_header X-Frame-Options "SAMEORIGIN" always;

# Prevenir MIME sniffing
add_header X-Content-Type-Options "nosniff" always;

# XSS Protection
add_header X-XSS-Protection "1; mode=block" always;

# Rate limiting (anti DDoS)
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req zone=api burst=20 nodelay;
```

### 2. Performance

```nginx
# Keepalive timeout
keepalive_timeout 65;

# Worker connections
worker_connections 1024;

# Sendfile optimization
sendfile on;
tcp_nopush on;
tcp_nodelay on;

# Client buffer
client_body_buffer_size 128k;
```

### 3. Logging Estructurado

```nginx
# Log format con más detalles
log_format detailed '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" '
                    'rt=$request_time uct="$upstream_connect_time" '
                    'uht="$upstream_header_time" urt="$upstream_response_time"';

access_log /var/log/nginx/ecommerce-access.log detailed;
```

### 4. Backup de Configuración

```bash
# Crear backup antes de cambios
sudo cp /etc/nginx/sites-available/ecommerce /etc/nginx/sites-available/ecommerce.backup

# O con fecha
sudo cp /etc/nginx/sites-available/ecommerce /etc/nginx/sites-available/ecommerce.$(date +%Y%m%d)
```

### 5. Testing Antes de Deploy

```bash
# Siempre validar sintaxis
sudo nginx -t

# Test de carga antes de producción
wrk -t4 -c100 -d30s http://localhost/

# Monitorear durante deploy
sudo tail -f /var/log/nginx/ecommerce-error.log
```

---

## 🔄 Actualización Post-Migración a K3s (23/12/2025)

### Contexto

Después de implementar Kubernetes (Paso 03) y Jenkins (Paso 04), Nginx fue actualizado para apuntar al **ClusterIP de K3s** en lugar del contenedor Docker Compose directo.

### Cambio de Configuración

**Archivo:** `/etc/nginx/sites-enabled/ecommerce`

**ANTES (apuntando a Docker Compose):**
```nginx
upstream backend_app {
    server localhost:4321;  # ← Docker Compose directo
    keepalive 32;
}
```

**DESPUÉS (apuntando a K3s Service):**
```nginx
upstream backend_app {
    server 10.43.7.181:80;  # ← K3s ClusterIP del service ecommerce-app
    keepalive 32;
}
```

### Razón del Cambio

1. **Docker Compose reemplazado:** Los contenedores `ecommerce_app_prod` y `ecommerce_db_prod` fueron eliminados
2. **K3s es ahora el orquestador:** La aplicación corre como Deployment en Kubernetes con 2 réplicas
3. **Service ClusterIP estable:** `10.43.7.181` es la IP estable del Service que balancea entre los pods

### Proceso de Actualización

```bash
# 1. Backup de configuración original
sudo cp /etc/nginx/sites-enabled/ecommerce /etc/nginx/sites-enabled/ecommerce.backup

# 2. Editar configuración
sudo nano /etc/nginx/sites-enabled/ecommerce
# Cambiar línea 3: server 10.43.7.181:80;

# 3. Validar sintaxis
sudo nginx -t
# nginx: configuration file /etc/nginx/nginx.conf test is successful

# 4. Recargar Nginx
sudo systemctl reload nginx

# 5. Verificar funcionamiento
curl http://localhost/api/analytics/dashboard
# {"total_pedidos_hoy":0,"total_pedidos_pendientes":0,...}
```

### Troubleshooting Común

**Error:** `duplicate upstream "backend_app"`
- **Causa:** Archivo `.backup` en `sites-enabled/` (Nginx carga TODO el directorio)
- **Solución:** `sudo rm /etc/nginx/sites-enabled/ecommerce.backup`

**Error:** `invalid port in upstream "localhost:10.43.7.181:80"`
- **Causa:** Sintaxis incorrecta (no usar "localhost:" antes de la IP)
- **Solución:** Usar solo `server 10.43.7.181:80;`

### Arquitectura Actual (Post-K3s)

```
┌──────────────────────────────────────────────────────┐
│                    CLIENTE                           │
│              http://192.168.0.119                    │
└─────────────────────┬────────────────────────────────┘
                      │ Puerto 80
                      ▼
┌─────────────────────────────────────────────────────┐
│                  NGINX (Reverse Proxy)               │
│              Compresión + Cache + Logs               │
└─────────────────────┬───────────────────────────────┘
                      │ proxy_pass
                      ▼
┌─────────────────────────────────────────────────────┐
│           K3S SERVICE: ecommerce-app                 │
│              ClusterIP: 10.43.7.181:80               │
└─────────────────────┬───────────────────────────────┘
                      │ Load Balancer
              ┌───────┴────────┐
              ▼                ▼
    ┌─────────────────┐  ┌─────────────────┐
    │  POD Replica 1  │  │  POD Replica 2  │
    │  ecommerce-app  │  │  ecommerce-app  │
    │  Astro + Node   │  │  Astro + Node   │
    └─────────┬───────┘  └─────────┬───────┘
              │                    │
              └──────────┬─────────┘
                         ▼
              ┌─────────────────────┐
              │   POD: PostgreSQL   │
              │    Service: 5432    │
              └─────────────────────┘
```

### Estado Actual

- ✅ **Nginx:** Activo en puerto 80, proxying a K3s
- ✅ **K3s:** Service ClusterIP `10.43.7.181` con 2 pods backend
- ✅ **Docker Compose:** Eliminado (solo Jenkins permanece)
- ✅ **Aplicación:** Accesible vía `http://192.168.0.119`
- ✅ **Compresión gzip:** Funcionando
- ✅ **Logs:** Centralizados en Nginx

### Comandos de Verificación

```bash
# Verificar IP del Service K3s
kubectl get svc -n ecommerce ecommerce-app
# ClusterIP: 10.43.7.181

# Test directo a K3s (bypass Nginx)
curl http://10.43.7.181/api/analytics/dashboard

# Test vía Nginx
curl http://localhost/api/analytics/dashboard

# Logs de Nginx
sudo tail -f /var/log/nginx/ecommerce-access.log
```

---

## 🎯 PRÓXIMOS PASOS

### Opción A: SSL/TLS con Let's Encrypt (RECOMENDADO)

**Tiempo:** ~30 minutos
**Dificultad:** 🔥 Fácil

**Beneficios:**

- HTTPS gratis
- Certificados renovables automáticamente
- Mejora SEO y confianza del usuario

**Preview:**

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d tudominio.com
```

---

### Opción B: Kubernetes (K3s) ✅ COMPLETADO

**Tiempo:** 2-3 horas
**Dificultad:** 🔥🔥🔥 Avanzado

**Estado:** ✅ IMPLEMENTADO (18/12/2025)

**Logros:**

- ✅ K3s instalado y operacional
- ✅ 2 réplicas de aplicación (HA)
- ✅ PostgreSQL con storage persistente
- ✅ Nginx integrado con K3s
- ✅ Auto-healing configurado

---

### Opción C: CI/CD con Jenkins ✅ COMPLETADO

**Tiempo:** 1-2 horas
**Dificultad:** 🔥🔥 Intermedio

**Estado:** ✅ IMPLEMENTADO (22/12/2025)

**Logros:**

- ✅ Jenkins containerizado con Docker-in-Docker
- ✅ Pipeline automatizado (Poll SCM cada 2min)
- ✅ Build #9 exitoso con deployment a K3s
- ✅ Systemd service para auto-start

---

## 📈 RESUMEN DE LOGROS

| Métrica                | Antes (Solo Docker) | Después (Docker + Nginx) | Con K3s (Actual)       |
| ----------------------- | ------------------- | ------------------------- | ---------------------- |
| **Puerto**        | 4321 (no estándar) | 80 (HTTP estándar)       | ✅ 80 (Nginx → K3s)   |
| **Compresión**   | No                  | Gzip activa               | ✅ Gzip activa         |
| **Cache**         | No                  | 1 año assets             | ✅ 1 año assets        |
| **Logs**          | Solo Docker         | Centralizados Nginx       | ✅ Centralizados       |
| **Escalabilidad** | 1 instancia         | Load balance ready        | ✅ 2 réplicas K3s     |
| **SSL**           | No                  | Preparado                 | 🔜 Siguiente paso      |
| **Headers**       | Básicos            | Seguridad + Proxy         | ✅ Configurados        |
| **CI/CD**         | Manual              | Manual                    | ✅ Jenkins automatizado |
| **Orquestación** | Docker Compose      | Docker Compose            | ✅ Kubernetes (K3s)    |

---

## 🎓 LECCIONES APRENDIDAS

### 1. Nginx NO es solo un servidor web

Es una **herramienta DevOps completa** que hace:

- Reverse proxy
- Load balancer
- Cache server
- SSL termination
- API gateway
- Rate limiter
- WAF (Web Application Firewall)

### 2. El Reverse Proxy es la "puerta de entrada"

En infraestructura moderna:

```
Internet → Reverse Proxy → [App1, App2, App3, ...]
```

TODO el tráfico pasa por ahí. Es el punto perfecto para:

- Seguridad (filtrar ataques)
- Observabilidad (logs, métricas)
- Performance (cache, compresión)

### 3. Reload vs Restart

| Comando     | Downtime       | Cuándo usar        |
| ----------- | -------------- | ------------------- |
| `reload`  | ❌ No          | Cambios de config   |
| `restart` | ⚠️ Sí (~1s) | Problemas críticos |

En producción: **SIEMPRE reload**.

### 4. Validar ANTES de aplicar

```bash
sudo nginx -t  # ← CRÍTICO
sudo systemctl reload nginx
```

Un error de sintaxis puede tumbar todo el sitio.

### 5. Adaptabilidad del Proxy (Nueva lección)

Nginx puede adaptarse sin cambios mayores cuando migras el backend:
- **Docker Compose:** `server localhost:4321;`
- **K3s Service:** `server 10.43.7.181:80;`
- **Múltiples backends:** Solo agregar más líneas `server ...;`

La configuración de compresión, cache, headers permanece **igual** independientemente del backend.

---

## 📚 RECURSOS ADICIONALES

### Documentación Oficial

- [Nginx Official Docs](https://nginx.org/en/docs/)
- [Nginx Admin Guide](https://docs.nginx.com/nginx/admin-guide/)
- [Nginx Beginner's Guide](https://nginx.org/en/docs/beginners_guide.html)

### Herramientas Útiles

- [Nginx Config Generator](https://www.digitalocean.com/community/tools/nginx)
- [SSL Test](https://www.ssllabs.com/ssltest/)
- [WebPageTest](https://www.webpagetest.org/)

### Comunidad

- [r/nginx](https://reddit.com/r/nginx)
- [Nginx Forum](https://forum.nginx.org/)
- [Stack Overflow - Nginx](https://stackoverflow.com/questions/tagged/nginx)

---

## ✅ CHECKLIST DE VERIFICACIÓN

Antes de dar por completado este paso, verifica:

- [x] Nginx instalado y corriendo (`systemctl status nginx`)
- [x] Configuración creada en `/etc/nginx/sites-available/ecommerce`
- [x] Symlink creado en `/etc/nginx/sites-enabled/`
- [x] Sintaxis validada (`nginx -t`)
- [x] Servicio recargado sin errores
- [x] Firewall permite puerto 80 (`ufw status`)
- [x] App accesible desde VM (`curl http://localhost`)
- [x] App accesible desde Windows (`http://192.168.0.119`)
- [x] API responde correctamente
- [x] Compresión gzip funciona
- [x] Logs generándose en `/var/log/nginx/`
- [x] Health check responde (`/health`)
- [x] **[NUEVO]** Configuración actualizada para K3s
- [x] **[NUEVO]** Proxy funcional a ClusterIP de Kubernetes
- [x] **[NUEVO]** Archivos backup eliminados de sites-enabled

---

**FIN DEL PASO 2**

*Documento generado el 18/12/2025*
*Última actualización: 23/12/2025*
*Autor: ITZAN44 / Clark con GitHub Copilot*
*Estado: ✅ VALIDADO EN PRODUCCIÓN (K3s + Jenkins)*
