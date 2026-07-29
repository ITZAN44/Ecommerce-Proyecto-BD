# ADR — Registro de decisiones de arquitectura

> **ADR** (Architecture Decision Record): un archivo por decisión relevante. Son **inmutables** — si una decisión se revierte, no se borra el ADR; se escribe uno nuevo que lo supersede y se marca el viejo como `Superado`.
>
> Estos ADR documentan las decisiones tomadas durante la **auditoría** del proyecto: metodología y herramientas.

## Formato

Cada ADR tiene: **Estado**, **Contexto** (el problema), **Decisión**, **Alternativas consideradas** y **Consecuencias** (lo bueno y lo malo que aceptamos).

## Índice

| # | Decisión | Estado |
|---|----------|--------|
| [0001](./0001-base-viva-fuente-de-verdad.md) | La base viva es la fuente de verdad de la BD | Aceptado |
| [0002](./0002-diataxis-pragmatico.md) | Diátaxis pragmático: reference generado + explanation curado | Aceptado |
| [0003](./0003-tbls-via-docker.md) | `tbls` vía Docker para la reference estructural de la BD | Aceptado |
| [0004](./0004-ast-grep-via-docker.md) | `ast-grep` vía Docker para el mapeo endpoint → SQL | Aceptado |
| [0005](./0005-remediacion-separada.md) | Separar el registro de remediación de la doc descriptiva | **Superado** por 0008 |
| [0006](./0006-archivar-legacy.md) | Archivar la doc previa en `_legacy/` en vez de borrarla o consolidarla | Aceptado |
| [0007](./0007-tooling-en-docker-versionado.md) | Todo el tooling de auditoría en Docker versionado, sin binarios globales | Aceptado |
| [0008](./0008-remediacion-en-github-issues.md) | Remediación en GitHub Issues + documentación en formato evergreen | Aceptado |
