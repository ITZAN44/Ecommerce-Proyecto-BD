# Spec de despliegue — Render (app) + Neon (PostgreSQL)

> **Qué es este documento.** Un spec **vivo** del despliegue: recoge únicamente lo que ya fue **verificado contra una fuente real** (archivo del repo, salida de comando, base viva o documentación oficial del proveedor), y declara de forma explícita lo que todavía **no** lo fue.
>
> **Qué NO es.** No es una guía teórica ni una copia de un tutorial. Cada afirmación lleva su cita. Si un dato no se pudo confirmar, aparece marcado `SIN VERIFICAR` — nunca se rellena con una suposición.
>
> **Cómo crece.** Se amplía a medida que avanzamos: cada paso que se ejecuta y se comprueba se incorpora acá con su evidencia. Los pasos aún no ejecutados viven en la sección [Pendiente de verificar](#-pendiente-de-verificar), no mezclados con los hechos.
>
> **Relación con `remediacion.md`.** Aquel archivo es un **registro de issues** (qué está roto y hay que arreglar). Este es el **procedimiento** (cómo se despliega). Los issues del bloque `☁️ Deploy` se referencian acá por su ID (H1, H2, H3), pero su estado se mantiene allá.

Fecha de creación: **2026-07-27** · Última actualización: **2026-07-27**

---

## 📊 Estado del spec

| Bloque | Estado |
|---|---|
| 1. Arquitectura objetivo | ✅ Definida |
| 2. Precondiciones del código | ✅ Verificado — H1 resuelto |
| 3. Compatibilidad de la app con Render | ✅ Verificado por lectura de código |
| 4. Plataforma Neon: tooling y límites | ✅ Verificado en docs oficiales |
| 5. Inventario del entorno local | ✅ Verificado por ejecución |
| 6. Dump apto para Neon | ✅ **Re-exportado y validado por restauración real** — cierra H2 |
| 7. Creación del proyecto Neon | ⬜ Pendiente de ejecutar |
| 8. Carga del dump en Neon | ⬜ Pendiente de ejecutar |
| 9. Despliegue en Render | ⬜ Pendiente de ejecutar |
| 10. Verificación post-deploy | ⬜ Pendiente de ejecutar |

**Bloqueantes vigentes**: ninguno. Lo que resta depende de una API key de Neon, no de arreglos en el proyecto.

---

## 1. Arquitectura objetivo

```
Internet
   │
   ├─→ Render (Web Service, Docker)  ── app Astro 5 SSR, Node standalone
   │        │
   │        └── conexion TLS (sslmode=require)
   │                    │
   └────────────────────┴─→ Neon (PostgreSQL 16 gestionado, serverless)
```

**Decisión**: hosting gestionado en lugar de la vía K3s/Jenkins/Ansible que ya existe en el repo.

> **Nota de alcance**: los issues de infraestructura **A1, A3, A4 y C1** son de Kubernetes, Jenkins y Ansible. Render **no usa ninguna de esas piezas**, así que no bloquean este despliegue. Siguen abiertos para la vía K3s.

---

## 2. Precondiciones del código — ✅ VERIFICADO

### 2.1 El pool de PostgreSQL soporta una base gestionada

Resuelto el 2026-07-27 (issue **H1**, commit `38561a1`). Antes de este cambio el deploy era **imposible**, no difícil: sin TLS la conexión a Neon no se establece.

| Variable | Por defecto | Para qué | Fuente |
|---|---|---|---|
| `DB_SSL` | `false` | `true` activa TLS. **Obligatoria en Neon.** | `src/lib/db.ts` |
| `DB_SSL_REJECT_UNAUTHORIZED` | `true` | Solo `false` si el proveedor usa certificado autofirmado. | `src/lib/db.ts` |
| `DB_CONNECTION_TIMEOUT_MS` | `15000` | Margen para el arranque en frío de una base suspendida. | `src/lib/db.ts` |

Las tres son **opcionales**: sin definirlas, el comportamiento es idéntico al anterior y el entorno local con Docker sigue funcionando sin cambios.

**Evidencia de la verificación (2026-07-27)**:

| Prueba | Resultado |
|---|---|
| `npx tsc --noEmit` | exit 0 |
| `npm run build` | build SSR completo, sin errores |
| Conexión real a `ecommerce_db`, por defecto | `CONEXION OK \| ssl=false \| db=ecommerce_db \| tablas=14` |
| Conexión real a `ecommerce_db`, con `DB_SSL=true` | `CONEXION FALLO: The server does not support SSL connections` |

El último resultado es **el esperado** y es la prueba que importa: confirma que el flag negocia TLS de verdad contra el servidor. El Postgres local no lo soporta; Neon sí. Si esa prueba hubiera dado "OK", el flag sería decorativo.

### 2.2 Se mantuvo la convención de variables existente

Se usan variables discretas `DB_HOST`/`DB_PORT`/`DB_NAME`/`DB_USER`/`DB_PASSWORD`. **No se introdujo `DATABASE_URL`**: se verificó por búsqueda en todo el repositorio que no existe ningún consumidor de esa variable en `src/`.

Consecuencia práctica para el despliegue: el connection string que entrega Neon **debe descomponerse** en sus cinco partes al cargarlo en Render. No se pega entero.

---

## 3. Compatibilidad de la app con Render — ✅ VERIFICADO

Render ejecuta el contenedor e **inyecta su propia variable `PORT`**. La pregunta que decide si esto funciona es si la app la respeta. Verificado leyendo el código del adaptador instalado, no la documentación:

```js
// node_modules/@astrojs/node/dist/standalone.js:15-16  (@astrojs/node v9.5.0)
const port = process.env.PORT ? Number(process.env.PORT) : options.port ?? 8080;
const host = process.env.HOST ?? hostOptions(options.host);
```

**Conclusión**: el adaptador lee `PORT` y `HOST` del entorno en **runtime**. El `ENV PORT=4321` del `Dockerfile:48-50` es solo un valor por defecto que Render sobrescribe. La app se adapta sin cambios.

Otras piezas confirmadas por lectura directa:

| Punto | Fuente | Estado |
|---|---|---|
| `output: 'server'` + adaptador `node` en modo `standalone` | `astro.config.mjs:9-12` | ✅ Compatible con Render |
| `host: true` — acepta conexiones externas al contenedor | `astro.config.mjs:14` | ✅ |
| Build multi-stage, imagen final sin devDependencies | `Dockerfile:4,23,35` | ✅ |
| Corre como usuario no-root (`astro`, uid 1001) | `Dockerfile:26-27,42` | ✅ |
| Arranque: `node ./dist/server/entry.mjs` | `Dockerfile:57` | ✅ |

> ⚠️ **Detalle a vigilar**: el `HEALTHCHECK` del `Dockerfile:53-54` tiene el puerto **4321 hardcodeado**. Si Render asigna otro `PORT`, ese healthcheck de Docker apuntaría al puerto equivocado. `SIN VERIFICAR` si Render llega a usar el `HEALTHCHECK` del Dockerfile o solo su propio chequeo HTTP — hay que confirmarlo al desplegar.

> ⚠️ **Diferencia clave con el entorno local**: `docker-compose.yml:52` monta `- .:/app`, lo que **sombrea** el `/app/dist` construido dentro de la imagen. Render usa el `Dockerfile` **sin** ese bind mount, así que sí ejecuta el build de la imagen. Es una diferencia real de comportamiento entre local y producción.

---

## 4. Plataforma Neon: tooling y límites — ✅ VERIFICADO

### 4.1 Las dos superficies de automatización

| | CLI `neon` / `neonctl` | Servidor MCP oficial |
|---|---|---|
| Instalación | `npm i -g neonctl` (Node ≥18); también binarios Windows y Homebrew | `npx neon@latest init`, o `npx -y @neondatabase/mcp-server-neon start <API_KEY>` |
| Auth sin navegador | ✅ `--api-key` o `NEON_API_KEY` | ✅ API key u OAuth |
| Salida para máquina | ✅ `--output json` en todo comando | N/A |
| Auditabilidad | ✅ cada comando queda en el log del shell | ❌ menor |
| Postura del proveedor | Sin restricción | **Neon lo desaconseja explícitamente en producción** |

**Decisión: se usa el CLI.** Es determinista, cada acción queda registrada, y no aporta menos que el MCP para este caso. El servidor MCP añade una capa de interpretación en lengua natural que acá no hace falta y que complica reproducir lo hecho.

### 4.2 Autenticación headless

Orden de precedencia de credenciales, según la documentación oficial:

```
--api-key  →  NEON_API_KEY (env)  →  credentials.json (de `neon auth`)  →  OAuth interactivo
```

Las dos primeras no requieren navegador, que es lo que permite operarlo de forma no interactiva.

### 4.3 Comandos relevantes para este despliegue

| Comando | Para qué |
|---|---|
| `neon projects create` | Crear el proyecto |
| `neon connection-string [branch]` | Obtener el string de conexión |
| `neon psql <branch> -- <args>` | Ejecutar SQL contra la base |
| `neon databases list` | Confirmar la base creada |
| `neon api` | Passthrough autenticado a la API cruda |

### 4.4 Dato decisivo: `neon psql` no requiere PostgreSQL instalado

Textual de la documentación oficial:

> *"neon psql uses the native psql binary from your $PATH if one is available, and otherwise falls back to a built-in TypeScript implementation, so no PostgreSQL client tools installation is required."*

Los argumentos se pasan tras `--`:

```bash
neon psql <branch> -- -f archivo.sql
neon psql <branch> -- -c "SELECT version()"
```

**Por qué importa acá**: en este equipo no hay `psql` ni `pg_dump` en el host (§5). Sin esta característica habría que instalar las client tools de PostgreSQL solo para cargar el dump.

### 4.5 Formato del connection string

```
postgresql://[role]:[password]@[endpoint]/[database]?sslmode=require&channel_binding=require
```

El `--ssl` de `neon connection-string` **por defecto es `require`**. Esto **confirma de forma independiente** que el `DB_SSL=true` implementado en §2.1 no era una precaución teórica: es obligatorio.

> Para cargar el dump hay que usar el string **no-pooled**. La documentación advierte contra `pg_dump` sobre conexión pooled por incompatibilidad con PgBouncer.

### 4.6 Límites del plan Free

Según el FAQ oficial de Neon:

| Recurso | Límite |
|---|---|
| Proyectos | 100 |
| Branches por proyecto | 10 |
| Storage | **0.5 GB por proyecto** |
| Compute | 100 CU-hours por proyecto/mes, autoscaling hasta 2 CU (~8 GB RAM) |
| Transferencia de red | 5 GB por proyecto/mes |
| Scale-to-zero | A los **5 min de inactividad**, y **no se puede desactivar** |

**Contraste con nuestro caso**: el dump pesa **157 KB** (§6). El margen de storage es holgadísimo.

**El scale-to-zero no desactivable** es la razón de fondo de dos de los tres arreglos de H1: el timeout de 2000 ms no alcanzaba para el arranque en frío, y el `process.exit(-1)` convertía un cierre de conexión ociosa rutinario en la caída del servidor entero.

> Se encontraron fuentes de terceros con cifras distintas (p. ej. "5 GB agregados en 10 proyectos"). Se descartaron: **gana el FAQ oficial de Neon**.

---

## 5. Inventario del entorno local — ✅ VERIFICADO

Ejecutado el 2026-07-27 sobre esta máquina (Windows 11):

| Herramienta | Estado | Consecuencia |
|---|---|---|
| `node` | ✅ v24.14.1 | Cumple el mínimo del CLI de Neon (≥18) |
| `npx` | ✅ 11.11.0 | Permite `npx neon@latest` sin instalar global |
| `neonctl` / `neon` | ❌ no instalado | Hay que instalarlo |
| `psql` (host) | ❌ no instalado | Mitigado por §4.4 |
| `pg_dump` (host) | ❌ no instalado | **Mitigado por el contenedor**, ver abajo |
| `psql` / `pg_dump` (contenedor `ecommerce_db`) | ✅ **PostgreSQL 16.11** | Es la vía para re-exportar el dump |
| Contenedor `ecommerce_db` | ✅ Up, healthy, publica `0.0.0.0:5432` | Fuente del re-export |
| Contenedor `ecommerce_app` | ✅ Up, healthy, publica `0.0.0.0:4321` | — |

### 5.1 Hallazgo: la instalación nativa de PostgreSQL ya no existe

`exportar_bd.ps1:37` exporta desde `127.0.0.1:5501`, que correspondía a una instalación **nativa** de PostgreSQL en el host, distinta del contenedor.

Verificado el 2026-07-27 con dos comprobaciones independientes:

1. `Get-NetTCPConnection -State Listen -LocalPort 5501` → **nada escuchando**.
2. `Get-Service -Name 'postgresql*'` → **ningún servicio registrado**.

**Conclusiones**:
- `exportar_bd.ps1` **no funcionaba** tal como estaba escrito. **Reescrito el 2026-07-27** para exportar contra el contenedor (§6.2).
- Esto explica el `DB_PORT=5501` del `.env` local: no es un error de tipeo, es un **remanente** de la era del Postgres nativo. Por eso la app **en Docker** funciona (`docker-compose.yml:43` fija `DB_PORT: 5432` y pisa el `.env`) pero levantarla **en el host** falla con `ECONNREFUSED 127.0.0.1:5501`.
- No bloquea el despliegue: Render define sus propias variables de entorno.

> `exportar_bd.ps1` imprimía la contraseña en texto plano y era uno de los 28 archivos alcanzados por **S1**. La reescritura del 2026-07-27 la eliminó: quedan **27**.

---

## 6. Dump apto para Neon — ✅ VERIFICADO

Ejecutado el 2026-07-27. Cierra el issue **H2**.

### 6.1 Por qué había que re-exportar: dos motivos independientes

El dump versionado (`pg_dump` 16.4, formato plano, 157 KB) tenía **dos problemas sin relación entre sí**, y cualquiera de los dos por separado ya obligaba a re-exportar:

**(a) Incompatibilidad con Neon — 78 sentencias `OWNER TO`.** El rol `neon_superuser` no puede ejecutar `ALTER ... OWNER TO`. La documentación oficial indica el flag `-O, --no-owner`, pero ese flag es de `pg_dump`/`pg_restore`, **no de `psql`**. Como el dump es de formato **plano**, se carga con `psql`: no había forma de corregirlo en el momento de la carga.

**(b) Divergencia de contenido (H2).** El dump no incluía el fix de V1 ni la limpieza de datos del 2026-07-25.

> **Cómo se verificó (b), y por qué el atajo engañaba**: una búsqueda simple de `sp_actualizar_stock_compra` en el dump viejo devolvía **3 coincidencias**, lo que sugería que el fix estaba. Al inspeccionar las líneas resultó que las tres eran la **definición del propio procedimiento** (`backup_bd_real.sql:1231`, `:1234`, `:1259`) — el comentario de cabecera, el `CREATE PROCEDURE` y el `ALTER ... OWNER TO`. Acotando la búsqueda al cuerpo de `sp_procesar_pago`: **cero `CALL`**. El fix efectivamente no estaba. Un conteo agregado no prueba presencia; hay que mirar el contexto.

### 6.2 El export: reproducible vía script

El re-export se ejecuta con **`exportar_bd.ps1`**, reescrito el 2026-07-27 para este propósito:

```powershell
.\exportar_bd.ps1
```

Internamente corre `pg_dump` **dentro del contenedor** (§5.1), no contra el puerto 5501:

```bash
docker exec ecommerce_db pg_dump -U postgres -d ecommerce_db \
  --no-owner --no-privileges --encoding=UTF8 -F p
```

| Flag | Por qué |
|---|---|
| `--no-owner` | Elimina las sentencias `OWNER TO` que Neon rechaza |
| `--no-privileges` | Preventivo: evita `GRANT`/`REVOKE` sobre roles inexistentes en Neon |
| `--encoding=UTF8` | Reemplaza `WIN1252`; evita corrupción de acentos |

> **Por qué script y no comando suelto**: el valor no es ahorrar tipeo, es que el dump salga **igual todas las veces**. Un flag olvidado en un export manual no se nota hasta que falla la carga en Neon.

Garantías del script, verificadas por ejecución:

- **Escritura atómica** — exporta a un temporal y solo reemplaza el dump anterior si todo salió bien. Probado con un contenedor inexistente: `exit 1` y el dump previo **intacto**.
- **Verificación post-export** — comprueba 5 condiciones sobre el archivo generado (0 `OWNER TO`, `UTF8`, 0 `GRANT`/`REVOKE`, presencia de tablas, marca de cierre). Si alguna falla, rechaza el dump.
- **Sin credenciales** — `pg_dump` se autentica por el socket local del contenedor.
- **Sin comandos destructivos** — la versión anterior sugería `docker-compose down -v`, que borra el volumen de datos.
- **Aviso de `\restrict`** — detecta los meta-comandos de pg_dump 16.10+ y remite a §6.4.
- **Parametrizado** — `-Container`, `-Database`, `-User`, `-OutputPath`.

Salida de la ejecución real: exit 0, stderr vacío, las 5 verificaciones OK.

### 6.3 Comparación antes/después

| Característica | Antes (16.4) | Después (16.11) |
|---|---|---|
| Tamaño | 157 KB | 155 KB |
| `client_encoding` | `WIN1252` | ✅ `UTF8` |
| `OWNER TO` | 78 | ✅ **0** |
| `GRANT` / `REVOKE` | 0 | ✅ 0 |
| `CREATE ROLE` | 0 | ✅ 0 |
| `CREATE DATABASE` | 0 | ✅ 0 |
| `CREATE EXTENSION` | 0 | ✅ 0 |
| Fix de V1 (`CALL` en `sp_procesar_pago`) | ❌ ausente | ✅ **presente** |

### 6.4 🆕 Hallazgo: `\restrict` / `\unrestrict`

El dump nuevo trae dos líneas que el viejo **no tenía** (verificado: 2 ocurrencias en el nuevo, 0 en el viejo):

```
línea 5     \restrict cUGDgNHYurrYmak3dOTe8f2Zow8AbdWyQ8hLi3SahFwIy5fHX6gXBtKGRkXP60X
línea 3651  \unrestrict cUGDgNHYurrYmak3dOTe8f2Zow8AbdWyQ8hLi3SahFwIy5fHX6gXBtKGRkXP60X
```

**Qué son**: una medida de seguridad introducida en PostgreSQL **16.10**. Un atacante con control del servidor de origen podría hacer que emita texto interpretable como meta-comandos de `psql`, logrando acceso a shell en la máquina que restaura. Para evitarlo, `pg_dump` entra en modo restringido con una **clave aleatoria distinta en cada dump** y sale con la clave coincidente.

**Por qué importa acá**: son meta-comandos de `psql`, es decir **del lado del cliente**. Un cliente que no los conozca falla con `invalid command \restrict`.

| Cliente | ¿Los entiende? |
|---|---|
| `psql` 16.11 del contenedor `ecommerce_db` | ✅ Sí — es el que los generó |
| Implementación TypeScript embebida de `neon psql` | ⚠️ **`SIN VERIFICAR`** |

**Consecuencia sobre la ruta de carga** — ver §6.6.

### 6.5 Validación por restauración real

No alcanza con inspeccionar el archivo. Se restauró el dump en un **contenedor `postgres:16-alpine` descartable**, sin tocar el volumen de datos del proyecto, y se comparó contra la base viva.

**Carga**: `psql -v ON_ERROR_STOP=0 -f dump.sql` → **cero errores**, cero avisos.

| Indicador | Base viva `ecommerce_db` | Restaurado | |
|---|---|---|---|
| Tablas | 13 | 13 | ✅ |
| Vistas | 1 | 1 | ✅ |
| Vistas materializadas | 2 | 2 | ✅ |
| Funciones | 35 | 35 | ✅ |
| Procedimientos | 14 | 14 | ✅ |
| Triggers | 18 | 18 | ✅ |
| Índices | 48 | 48 | ✅ |
| Foreign keys | 12 | 12 | ✅ |

> Las 49 rutinas de la auditoría = 35 funciones + 14 procedimientos. ✅
>
> Los 48 índices reconcilian así: **30** `CREATE INDEX` explícitos en el dump + **18** índices creados implícitamente por constraints `PRIMARY KEY`/`UNIQUE` (verificado con `pg_constraint`). No falta ninguno.

**Filas por tabla**: comparación automatizada de las 13 tablas → **idénticas**.

```
auditoria 76 · categorias 7 · clientes 15 · cupones 6 · detalle_pedido 27
devoluciones 11 · direcciones 18 · envios 23 · historial_estados 36
pagos 34 · pedidos 25 · productos 12 · stock 17
```

**Fix de V1**: presente en la base restaurada. ✅

**Codificación**: se compararon filas con acentos entre origen y restaurado — **idénticas byte a byte**. La conversión `WIN1252` → `UTF8` no corrompió nada.

```
Electrónica / Dispositivos y gadgets tecnológicos.
Hogar y Cocina / Artículos para el hogar, decoración y utensilios de cocina.
Libros / Libros físicos y digitales de diversos géneros.
```

El contenedor descartable fue eliminado tras la verificación.

> **Por qué esta prueba y no `docker compose down -v`**: recargar el entorno del proyecto habría **destruido el volumen de datos**. El contenedor descartable da la misma evidencia sin riesgo.

### 6.6 Ruta de carga a Neon: revisada por el hallazgo de §6.4

El plan original era cargar con `neon psql <branch> -- -f dump.sql`, apoyándose en la implementación TypeScript embebida (§4.4). El hallazgo de `\restrict` obliga a reconsiderarlo, porque **no está verificado** que esa implementación soporte ese meta-comando.

**Ruta preferida** — usar el `psql` 16.11 del contenedor apuntando a Neon:

```bash
docker exec ecommerce_db psql "<connection-string-no-pooled-de-neon>" -f /tmp/dump.sql
```

Ventajas verificadas:

- Ese cliente **generó** las líneas `\restrict`, así que las entiende con certeza.
- El contenedor **tiene salida a internet**: verificado el 2026-07-27 → DNS `neon.tech` → `104.18.23.51`, y `nc -z neon.tech 443` → OK.
- No agrega dependencias al host, que no tiene `psql` (§5).

**Ruta alternativa**: `neon psql -- -f dump.sql`. Queda como respaldo; si se usa, hay que verificar primero que no falle con `invalid command \restrict`.

> ⚠️ Recordatorio de §4.5: la carga debe usar el connection string **no-pooled**.
>
> ⚠️ Detalle operativo: en Git Bash sobre Windows, las rutas tipo `/tmp/dump.sql` en `docker exec` se convierten a rutas Windows y el comando falla con `No such file or directory`. Se evita anteponiendo `MSYS_NO_PATHCONV=1`.

---

## 7. Riesgos y gotchas confirmados

| # | Gotcha | Fuente | Mitigación |
|---|---|---|---|
| 1 | Sin TLS, la conexión a Neon **falla**, no degrada | Docs Neon + `neon connection-string` default `sslmode=require` | `DB_SSL=true` en Render (§2.1) |
| 2 | Scale-to-zero a los 5 min, **no desactivable** | FAQ oficial | Timeout de 15 s y handler de error no letal (§2.1) |
| 3 | 78 `OWNER TO` que `neon_superuser` no puede ejecutar | Análisis del dump | ✅ **Resuelto**: re-exportado con `--no-owner`, 0 ocurrencias (§6.3) |
| 4 | El bind mount de compose sombrea `/app/dist` | `docker-compose.yml:52` | No aplica en Render; sí explica diferencias local↔prod |
| 5 | El connection string de Neon **no se pega entero** | El código usa `DB_*` discretas (§2.2) | Descomponerlo en 5 variables en Render |
| 6 | `pg_dump` sobre conexión **pooled** rompe con PgBouncer | Docs Neon | Usar el string no-pooled para la carga |
| 7 | El `HEALTHCHECK` del Dockerfile tiene el puerto hardcodeado | `Dockerfile:53-54` | `SIN VERIFICAR` si Render lo usa — confirmar al desplegar |
| 8 | `\restrict` en el dump: falla en clientes psql que no lo conocen | Dump nuevo, líneas 5 y 3651 | Cargar con el `psql` 16.11 del contenedor (§6.6) |
| 9 | Git Bash convierte rutas `/tmp/...` de `docker exec` a rutas Windows | Observado el 2026-07-27 | Anteponer `MSYS_NO_PATHCONV=1` |

### 7.1 Frontera de seguridad

Las credenciales del entorno local están documentadas como **riesgo aceptado** (S1 en `remediacion.md`): son de una red LAN privada, sin entropía y no alcanzables desde internet.

**Esa aceptación NO se extiende a este despliegue.** Neon y Render generan credenciales propias de alta entropía, expuestas a internet, y esas:

- ❌ **nunca** se commitean;
- ✅ viven solo en el panel de variables de entorno de Render;
- ✅ se generan desde el proveedor, no se eligen a mano.

La frontera está en el borde de internet: lo de adentro de la LAN se aceptó con fundamento; lo que sale a la red pública, no.

---

## ⬜ Pendiente de verificar

Nada de esta sección está comprobado. Se irá moviendo a las secciones de arriba **con su evidencia** a medida que se ejecute.

| # | Paso | Depende de |
|---|---|---|
| ~~1~~ | ~~Re-exportar el dump y verificar que las `OWNER TO` desaparecieron~~ | ✅ Hecho 2026-07-27 → §6 |
| ~~2~~ | ~~Confirmar que el dump contiene el fix de V1~~ | ✅ Hecho 2026-07-27 → §6.5 |
| 3 | Instalar el CLI de Neon y autenticar con API key | 🔑 API key generada por el usuario |
| 4 | Crear el proyecto Neon y la base `ecommerce_db` | 3 |
| 5 | Cargar el dump por la ruta de §6.6 y comparar los 8 indicadores estructurales + filas contra la base local | 4 |
| 6 | Confirmar que las 49 rutinas y las 2 vistas materializadas sobrevivieron a la carga | 5 |
| 7 | Desplegar en Render desde el `Dockerfile`, con las 5 variables `DB_*` + `DB_SSL=true` | 5 |
| 8 | Confirmar si Render usa el `HEALTHCHECK` del Dockerfile o el suyo propio | 7 |
| 9 | Verificar el arranque en frío: primera petición tras >5 min de inactividad | 7 |
| 10 | Verificar que un error de cliente ocioso **ya no** tumba el servidor (la corrección de H1 en condiciones reales) | 9 |

**Único desbloqueo externo pendiente**: la API key de Neon (paso 3). Todo lo anterior está hecho y verificado.

---

## Bitácora de verificación

| Fecha | Qué se verificó | Cómo |
|---|---|---|
| 2026-07-27 | H1 resuelto: TLS condicional, timeout y handler de error | `tsc --noEmit`, `npm run build`, conexión real con y sin `DB_SSL` |
| 2026-07-27 | El adaptador de Astro respeta `PORT` en runtime | Lectura de `node_modules/@astrojs/node/dist/standalone.js:15-16` |
| 2026-07-27 | Tooling de Neon: CLI, MCP, auth headless, `neon psql` embebido | Documentación oficial de Neon |
| 2026-07-27 | Límites del plan Free | FAQ oficial de Neon (se descartaron fuentes de terceros contradictorias) |
| 2026-07-27 | Inventario local: sin `psql`/`pg_dump`/`neonctl` en el host; PostgreSQL 16.11 en el contenedor | Ejecución directa de comandos |
| 2026-07-27 | Puerto 5501 sin servicio; instalación nativa inexistente | `Get-NetTCPConnection`, `Get-Service` |
| 2026-07-27 | Composición del dump: 157 KB, plano, 78 `OWNER TO`, `WIN1252`, sin extensiones/roles/grants | Análisis de `database/backup_bd_real.sql` |
| 2026-07-27 | El dump viejo **no** tenía el fix de V1 (las 3 coincidencias eran la definición del propio procedimiento) | Búsqueda acotada al cuerpo de `sp_procesar_pago` |
| 2026-07-27 | Re-export con `--no-owner --no-privileges --encoding=UTF8`: 0 `OWNER TO`, `UTF8`, fix de V1 presente | `docker exec ecommerce_db pg_dump`, exit 0, stderr vacío |
| 2026-07-27 | `\restrict`/`\unrestrict` son nuevos en el dump (2 vs 0) y provienen de PostgreSQL 16.10 | Comparación de dumps + release notes oficiales |
| 2026-07-27 | El dump restaura limpio y produce una base **idéntica** a la viva: 8 indicadores estructurales + filas de las 13 tablas + acentos | Restauración real en contenedor `postgres:16-alpine` descartable |
| 2026-07-27 | El contenedor tiene salida a internet (necesario para cargar Neon desde él) | DNS `neon.tech` → `104.18.23.51`; `nc -z neon.tech 443` OK |
| 2026-07-27 | `exportar_bd.ps1` reescrito: falla limpio sin pisar el dump previo, y su salida restaura idéntica a la base viva | Ejecución con contenedor inexistente (`exit 1`, hash intacto) + ejecución normal + restauración en contenedor descartable |
