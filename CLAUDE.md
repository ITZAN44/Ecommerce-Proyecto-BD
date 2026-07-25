# CLAUDE.md — Reglas del proyecto

> Objetivo actual: **auditar** cómo está realmente construido este proyecto (app Astro + base de datos PostgreSQL + capa DevOps) y luego documentarlo con el framework **Diátaxis**. La auditoría va primero; la documentación se escribe solo sobre hechos verificados.

## 1. Verdad verificada — sin excepciones

- Nada de resultados sin verificar. Toda afirmación técnica debe estar **cruzada en al menos 2 fuentes independientes** (ej: archivo de código + base real, o config + comportamiento observado).
- **Prohibido inventar** datos, tablas, endpoints, relaciones, flags o comportamientos que no se hayan visto en el proyecto.
- **Prohibido suponer.** Si algo no se puede verificar con datos reales, se dice explícitamente: `SIN VERIFICAR` o `NO SE PUDO CONFIRMAR`. Nunca se rellena el hueco con una suposición presentada como hecho.
- Cada afirmación relevante debe poder citar su fuente (`ruta/archivo:línea`, salida de comando, o consulta a la BD).
- Una sola pasada de verificación no alcanza para afirmaciones importantes. Verificar en varios lugares.

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
- Cada afirmación relevante lleva su cita (`ruta/archivo:línea`, consulta a la BD o salida de comando). Sin cita comprobable, no se afirma.
