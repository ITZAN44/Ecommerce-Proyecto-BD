# Ecommerce — Proyecto BD + DevOps

Aplicación de ecommerce con dashboard analítico. La lógica de negocio (impuestos, comisiones, fidelidad, devoluciones, máquina de estados de pedidos) vive en **PostgreSQL** (funciones y procedimientos); la app **Astro SSR** la consume y la muestra. Encima tiene una capa DevOps completa (Docker, Jenkins, K3s, Ansible).

## Stack

- **Astro 5** (SSR, `output: 'server'`) + `@astrojs/node` (standalone) — puerto **4321**
- **TypeScript**, **Tailwind 4**, **Chart.js**
- **PostgreSQL 16** vía `pg` (Pool en `src/lib/db.ts`)
- **DevOps**: Docker (multi-stage) · Jenkins · Kubernetes (K3s) · Ansible

## Arranque rápido (desarrollo)

```bash
# Con Docker (app + PostgreSQL con datos de prueba)
docker-compose up

# O local (requiere Postgres corriendo y variables DB_* en .env)
npm install
npm run dev
```

La app queda en `http://localhost:4321`.

## Documentación

📚 **Toda la documentación técnica está en [`docs/`](./docs/README.md).**

Empezá por 👉 **[`docs/vision-general.md`](./docs/vision-general.md)** — qué es el proyecto y cuál es el stack, con cada dato verificado contra la fuente real.

- **Base de datos** → [`docs/explanation/database/`](./docs/explanation/database/README.md) · estructura exacta en [`docs/reference/database/`](./docs/reference/database/README.md)
- **Aplicación** (endpoints → SQL, páginas) → [`docs/explanation/app/`](./docs/explanation/app/README.md)
- **DevOps** (infra y despliegue) → [`docs/explanation/devops/`](./docs/explanation/devops/README.md)
- **Issues a resolver** → [`docs/remediacion.md`](./docs/remediacion.md)

> La documentación sigue el marco **Diátaxis** y se escribe **solo sobre hechos verificados**. Material previo a la auditoría (sin verificar) está archivado en [`docs/_legacy/`](./docs/_legacy/README.md).
