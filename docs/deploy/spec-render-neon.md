# Despliegue a hosting gestionado — Render (app) + Neon (PostgreSQL)

> **Qué es este documento.** El conocimiento que **no vive en ninguna otra parte del repositorio**: por qué se eligió esta arquitectura, qué trampas tiene, y qué falta ejecutar.
>
> **Qué NO es.** No es un registro de cifras ni de resultados de comandos. Cada dato verificable se acompaña del **comando que lo produce**, no de su resultado transcripto — un resultado transcripto envejece, un comando no.
>
> **Los issues viven en [GitHub Issues](https://github.com/ITZAN44/Ecommerce-Proyecto-BD/issues)**, no acá.

---

## 1. Arquitectura objetivo

```
Internet
   │
   ├─→ Render (Web Service, Docker)  ── app Astro SSR, Node standalone
   │        │
   │        └── conexión TLS (sslmode=require)
   │                    │
   └────────────────────┴─→ Neon (PostgreSQL gestionado, serverless)
```

**Decisión**: hosting gestionado en lugar de la vía K3s/Jenkins/Ansible que ya existe en el repo.

Los issues de infraestructura de Kubernetes, Jenkins y Ansible **no bloquean este despliegue**: Render no usa ninguna de esas piezas. Siguen abiertos para la vía K3s.

---

## 2. Precondiciones — resueltas

| Precondición | Issue | Estado |
|---|---|---|
| El pool de PostgreSQL soporta TLS, arranque en frío y errores de conexión ociosa | [#17](https://github.com/ITZAN44/Ecommerce-Proyecto-BD/issues/17) | ✅ Cerrado |
| El dump es cargable en una base gestionada y refleja la base viva | [#18](https://github.com/ITZAN44/Ecommerce-Proyecto-BD/issues/18) | ✅ Cerrado |
| Sin datos personales en el dump que se sube a la nube | [#13](https://github.com/ITZAN44/Ecommerce-Proyecto-BD/issues/13) | ✅ Cerrado |

**Bloqueante vigente**: ninguno. La base ya está cargada y verificada en Neon (§5); lo que resta es la parte de Render.

### Variables de entorno que introdujo el fix del pool

Las tres son **opcionales**: sin definirlas, el entorno local con Docker funciona igual que antes. Su documentación autoritativa son los comentarios de `src/lib/db.ts`.

| Variable | En Render |
|---|---|
| `DB_SSL` | **`true`** — obligatoria. Sin TLS la conexión a Neon no se establece. |
| `DB_SSL_REJECT_UNAUTHORIZED` | Sin definir. Solo `false` ante certificados autofirmados. |
| `DB_CONNECTION_TIMEOUT_MS` | Sin definir (el valor por defecto ya cubre el arranque en frío). |

> **El proyecto usa variables `DB_*` discretas, no `DATABASE_URL`.** Consecuencia práctica: **el connection string de Neon no se pega entero** — hay que descomponerlo en host, puerto, base, usuario y password.

---

## 3. Compatibilidad con Render

Render inyecta su propia variable `PORT`. La pregunta que decide si esto funciona es si la app la respeta — y la respuesta está en el adaptador instalado, no en la documentación:

```bash
rg "process.env.PORT" node_modules/@astrojs/node/dist/standalone.js
```

El adaptador lee `PORT` y `HOST` del entorno **en runtime**. El `ENV PORT` del `Dockerfile` es solo un valor por defecto que Render sobrescribe. **La app se adapta sin cambios.**

Verificable en el repo:

```bash
rg "output|adapter" astro.config.mjs      # server + node standalone
rg "USER|CMD|HEALTHCHECK" Dockerfile      # no-root, entry.mjs, healthcheck
```

---

## 4. Neon: decisiones de plataforma

**Se usa el CLI (`neonctl`), no el servidor MCP.** El CLI es determinista, cada acción queda en el log del shell, y Neon desaconseja explícitamente el MCP en producción. El MCP añade una capa de interpretación en lengua natural que acá no aporta y complica reproducir lo hecho.

**Autenticación sin navegador** — precedencia: `--api-key` → `NEON_API_KEY` → `credentials.json` → OAuth interactivo. Las dos primeras permiten operar de forma no interactiva.

**`neon psql` no requiere PostgreSQL instalado**: usa el `psql` nativo del `PATH` si existe, y si no cae a una implementación TypeScript embebida. Importa porque en esta máquina **no hay `psql` ni `pg_dump` en el host** — solo dentro del contenedor.

```bash
node --version                        # el CLI requiere >= 18
docker exec ecommerce_db psql --version
psql --version                        # se espera que falle: no está en el host
```

### El proyecto creado

La única coordenada que hace falta recordar es el **project id**; todo lo demás se le pregunta a Neon, que es su dueño:

```bash
PID=delicate-silence-40789773
neonctl projects get   "$PID"                     # id, nombre, región (ojo: posicional, NO --project-id)
neonctl branches list  --project-id "$PID"        # rama por defecto
neonctl databases list --project-id "$PID"        # bases y su owner
neonctl connection-string main --project-id "$PID" --database-name ecommerce_db --role-name neondb_owner
```

> ⚠️ El último comando **imprime el password**. Nunca redirigirlo a un archivo del repo ni pegar su salida en un documento o un issue. Para usarlo en un script: capturarlo en una variable y no volver a imprimirlo.

Se eligió la región del proyecto **igual a la región donde correrá Render**: cada query de una página SSR cruzaría el continente si no coinciden.

Se eligió el **PostgreSQL 16** de Neon para igualar el `server_version` de la base local (comprobable con `docker exec ecommerce_db psql -U postgres -tAc "SELECT current_setting('server_version')"`). No es obligatorio, pero elimina de entrada una clase entera de incompatibilidades entre lo que genera `pg_dump` y lo que acepta el destino.

**Plan Free**: el límite relevante es el scale-to-zero **a los 5 minutos de inactividad, no desactivable**. Esa es la razón de fondo de dos de los tres arreglos del pool ([#17](https://github.com/ITZAN44/Ecommerce-Proyecto-BD/issues/17)): el timeout corto no alcanzaba para despertar la base, y el handler de error convertía un cierre de conexión ociosa rutinario en la caída del servidor. Los límites de storage y transferencia sobran para el tamaño de este dump — consultar el [FAQ oficial](https://neon.com/docs/introduction/plans) antes de asumir cifras.

---

## 5. El dump

El export se hace con **`exportar_bd.ps1`**, que corre `pg_dump` dentro del contenedor y verifica el resultado antes de reemplazar el archivo anterior:

```powershell
.\exportar_bd.ps1
```

El porqué de cada flag obligatorio (`--no-owner`, `--no-privileges`, `--encoding=UTF8`) está en el bloque `.SYNOPSIS` del propio script — **ahí y no acá**, porque ahí no puede quedar desactualizado.

Comprobaciones sobre el dump versionado:

```bash
rg -c "OWNER TO" database/backup_bd_real.sql      # esperado: sin coincidencias
rg "client_encoding" database/backup_bd_real.sql  # esperado: UTF8
rg "@gmail.com" database/backup_bd_real.sql       # esperado: sin coincidencias
```

### Validar el dump sin arriesgar el entorno

La inspección del archivo no prueba que cargue. Para eso: restaurarlo en un contenedor **descartable** y comparar contra la base viva.

> ⚠️ **Nunca usar `docker compose down -v` para esto**: ese comando **destruye el volumen de datos** del proyecto. Un contenedor descartable da la misma evidencia sin riesgo.

---

## 6. Gotchas confirmados

Esto es el corazón del documento: lo que **nadie deduce mirando el repo**.

| Gotcha | Mitigación |
|---|---|
| Sin TLS la conexión a Neon **falla**, no degrada | `DB_SSL=true` en Render |
| Scale-to-zero a los 5 min, no desactivable | Timeout amplio y handler de error no letal (ya en `db.ts`) |
| El connection string **no se pega entero** | Descomponerlo en las variables `DB_*` |
| `pg_dump`/carga sobre conexión **pooled** rompe con PgBouncer | Usar el connection string **no-pooled** |
| El dump trae `\restrict` / `\unrestrict` (PostgreSQL 16.10+) | Cargar con un cliente `psql` reciente — ver §7 |
| Esos meta-comandos llevan **clave aleatoria en cada export** | Todo re-export muestra esas 2 líneas como cambiadas en el diff, incluso sin cambios de datos. No es un error |
| El `HEALTHCHECK` del `Dockerfile` tiene el puerto hardcodeado | `SIN VERIFICAR` si Render lo usa o solo su propio chequeo HTTP. Confirmar al desplegar |
| `docker-compose.yml` monta `.:/app` y **sombrea** el `dist/` de la imagen | No aplica en Render (sin bind mount), pero explica diferencias local↔producción |
| Git Bash convierte rutas `/tmp/...` de `docker exec` a rutas Windows | Anteponer `MSYS_NO_PATHCONV=1` |
| El `.env` local define un `DB_PORT` que no coincide con el del contenedor | Remanente de una instalación nativa que ya no existe. En Docker funciona porque compose lo pisa; en el host falla con `ECONNREFUSED` |
| `neonctl projects create --database-name <x>` **se ignora en silencio**: exit 0, sin warning, y la base queda llamándose `neondb` | Crear la base aparte con `neonctl databases create --name … --owner-name …` y **listar** para confirmar. No confiar en el exit code |
| El rol de Neon es `neondb_owner`, no `postgres` | `DB_USER` cambia de valor entre local y producción; es la única variable `DB_*` cuyo nombre no coincide con lo de siempre |

---

## 7. Ruta de carga a Neon

El plan inicial era `neon psql <branch> -- -f dump.sql`. **Quedó descartado como opción principal** por el `\restrict`: no está verificado que la implementación TypeScript embebida entienda ese meta-comando, y un cliente que no lo conozca falla con `invalid command \restrict`.

**Ruta preferida** — el `psql` del contenedor, que es el mismo que generó esas líneas:

```bash
MSYS_NO_PATHCONV=1 docker exec ecommerce_db psql "<connection-string-no-pooled>" -f /tmp/dump.sql
```

El contenedor tiene salida a internet (comprobable con `docker exec ecommerce_db nc -z neon.tech 443`), así que no hace falta instalar nada en el host.

**Ruta alternativa**: `neon psql -- -f dump.sql`. Si se usa, verificar primero que no falle con `invalid command \restrict`.

### Qué hay que comparar para dar la carga por buena

Que `psql` termine con exit 0 y stderr vacío **no prueba que la base destino sea equivalente**. La comparación se corre sobre las dos bases con la misma consulta y se hace `diff` de las salidas. Tiene que cubrir:

- **Estructura**: tablas, columnas, PKs, FKs, checks, uniques, índices, rutinas (`pg_proc`), triggers no internos (`pg_trigger` con `NOT tgisinternal`), secuencias, vistas y vistas materializadas.
- **Los nombres**, no solo los conteos: dos bases pueden tener 49 rutinas y no ser las mismas 49.
- **Filas por tabla.**
- **Vistas materializadas aparte.** Filtrar por `relkind='r'` las deja fuera, y `pg_dump` puede restaurarlas `WITH NO DATA`. Se comprueba con `relispopulated` **y** su conteo de filas.
- **`last_value` de cada secuencia** (`pg_sequences`). Si quedan desfasadas, la carga se ve perfecta y el **primer `INSERT` en producción choca con una PK existente**. Ojo: `pg_sequences` no tiene columna `is_called`.
- **Ausencia de PII**, otra vez, ya en el destino.

---

## 8. Lo que falta ejecutar

| # | Paso | Estado |
|---|---|---|
| 1 | Instalar `neonctl` y autenticar | ✅ hecho — vía `neonctl auth` (OAuth de navegador), sin pegar la API key en ninguna parte |
| 2 | Crear el proyecto Neon y la base | ✅ hecho — ver §4 |
| 3 | Cargar el dump por la ruta de §7 y comparar contra la base local | ✅ hecho — comparación sin diferencias |
| 4 | Desplegar en Render desde el `Dockerfile`, con las variables `DB_*` + `DB_SSL=true` | ⏳ pendiente |
| 5 | Confirmar si Render usa el `HEALTHCHECK` del `Dockerfile` o el suyo | ⏳ depende de 4 |
| 6 | Verificar el arranque en frío: primera petición tras >5 min de inactividad | ⏳ depende de 4 |
| 7 | Verificar que un error de cliente ocioso **ya no** tumba el servidor | ⏳ depende de 6 |

Los pasos 6 y 7 son los que validan el fix del pool ([#17](https://github.com/ITZAN44/Ecommerce-Proyecto-BD/issues/17)) en condiciones reales. Hasta entonces, ese arreglo está verificado en local pero **no en producción**.

Cierra [#11](https://github.com/ITZAN44/Ecommerce-Proyecto-BD/issues/11) cuando exista una URL pública verificada.

---

## 9. Frontera de seguridad

Las credenciales del entorno local son **riesgo aceptado** ([#12](https://github.com/ITZAN44/Ecommerce-Proyecto-BD/issues/12)): LAN privada, sin entropía, no alcanzables desde internet.

**Esa aceptación no se extiende a este despliegue.** Las credenciales de Neon y Render son de alta entropía y están expuestas a internet:

- ❌ **nunca** se commitean;
- ✅ viven solo en el panel de variables de entorno de Render;
- ✅ las genera el proveedor, no se eligen a mano.

La frontera está en el borde de internet: lo de la LAN se aceptó con fundamento; lo que sale a la red pública, no.

---

## Trampas de verificación (para el próximo que audite)

Dos formas de engañarse que ya ocurrieron acá:

**Un conteo agregado no prueba presencia.** Buscar el nombre de una rutina en el dump devolvía coincidencias que parecían confirmar que un fix estaba aplicado. Eran todas la **definición del propio procedimiento**. Al acotar la búsqueda al cuerpo de quien debía invocarla: cero llamadas. Hay que mirar el contexto, no el número.

**Buscar en el working tree no dice nada del historial.** La comprobación de que el dump no lleva PII (`rg "@gmail.com" database/backup_bd_real.sql`) devuelve cero y se siente como prueba de limpieza. Solo prueba el estado presente del archivo. Los datos siguieron siendo legibles en commits ya publicados, en un repositorio público ([#20](https://github.com/ITZAN44/Ecommerce-Proyecto-BD/issues/20)). Al historial hay que preguntarle con su propia herramienta:

```bash
git log --all --oneline -S"<patron>" -- <ruta>            # commits donde el patrón entró o salió
git grep -l "<patron>" $(git rev-list --all) -- <ruta>    # todos los commits cuyo árbol lo contiene
```

**Y una segunda capa de la misma trampa, que ya se cayó acá:** `git grep <patron> origin/main` **tampoco** sirve. Busca en el árbol de *ese commit*, no en el historial. En cuanto el fix de anonimización llegó a `origin/main`, ese comando empezó a devolver cero — igual que la búsqueda en el working tree, y por la misma razón. Solo `git log -S` (o un `git grep` sobre `git rev-list --all`) recorre el pasado.

Fue el primer comando que se escribió como "la forma correcta" en este mismo documento, y estaba mal. Lo delató ejecutarlo (§8.5 de `CLAUDE.md`).

**Anonimizar el presente y eliminar una exposición publicada son dos trabajos distintos**, y el primero no implica el segundo. Un `UPDATE` remedia la base; el historial de git no lo toca nadie salvo una reescritura explícita.

**`pg_stat_ssl` miente en Neon.** Consultarlo desde una sesión conectada a Neon devuelve `ssl = false` **aunque TLS esté activo y sea obligatorio**: el proxy de Neon termina TLS antes de llegar a Postgres, así que el backend no lo ve. Concluir "no hay cifrado" desde ese dato sería falso. La prueba válida es negativa — intentar conectar con `sslmode=disable` y comprobar que el servidor **rechaza**:

```bash
# esperado: ERROR: connection is insecure (try using `sslmode=require`)
```

Es la diferencia entre preguntarle al lugar equivocado y forzar al sistema a demostrar el comportamiento.

**Un exit code 0 no es una verificación.** La carga del dump terminó con exit 0 y stderr vacío, y eso solo dice que ninguna sentencia falló. No dice que la base destino sea equivalente: ver la lista de §7.

**Contar filas antes de un `UPDATE` masivo.** Un `WHERE` que parecía correcto dejaba fuera las filas de tipo `INSERT` (columna en `NULL`). Se detectó porque el conteo previo no coincidía con lo esperado. El conteo previo no es ceremonia: es el test.
