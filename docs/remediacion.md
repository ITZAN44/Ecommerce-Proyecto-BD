# Registro de remediación

> **El registro vive en GitHub Issues**, no en este archivo:
> **https://github.com/ITZAN44/Ecommerce-Proyecto-BD/issues**

## Por qué se movió

Este archivo llegó a 494 líneas y **ya contenía afirmaciones falsas**. El caso concreto: el issue del pool de PostgreSQL citaba `db.ts:28-31` como la ubicación del handler de error; el propio arreglo corrió las líneas y el handler quedó en otra posición. La cita se volvió falsa **en el mismo commit que la escribió**.

El fallo era estructural, no de disciplina:

- **El estado se escribía a mano.** El encabezado llevaba un conteo de issues que ya se había desincronizado una vez. Ahora GitHub lo calcula.
- **Cerrar un issue obligaba a editar tres lugares** (el issue, la tabla del encabezado, el spec de deploy).
- **Se transcribían cifras y números de línea** — conteos de filas, de tablas, de índices. Cada número era una promesa que alguien tenía que renovar a mano.

Un estudio de [9.6 millones de enlaces en comentarios de código](https://arxiv.org/abs/1901.07440) encontró que casi el 10% están muertos y que rara vez se actualizan. Las referencias por número de línea son de lo más frágil que existe.

## Cómo se escriben los issues ahora

Formato **evergreen**: sin nada que actualizar a mano.

| En vez de | Se escribe |
|---|---|
| `db.ts:28-31` | `pool.on('error')` en `src/lib/db.ts` — el identificador se encuentra siempre |
| "76 filas contienen correos" | La consulta SQL que lo comprueba, con su resultado esperado |
| Narrar cómo se reescribió un script | Apuntar al script: se lee solo y no puede quedar desactualizado |

Se conserva lo que **no vive en ninguna otra fuente**: el porqué de cada decisión, los gotchas y las trampas de verificación. Eso es conocimiento estable — el resto lo produce un comando.

Referencia del enfoque: [Living Documentation](https://www.oreilly.com/library/view/living-documentation-continuous/9780134689418/) (conocimiento estable vs. volátil), [Diátaxis](https://diataxis.fr/reference/) y [Docs as Tests](https://www.barnesandnoble.com/w/docs-as-tests-manny-silva/1147310716).

## Navegación

| Qué busco | Dónde |
|---|---|
| Issues abiertos | [`is:issue is:open`](https://github.com/ITZAN44/Ecommerce-Proyecto-BD/issues?q=is%3Aissue+is%3Aopen) |
| Lo ya resuelto, con su evidencia | [`is:issue is:closed`](https://github.com/ITZAN44/Ecommerce-Proyecto-BD/issues?q=is%3Aissue+is%3Aclosed) |
| Riesgos evaluados y aceptados | [`label:riesgo-aceptado`](https://github.com/ITZAN44/Ecommerce-Proyecto-BD/issues?q=label%3Ariesgo-aceptado) |
| Por área | Etiquetas `area:seguridad`, `area:base-de-datos`, `area:devops`, `area:deploy`, `area:frontend`, `area:arquitectura` |
| Por severidad | Etiquetas `sev:alta`, `sev:media`, `sev:baja` |

Los IDs originales de la auditoría (S1, A1, D1, H1…) se conservan en el título de cada issue, así que las referencias de la documentación siguen siendo rastreables.
