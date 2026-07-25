# ADR 0001 — La base viva es la fuente de verdad de la BD

- **Estado**: Aceptado
- **Fecha**: 2026-07-24

## Contexto

El proyecto tiene tres representaciones posibles de la base de datos: (1) los archivos `.sql` en disco (`database/`), (2) lo que el código de la app **asume** que existe, y (3) la **base PostgreSQL viva** (`ecommerce_db`). Estas tres pueden divergir: un `.sql` refleja la *intención* en un momento dado, pero migraciones, cargas manuales o dumps posteriores pueden haber cambiado la base real.

Durante la auditoría necesitábamos decidir cuál manda cuando difieren.

## Decisión

La **base viva** (o su dump real `database/backup_bd_real.sql`) es la única fuente de verdad para afirmaciones sobre la BD. Los `.sql` en disco documentan la intención; si difieren de la base real, **gana la base real** y se anota la discrepancia.

Toda afirmación sobre estructura o datos se verifica con introspección directa (`docker exec ecommerce_db psql ...` sobre `information_schema`/`pg_catalog`) y se cruza con una segunda fuente.

## Alternativas consideradas

- **Confiar en los `.sql` de disco**: más simple, pero un archivo puede estar desactualizado respecto a la base que realmente corre. Rechazada: documentaríamos una intención, no la realidad.
- **Confiar en lo que asume el código de la app**: el código puede referenciar columnas o rutinas que ya no existen (código muerto), o ignorar otras. Rechazada por lo mismo.

## Consecuencias

- ✅ La documentación describe lo que **realmente** existe, no lo que se planeó.
- ✅ Detectamos discrepancias reales (p. ej. estimaciones `n_live_tup` vs `COUNT(*)` real; rutinas que existen en la base pero no se invocan).
- ⚠️ Requiere tener la base levantada para verificar. Se mitiga con el dump real versionado.
- ⚠️ Obliga a re-verificar contra la base viva en cada sesión (ver `CLAUDE.md` §2 y §7), lo que es más lento pero es el precio de no inventar.
