# ☸️ PASO 03: KUBERNETES (K3S) — ORQUESTACIÓN EN PRODUCCIÓN

**Fecha:** 18/12/2025  
**Objetivo:** Migrar el despliegue de Docker Compose a Kubernetes (K3s) con alta disponibilidad, auto-healing, storage persistente e Ingress HTTP.

---

## 1) Resultado final (qué quedó funcionando)

- ✅ K3s instalado en la VM Ubuntu
- ✅ Namespace dedicado `ecommerce`
- ✅ PostgreSQL corriendo en Kubernetes con PVC (storage persistente)
- ✅ App Astro corriendo en Kubernetes con **2 réplicas** (HA)
- ✅ Traefik (Ingress Controller incluido en K3s) exponiendo HTTP por puerto 80
- ✅ Base de datos restaurada con datos reales (13 productos, 25 pedidos, etc.)
- ✅ Nginx del Paso 02 deshabilitado (para evitar conflicto en puerto 80)

---

## 2) Contexto y por qué K3s

**K3s** es Kubernetes “ligero”, ideal para una VM:
- Menor consumo de RAM/CPU
- Instalación en un comando
- Traefik + storage local incluidos

En DevOps real, Kubernetes te da:
- **Auto-healing:** si un Pod muere, el ReplicaSet lo recrea.
- **Rolling updates:** despliegue sin downtime.
- **Escalado:** más réplicas cuando lo necesites.
- **Declarativo:** la infraestructura queda como código (YAML).

---

## 3) Prerrequisitos

- VM Ubuntu accesible por SSH
- Docker funcionando (usado para construir la imagen de la app)
- Aplicación ya compilada/empacada como imagen Docker: `ecommerce-app:1.0.0`

---

## 4) Instalación de K3s

En la VM:

```bash
curl -sfL https://get.k3s.io | sh -

sudo systemctl status k3s
sudo chmod 644 /etc/rancher/k3s/k3s.yaml

echo 'alias k="sudo k3s kubectl"' >> ~/.bashrc
source ~/.bashrc

k get nodes
k get pods -A
```

**Validación esperada**:
- Nodo `Ready`
- CoreDNS, local-path-provisioner y Traefik iniciando en `kube-system`

---

## 5) Importar imagen Docker a K3s (containerd)

K3s usa `containerd` interno, por eso importamos la imagen:

```bash
# Exportar desde Docker
TIMEFORMAT=$'real\t%3R s'; time docker save ecommerce-app:1.0.0 -o /tmp/ecommerce-app.tar
ls -lh /tmp/ecommerce-app.tar

# Importar en K3s/containerd
sudo k3s ctr images import /tmp/ecommerce-app.tar
sudo k3s ctr images ls | grep ecommerce

rm /tmp/ecommerce-app.tar
```

**Nota:** `docker save` no muestra progreso por defecto; es normal que “parezca” que no hace nada.

---

## 6) Manifiestos Kubernetes

Se creó la carpeta [k8s/](k8s/) con:

- `namespace.yaml`
- `postgres-secret.yaml`
- `postgres-pvc.yaml`
- `postgres-deployment.yaml`
- `postgres-service.yaml`
- `app-configmap.yaml`
- `app-deployment.yaml`
- `app-service.yaml`
- `ingress.yaml`

Subida a la VM:

```powershell
scp -r k8s clark@192.168.0.119:~/
```

Aplicación en cluster:

```bash
k apply -f ~/k8s/
```

### Incidencia: namespace “no encontrado” al aplicar todo

Al aplicar todo junto, algunos recursos fallaron con:

`namespaces "ecommerce" not found`

**Causa:** condición de carrera al crear `Namespace` y aplicar el resto.

**Solución:** volver a aplicar.

```bash
k apply -f ~/k8s/
```

---

## 7) Diagnóstico de fallos en la app (Readiness/Liveness)

Las réplicas de `ecommerce-app` estaban `Running` pero `0/1 Ready` con reinicios.

Logs mostraron:

`function fn_estadisticas_dashboard() does not exist`

**Causa:** PostgreSQL estaba “vacío” (PVC nuevo), sin funciones/procedimientos ni datos.

---

## 8) Restauración de la base de datos (backup completo)

Se optó por restaurar el backup completo: `database/backup_bd_real.sql`.

Subida a la VM:

```powershell
scp -r database clark@192.168.0.119:~/
```

Copia al Pod:

```bash
# Confirmar nombre del pod
k get pods -n ecommerce | grep postgres

# Copiar backup al pod
k cp ~/database/backup_bd_real.sql ecommerce/postgres-7cb6d868b-clgmz:/tmp/
```

Restauración:

```bash
k exec -n ecommerce postgres-7cb6d868b-clgmz -- psql -U ecommerce_user -d ecommerce_db -f /tmp/backup_bd_real.sql
```

### Nota sobre warnings de roles

Durante la restauración aparecieron mensajes tipo:

`ERROR: role "postgres" does not exist`

Esto ocurre cuando el dump contiene `OWNER TO postgres` u objetos con propietario `postgres`. En este caso, la restauración siguió y los datos/funciones quedaron disponibles.

Verificación:

```bash
k exec -n ecommerce postgres-7cb6d868b-clgmz -- psql -U ecommerce_user -d ecommerce_db -c "SELECT COUNT(*) FROM productos;"
k exec -n ecommerce postgres-7cb6d868b-clgmz -- psql -U ecommerce_user -d ecommerce_db -c "SELECT COUNT(*) FROM pedidos;"
```

---

## 9) Validación final en Kubernetes

Recursos:

```bash
k get all -n ecommerce
k get deployment ecommerce-app -n ecommerce
```

Esperado:
- `deployment.apps/ecommerce-app` con **2/2 READY**
- `deployment.apps/postgres` con **1/1 READY**

Logs:

```bash
k logs -n ecommerce -l app=ecommerce-app --tail=20 --prefix
```

Uso de recursos:

```bash
k top pods -n ecommerce
```

---

## 10) Ingress / Acceso HTTP (Traefik)

Traefik en K3s expone:

```bash
k get svc -A | grep traefik
```

Ingress:

```bash
k get ingress -n ecommerce
```

Prueba (desde la VM):

```bash
curl http://localhost/api/analytics/dashboard
```

---

## 11) Conflicto puerto 80: Nginx vs Traefik

Como Nginx (Paso 02) y Traefik compiten por el puerto 80, se deshabilitó Nginx:

```bash
sudo systemctl stop nginx
sudo systemctl disable nginx
sudo systemctl status nginx
```

---

## 12) Operación diaria (comandos útiles)

```bash
# Estado del namespace
k get all -n ecommerce

# Ver pods y su IP
k get pods -n ecommerce -o wide

# Logs de la app
k logs -n ecommerce -l app=ecommerce-app --tail=100 -f

# Reiniciar la app (rolling restart)
k rollout restart deployment ecommerce-app -n ecommerce

# Escalar app
k scale deployment ecommerce-app -n ecommerce --replicas=3

# Ver eventos (debug)
k get events -n ecommerce --sort-by='.lastTimestamp' | tail -50
```

---

## 13) Recuperación Post-Reboot (23/12/2025)

### Problema: K3s en crash loop tras reinicio de VM

**Síntomas:**
- K3s service en estado "activating" constante
- Error: `auto-restart (Result: protocol)`
- Aplicación inaccesible vía Nginx (502 Bad Gateway)

**Diagnóstico:**
```bash
sudo journalctl -u k3s -n 100 --no-pager
# Error: failed to create unix socket on /run/k3s/containerd/containerd.sock: is a directory
```

**Causa raíz:** El socket de containerd (`/run/k3s/containerd/containerd.sock`) se corrompió durante el reinicio, convirtiéndose en un directorio en lugar de un socket file.

**Solución aplicada:**
```bash
# 1. Verificar tipo de archivo
ls -la /run/k3s/containerd/containerd.sock
# Resultado: drwxr-xr-x (directorio - incorrecto)

# 2. Eliminar directorio corrupto
sudo rm -rf /run/k3s/containerd/containerd.sock

# 3. Reiniciar K3s (regenera el socket correctamente)
sudo systemctl restart k3s

# 4. Verificar que el socket sea tipo 's' (socket)
ls -la /run/k3s/containerd/containerd.sock
# Resultado: srwxr-xr-x (socket - correcto)

# 5. Verificar estado del servicio
sudo systemctl status k3s
# Estado: active (running)
```

**Configuraciones adicionales después de la recuperación:**

1. **Permisos de kubeconfig:**
```bash
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
```

2. **Regenerar kubeconfig para Jenkins:**
```bash
sudo cat /etc/rancher/k3s/k3s.yaml > ~/Ecommerce-Proyecto-BD/jenkins/kubeconfig
```

3. **Actualizar Nginx para apuntar a K3s (no a Docker Compose):**
```bash
# Editar /etc/nginx/sites-enabled/ecommerce
sudo nano /etc/nginx/sites-enabled/ecommerce

# Cambiar línea 3:
# ANTES: server localhost:4321;
# DESPUÉS: server 10.43.7.181:80;

# Verificar y recargar
sudo nginx -t
sudo systemctl reload nginx
```

4. **Limpiar contenedores Docker Compose antiguos:**
```bash
docker compose -f docker-compose.production.yml down
```

5. **Sincronizar Jenkins con systemd:**
```bash
# Detener contenedores manuales
docker compose -f docker-compose.jenkins.yml down

# Iniciar vía systemd
sudo systemctl start jenkins-docker.service

# Verificar estado
sudo systemctl status jenkins-docker.service
```

**Verificación post-recuperación:**
```bash
# K3s nodes
kubectl get nodes
# clark-virtualbox   Ready   control-plane,master   5d3h   v1.33.6+k3s1

# Pods en ecommerce namespace
kubectl get pods -n ecommerce
# ecommerce-app-557d667469-pqpms   1/1     Running   1          43h
# ecommerce-app-557d667469-rwmq9   1/1     Running   1          43h
# postgres-7cb6d868b-clgmz         1/1     Running   2          5d3h

# Services
kubectl get svc -n ecommerce
# ecommerce-app   ClusterIP   10.43.7.181     <none>        80/TCP       5d3h
# postgres        ClusterIP   10.43.205.184   <none>        5432/TCP     5d3h

# Test API vía Nginx
curl http://localhost/api/analytics/dashboard
# {"total_pedidos_hoy":0,"total_pedidos_pendientes":0,...}
```

**Estado final del stack:**
- ✅ K3s: Running (3 pods saludables)
- ✅ Nginx: Proxying a K3s (puerto 80)
- ✅ Jenkins: Gestionado por systemd (auto-start)
- ✅ Contenedores viejos: Eliminados
- ✅ Aplicación: Accesible vía http://192.168.0.119

**Lección aprendida:** Los sockets efímeros en `/run` pueden corromperse durante reinicios inesperados. Siempre verificar el tipo de archivo (`ls -la`) antes de asumir que el servicio está mal configurado.

---

## 14) Próximos pasos recomendados

- **Paso 04 (CI/CD):** ✅ COMPLETADO - Pipeline Jenkins operacional
- **Paso 05 (TLS):** HTTPS (Traefik + cert-manager / Let’s Encrypt)
- **Paso 06 (Observabilidad):** Prometheus + Grafana + alertas
- **Paso 07 (IaC):** Ansible para automatizar instalación/configuración
