# Visión general del proyecto — Ecommerce

> La puerta de entrada real: qué es este proyecto y con qué está construido.
> Cada dato está verificado contra la fuente indicada (`archivo:línea`, config o base viva). Fecha: 2026-07-23.

## Qué es

Una aplicación web de **ecommerce** con dashboard analítico. Nació como proyecto académico de **base de datos** (esquema, funciones, procedimientos y reglas de negocio en PostgreSQL) y luego se le montó encima una **capa de aplicación** (Astro SSR) y una **capa DevOps** completa (Docker, CI/CD, Kubernetes, IaC).

El peso del proyecto está en la **base de datos**: la lógica de negocio (impuestos, comisiones, fidelidad, devoluciones, máquina de estados de pedidos) vive en funciones y procedimientos de Postgres, no en la app. La app es, en gran medida, una capa que **invoca ese SQL** y lo muestra.

## Stack verificado

| Capa | Tecnología | Versión | Fuente |
|------|-----------|---------|--------|
| Framework web | **Astro** (SSR, `output: 'server'`) | 5.15.4 | `package.json:14`, `astro.config.mjs:9` |
| Runtime servidor | **Node.js** vía `@astrojs/node` (`mode: 'standalone'`) | adapter 9.5.0 / Node 20 | `astro.config.mjs:10-12`, `Dockerfile` |
| Lenguaje | **TypeScript** (strict) | — | `tsconfig.json` |
| Estilos | **Tailwind CSS** (plugin Vite) | 4.1.17 | `package.json:13,18` |
| Gráficos | **Chart.js** | 4.5.1 | `package.json:16` |
| Base de datos | **PostgreSQL** | 16-alpine | `docker-compose.yml` |
| Driver BD | **`pg`** (Pool) | 8.16.3 | `package.json:17`, `src/lib/db.ts:1` |
| Config entorno | **dotenv** | 17.2.3 | `package.json`, `src/lib/db.ts:2` |

**Puerto de la app: `4321`** (`astro.config.mjs:16`, `EXPOSE 4321` en `Dockerfile`) — no 3000.

## Cómo se conecta todo

```
Navegador
   │
   ▼
Astro SSR (Node standalone, :4321)
   │   src/pages/**  →  src/pages/api/**  (29 endpoints)
   ▼
src/lib/db.ts  →  query(sql, params)   ← única capa de acceso (Pool de pg)
   │
   ▼
PostgreSQL 16  (ecommerce_db)
   └─ 13 tablas · 49 rutinas (35 funciones + 14 procedimientos) · 3 vistas
      La lógica de negocio vive acá.
```

- **Un único punto de acceso a datos**: todo pasa por `query()` en `src/lib/db.ts:33` (Pool de `pg`, máx. 20 conexiones). Config por variables `DB_*` (`src/lib/db.ts:6-15`).
- **La app arma el SQL literal** en cada endpoint y lo delega a la BD en tres formas: `SELECT * FROM fn_*(...)`, `CALL sp_*(...)`, o CRUD crudo. Detalle en [`explanation/app/`](./explanation/app/README.md).

## Cómo se despliega

- **Docker** — `Dockerfile` multi-stage (build + producción con usuario no-root), 3 archivos compose.
- **CI/CD** — `Jenkinsfile`: construye la imagen y la despliega a K3s (`docker save` → `k3s ctr import`, sin registry).
- **Kubernetes (K3s)** — 11 manifests en `k8s/`: app (2 réplicas), PostgreSQL (1 réplica + PVC), ingress Traefik, monitoreo Prometheus/Grafana.
- **Ansible** — IaC en `ansible/`: 7 playbooks + 4 roles (docker, nginx, k3s, jenkins) para levantar todo desde cero.

Detalle en [`explanation/devops/`](./explanation/devops/README.md).

## Números del proyecto (verificados)

| Elemento | Cantidad |
|----------|----------|
| Tablas base | 13 |
| Claves foráneas | 12 |
| Rutinas (funciones + procedimientos) | 49 (35 + 14) |
| Vistas / vistas materializadas | 1 + 2 |
| Endpoints API | 29 |
| Páginas `.astro` | 10 |
| Manifests K8s | 11 |
| Playbooks Ansible | 7 |

## Por dónde seguir

- **Ver qué hay** y cómo está organizada la doc → [`README.md`](./README.md)
- **Base de datos** (esquema y reglas) → [`explanation/database/`](./explanation/database/README.md) · estructura exacta en [`reference/database/`](./reference/database/README.md)
- **Aplicación** (endpoints → SQL, páginas) → [`explanation/app/`](./explanation/app/README.md)
- **DevOps** (infra y despliegue) → [`explanation/devops/`](./explanation/devops/README.md)
