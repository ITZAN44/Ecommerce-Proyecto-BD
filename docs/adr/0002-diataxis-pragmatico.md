# ADR 0002 — Diátaxis pragmático: reference generado + explanation curado

- **Estado**: Aceptado
- **Fecha**: 2026-07-24

## Contexto

Diátaxis define cuatro cuadrantes de documentación: **tutorial**, **how-to**, **reference** y **explanation**. Aplicar los cuatro por completo a un proyecto académico que se está **auditando** (no enseñando) sería sobre-ingeniería: un tutorial paso a paso no aporta a alguien que quiere entender cómo está construido el sistema.

Además, buena parte de la "reference" (esquema, columnas, tipos, constraints, ER) se puede **generar** desde la fuente de verdad, mientras que el "por qué" (reglas de negocio, decisiones, flujos) debe **escribirse a mano**.

## Decisión

Adoptar Diátaxis de forma **pragmática**, con dos ejes activos:

- **Reference** → 🤖 **generada** por herramientas desde la fuente viva (regenerable, nunca miente). Vive en `docs/reference/`.
- **Explanation** → ✍️ **curada** a mano, citando la fuente. Vive en `docs/explanation/`.

`how-to/` y `adr/` se agregan **al final** y solo donde aportan (este ADR es parte de esa capa). El **tutorial** se descarta para este proyecto.

Principio rector: **single source of truth** — no se calca a mano lo que una herramienta puede regenerar.

## Alternativas consideradas

- **Los cuatro cuadrantes completos**: académicamente "correcto", pero infla el esfuerzo sin valor para una auditoría. Rechazada.
- **Un solo README gigante**: simple al inicio, pero mezcla estructura exhaustiva con narrativa y se vuelve inmantenible. Rechazada.
- **Solo explanation escrita a mano** (sin generar reference): duplicaría a mano lo que `tbls` genera, con riesgo de quedar desactualizado. Rechazada.

## Consecuencias

- ✅ La reference no se desactualiza: se regenera con un comando.
- ✅ El esfuerzo manual se concentra donde ninguna herramienta ayuda (el "por qué").
- ✅ Separación clara de responsabilidades por carpeta.
- ⚠️ Hay que recordar **regenerar** la reference tras cambios de esquema (ver ADR 0003).
- ⚠️ Al no haber tutorial, un recién llegado sin base técnica tiene una curva más empinada; se mitiga con [`vision-general.md`](../vision-general.md).
