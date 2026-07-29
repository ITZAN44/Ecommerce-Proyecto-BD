# CLAUDE.md — Reglas del proyecto

> Objetivo actual: **auditar** cómo está realmente construido este proyecto (app Astro + base de datos PostgreSQL + capa DevOps) y luego documentarlo con el framework **Diátaxis**. La auditoría va primero; la documentación se escribe solo sobre hechos verificados.

## 1. Verdad verificada — sin excepciones

- Nada de resultados sin verificar. Toda afirmación técnica debe estar **cruzada en al menos 2 fuentes independientes** (ej: archivo de código + base real, o config + comportamiento observado).
- **Prohibido inventar** datos, tablas, endpoints, relaciones, flags o comportamientos que no se hayan visto en el proyecto.
- **Prohibido suponer.** Si algo no se puede verificar con datos reales, se dice explícitamente: `SIN VERIFICAR` o `NO SE PUDO CONFIRMAR`. Nunca se rellena el hueco con una suposición presentada como hecho.
- Cada afirmación relevante debe poder citar su fuente: **el archivo y el identificador estable** (nombre de función, tabla, columna, clave de config), el comando que la produce, o la consulta a la BD. **Los números de línea sirven para navegar durante la sesión, nunca para quedar escritos en un entregable** (ver §8).
- Una sola pasada de verificación no alcanza para afirmaciones importantes. Verificar en varios lugares.
- **Verificar no es transcribir.** Comprobar un dato y pegar el resultado en un documento son dos cosas distintas: la primera es el trabajo, la segunda crea deuda. Se escribe **cómo reproducir** la verificación, no su resultado de hoy.

## 2. Fuente de verdad de la base de datos

- La verdad de la BD es la **base real** (Postgres vivo o su dump real `database/backup_bd_real.sql`), **no** lo que el código de la app asume ni lo que dice la documentación existente.
- Los archivos SQL en disco reflejan la intención; si difieren de la base real, gana la base real y se anota la discrepancia.

## 3. Alcance acotado — no irse por las ramas

- Reconocer el alcance de la tarea actual y **terminarla antes de saltar a otra**.
- Los hallazgos críticos que aparezcan en el camino se **anotan como "hallazgo para después"** y se continúa con lo que estábamos haciendo. No perseguir tangentes.
- No ampliar el alcance sin acordarlo primero.

## 4. Separación de herramientas vs. documentación

- Las herramientas de auditoría (introspección de BD, análisis estático, grafos) son para que el agente **navegue y verifique** el proyecto al 100%. Son insumo, no entregable.
- La documentación de salida se escribe con **Diátaxis** y solo sobre hechos ya validados.

## 5. Confianza en la documentación existente

- La capa DevOps está documentada, pero **no se confía a ciegas**: se valida contra los archivos reales (`Dockerfile`, `docker-compose*.yml`, `Jenkinsfile`, `k8s/`, `ansible/`) antes de darla por cierta.

## 6. Antes de responder

- Si no se verificó, no se afirma. Distinguir siempre `VERIFICADO` de `PENDIENTE`/`SIN VERIFICAR`.
- Ante la duda entre afirmar o comprobar, comprobar primero.

## 7. Confirmar todo lo que se hace — cero inventos

- **Todo lo que se afirme o se escriba en la documentación debe estar respaldado por datos reales del proyecto** (código, base viva, config, salida de comando). Nada se da por hecho de memoria ni por inercia.
- Antes de escribir un dato en un entregable, se **relee la fuente real** en ese momento. No vale citar de memoria una lectura anterior: si no se releyó en la sesión, se marca `SIN VERIFICAR` o se reconfirma.
- **Prohibido inventar o mentir** para rellenar un hueco. Si un dato no se puede confirmar, se dice explícitamente que no se pudo confirmar; jamás se maquilla como hecho.
- Cada afirmación relevante lleva su cita: archivo + identificador estable, consulta a la BD o comando reproducible. Sin cita comprobable, no se afirma. **La cita se escribe en la forma que sobrevive al cambio** (ver §8).

## 8. Documentación evergreen — no escribir nada que haya que actualizar a mano

> Decisión formalizada en [`docs/adr/0008-remediacion-en-github-issues.md`](./docs/adr/0008-remediacion-en-github-issues.md). Esta sección es su versión operativa.

### 8.1 La pregunta obligatoria antes de escribir cualquier afirmación

**¿Existe ya otra fuente en el sistema que sea dueña de este hecho?**

- **Sí** → escribir **cómo consultarla**, nunca su valor de hoy.
- **No** → escribirlo. Eso es el trabajo real, y casi siempre es un **porqué**.

Dueños de la verdad, por tipo de hecho:

| Hecho | Fuente autoritativa |
|---|---|
| Cuántas filas, tablas, índices, rutinas hay | La base viva |
| Qué hace el código y dónde está | El código |
| Cómo se ejecuta un procedimiento | El script (su `.SYNOPSIS` / `--help`) |
| Estado de un issue (abierto/cerrado) | GitHub Issues |
| **Por qué se decidió algo** | **La documentación — es lo único que le pertenece** |

Fundamento: DRY no es sobre código, es sobre conocimiento — *"every piece of knowledge must have a single, unambiguous, authoritative representation within a system"*. Transcribir un dato que ya vive en la base es duplicar conocimiento, y las copias divergen.

### 8.2 Prohibido en entregables

- ❌ **Números de línea** (`db.ts:28-31`). Se rompen al agregar una línea arriba, y **fallan en silencio**. Ocurrió en este proyecto: una cita se volvió falsa en el mismo commit que la escribió.
- ❌ **Cifras en tiempo presente** ("76 filas contienen X", "son 13 tablas", "el archivo tiene N líneas"). Se reemplazan por la consulta y su resultado esperado.
- ❌ **Estado escrito a mano** (conteos de issues, "7 resueltos · 11 abiertos"). Lo calcula la plataforma.
- ❌ **Narrar lo que un script ya explica.** Se apunta al script.

### 8.3 Cómo se escribe en su lugar

| En vez de | Se escribe |
|---|---|
| `db.ts:28-31` | `pool.on('error')` en `src/lib/db.ts` — el identificador se encuentra siempre |
| "6 filas tienen correos públicos" | La consulta que lo comprueba, con `-- esperado: 0` |
| "El script hace A, B y C" | "Ver el `.SYNOPSIS` de `exportar_bd.ps1`" |
| "19 issues, 7 resueltos" | Un enlace a la búsqueda de GitHub Issues |

**Excepción única — el pasado cerrado.** Un número que describe un hecho histórico ya ocurrido ("el archivo *llegó* a N líneas", "la cita *se volvió* falsa") no envejece nunca, porque no afirma nada sobre el presente. Por eso los ADR admiten cifras en su contexto: son documentos inmutables que congelan un momento. **La regla no es "no escribir números", es "no escribir números en tiempo presente".**

### 8.4 Lo que sí se escribe, siempre

Conocimiento estable, que no vive en ninguna otra fuente:

- **El porqué de cada decisión**, incluidas las alternativas rechazadas y su motivo.
- **Los gotchas**: lo que nadie deduce mirando el repo.
- **Las trampas de verificación**: las formas de engañarse que ya ocurrieron.
- **Los costos aceptados**: un documento que solo lista ventajas es propaganda, no un registro.

### 8.5 Los comandos documentados son afirmaciones — se ejecutan

Antes de entregar un documento con comandos o consultas embebidas, **ejecutarlos**. Un comando roto es el mismo error en otro envase.

Su ventaja frente a una cifra transcripta no es que sean infalibles —si se renombra un archivo o una columna, también se rompen— sino que **fallan ruidosamente**. Una cifra desactualizada miente con cara de póker.

### 8.6 Dónde va cada cosa

| Contenido | Destino |
|---|---|
| Issues accionables y su estado | [GitHub Issues](https://github.com/ITZAN44/Ecommerce-Proyecto-BD/issues) |
| Decisiones de arquitectura o metodología | `docs/adr/` — cortos, inmutables; si cambian se **supersede**, no se edita |
| Procedimientos verificados | Un script ejecutable; el runbook solo para lo que un script no puede decir |
| Estructura exacta (columnas, tipos, ER) | `docs/reference/` — **generada** por herramientas, regenerable |
| El porqué, los flujos, las reglas de negocio | `docs/explanation/` — curado a mano |
