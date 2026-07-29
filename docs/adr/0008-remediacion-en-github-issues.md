# ADR 0008 — Mover el registro de remediación a GitHub Issues y escribir en formato evergreen

- **Estado**: Aceptado
- **Fecha**: 2026-07-29
- **Supersede**: [ADR 0005 — Separar el registro de remediación de la doc descriptiva](./0005-remediacion-separada.md)

## Contexto

El ADR 0005 acertó al separar los issues de la documentación descriptiva, y consideró GitHub Issues como alternativa. La rechazó con este argumento: *"acá la doc debe ser autocontenida y offline"*.

Ese argumento resultó incompleto, porque no anticipó el modo de fallo real. `docs/remediacion.md` creció a 494 líneas y **empezó a contener afirmaciones falsas**. El caso que lo demuestra: el issue del pool de PostgreSQL citaba `db.ts:28-31` como ubicación del handler de error; el propio arreglo corrió las líneas y el handler quedó en otra posición. **La cita se volvió falsa en el mismo commit que la escribió.**

Tres causas estructurales, ninguna de disciplina:

1. **El estado se escribía a mano.** El encabezado llevaba un conteo de issues que ya se había desincronizado una vez y hubo que corregir.
2. **Cerrar un issue obligaba a editar tres lugares**: el issue, la tabla del encabezado y el spec de deploy.
3. **Se transcribían cifras y números de línea**: conteos de filas, tablas, índices, archivos. Cada número era una promesa de mantenimiento manual.

El problema de fondo: el documento mezclaba **conocimiento estable** (por qué se decidió algo) con **conocimiento volátil** (cuántas filas hay hoy), tratando a ambos igual.

## Decisión

**Dos cambios, uno de lugar y otro de forma.**

**1. El registro de issues se muda a [GitHub Issues](https://github.com/ITZAN44/Ecommerce-Proyecto-BD/issues).** El estado y el conteo los calcula la plataforma. `docs/remediacion.md` queda como puntero corto. Los IDs de la auditoría (S1, A1, D1, H1…) se conservan en los títulos, así que los punteros de `explanation/` siguen siendo rastreables.

**2. Todo documento de auditoría se escribe en formato evergreen**: sin nada que actualizar a mano.

| En vez de | Se escribe |
|---|---|
| Un número de línea (`db.ts:28-31`) | Un identificador estable (`pool.on('error')` en `src/lib/db.ts`) |
| Una cifra transcripta ("76 filas contienen correos") | El comando o consulta que la produce, con su resultado esperado |
| La narración de cómo se escribió un script | Un puntero al script: se lee solo y no puede desactualizarse |

Se conserva lo que **no vive en ninguna otra fuente**: el porqué de cada decisión, los gotchas y las trampas de verificación.

## Fundamento externo

- [Living Documentation](https://www.oreilly.com/library/view/living-documentation-continuous/9780134689418/) (Martraire) — distinguir conocimiento **estable** de **volátil**; *Evergreen Documents* de mantenimiento cero.
- [9.6 Million Links in Source Code Comments](https://arxiv.org/abs/1901.07440) — casi el 10% de los enlaces en comentarios están muertos y *"are seldom updated by developers"*. Las referencias por número de línea son especialmente frágiles.
- [Diátaxis — Reference](https://diataxis.fr/reference/) — la referencia generada desde la fuente *"remains faithfully accurate to the code"*; ante la duplicación, enlazar.
- [SSOT con reuso por referencia](https://paligo.net/blog/content-reuse/what-is-single-source-of-truth-ssot/) — *"Documents don't contain copies of components — they point to them."*
- [Docs as Tests](https://www.barnesandnoble.com/w/docs-as-tests-manny-silva/1147310716) (Silva) — la documentación contiene afirmaciones **verificables**; se validan automáticamente.
- [ADR — Martin Fowler](https://martinfowler.com/bliki/ArchitectureDecisionRecord.html) — brevedad, e inmutabilidad vía superseding en lugar de edición. Este ADR aplica esa regla al ADR 0005.

## Alternativas consideradas

- **Un archivo por issue en `docs/`, con índice generado por script.** Mantenía el registro dentro del repo (útil si la carpeta `docs/` es el entregable evaluado) y el conteo dejaba de escribirse a mano. Rechazada por decisión del responsable a favor de GitHub Issues, que además aporta ciclo de vida real sin escribir infraestructura propia.
- **Mantener el archivo único con disciplina de actualización.** Rechazada: ya falló dos veces (el conteo y la cita de línea), y la segunda falló en la misma sesión en que se escribió. El fallo es estructural.

## Consecuencias

- ✅ El estado deja de ser texto editable: lo calcula GitHub. El conteo no puede desincronizarse.
- ✅ Cerrar un issue toca un solo lugar, y `Closes #N` en un commit lo vincula al diff.
- ✅ Cada issue tiene historial propio, con fecha y motivo de cierre.
- ✅ Los dos documentos se reducen a lo que no puede envejecer: decisiones, gotchas y comandos de verificación.
- ⚠️ **El registro sale del repositorio.** Si hay que entregar la auditoría como carpeta autocontenida, hay que exportarlo (`gh issue list --json ...`). Este es exactamente el costo que el ADR 0005 quiso evitar; se acepta a cambio de que el registro deje de mentir.
- ⚠️ Depende de GitHub y del repositorio público. Si el repo se archiva o se hace privado, cambia el acceso al registro.
- ⚠️ Los comandos de verificación embebidos en los issues **son afirmaciones que pueden romperse** si se renombra un archivo o un identificador. Son mucho más robustos que un número de línea, pero no infalibles: conviene ejecutarlos al revisar un issue, no confiar en que siguen siendo válidos.
