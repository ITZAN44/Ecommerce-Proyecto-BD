# Validación de la doc DevOps existente

> La regla del proyecto: la capa DevOps está documentada, pero **no se confía a ciegas**. Acá el veredicto tras cruzar la doc previa contra los archivos reales.
> Doc previa: `devops.md/` (~9000 líneas), archivada en [`../../_legacy/devops.md/`](../../_legacy/README.md). Verificado 2026-07-23. Las rutas de la tabla siguientes son relativas a esa carpeta archivada.

## Veredicto por documento

| Documento | Tipo | Confiabilidad | Evidencia |
|-----------|------|---------------|-----------|
| `devops.md/devops-local/PASO_01_DOCKER...` | Operativo | ✅ **Fiel** | Puerto 4321, `EXPOSE 4321`, healthcheck con `node` a `/api/analytics/dashboard`, `npm ci` + `npm ci --only=production` — coincide exacto con el `Dockerfile` real. |
| `devops.md/devops-local/PASO_02..06` | Operativo | 🟡 **Mayormente fiel** | Usan el puerto real 4321 (44 menciones en total en la doc). No auditados línea por línea, pero el patrón operativo es consistente con la infra. |
| `devops.md/ROADMAP_DEVOPS.md` | Teórico | ⚠️ **No es fuente de verdad** | Guía de estudio de roadmap.sh. Sus "ejemplos del proyecto" están idealizados: puerto `3000` (15 menciones), `npm ci --only=production` en el builder (rompería el build real), healthcheck con `wget`, compose con `DATABASE_URL` y `networks` que el compose real no tiene. |

## Discrepancias concretas verificadas (ROADMAP vs realidad)

| Afirmación en la doc teórica | Realidad (archivo) |
|------------------------------|--------------------|
| Puerto `3000` / `EXPOSE 3000` | `4321` (`Dockerfile:45`) |
| `npm ci --only=production` en el **builder** | `npm ci` completo — el builder necesita devDependencies (`Dockerfile:12`) |
| Builder copia `node_modules` a producción | Producción hace `npm ci --only=production` fresco (`Dockerfile:35`) |
| Healthcheck con `wget --spider` | `node -e "require('http').get(...)"` (`Dockerfile:53-54`) |
| Compose con `DATABASE_URL` y `networks: bridge` | Variables `DB_*` separadas, sin `networks` (`docker-compose.yml`) |

## Conclusión

- **Para operar/entender el proyecto**: confiar en los `PASO_0X` operativos y, sobre todo, en los **archivos reales** (`Dockerfile`, `docker-compose*.yml`, `Jenkinsfile`, `k8s/`, `ansible/`), que son la fuente de verdad.
- **`ROADMAP_DEVOPS.md`**: tratarlo como **material didáctico** (teoría DevOps general), no como documentación del proyecto. Sus fragmentos "de nuestro proyecto" no reflejan el código real.
- **Doc dispersa** — ✅ *resuelto (2026-07-23)*: los `.md` que estaban sueltos en la raíz (`DOCKER_README.md`, `FLUJO_PEDIDOS_DETALLADO.md`, `CONTEXTO_AGENTE.md`) y la carpeta `devops.md/` se archivaron en [`../../_legacy/`](../../_legacy/README.md). La raíz quedó solo con `README.md` (real) y `CLAUDE.md`. Ver [`../../remediacion.md`](../../remediacion.md) (DOC1).
