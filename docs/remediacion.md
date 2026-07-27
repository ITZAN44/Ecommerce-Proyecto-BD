# Registro de remediación

> Issues detectados durante la auditoría, separados de la documentación descriptiva.
> La doc (`explanation/`) describe **cómo ES** el sistema; este archivo lista **qué conviene arreglar**.
> Cada issue cita su fuente real. Fecha de corte inicial: 2026-07-23 · última actualización: **2026-07-26**.

## Estado del plan (2026-07-26)

**15 issues: 4 resueltos · 11 abiertos.**

| Bloque | Abiertos |
|---|---|
| 🔴 Seguridad | S1, S2 |
| 🟡 Arquitectura y DevOps | A1, A2, A3, A4, C1 |
| 🟢 Código muerto y limpieza | D1, D2, D3, D4 |
| ☁️ Deploy | H1, H2, H3 |
| ✅ Resueltos | DOC1, V1, V2, V3 |

> **Nota importante**: la pasada de herramientas del 2026-07-24 (semgrep, gitleaks, hadolint, kubeconform, ansible-lint) fue de **verificación, no de remediación** — cruzó hallazgos con una 2ª fuente, pero **no corrigió ninguno**. Además, ninguna de esas herramientas cubre D1–D4: el código muerto en PostgreSQL no lo detecta un SAST de código de aplicación. **A la fecha no se ejecutó ninguna limpieza de código muerto.**

## Leyenda

- **Severidad**: 🔴 Alta · 🟡 Media · 🟢 Baja
- **Estado**: `Abierto` · `En curso` · `Resuelto` · `Verificar` (falta confirmar antes de accionar)

## Verificaciones automáticas (2026-07-24)

Pasada de herramientas SAST/lint (vía Docker) para cruzar los hallazgos con una 2ª fuente. Detalle en [`../audit/HERRAMIENTAS.md`](../audit/HERRAMIENTAS.md).

- **semgrep** (94 reglas, 50 archivos) → **0 hallazgos**: sin SQL injection; parametrización `pg` correcta.
- **gitleaks** (working tree + 18 commits) → **sin fugas de alta entropía**. No cubre las contraseñas de baja entropía de S1 (ver S1).
- **hadolint** → `Dockerfile` limpio. **kubeconform** → 10/11 manifests válidos (el "fallo" es un archivo de valores Helm). **ansible-lint** → sin errores funcionales, solo estilo (ver A4).

---

## 🔴 Seguridad

### S1 — Credenciales en texto plano commiteadas
**Severidad** 🔴 · **Estado** `Abierto`

Secretos versionados en el repo, en claro:
- `k8s/postgres-secret.yaml:9-11` → `stringData` con `ecommerce_user` / `ecommerce_secure_2024`. El propio archivo lo admite: *"En producción real usa Sealed Secrets o Vault"* (`postgres-secret.yaml:2`).
- `docker-compose.yml` → password `12345678` en claro.
- `ansible/inventory/hosts.ini` → IP real `192.168.0.119` + usuario `clark`.

**Remediación**: mover secretos a Sealed Secrets / Vault (o al menos fuera del control de versiones); parametrizar inventario Ansible con variables/vault. Rotar credenciales expuestas.

> **Cruce con gitleaks (2026-07-24)**: gitleaks NO marcó estos secretos porque son de **baja entropía** (contraseñas de config), fuera de su modelo de detección (tokens/API keys de alta entropía). El hallazgo se sostiene por lectura directa de los archivos citados; gitleaks solo aporta que **no hay además** tokens/keys de alta entropía filtrados.

### S2 — `hash_contrasena` no es un hash y no hay login real
**Severidad** 🔴 (nombre engañoso) / contexto académico · **Estado** `Abierto`

`src/pages/api/clientes/index.ts:43,72` guarda `` `hash_${contrasena}` `` — la contraseña en texto plano con un prefijo literal `"hash_"`, sin ninguna función criptográfica. Además **ningún endpoint la lee ni compara** → no existe autenticación real.

**Remediación**: si el proyecto necesita auth, usar hashing real (bcrypt/argon2) y un flujo de login. Si no lo necesita (proyecto académico), **renombrar la columna** para no inducir a error (`hash_contrasena` sugiere seguridad que no existe).

---

## 🟡 Arquitectura y DevOps

### A1 — Manifests K8s duplicados (riesgo de drift)
**Severidad** 🟡 · **Estado** `Abierto`

Los 9 manifests compartidos entre `k8s/` y `ansible/roles/k3s/files/` son **byte a byte idénticos** (verificado por `diff`, 2026-07-23). Cambiar uno deja el otro desactualizado. (`k8s/` tiene además `grafana-patch.yaml` y `prometheus-values.yaml`, que Ansible no copia.)

**Remediación**: una única fuente de manifests. Que el rol Ansible referencie `k8s/` (symlink o path relativo) en vez de mantener copia propia.

### A2 — No hay una capa única de acceso a datos
**Severidad** 🟡 · **Estado** `Abierto`

La misma consulta se escribe en dos lugares con SQL casi idéntico: el SSR de la página (`*.astro`) y el `GET` del endpoint homónimo. Ej.: `productos/index.astro` (SSR) y `GET /api/productos` consultan `productos ⨝ categorias ⨝ stock` por separado. Un cambio de esquema obliga a tocar los dos.

**Remediación**: extraer las consultas a un módulo de repositorio/servicio reutilizado tanto por el SSR como por los endpoints.

### A3 — Tag de imagen inconsistente en el manifiesto base
**Severidad** 🟢 · **Estado** `Abierto`

`k8s/app-deployment.yaml` fija la imagen en `:1.0.0`, pero Jenkins despliega por `:${commit}` (`Jenkinsfile`). En runtime funciona (Jenkins sobreescribe con `kubectl set image`), pero el manifiesto base induce a confusión sobre qué versión corre.

**Remediación**: dejar el tag del manifiesto como placeholder explícito (ej. `:PLACEHOLDER` o `:latest`) documentando que Jenkins lo sobreescribe.

### A4 — Playbooks Ansible dependen del cwd + estilo (ansible-lint)
**Severidad** 🟢 · **Estado** `Abierto`

Los playbooks resuelven roles vía `ansible.cfg` con `roles_path = ./roles` (relativo). Solo funcionan si se ejecuta **desde `ansible/`**; correr `ansible-playbook ansible/playbooks/deploy-all.yml` desde la raíz rompe con "role not found" (verificado con ansible-lint, 2026-07-24). Además, `ansible-lint` reporta solo estilo: 48 trailing-spaces, 28 acciones sin FQCN (`apt` en vez de `ansible.builtin.apt`), 2 `truthy` (`yes/no`), 1 line-length. Sin errores funcionales.

**Remediación**: documentar que el deploy se corre desde `ansible/` (o usar rutas absolutas / `ANSIBLE_CONFIG`); opcionalmente aplicar el autofix de estilo (`ansible-lint --fix`) y migrar a FQCN.

### C1 — Pipeline sin tests ni rollback activo
**Severidad** 🟡 · **Estado** `Abierto`

El `Jenkinsfile` no tiene stage de testing (coherente: el proyecto no tiene suite de tests) y el rollback automático **está comentado** (no activo).

**Remediación**: agregar (a) un stage mínimo de tests/lint que bloquee el deploy ante fallo, y (b) reactivar el rollback automático ante health check fallido.

---

## 🟢 Código muerto y limpieza

### D1 — 8 rutinas de BD sin uso (código muerto confirmado)
**Severidad** 🟢 · **Estado** `Abierto`

Confirmado por **triple cruce** (endpoints `api/`, páginas `.astro`, y llamadas internas entre funciones en el dump de las 49 definiciones): estas rutinas no se invocan desde ningún lado —
`fn_obtener_productos_mas_vendidos`, `fn_metricas_producto`, `fn_obtener_clientes_frecuentes`, `fn_estadisticas_estados`, `fn_calcular_total_pedido`, `fn_calcular_comision_venta`, `fn_calcular_tiempo_entrega`, `fn_calcular_total_ventas_periodo`.

> Eran **9**: `sp_actualizar_stock_compra` salió de la lista el 2026-07-24 al cablearse en `sp_procesar_pago` (resolución de **V1**); ya no es código muerto.

> **Reconfirmado el 2026-07-26** (doble cruce, ninguna acción de limpieza ejecutada aún):
> - **Código**: búsqueda de las 8 rutinas en todo `src/` → **0 coincidencias**.
> - **Base viva**: barrido de `pg_get_functiondef` sobre las rutinas de `public` buscando llamadas cruzadas → **0 llamadas** para las 8.
> Las 8 siguen existiendo en `ecommerce_db` y nadie las invoca.

**Remediación**: decidir por rutina — eliminar, o cablearla a un endpoint/página si se pensaba usar.

### D2 — Las vistas materializadas se refrescan a mano
**Severidad** 🟡 · **Estado** `Abierto`

`index.astro` (dashboard) lee `mv_clientes_vip` y `mv_productos_top_ventas` **sin refrescarlas**. El `REFRESH MATERIALIZED VIEW CONCURRENTLY` vive en un `POST` separado de `clientes-vip.ts` / `top-productos.ts` que hay que invocar explícitamente. Si nadie lo llama, la pantalla principal muestra rankings viejos.

**Remediación**: refrescar por schedule (cron/pg_cron) o al escribir los datos que las alimentan, no depender de un POST manual.

### D3 — Redundancia de auditoría
**Severidad** 🟢 · **Estado** `Abierto` (confirmado el 2026-07-26; ya no es `Verificar`)

Coexisten funciones de auditoría específicas por tabla **y** `fn_auditoria_generica` con la misma lógica. Se confirmó cuál de las dos vías es la muerta.

**Confirmado contra la base viva** (`pg_trigger ⨝ pg_class ⨝ pg_proc`, 2026-07-26):

- Hay **7** funciones `fn_auditoria_<tabla>` y las **7 están enganchadas** a su trigger: `categorias`, `clientes`, `cupones`, `pagos`, `pedidos`, `productos`, `stock`.
- `fn_auditoria_generica` **existe pero no está enganchada a ningún trigger** → **es la vía muerta**.

> **Corrección al texto previo**: este issue decía "8 `fn_auditoria_<tabla>` específicas". Son **7**. El total de 8 salía de contar `fn_auditoria_generica` dentro del grupo.

**Remediación**: eliminar `fn_auditoria_generica` (nadie la usa), o —si se prefiere la vía genérica— migrar los 7 triggers a ella y borrar las 7 específicas. Hoy la redundancia es 7 activas + 1 muerta.

### D4 — Scripts de init de BD por subcarpetas no se ejecutan solos
**Severidad** 🟢 · **Estado** `Abierto` (confirmado el 2026-07-26; ya no es `Verificar`)

`database/fase1|2|3` se montan en `docker-entrypoint-initdb.d`, pero Postgres **no ejecuta subdirectorios recursivamente** → esas fases no corren en el init automático. Las 49 rutinas existen igual (vía `functions_procedures_LIMPIO.sql` / `backup_bd_real.sql`).

**Confirmado por lectura directa de `docker-compose.yml` (2026-07-26)** — qué se monta realmente:

- **Se ejecutan** (archivos `.sql` planos, `docker-compose.yml:17-20`): `init.sql` → `01_init.sql`, `schema.sql`, `functions_procedures_LIMPIO.sql`, `backup_bd_real.sql`.
- **NO se ejecutan** (directorios, `docker-compose.yml:21-23`): `fase1`, `fase2`, `fase3`.

> **Sub-hallazgo (SIN VERIFICAR el impacto)**: los 4 `.sql` planos corren en **orden alfabético** (`01_init.sql`, `backup_bd_real.sql`, `functions_procedures_LIMPIO.sql`, `schema.sql`), no en el orden lógico esquema→funciones→datos. No se comprobó si ese orden produce errores o si el resultado final es equivalente.

**Remediación**: aplanar los scripts al nivel que Postgres sí ejecuta (con prefijo numérico que fije el orden), o cargar por un orquestador explícito.

---

## 📄 Documentación

### DOC1 — Documentación dispersa fuera de `docs/`
**Severidad** 🟢 · **Estado** `Resuelto` (2026-07-23)

Había `.md` sueltos en la raíz (`DOCKER_README.md`, `FLUJO_PEDIDOS_DETALLADO.md`, `CONTEXTO_AGENTE.md`) y la carpeta `devops.md/` fuera de `docs/`. El `ROADMAP_DEVOPS.md` además es material teórico, no doc del proyecto (ver [`explanation/devops/validacion-doc-existente.md`](./explanation/devops/validacion-doc-existente.md)).

**Resuelto**: archivados en [`_legacy/`](./_legacy/README.md) con un README que aclara que son material previo a la auditoría, no verificado. El `README.md` boilerplate de Astro en la raíz se reemplazó por uno real que apunta a `docs/`. La raíz quedó solo con `README.md` y `CLAUDE.md`.

---

## 🔴 Integridad de datos

### V1 — El stock físico nunca se descuenta al vender
**Severidad** 🔴 · **Estado** `Resuelto` (2026-07-24)

En el flujo crear → pagar, el stock físico (`stock.cantidad_en_stock`) **nunca bajaba** y la reserva (`stock.cantidad_reservada`) **nunca se liberaba**. Verificado leyendo la base viva:

- `sp_crear_pedido` solo **reserva**: `UPDATE stock SET cantidad_reservada = cantidad_reservada + cantidad`. No toca el físico.
- `sp_procesar_pago` **no tocaba stock** en absoluto (registraba pago, pasaba el pedido a `pagado`, creaba el envío).
- `sp_actualizar_stock_compra` es la única rutina del flujo de compra que hace `cantidad_en_stock -= cantidad` **y** `cantidad_reservada -= cantidad` ("Reducir stock y liberar reserva")… pero era **código muerto: nadie la invocaba** (ver D1).

**Consecuencia (antes del fix)**: cada venta dejaba la reserva colgada para siempre; la disponibilidad real (`cantidad_en_stock − cantidad_reservada`) se degradaba con cada pedido sin que la venta se reflejara en el inventario físico.

**Resuelto**: se agregó `CALL sp_actualizar_stock_compra(p_pedido_id)` **dentro de `sp_procesar_pago`**, tras marcar el pedido `pagado` y antes de crear el envío. Corre en la misma transacción del pago (los `CALL` de plpgsql no abren transacción nueva) → pago y descuento de stock son atómicos.

- Migración versionada: [`database/migrations/001_fix_stock_compra.sql`](../database/migrations/001_fix_stock_compra.sql).
- Aplicada a la base viva `ecommerce_db` el 2026-07-24 (`CREATE OR REPLACE PROCEDURE`), verificada con `pg_get_functiondef`.
- **Prueba funcional de punta a punta** (crear 2 uds → pagar), en transacción revertida: `fisico 15→15, reserva 0→2` tras crear; `fisico 15→13, reserva 2→0` tras pagar. ✅
- Cierra la excepción de D1: `sp_actualizar_stock_compra` ya no es código muerto.

---

## 🖥️ Frontend / UI

> Bugs visuales detectados el 2026-07-25 al capturar la UI para una landing de promoción (no estaban en la auditoría estática; salieron al ver las pantallas renderizadas).

### V2 — El dashboard mostraba `$NaN` en "Productos Más Vendidos"
**Severidad** 🟡 · **Estado** `Resuelto` (2026-07-25)

`src/pages/index.astro` leía `producto.total_ventas` y `producto.cantidad_vendida`, pero la matview `mv_productos_top_ventas` **no expone esos nombres**: las columnas reales (verificadas en la base viva) son `ingresos_totales` y `total_vendido`. `parseFloat(undefined)` → `NaN` → se renderizaba "$NaN vendidos".

**Resuelto**: `index.astro:206,209` ahora usan `producto.ingresos_totales` y `producto.total_vendido`. Verificado a la vista: el #1 muestra `$840 / 7 vendidos`.

### V3 — Código CSS filtrado como texto en la tabla de Pedidos
**Severidad** 🟡 · **Estado** `Resuelto` (2026-07-25)

`src/pages/pedidos/index.astro:234` tenía un fragmento duplicado (`ar(--bg-secondary); border-color: var(--border-color);">`) pegado tras el cierre del `<tbody>`, que se renderizaba como texto plano sobre la tabla.

**Resuelto**: se eliminó el fragmento sobrante; el `<tbody>` quedó con un único `style` válido.

> **Nota de datos (no es bug)**: las tarjetas "Ventas Hoy / Ventas del Mes" muestran `$0` porque `fn_estadisticas_dashboard` filtra por `CURRENT_DATE` / mes actual, y todos los pedidos del seed son de nov–dic 2025. Es dato correcto, no un defecto.

> **Gotcha DevOps (para el deploy)**: `docker-compose.yml` monta `.:/app` (bind mount de dev). Eso **tapa el `dist/` de la imagen con el del host**, así que rebuildear la imagen no basta: hay que `npm run build` en el host. En Render/producción se usa el `Dockerfile` sin bind mount, así que el `dist/` de la imagen (con estos fixes) sí se sirve.

---

## ☁️ Deploy a hosting gestionado (Render + Neon)

> Hallazgos del 2026-07-26 al evaluar el despliegue en **Render** (app) + **Neon** (PostgreSQL gestionado).
> Son específicos de una base gestionada; **no afectan al entorno local con Docker**, donde todo funciona.
> Objetivo elegido: Render (Docker, free tier) + Neon (Postgres free tier).

### H1 — `db.ts` no está preparado para una base gestionada (bloquea el deploy)
**Severidad** 🔴 · **Estado** `Abierto`

`src/lib/db.ts` configura el `Pool` para un Postgres local en la misma red. Tres puntos lo hacen incompatible con Neon (verificados por lectura directa del archivo, 2026-07-26):

| # | Punto | Fuente | Por qué rompe con Neon |
|---|---|---|---|
| a | **No hay opción `ssl`** en el `Pool` | `db.ts:6-15` | Neon exige TLS. Sin `ssl`, la conexión **falla**. Es el bloqueante duro. |
| b | `connectionTimeoutMillis: 2000` | `db.ts:14` | Neon duerme la base tras inactividad; despertarla puede exceder 2 s → la primera visita falla. |
| c | `pool.on('error', …)` hace `process.exit(-1)` | `db.ts:28-31` | Un error de conexión ocioso (habitual cuando Neon escala a cero) **termina el proceso del servidor entero**. |

**Remediación**: (a) SSL condicional por variable de entorno para no romper el entorno local sin TLS; (b) subir el timeout de conexión; (c) registrar el error del pool sin matar el proceso.

> **Aclaración**: (c) es un problema de robustez que existe hoy también en local — con Neon simplemente pasa de improbable a esperable.

### H2 — La base viva diverge del dump versionado
**Severidad** 🟡 · **Estado** `Abierto`

`database/backup_bd_real.sql` **ya no refleja** la base viva `ecommerce_db`. Cambios aplicados a la base y no re-exportados:

- El fix de **V1** (`CALL sp_actualizar_stock_compra` dentro de `sp_procesar_pago`), aplicado el 2026-07-24.
- Limpieza de datos de prueba del 2026-07-25 (nombres de clientes y productos, SKUs, categoría `COMIDA`→`Alimentos`, baja de un producto y una categoría huérfanos).

**Impacto en el deploy**: la carga inicial de Neon se hace desde el dump. Si se sube el dump actual, la base en la nube arranca **sin el fix de V1 y con los datos de prueba**.

**Remediación**: re-exportar el dump (`exportar_bd.ps1`) **antes** de cargar Neon, y volver a versionarlo.

### H3 — Estado del despliegue
**Severidad** 🟢 · **Estado** `Abierto`

El proyecto **NO está deployado**: no hay URL pública (`NO CONFIRMADO`). Corre en `http://localhost:4321`, local y vía Docker.

> **Nota de alcance**: los issues de infra **A1, A3, A4 y C1** son de Kubernetes, Jenkins y Ansible. Render **no usa ninguna de esas piezas**, así que no bloquean este despliegue; siguen abiertos para la vía K3s/Jenkins.

> **Nota sobre S1 y el repo público**: el remoto `github.com/ITZAN44/Ecommerce-Proyecto-BD` es **público** (verificado con `gh repo view`, 2026-07-26). Las credenciales de S1 son visibles para cualquiera. No bloquea el deploy (Render inyecta sus propias variables y las de Neon son distintas), pero publicar una URL le da visibilidad al repo. Refuerza la prioridad de **S1**.

---

## 🔎 Sub-hallazgos por verificar (no accionar sin confirmar)

- **D3 y D4 dejaron de ser `Verificar`** el 2026-07-26: ambos quedaron confirmados contra la base viva y `docker-compose.yml`. Pasaron a `Abierto` (falta accionarlos, no verificarlos).
- **Pendiente de verificar**: el orden alfabético de carga de los `.sql` de init (ver sub-hallazgo en **D4**) — no se comprobó si produce errores o si el resultado final es equivalente.
