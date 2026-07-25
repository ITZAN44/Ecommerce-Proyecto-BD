# Base de datos — explicación (Diátaxis · Explanation)

> Dominio: **base de datos** del ecommerce (`ecommerce_db`, PostgreSQL 16).
> Esta carpeta explica **el porqué y la lógica de negocio**. La estructura exhaustiva (columnas, tipos, constraints, índices, ER) no se repite acá: vive en la reference generada.

## Cómo está organizado este dominio

| Necesitás… | Andá a | Cómo se mantiene |
|------------|--------|------------------|
| La estructura exacta de una tabla (columnas, tipos, PK/FK, índices, ER) | [`docs/reference/database/`](../../reference/database/README.md) | 🤖 **Generado** con `tbls` desde la base viva. Regenerable con un comando. Nunca miente. |
| Entender el esquema y las decisiones de diseño | [`esquema.md`](./esquema.md) | ✍️ Curado |
| Entender las funciones/procedimientos y las reglas de negocio | [`funciones-y-reglas.md`](./funciones-y-reglas.md) | ✍️ Curado |
| Entender las vistas y vistas materializadas | [`vistas.md`](./vistas.md) | ✍️ Curado |

## Fuente de verdad

La verdad de la BD es la **base viva** `ecommerce_db`, no los archivos SQL en disco ni el código de la app. Toda afirmación acá está verificada por introspección directa:

```bash
docker exec ecommerce_db psql -U postgres -d ecommerce_db -c "<consulta>"
```

## Regenerar la reference estructural

```bash
# la base debe estar levantada
docker run --rm --network ecommers-proyecto_default -v "$PWD:/work" -w /work k1low/tbls doc -c audit/tools/.tbls.yml --force
```
Config en [`.tbls.yml`](../../../audit/tools/.tbls.yml). Salida a `docs/reference/database/`.

## Inventario del dominio (verificado 2026-07-23)
- **13 tablas** base · **104 columnas**.
- **12 claves foráneas**.
- **35 funciones + 14 procedimientos**.
- **1 vista** + **2 vistas materializadas**.
