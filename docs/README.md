# Documentación del proyecto — Ecommerce

> 👉 **¿Primera vez acá? Empezá por [`vision-general.md`](./vision-general.md)** — qué es el proyecto y cuál es el stack.
>
> Este archivo explica cómo está **organizada la documentación**. Sigue el marco **Diátaxis** (reference + explanation), escrita **solo sobre hechos verificados** contra las fuentes reales del proyecto.
>
> Fuente de verdad de la base de datos: la **base viva** `ecommerce_db` (PostgreSQL 16), no los archivos SQL en disco ni lo que asume el código.

## Cómo está organizada

| Carpeta | Qué contiene | Cómo se mantiene |
|---------|--------------|------------------|
| [`reference/`](./reference/) | Estructura exacta y exhaustiva (columnas, tipos, constraints, ER, endpoints) | 🤖 **Generada** por herramientas desde la fuente viva. Regenerable. |
| [`explanation/`](./explanation/) | El porqué: lógica de negocio, decisiones de diseño, flujos | ✍️ **Curada** a mano, apuntando a la fuente. |
| [`remediacion.md`](./remediacion.md) | Registro de issues a arreglar (separado de la doc descriptiva) | ✍️ Mantenido a mano; se cierra a medida que se resuelve. |
| [`adr/`](./adr/README.md) | Decisiones de arquitectura de la auditoría (metodología + herramientas) | ✍️ Inmutables; un archivo por decisión. |
| [`how-to/`](./how-to/README.md) | Guías operativas paso a paso | ✍️ Se agregan a medida que hacen falta. |

## Dominios

### 🗄️ Base de datos — ✅ documentado
- **Reference**: [`reference/database/`](./reference/database/README.md) — 13 tablas, 12 FKs, 49 rutinas, 3 vistas.
- **Explanation**: [`explanation/database/`](./explanation/database/README.md) — esquema y decisiones, funciones y reglas de negocio, vistas.

### 🌐 Aplicación (Astro + TypeScript) — ⏳ en auditoría
- Endpoints API, páginas y componentes, y el mapeo **endpoint → SQL**. Aún no consolidado.

### ⚙️ DevOps — ✅ documentado
- **Explanation**: [`explanation/devops/`](./explanation/devops/README.md) — arquitectura real (Docker, Jenkins, K3s, Ansible) + validación de la doc previa.

## Estado de la auditoría

El avance detallado (qué está `VERIFICADO` vs `PENDIENTE`) vive en [`../audit/ESTADO-AUDITORIA.md`](../audit/ESTADO-AUDITORIA.md). La carpeta `audit/` es **insumo interno** (hallazgos y tablero), no entregable: la documentación final es esta carpeta `docs/`.
