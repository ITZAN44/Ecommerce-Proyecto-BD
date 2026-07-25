# Registro de remediación

> Issues detectados durante la auditoría, separados de la documentación descriptiva.
> La doc (`explanation/`) describe **cómo ES** el sistema; este archivo lista **qué conviene arreglar**.
> Cada issue cita su fuente real. Fecha de corte: 2026-07-23.

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

**Remediación**: decidir por rutina — eliminar, o cablearla a un endpoint/página si se pensaba usar.

### D2 — Las vistas materializadas se refrescan a mano
**Severidad** 🟡 · **Estado** `Abierto`

`index.astro` (dashboard) lee `mv_clientes_vip` y `mv_productos_top_ventas` **sin refrescarlas**. El `REFRESH MATERIALIZED VIEW CONCURRENTLY` vive en un `POST` separado de `clientes-vip.ts` / `top-productos.ts` que hay que invocar explícitamente. Si nadie lo llama, la pantalla principal muestra rankings viejos.

**Remediación**: refrescar por schedule (cron/pg_cron) o al escribir los datos que las alimentan, no depender de un POST manual.

### D3 — Redundancia de auditoría
**Severidad** 🟢 · **Estado** `Verificar`

Coexisten 8 `fn_auditoria_<tabla>` específicas **y** `fn_auditoria_generica` con la misma lógica. Probable código muerto en una de las dos vías.

**Remediación**: confirmar qué trigger está realmente enganchado por tabla; unificar en la vía genérica y eliminar la redundante.

### D4 — Scripts de init de BD por subcarpetas no se ejecutan solos
**Severidad** 🟢 · **Estado** `Verificar`

`database/fase1|2|3` se montan en `docker-entrypoint-initdb.d`, pero Postgres **no ejecuta subdirectorios recursivamente** → esas fases no corren en el init automático. Las 49 rutinas existen igual (vía `functions_procedures_LIMPIO.sql` / `backup_bd_real.sql`).

**Remediación**: aplanar los scripts al nivel que Postgres sí ejecuta, o cargar por un orquestador explícito. Confirmar antes qué scripts se cargan hoy realmente.

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

## 🔎 Sub-hallazgos por verificar (no accionar sin confirmar)

*(Ninguno pendiente por ahora — V1 se confirmó arriba. Ver también D3 y D4, marcados `Verificar`.)*
