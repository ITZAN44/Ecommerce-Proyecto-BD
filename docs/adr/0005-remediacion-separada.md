# ADR 0005 — Separar el registro de remediación de la doc descriptiva

- **Estado**: **Superado** por [ADR 0008](./0008-remediacion-en-github-issues.md) (2026-07-29)
- **Fecha**: 2026-07-24

> El principio de separar issues de documentación descriptiva **sigue vigente**. Lo que cambió es el soporte: el archivo único se volvió insostenible y el registro pasó a GitHub Issues. El contenido de abajo se conserva sin modificar, como registro de la decisión original.

## Contexto

Durante la auditoría aparecieron hallazgos accionables (secretos en claro, código muerto, manifests duplicados, etc.). Inicialmente se escribieron como secciones "Hallazgos (para el informe)" **dentro** de los documentos de `explanation/`.

Problema: mezcla dos cosas de naturaleza distinta. La documentación describe **cómo ES** el sistema (verdad presente); un issue describe **qué arreglar** (trabajo futuro). Cuando un issue se resuelve, el bloque en la explanation queda mintiendo, u obliga a editarla en cada fix. Es deuda de mantenimiento disfrazada de documentación.

## Decisión

Separar en un **único registro** [`docs/remediacion.md`](../remediacion.md) todos los issues accionables, con severidad y estado. Las `explanation/` describen la realidad (incluidas sus fallas) y, donde corresponde, apuntan al ID de remediación (S1, D2, etc.).

Regla para clasificar: si la frase **describe cómo es** el sistema ("usa", "tiene", "son 3 vías") → queda en explanation. Si propone una **acción futura** ("migrar", "consolidar", "corregir") → va a remediación.

## Alternativas consideradas

- **Hallazgos embebidos en cada explanation**: cómodo al escribir, pero se pudre al resolverse y dispersa los issues en 7 lugares. Rechazada.
- **Issues en un tracker externo** (GitHub Issues): válido en un proyecto activo, pero acá la doc debe ser autocontenida y offline. Se prefirió un archivo versionado.

## Consecuencias

- ✅ Un solo lugar para ver qué falta arreglar, con severidad y estado.
- ✅ Al cerrar un issue, la doc descriptiva **no** queda desactualizada.
- ✅ La explanation se lee como descripción, no como lista de tareas.
- ⚠️ Hay que mantener los punteros explanation → remediación cuando cambian los IDs.
