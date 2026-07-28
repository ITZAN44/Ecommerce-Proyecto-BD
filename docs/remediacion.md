# Registro de remediación

> Issues detectados durante la auditoría, separados de la documentación descriptiva.
> La doc (`explanation/`) describe **cómo ES** el sistema; este archivo lista **qué conviene arreglar**.
> Cada issue cita su fuente real. Fecha de corte inicial: 2026-07-23 · última actualización: **2026-07-27**.

## Estado del plan (2026-07-27)

**19 issues: 6 resueltos · 1 riesgo aceptado · 12 abiertos.**

| Bloque | Abiertos |
|---|---|
| 🔴 Seguridad | S2, S3 |
| 🟡 Arquitectura y DevOps | A1, A2, A3, A4, C1 |
| 🟢 Código muerto y limpieza | D1, D2, D3, D4 |
| ☁️ Deploy | H3 |
| ✅ Resueltos | DOC1, V1, V2, V3, H1, H2 |
| 🤝 Riesgo aceptado | S1 (credenciales LAN ya públicas — ver decisión del 2026-07-27) |

> **Corrección de conteo (2026-07-27)**: el encabezado venía arrastrando un total de **15** issues. Al recontar sobre los encabezados reales del documento son **18**: el bloque `☁️ Deploy` (H1, H2, H3) se agregó el 2026-07-26 y el total nunca se actualizó. Los estados individuales siempre fueron correctos; el error estaba solo en la suma.

> **El camino al deploy quedó libre.** H1 levantó el bloqueante de conexión (TLS) y H2 dejó el dump apto y validado. H3 no es un defecto: solo registra que el proyecto todavía no está desplegado. Lo que resta depende de una cuenta en Neon, no de arreglos en el proyecto.

> **Nota importante**: la pasada de herramientas del 2026-07-24 (semgrep, gitleaks, hadolint, kubeconform, ansible-lint) fue de **verificación, no de remediación** — cruzó hallazgos con una 2ª fuente, pero **no corrigió ninguno**. Además, ninguna de esas herramientas cubre D1–D4: el código muerto en PostgreSQL no lo detecta un SAST de código de aplicación. **A la fecha no se ejecutó ninguna limpieza de código muerto.**

## Leyenda

- **Severidad**: 🔴 Alta · 🟡 Media · 🟢 Baja
- **Estado**: `Abierto` · `En curso` · `Resuelto` · `Verificar` (falta confirmar antes de accionar) · `Riesgo aceptado` (evaluado y no se acciona, con fundamento y condición de disparo)

## Verificaciones automáticas (2026-07-24)

Pasada de herramientas SAST/lint (vía Docker) para cruzar los hallazgos con una 2ª fuente. Detalle en [`../audit/HERRAMIENTAS.md`](../audit/HERRAMIENTAS.md).

- **semgrep** (94 reglas, 50 archivos) → **0 hallazgos**: sin SQL injection; parametrización `pg` correcta.
- **gitleaks** (working tree + 18 commits) → **sin fugas de alta entropía**. No cubre las contraseñas de baja entropía de S1 (ver S1).
- **hadolint** → `Dockerfile` limpio. **kubeconform** → 10/11 manifests válidos (el "fallo" es un archivo de valores Helm). **ansible-lint** → sin errores funcionales, solo estilo (ver A4).

---

## 🔴 Seguridad

### S1 — Credenciales en texto plano commiteadas
**Severidad** 🟡 (reevaluada desde 🔴) · **Estado** `Riesgo aceptado` (decisión del 2026-07-27)

Credenciales versionadas en claro. **Ya son públicas**: el repo `github.com/ITZAN44/Ecommerce-Proyecto-BD` es abierto (verificado con `gh repo view`) y los commits están publicados. Los valores se consideran **quemados y permanentes** — están en el historial de git y en cualquier fork.

> Los valores concretos **no se transcriben acá** para no seguir replicándolos. Se identifican por ubicación.

#### Alcance real: 28 archivos, no 3

El registro original listaba 3 archivos. Un barrido sobre todo el árbol trackeado (2026-07-27) encontró **28**. Los relevantes:

| Categoría | Archivos | Qué contiene |
|---|---|---|
| Config activa | `docker-compose.yml`, `k8s/postgres-secret.yaml`, `ansible/inventory/hosts.ini`, `ansible/inventory/group_vars/{all,production}.yml`, `ansible/roles/k3s/{defaults/main.yml,files/postgres-secret.yaml}`, ~~`exportar_bd.ps1`~~ (✅ limpiado 2026-07-27), `audit/tools/.tbls.yml` | password de BD, password de k8s, IP y usuario de la VM |
| Documentación | `docs/explanation/devops/arquitectura.md`, `audit/HERRAMIENTAS.md`, **este mismo archivo** (antes de esta redacción), 12 archivos en `docs/_legacy/` | los mismos valores, citados como ejemplo |
| Falso positivo | `jenkins/kubeconfig` | **No es filtración**: son 3 líneas de comentario, una plantilla sin certificados ni tokens (verificado por lectura directa) |

> ✅ **Resuelto el 2026-07-27** (era `SIN VERIFICAR`): `database/backup_bd_real.sql` matchea la cadena de la password **5 veces, pero NO es la credencial**. Todas son `hash_12345678`, un placeholder de contraseña en la columna `hash_contrasena` de `clientes` (3 en filas de `auditoria`, 2 en filas de `clientes`). Es dato de prueba de la aplicación, no credencial de infraestructura. **El dump sale de la lista de S1.**

#### Evaluación de riesgo (2026-07-27)

| Valor filtrado | Riesgo real |
|---|---|
| IP `192.168.x.x` de la VM | **Nulo desde internet** — rango privado RFC 1918, no enrutable |
| Password de Postgres | **Casi nulo** — sin entropía; está en el top-10 de cualquier diccionario, un atacante la probaría igual |
| Password del Secret de k8s | Nulo — el cluster corre en esa VM de LAN |
| Usuario SSH de la VM | Bajo, pero es el dato **más duradero**: las passwords se cambian, los usuarios no |

**Conclusión**: sin exposición a internet no hay superficie de ataque. El riesgo práctico hoy es cercano a cero.

#### Decisión: aceptar el riesgo, no rotar

Se decidió **no rotar** estas credenciales. Fundamento:

1. Toda la infraestructura afectada es **local/LAN**, sin IP pública.
2. La password no tiene entropía: rotarla no cambia el modelo de amenaza mientras siga en LAN.
3. **El costo excede el beneficio**: rotar rompe la VM de pruebas, Ansible, K3s y Jenkins, y obliga a re-sincronizar toda la capa DevOps, a cambio de una ganancia de seguridad nula.

**La frontera de seguridad se traza en el borde de internet**, no en el repo:

- Lo de LAN queda como está — riesgo aceptado y fundamentado.
- **Todo lo que toque internet (Neon, Render) usa credenciales nuevas de alta entropía que NUNCA entran al repo.** El connection string de Neon es el activo a proteger: alta entropía, alcanzable desde internet y con datos reales. Si ese se filtra, sí es incidente.

**Condición de disparo para rotar** (revisar si ocurre alguna):

- La VM se expone hacia afuera (port forwarding, túnel tipo ngrok, VPN mal configurada).
- La VM se migra a un proveedor cloud con IP pública.
- Se detecta reutilización de ese usuario/password en algún servicio alcanzable.

#### Medidas preventivas (hacia adelante)

- ✅ **Aplicado**: `docker-compose.yml` toma las credenciales de `.env` (ignorado por git), con la convención `DB_*` de `src/lib/db.ts`. `k8s/postgres-secret.yaml` y `ansible/inventory/hosts.ini` quedaron como plantillas sin valores reales.
- ✅ **Aplicado**: valores redactados en este documento.
- ⬜ **Pendiente recomendado**: hook de `gitleaks` en pre-commit. Es la medida de mayor valor: ataja el connection string de Neon —alta entropía, sí detectable— antes de que se commitee por accidente.
- ⬜ **Pendiente**: los otros 26 archivos siguen conteniendo los valores. Al estar el riesgo aceptado, limpiarlos es cosmético (no revierte el historial público); se deja como tarea de higiene de baja prioridad.

> **Cruce con gitleaks (2026-07-24)**: gitleaks NO marcó estos secretos porque son de **baja entropía** (contraseñas de config), fuera de su modelo de detección (tokens/API keys de alta entropía). El hallazgo se sostiene por lectura directa de los archivos citados; gitleaks solo aporta que **no hay además** tokens/keys de alta entropía filtrados. Esa misma limitación es la razón por la que el hook propuesto **sí** serviría para Neon.

### S2 — `hash_contrasena` no es un hash y no hay login real
**Severidad** 🔴 (nombre engañoso) / contexto académico · **Estado** `Abierto`

`src/pages/api/clientes/index.ts:43,72` guarda `` `hash_${contrasena}` `` — la contraseña en texto plano con un prefijo literal `"hash_"`, sin ninguna función criptográfica. Además **ningún endpoint la lee ni compara** → no existe autenticación real.

**Remediación**: si el proyecto necesita auth, usar hashing real (bcrypt/argon2) y un flujo de login. Si no lo necesita (proyecto académico), **renombrar la columna** para no inducir a error (`hash_contrasena` sugiere seguridad que no existe).

> **Confirmación colateral (2026-07-27)**: al auditar el dump aparecieron 5 ocurrencias de `hash_12345678`. Es exactamente lo que describe este issue — la contraseña `12345678` guardada en claro con el prefijo `hash_`. El nombre de la columna es engañoso y el dato queda legible en el dump versionado.

### S3 — La limpieza de datos no alcanzó la tabla `auditoria`
**Severidad** 🟡 · **Estado** `Abierto` (detectado el 2026-07-27)

La limpieza de datos de prueba del 2026-07-25 renombró los clientes a nombres ficticios (`Karina Flores`, `Óscar Vargas`), pero **la tabla `auditoria` conserva los valores previos** en sus columnas `datos_anteriores` / `datos_nuevos`.

**Verificado en la base viva**: 6 filas de `auditoria` contienen direcciones de correo de dominios públicos. Como `auditoria` se exporta en el dump, esos valores viajan al repositorio.

Direcciones presentes en el dump (5 únicas): `chile@gmail.com`, `ijij@gmail.com`, `sales.lol@gmail.com`, `tieso@gmail.com`, `torque@gmail.com`. `SIN VERIFICAR` si corresponden a personas reales o son cuentas inventadas durante las pruebas.

**Alcance real de la exposición**: las 5 **ya estaban** en el dump publicado en `origin/main` antes de este re-export — se comprobó que el dump nuevo **no agrega ninguna dirección nueva**. Es decir, no es una fuga nueva, es una preexistente que la limpieza no cubrió.

**Por qué pasó**: la limpieza operó sobre las tablas de negocio, pero los triggers de auditoría ya habían registrado los valores originales. Un `UPDATE` de limpieza **genera una fila de auditoría más** con el valor viejo en `datos_anteriores`, en vez de borrar rastro.

**Remediación**: decidir una de dos.
1. Purgar o anonimizar `auditoria` antes de re-exportar (`UPDATE` sobre los JSON, o `TRUNCATE` si el histórico no aporta).
2. Excluir `auditoria` del dump versionado (`--exclude-table-data=auditoria`), conservándola solo en la base viva.

> La opción 2 es más simple y no pierde nada del esquema; la 1 conserva el histórico a costa de más trabajo. **No se aplicó ninguna**: requiere decisión del responsable, porque implica descartar datos.

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
>
> 📄 **El procedimiento vive aparte**: [`deploy/spec-render-neon.md`](./deploy/spec-render-neon.md).
> Este archivo registra **qué está roto** (issues); aquel documenta **cómo se despliega** (spec verificado, paso a paso).

### H1 — `db.ts` no está preparado para una base gestionada (bloquea el deploy)
**Severidad** 🔴 · **Estado** `Resuelto` (2026-07-27)

`src/lib/db.ts` configuraba el `Pool` para un Postgres local en la misma red. Tres puntos lo hacían incompatible con Neon (verificados por lectura directa del archivo, 2026-07-26):

| # | Punto | Fuente original | Por qué rompía con Neon | Corrección aplicada |
|---|---|---|---|---|
| a | **No había opción `ssl`** en el `Pool` | `db.ts:6-15` | Neon exige TLS. Sin `ssl`, la conexión **falla**. Era el bloqueante duro. | `ssl` condicional por `DB_SSL`, más `DB_SSL_REJECT_UNAUTHORIZED` como escotilla para certificados autofirmados. |
| b | `connectionTimeoutMillis: 2000` | `db.ts:14` | Neon duerme la base tras inactividad; despertarla puede exceder 2 s → la primera visita falla. | Configurable por `DB_CONNECTION_TIMEOUT_MS`, por defecto **15000**. |
| c | `pool.on('error', …)` hacía `process.exit(-1)` | `db.ts:28-31` | Un error de conexión ocioso (habitual cuando Neon escala a cero) **terminaba el proceso del servidor entero**. | El handler solo registra el error; el pool descarta el cliente roto y abre otro. |

Se mantuvo la convención de variables discretas `DB_*` ya establecida en `db.ts` y `docker-compose.yml`. **No se introdujo `DATABASE_URL`**: se verificó por búsqueda en todo el repo que no existe ningún consumidor de esa variable en `src/`.

**Variables nuevas** (las tres opcionales; sin definirlas, el comportamiento es idéntico al anterior):

| Variable | Por defecto | Para qué |
|---|---|---|
| `DB_SSL` | `false` | `true` activa TLS. Necesaria en Neon; debe quedar sin definir en local. |
| `DB_SSL_REJECT_UNAUTHORIZED` | `true` | Solo se pone en `false` si el proveedor usa un certificado autofirmado. |
| `DB_CONNECTION_TIMEOUT_MS` | `15000` | Margen para el arranque en frío de una base con suspensión por inactividad. |

**Verificación** (2026-07-27, tres fuentes independientes):

1. `npx tsc --noEmit` → exit 0.
2. `npm run build` → build SSR completo sin errores.
3. Prueba de conexión real contra `ecommerce_db` con la config nueva:
   - por defecto → `CONEXION OK | ssl=false | db=ecommerce_db`
   - con `DB_SSL=true` → `The server does not support SSL connections`

   El segundo resultado es el esperado y **confirma que el flag negocia TLS de verdad**: el Postgres local no lo tiene, Neon sí.

> **Aclaración**: (c) era un problema de robustez que existía también en local — con Neon simplemente pasaba de improbable a esperable.

> **Hallazgo para después** (detectado al verificar, fuera del alcance de H1): el `.env` local define `DB_PORT=5501`, pero el contenedor `ecommerce_db` publica `5432` (`docker ps`) y `docker-compose.yml:43` fija `DB_PORT: 5432` para el servicio `app`. Por eso la app **en Docker funciona**, pero levantar la app **en el host** leyendo el `.env` falla con `ECONNREFUSED 127.0.0.1:5501`. No bloquea el deploy (Render define sus propias variables). Requiere decidir cuál de los dos puertos es el correcto.

### H2 — La base viva diverge del dump versionado
**Severidad** 🟡 · **Estado** `Resuelto` (2026-07-27)

`database/backup_bd_real.sql` **ya no refleja** la base viva `ecommerce_db`. Cambios aplicados a la base y no re-exportados:

- El fix de **V1** (`CALL sp_actualizar_stock_compra` dentro de `sp_procesar_pago`), aplicado el 2026-07-24.
- Limpieza de datos de prueba del 2026-07-25 (nombres de clientes y productos, SKUs, categoría `COMIDA`→`Alimentos`, baja de un producto y una categoría huérfanos).

**Impacto en el deploy**: la carga inicial de Neon se hace desde el dump. Si se sube el dump actual, la base en la nube arranca **sin el fix de V1 y con los datos de prueba**.

**Remediación**: re-exportar el dump **antes** de cargar Neon, y volver a versionarlo.

#### Ampliación del 2026-07-27 — el re-export tiene dos motivos, no uno

Al analizar el dump para el despliegue aparecieron **requisitos técnicos adicionales** que convierten el re-export en obligatorio incluso ignorando la divergencia de contenido:

- **78 sentencias `OWNER TO`** en `database/backup_bd_real.sql`. El rol `neon_superuser` no puede ejecutar `ALTER ... OWNER TO`. Como el dump es de **formato plano**, se carga con `psql`, y `--no-owner` es un flag de `pg_dump`/`pg_restore` que **no existe en `psql`**: no se puede corregir al cargar.
- **`client_encoding = 'WIN1252'`**, con riesgo de corromper acentos. Conviene `--encoding=UTF8`.

Flags requeridos en el nuevo export: `--no-owner --no-privileges --encoding=UTF8`.

> ✅ Confirmado también por análisis: el dump **no** contiene `CREATE EXTENSION`, `CREATE ROLE`, `GRANT`/`REVOKE` ni `CREATE DATABASE`. Por ese lado está limpio.

#### ~~🔴 `exportar_bd.ps1` no funciona hoy~~ → ✅ Reescrito el 2026-07-27

El script apunta a `127.0.0.1:5501` (`exportar_bd.ps1:37`), que correspondía a una instalación **nativa** de PostgreSQL en el host, distinta del contenedor. Verificado el 2026-07-27 con dos comprobaciones independientes:

1. `Get-NetTCPConnection -State Listen -LocalPort 5501` → **nada escuchando**.
2. `Get-Service -Name 'postgresql*'` → **ningún servicio registrado**.

El re-export debe hacerse contra el contenedor `ecommerce_db` (que tiene `pg_dump` 16.11), no con ese script tal como está.

> Esto **explica el hallazgo anotado en H1** sobre el `DB_PORT=5501` del `.env`: no es un error de tipeo, es un remanente de la era del Postgres nativo.

Además, el script tenía otros tres defectos detectados al revisarlo:

| # | Defecto | Línea original |
|---|---|---|
| 1 | No pasaba `--no-owner --no-privileges --encoding=UTF8`: aunque se arreglara el puerto, **volvía a generar un dump incompatible con Neon** | `:37` |
| 2 | Imprimía la contraseña en texto plano, dos veces | `:32`, `:50` |
| 3 | Sugería `docker-compose down -v` como "siguiente paso" — ese comando **destruye el volumen de datos** | `:43` |

**Reescrito el 2026-07-27.** Ahora ejecuta `pg_dump` dentro del contenedor (no necesita client tools en el host), aplica los tres flags obligatorios, no maneja ni imprime credenciales, y no sugiere ningún comando destructivo.

Buenas prácticas incorporadas:

- **Escritura atómica**: exporta a un temporal y solo reemplaza el dump anterior si todo salió bien. Un `pg_dump` que falle a mitad ya no puede pisar un dump bueno.
- **Verificación post-export**: comprueba 5 condiciones sobre el archivo generado (0 `OWNER TO`, `UTF8`, 0 `GRANT`/`REVOKE`, presencia de tablas, marca de cierre del dump). Si alguna falla, **rechaza el dump y conserva el anterior**.
- **Precondiciones explícitas**: valida que exista `docker`, que el contenedor esté corriendo y que PostgreSQL acepte conexiones, con mensajes accionables y `exit 1`.
- **Parametrizado**: `-Container`, `-Database`, `-User`, `-OutputPath`, con ayuda vía `Get-Help`.
- **Aviso de `\restrict`**: detecta los meta-comandos de pg_dump 16.10+ y remite al spec de deploy.
- **ASCII puro**: un `.ps1` sin BOM con caracteres no-ASCII se corrompe en Windows PowerShell 5.1.

**Verificado por ejecución (2026-07-27)**:

| Prueba | Resultado |
|---|---|
| Contenedor inexistente | `exit 1`, mensaje claro, **dump anterior intacto** (hash sin cambios) |
| Ejecución normal | `exit 0`, las 5 verificaciones OK, aviso de `\restrict` mostrado |
| Restauración del dump que produjo | Contenedor descartable, **cero errores**; 12 indicadores idénticos a la base viva, acentos y fix de V1 correctos |

> Con esto `exportar_bd.ps1` sale de la lista de archivos con credenciales de **S1**: quedan **27**.

#### ✅ Resolución (2026-07-27)

Re-exportado desde el contenedor `ecommerce_db` con `pg_dump` 16.11 y los flags `--no-owner --no-privileges --encoding=UTF8`. Exit 0, stderr vacío.

| Comprobación | Antes | Después |
|---|---|---|
| `OWNER TO` | 78 | **0** |
| `client_encoding` | `WIN1252` | **UTF8** |
| Fix de V1 (`CALL` dentro de `sp_procesar_pago`) | ausente | **presente** |

**Validado por restauración real**, no solo por inspección del archivo: se cargó en un contenedor `postgres:16-alpine` descartable (sin tocar el volumen del proyecto) y se comparó contra la base viva. Cero errores en la carga; los 8 indicadores estructurales (13 tablas, 1 vista, 2 materializadas, 35 funciones, 14 procedimientos, 18 triggers, 48 índices, 12 FKs) y las filas de las 13 tablas resultaron **idénticos**. Los acentos también, byte a byte.

> ✅ **El re-export es reproducible**: `exportar_bd.ps1` fue reescrito el 2026-07-27 y genera este mismo dump con una sola ejecución. El primer re-export se hizo a mano; el definitivo salió del script y se validó por restauración.

> 🆕 **Efecto colateral del cambio de versión**: el dump nuevo incluye los meta-comandos `\restrict`/`\unrestrict` (PostgreSQL 16.10+), que el viejo no tenía. Solo los entienden clientes `psql` recientes. Impacta la ruta de carga a Neon — detalle en [`deploy/spec-render-neon.md` §6.4 y §6.6](./deploy/spec-render-neon.md).

Procedimiento y evidencia completa en [`deploy/spec-render-neon.md` §6](./deploy/spec-render-neon.md).

### H3 — Estado del despliegue
**Severidad** 🟢 · **Estado** `Abierto`

El proyecto **NO está deployado**: no hay URL pública (`NO CONFIRMADO`). Corre en `http://localhost:4321`, local y vía Docker.

> **Nota de alcance**: los issues de infra **A1, A3, A4 y C1** son de Kubernetes, Jenkins y Ansible. Render **no usa ninguna de esas piezas**, así que no bloquean este despliegue; siguen abiertos para la vía K3s/Jenkins.

> **Nota sobre S1 y el repo público**: el remoto `github.com/ITZAN44/Ecommerce-Proyecto-BD` es **público** (verificado con `gh repo view`, 2026-07-26). Las credenciales de S1 son visibles para cualquiera. No bloquea el deploy (Render inyecta sus propias variables y las de Neon son distintas), pero publicar una URL le da visibilidad al repo. Refuerza la prioridad de **S1**.

---

## 🔎 Sub-hallazgos por verificar (no accionar sin confirmar)

- **D3 y D4 dejaron de ser `Verificar`** el 2026-07-26: ambos quedaron confirmados contra la base viva y `docker-compose.yml`. Pasaron a `Abierto` (falta accionarlos, no verificarlos).
- **Pendiente de verificar**: el orden alfabético de carga de los `.sql` de init (ver sub-hallazgo en **D4**) — no se comprobó si produce errores o si el resultado final es equivalente.
