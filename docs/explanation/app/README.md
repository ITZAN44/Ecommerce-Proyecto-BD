# Aplicación (Astro + TypeScript) — explicación

> Dominio: la **app** del ecommerce (Astro 5 SSR + TypeScript). Cómo consume la base de datos.
> Verificado con `ast-grep` (`audit/tools/ast-grep.Dockerfile`) + lectura directa de los endpoints.

## Cómo la app habla con la base de datos

- Toda consulta pasa por una única capa: `src/lib/db.ts`, que exporta `query(sql, params)` — un Pool de `pg`.
- Los endpoints viven en `src/pages/api/**` (29 en total). Cada uno arma el SQL **literal en el código** (no en variables) y lo pasa a `query()`.
- Tres formas de tocar la BD, verificadas:
  1. `SELECT * FROM fn_*(...)` → funciones de la BD (reportes, validaciones, cálculos).
  2. `CALL sp_*(...)` → procedimientos transaccionales.
  3. SQL crudo (`SELECT/INSERT/UPDATE` con JOINs) → CRUD directo sobre tablas.

## Documentos

| Documento | Contenido |
|-----------|-----------|
| [`endpoints-sql.md`](./endpoints-sql.md) | Mapeo **endpoint → tabla/función SQL** que toca cada uno (grafo cross-capa). |
| [`paginas-y-componentes.md`](./paginas-y-componentes.md) | Las 10 páginas `.astro` y los componentes; las 3 vías de acceso a datos; código muerto confirmado. |

## Reference

La estructura de la BD que estos endpoints consumen → [`../database/`](../database/README.md) y [`../../reference/database/`](../../reference/database/README.md).
