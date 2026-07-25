# Estado de la auditoría

> Artefacto **interno de auditoría** (insumo, no entregable). La documentación final Diátaxis se escribe aparte, en `docs/`, y solo sobre hechos marcados `VERIFICADO` aquí.
>
> Fuente de verdad de la BD: **base viva** `ecommerce_db` (Postgres 16-alpine, contenedor `ecommerce_db`, puerto 5432). Verificado vía `docker exec ... psql` + `information_schema`/`pg_catalog`, cruzado con `docker-compose.yml` y `src/lib/db.ts`.
>
> Última verificación: 2026-07-23.

## Leyenda
- ✅ `VERIFICADO` — cruzado en ≥2 fuentes, con dato real.
- 🟡 `PARCIAL` — hay datos, falta completar.
- 🔴 `PENDIENTE` — sin auditar.

---

## Metodología y flujo (cómo lo hacemos)

### Principio rector: single source of truth
No se calca a mano lo que una herramienta puede regenerar desde la fuente de verdad. La doc que se escribe a mano es solo la que ningún tool genera (el "por qué" y los flujos).

### Herramientas y cómo se ejecutan
- **tbls vía Docker** (imagen oficial `k1low/tbls`), **no** binario global. Se corre como contenedor contra la base viva → genera la **reference estructural** (tablas, columnas, constraints, índices, triggers, ER). Reproducible y citable en el ADR.
- **Introspección `psql` directa** (`docker exec ecommerce_db psql ...`) para lo que `tbls` NO cubre: el **cuerpo/lógica** de funciones y procedimientos (`tbls` lista sus firmas en el índice, no su código) y las definiciones de vistas.
- **ast-grep** para el mapeo **endpoint → SQL** (Capa 2).

### Separación reference vs explanation
| Contenido | Cómo se produce | Dónde vive |
|-----------|-----------------|------------|
| **Reference** (exhaustiva: esquema completo) | 🤖 GENERADA con `tbls` (regenerable, nunca miente) | `docs/reference/database/` |
| **Explanation / How-to** (lógica de funciones, flujos, el porqué) | ✍️ CURADA a mano, apuntando a la fuente | `docs/` |
| **Hallazgos / insumo de auditoría** (lo no obvio, anomalías, mapa endpoint→SQL) | ✍️ Capturado durante la auditoría | `audit/` |

`audit/` es **solo insumo** (hallazgos). La reference generada NO se duplica en `audit/`.

### Flujo por capa
1. Correr la herramienta (`tbls` / introspección / `ast-grep`).
2. Minar los **hallazgos** (más fácil con la herramienta ya ejecutada) → a `audit/`.
3. Recién al final: escribir la doc Diátaxis en `docs/` = **reference generada + explanation curada**, citando la fuente en cada afirmación.

---

## Capa 1 — Base de datos — ✅ COMPLETA Y CONSOLIDADA EN `docs/`

> Dominio database cerrado (2026-07-23). Entregable Diátaxis:
> - **Reference** (estructura): `docs/reference/database/` — generada por `tbls`.
> - **Explanation** (lógica/reglas): `docs/explanation/database/` (README + esquema + funciones-y-reglas + vistas).
>
> Los borradores de insumo `audit/db-*.md` se migraron íntegros a `docs/` y se eliminaron para no duplicar (single source of truth).

### 1.1 Estructura general — ✅ VERIFICADO
- 13 tablas base, 1 vista (`vw_timeline_pedidos`), 2 vistas materializadas (`mv_clientes_vip`, `mv_productos_top_ventas`).
- 49 rutinas: **35 funciones + 14 procedimientos** en schema `public`.
- 115 columnas en total (schema `public`).

Tablas: `auditoria`, `categorias`, `clientes`, `cupones`, `detalle_pedido`, `devoluciones`, `direcciones`, `envios`, `historial_estados`, `pagos`, `pedidos`, `productos`, `stock`.

### 1.2 Relaciones (FKs) — ✅ VERIFICADO
12 claves foráneas reales:
- `pedidos` → `clientes`, `cupones`, `direcciones`
- `detalle_pedido` → `pedidos`, `stock`
- `stock` → `productos` → `categorias`
- `envios`, `pagos`, `historial_estados` → `pedidos`
- `devoluciones` → `detalle_pedido`
- `direcciones` → `clientes`

### 1.3 Datos reales (conteo) — ✅ VERIFICADO
clientes 15 · productos 13 · pedidos 25 · detalle_pedido 27 · categorias 8 · stock 17 · pagos 34 · auditoria 62.

### 1.4 Columnas / tipos / PKs — ✅ VERIFICADO
104 columnas en las 13 tablas base (las 11 restantes hasta 115 son de vistas/matviews). **Reference exhaustiva generada por `tbls`** (columnas, tipos, PKs, constraints, índices, triggers, ER) en `docs/reference/database/`. Hallazgos no obvios en `audit/db-esquema-tablas.md`.

### 1.5 Lógica: funciones y procedimientos — ✅ VERIFICADO
Inventario + firmas por `tbls`; **propósito, reglas de negocio y máquina de estados** capturados leyendo las 49 definiciones reales → `audit/db-funciones.md`. Agrupadas en 5 familias (triggers, cálculos, validaciones, reportes, procedimientos transaccionales). Reglas clave: impuesto 15%, comisión 5%, fidelidad 1pto/$10, devolución ≤30 días.

### 1.6 Vistas — ✅ VERIFICADO
Estructura por `tbls`; **qué resuelve y qué reglas embebe** capturado leyendo las 3 definiciones reales (`pg_get_viewdef`) → `audit/db-vistas.md`. 1 vista (`vw_timeline_pedidos`, aplana `historial_estados`) + 2 matviews (`mv_clientes_vip` con niveles Platinum/Gold/Silver/Bronze; `mv_productos_top_ventas` con join vía `detalle_pedido→stock→productos`). Hallazgo: matviews no se refrescan solas (falta ver quién dispara `REFRESH` en Capa 2).

---

## Capa 2 — Aplicación (Astro + TS)

### 2.1 Stack — ✅ VERIFICADO
Astro 5 (SSR con `@astrojs/node`), Tailwind 4, `pg`, `chart.js`. Capa de datos en `src/lib/db.ts` (Pool de `pg`).

### 2.2 Endpoints API — ✅ VERIFICADO
Los 29 endpoints de `src/pages/api/` mapeados a su SQL con `ast-grep` + lectura directa → `docs/explanation/app/endpoints-sql.md`. Patrón: todo pasa por `query()` de `src/lib/db.ts`; SQL literal (3 formas: `fn_*()`, `CALL sp_*()`, CRUD crudo). Cruce: `query()` → 68 matches (coincide con conteo previo). Hallazgos: matviews con refresh manual (POST separado), `hash_contrasena` es texto plano (no hash, sin login real), y rutinas de BD no alcanzadas por `api/` (pendiente cruzar con 2.3).

### 2.3 Páginas / componentes — ✅ VERIFICADO
10 páginas `.astro` + componentes (charts, timeline, Icon) mapeados → `docs/explanation/app/paginas-y-componentes.md`. Hallazgo arquitectónico: **3 vías de acceso a datos** (SSR `query()` directo, form POST, client `fetch`) — sin capa única; SQL duplicado entre SSR de página y GET del endpoint homónimo. Componentes son presentacionales. Código muerto **confirmado por triple cruce** (api + astro + BD interna): 9 rutinas sin uso.

---

## Capa 3 — DevOps

### 3.1 Inventario real — ✅ VERIFICADO
Dockerfile ✓, Jenkinsfile ✓, 3 `docker-compose*.yml`, 11 manifests en `k8s/`, 7 playbooks + 4 roles en `ansible/`.

### 3.2 Validación contra la doc existente — ✅ VERIFICADO
Arquitectura DevOps real leída de los archivos fuente (Dockerfile, 3 compose, Jenkinsfile, 11 manifests k8s, 7 playbooks + 4 roles ansible) → `docs/explanation/devops/`. Veredicto de la doc previa: `PASO_0X` operativos fieles (44 usos del puerto real 4321); `ROADMAP_DEVOPS` es teórico con ejemplos idealizados (puerto 3000, npm flags erróneos) → no es fuente de verdad. Hallazgos: manifests k8s duplicados (9 idénticos k8s/ vs ansible), secretos en texto plano, pipeline sin tests, IP+user commiteados.

---

## Hallazgos parqueados (no perseguir ahora)
1. Las subcarpetas `database/fase1|2|3` se montan en `docker-entrypoint-initdb.d` pero Postgres **no ejecuta subdirectorios recursivamente** → esas fases no corren solas al init. Las 49 rutinas igual existen (vía `functions_procedures_LIMPIO.sql` / `backup_bd_real.sql`).
2. `pg_stat_user_tables.n_live_tup` daba 0 en todas las tablas por stats sin `ANALYZE` tras arranque — es estimado, **no** conteo. Siempre confirmar con `COUNT(*)`.
3. Redundancia de auditoría: coexisten 8 `fn_auditoria_<tabla>` específicas **y** `fn_auditoria_generica` (misma lógica). Confirmar cuál está realmente enganchada por tabla (probable código muerto).
4. ~~Matviews: quién dispara el REFRESH~~ **RESUELTO en 2.2**: las refresca un POST manual en `clientes-vip.ts`/`top-productos.ts`; el GET no refresca (sirve datos potencialmente viejos).
5. **Seguridad (2.2)**: `hash_contrasena` se guarda como `` `hash_${contrasena}` `` (texto plano con prefijo, sin hashing real) y ningún endpoint autentica con ella. Nombre engañoso; no hay login. Hallazgo para el informe.
6. ~~Rutinas sin uso desde api/~~ **CONFIRMADO CÓDIGO MUERTO en 2.3** (triple cruce api + astro + BD interna): 9 rutinas sin uso — `fn_obtener_productos_mas_vendidos`, `fn_metricas_producto`, `fn_obtener_clientes_frecuentes`, `fn_estadisticas_estados`, `fn_calcular_total_pedido`, `fn_calcular_comision_venta`, `fn_calcular_tiempo_entrega`, `fn_calcular_total_ventas_periodo`, `sp_actualizar_stock_compra`.
7. ~~Sub-hallazgo funcional: `sp_actualizar_stock_compra`~~ **RESUELTO (2026-07-24)**: era un bug — el flujo crear→pagar nunca descontaba el stock físico. Se cableó `CALL sp_actualizar_stock_compra(p_pedido_id)` dentro de `sp_procesar_pago`; aplicado a la base viva y probado punta a punta (crear→pagar descuenta físico y libera reserva). Migración `database/migrations/001_fix_stock_compra.sql`. → `docs/remediacion.md` (V1, `Resuelto`). Baja el código muerto de 9 a **8 rutinas**.

---

## Orden de trabajo propuesto
1. Completar Capa 1 (1.4 → 1.5 → 1.6) — extracción determinística desde la base viva.
2. Capa 2 (mapeo endpoint → SQL).
3. Capa 3 (validación DevOps contra archivos reales).
4. Recién entonces: documentación Diátaxis en `docs/`.
