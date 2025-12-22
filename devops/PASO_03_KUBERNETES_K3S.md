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

## 13) Próximos pasos recomendados

- **Paso 04 (CI/CD):** pipeline para build + push de imagen + rollout en K3s
- **Paso 05 (TLS):** HTTPS (Traefik + cert-manager / Let’s Encrypt)
- **Paso 06 (Observabilidad):** Prometheus + Grafana + alertas
- **Paso 07 (IaC):** Ansible para automatizar instalación/configuración
