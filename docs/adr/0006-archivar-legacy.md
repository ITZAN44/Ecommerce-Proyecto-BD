# ADR 0006 — Archivar la doc previa en `_legacy/` en vez de borrarla o consolidarla

- **Estado**: Aceptado
- **Fecha**: 2026-07-24

## Contexto

Antes de la auditoría existían `.md` sueltos fuera de `docs/` (`CONTEXTO_AGENTE.md`, `DOCKER_README.md`, `FLUJO_PEDIDOS_DETALLADO.md`) y la carpeta `devops.md/`. Contienen material potencialmente útil, pero con afirmaciones **sin verificar** (p. ej. "todo en producción", ejemplos con puerto 3000 que no reflejan el código real).

`docs/` sigue la regla de **solo hechos verificados** (ADR 0001, `CLAUDE.md`). Meter ese material tal cual contaminaría la fuente limpia; pero borrarlo perdería contenido que quizá valga reescribir.

## Decisión

**Archivar** todo ese material en [`docs/_legacy/`](../_legacy/README.md), con un README que lo marca explícitamente como *previo a la auditoría, no verificado, no fuente de verdad*. Además, reemplazar el `README.md` boilerplate de Astro en la raíz por uno real que apunta a `docs/`.

La raíz queda solo con `README.md` (real) y `CLAUDE.md`.

## Alternativas consideradas

- **Borrar** los archivos: el historial de git los conserva, pero se pierde acceso directo y la posibilidad de reciclar contenido verificándolo. Rechazada.
- **Consolidar** en `docs/` tal cual: viola "solo hechos verificados"; mezclaría narrativa sin auditar con la doc confiable. Rechazada.
- **Dejarlos en la raíz**: sigue ensuciando la entrada del repo y confunde sobre qué es la fuente de verdad. Rechazada.

## Consecuencias

- ✅ `docs/` permanece limpio y 100% verificado.
- ✅ No se pierde nada; el material queda accesible y claramente etiquetado como no confiable.
- ✅ La raíz del repo comunica de entrada dónde está la doc real.
- ⚠️ El contenido de `_legacy/` **no se mantiene**; si algo de ahí se necesita, hay que verificarlo y reescribirlo en el lugar Diátaxis que corresponda.
