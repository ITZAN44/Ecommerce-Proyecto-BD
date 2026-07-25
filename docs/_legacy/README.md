# Material heredado (previo a la auditoría)

> ⚠️ **Contenido NO verificado.** Estos archivos existían antes de la auditoría Diátaxis y se conservan solo como referencia histórica.
> **No** son fuente de verdad. Algunos afirman cosas sin comprobar (p. ej. "todo en producción") que la auditoría no validó, y otros contienen ejemplos idealizados que no reflejan el código real.
>
> La documentación válida y verificada vive en [`../`](../README.md) (empezá por [`../vision-general.md`](../vision-general.md)).

## Qué hay acá

| Archivo / carpeta | Qué es | Estado |
|---|---|---|
| `CONTEXTO_AGENTE.md` | Volcado de contexto "para agente IA" (793 líneas). | Sin verificar. Narrativa, no auditada. |
| `DOCKER_README.md` | Guía de uso de Docker (126 líneas). | Operativo; su versión verificada irá a `docs/how-to/` cuando se escriba. |
| `FLUJO_PEDIDOS_DETALLADO.md` | Flujo de pedidos con referencias a archivos (870 líneas). | Contenido potencialmente útil, pero sin auditar. |
| `devops.md/` | Doc DevOps previa: `PASO_01..06`, `FLUJO_...`, `ROADMAP_DEVOPS.md`, `nube-devops/`. | Ver el veredicto en [`../explanation/devops/validacion-doc-existente.md`](../explanation/devops/validacion-doc-existente.md): los `PASO_0X` son fieles; el `ROADMAP` es teórico/idealizado. |

## Por qué se archivó y no se movió a `docs/`

`docs/` sigue la regla del proyecto: **solo hechos verificados**. Meter estos archivos tal cual contaminaría esa fuente limpia con afirmaciones sin auditar. Se archivan acá (reversible, no se pierde nada) hasta que —si hace falta— su contenido se verifique y se reescriba en el lugar Diátaxis que corresponda.
