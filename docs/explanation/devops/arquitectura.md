# Arquitectura DevOps

> Verificado contra los archivos reales (2026-07-23). Cada afirmación cita su fuente.

## 1. Docker

### Dockerfile (multi-stage) — `Dockerfile`
- **Stage `builder`** (`node:20-alpine`): `npm ci` (todas las deps, incluye devDependencies) → `npm run build` (compila Astro).
- **Stage `production`** (`node:20-alpine`): crea usuario **no-root** `astro` (uid 1001), `npm ci --only=production`, copia solo `dist/` del builder.
- `EXPOSE 4321`, `HEALTHCHECK` con `node` a `/api/analytics/dashboard`, `CMD node ./dist/server/entry.mjs` (SSR).

### Compose — 3 archivos
- **`docker-compose.yml`** (desarrollo): `postgres:16-alpine` (`ecommerce_db`, credenciales `postgres`/`12345678`) + `app` (build local, monta `.:/app` para hot-reload, `DB_HOST=postgres`, puerto 4321). Monta scripts de init de la BD.
- **`docker-compose.jenkins.yml`** — stack de Jenkins.
- **`docker-compose.production.yml`** — variante de producción.

## 2. CI/CD — Jenkins (`Jenkinsfile`)

Pipeline declarativo (`agent any`). Variables: `IMAGE_NAME=ecommerce-app`, `IMAGE_TAG` = hash corto del commit (`GIT_COMMIT.take(7)`), `K8S_NAMESPACE=ecommerce`.

Stages (en orden):
1. Verificar entorno (`docker`, `kubectl`, `git`).
2. Checkout (`checkout scm`).
3. Build imagen Docker (tags `:${IMAGE_TAG}` y `:latest`).
4. **Importar a K3s** — `docker save` → `k3s ctr images import` (sin registry; single-node).
5. Deploy — `kubectl set image deployment/ecommerce-app ...`.
6. Esperar rollout (`kubectl rollout status`, timeout 300s).
7. Verificar pods.
8. Health check — `curl` a `/api/analytics/dashboard`, exige HTTP 200.
9. Historial de rollouts.

`post`: mensajes de éxito/fallo y `cleanWs()`. **Rollback automático está comentado** (no activo). **No hay stage de tests.**

## 3. Kubernetes (K3s) — `k8s/` (11 manifests)

Namespace: **`ecommerce`**.

| Recurso | Detalle |
|---------|---------|
| `app-deployment` | **2 réplicas**, RollingUpdate (`maxUnavailable: 0` → sin downtime). Imagen local `ecommerce-app:1.0.0` con `imagePullPolicy: Never`. Liveness/readiness a `/api/analytics/dashboard`. Recursos: 256Mi/200m req, 512Mi/500m lim. |
| `app-service` | ClusterIP, `port 80 → targetPort 4321`. |
| `app-configmap` | `DB_HOST=postgres`, `DB_USER=ecommerce_user`, `NODE_ENV=production`, etc. |
| `postgres-deployment` | **1 réplica**, estrategia `Recreate` (volumen persistente). Credenciales desde `postgres-secret`. `PGDATA` en subpath. |
| `postgres-pvc` | Almacenamiento persistente `postgres-data`. |
| `postgres-secret` | `ecommerce_user` / `ecommerce_secure_2024` — ⚠️ **en texto plano** (`stringData`). |
| `ingress` | Traefik (K3s). Host `ecommerce.local` + regla sin host (acceso por IP) → service `ecommerce-app:80`. |
| `prometheus-values`, `grafana-patch` | Monitoreo. |

**Coherencia de credenciales en K8s**: el `app-deployment` toma `DB_USER` del configMap (`ecommerce_user`) y `DB_PASSWORD` del secret; el `postgres-deployment` crea la BD con las mismas → internamente consistente. Difiere de `docker-compose` (`postgres`/`12345678`), lo cual es esperable dev-vs-prod.

## 4. IaC — Ansible (`ansible/`)

- **Inventario** (`hosts.ini`): grupo `production` = `vm-ubuntu` (`192.168.0.119`, user `clark`); `development` = localhost. ⚠️ IP y usuario reales commiteados.
- **Roles** (4): `docker`, `nginx`, `k3s`, `jenkins`. El rol `k3s` incluye copia de los manifests (los mismos que `k8s/`).
- **Playbook maestro** (`deploy-all.yml`): `become`, sobre `production`. Pre-flight checks (Ubuntu ≥20.04, RAM ≥2GB, disco ≥5GB, internet). 4 fases en orden: **Docker → Nginx → K3s+App → Jenkins**. Post: verifica servicios y cuenta pods `Running`. Soporta `--check` (dry-run).
- Otros playbooks: `deploy-docker`, `deploy-nginx`, `deploy-k3s`, `deploy-jenkins`, `destroy-all`, `ping-test`.

## Flujo de despliegue completo

```
git push ──▶ Jenkins (build imagen ─▶ k3s ctr import ─▶ kubectl set image)
                                                             │
Ansible (bootstrap del servidor: Docker+Nginx+K3s+Jenkins) ──┘
                                                             ▼
                            K3s: 2 réplicas app + PostgreSQL ─▶ Ingress Traefik ─▶ Nginx ─▶ usuario
```

## Issues detectados

Los puntos a mejorar de esta capa (manifests duplicados k8s/ansible, secretos en texto plano, pipeline sin tests ni rollback activo, tag de imagen inconsistente) están registrados con severidad y plan de remediación en [`../../remediacion.md`](../../remediacion.md) (A1, A3, C1, S1). Las características reales que los originan ya quedaron descritas en las tablas de arriba.
