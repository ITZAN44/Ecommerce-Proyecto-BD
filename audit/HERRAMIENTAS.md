# Herramientas de auditoría — stack elegido

> Solo las que **vamos a usar de verdad**, no el catálogo completo. Son **insumo** para navegar y verificar el proyecto al 100% (no entregable). La doc final Diátaxis se escribe aparte, sobre los hechos que estas herramientas confirmen.
>
> Conexión BD de referencia: `postgres://postgres:12345678@localhost:5432/ecommerce_db` (contenedor `ecommerce_db`).

---

## Núcleo — se usan ya (Capas 1 y 2)

### 1. Introspección `psql` directa — *(ya en uso, sin instalar)*
- **Qué hace:** consulta la base viva (`information_schema` / `pg_catalog`). Es la **fuente de verdad** del esquema; tbls y SchemaSpy por debajo hacen esto mismo.
- **Cómo la usamos:**
  - Columnas/tipos/PKs: `docker exec ecommerce_db psql -U postgres -d ecommerce_db -c "\d+ nombre_tabla"`
  - Definición real de una función: `... -c "SELECT pg_get_functiondef('nombre'::regproc);"`
  - Definición de vistas: `... -c "\d+ vw_timeline_pedidos"`
- **Produce:** hechos crudos verificados (columnas, firmas, cuerpos de funciones).
- **Capa:** 1 (BD).

### 2. tbls — *(vía Docker, imagen oficial `k1low/tbls` — SIN binario global)*
- **Qué hace:** documenta la BD viva a **Markdown + diagrama ER** (mermaid embebido) automáticamente: columnas, constraints, índices, triggers y relaciones. **Lista** funciones/procedimientos en el índice con su firma (retorno + argumentos), pero **NO** su cuerpo/lógica (eso lo saca la introspección `psql`). Regenerable en CI.
- **Cómo la usamos** (config en `audit/tools/.tbls.yml`, salida a `docs/reference/database/`, correr desde la raíz):
  - `docker run --rm --network ecommers-proyecto_default -v "$PWD:/work" -w /work k1low/tbls doc -c audit/tools/.tbls.yml --force`
  - `... k1low/tbls lint -c audit/tools/.tbls.yml` (detecta tablas/columnas sin comentario)
- **Produce:** un `.md` + `.svg` por tabla/vista + ER completo → la Reference de Diátaxis directamente.
- **Capa:** 1 (BD). **Mayor ROI del stack.**

### 3. ast-grep — *(vía Dockerfile de tooling versionado — SIN binario global)*
- **Qué hace:** búsqueda **estructural** (por AST, no por texto). Ideal para lo que ningún tool de esquema resuelve: el mapeo **endpoint → SQL**.
- **Dónde vive:** declarada en `audit/tools/ast-grep.Dockerfile` (`@ast-grep/cli@0.45.0` sobre `node:20-slim`). Versionada y visible en el repo; el binario no se comitea.
  - ⚠️ No se instaló como devDependency de la app: el contenedor `ecommerce_app` es Alpine (musl) y `@ast-grep/cli` solo publica binarios Linux glibc (`-gnu`). Corre sobre Debian glibc, aislado.
- **Cómo la usamos:**
  - Construir (una vez): `docker build -f audit/tools/ast-grep.Dockerfile -t audit-ast-grep .`
  - Correr: `MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD:/work" -w /work audit-ast-grep run -p 'query($$$)' -l ts src/pages/api`
- **Produce:** el grafo cross-capa (qué endpoint toca qué tabla/función).
- **Verificación cruzada:** `query($$$)` → 68 matches en `src/pages/api`, coincide con el conteo previo independiente.
- **Capa:** 2 (App).

### 4. `astro check` — *(nativo, vía contenedor o npx)*
- **Qué hace:** diagnóstico oficial de Astro (tipos, imports rotos, errores de `.astro`).
- **Cómo la usamos:** `docker exec ecommerce_app npx astro check`
- **Produce:** validación de que la app está sana y sin tipos rotos.
- **Capa:** 2 (App).

---

## Por capa — ✅ ejecutadas en la pasada de verificación (2026-07-24)

> Todas vía Docker (imagen oficial), sin binario global — misma doctrina que tbls/ast-grep.

### 5. gitleaks — *(seguridad; `ghcr.io/gitleaks/gitleaks`)*
- **Qué hace:** barre secretos comiteados por patrón + entropía.
- **Cómo la usamos:** `docker run --rm -v "$PWD:/repo" ghcr.io/gitleaks/gitleaks detect --source /repo --no-git` (working tree) y sin `--no-git` (historial, 18 commits).
- **✅ Resultado (2026-07-24):** `no leaks found` en working tree **y** en el historial. **Matiz clave**: gitleaks apunta a tokens/API keys de alta entropía; **NO** detecta las contraseñas de config de baja entropía de S1 (`12345678`, `ecommerce_secure_2024`). Por eso **no confirma S1** (que se verificó leyendo), pero **sí asegura** que no hay tokens/keys de alta entropía filtrados. Refina S1: la exposición se limita a credenciales dev/infra de baja entropía.

### 6. Semgrep — *(seguridad; `semgrep/semgrep`, reglas `p/typescript` + `p/security-audit` + `p/owasp-top-ten`)*
- **Qué hace:** SAST. Caza **SQL injection** en las queries `pg` y malas prácticas.
- **Cómo la usamos:** `docker run --rm -v "$PWD:/src" -w /src semgrep/semgrep semgrep scan --config p/typescript --config p/security-audit --config p/owasp-top-ten src/`
- **✅ Resultado (2026-07-24):** 94 reglas sobre 50 archivos → **0 hallazgos**. Confirma que la parametrización `pg` (`$1`, `$2` vía `query(text, params)`) está bien usada: no hay concatenación de input en SQL → **sin SQL injection detectado**. (Reglas community; no exhaustivo, pero es una segunda fuente sólida.)

### 7. hadolint / kubeconform / ansible-lint — *(validación DevOps)*
- **hadolint** (`Dockerfile`): `docker run --rm -i hadolint/hadolint hadolint - < Dockerfile` → **✅ limpio, 0 observaciones**.
- **kubeconform** (`k8s/`): `docker run --rm -v "$PWD:/work" -w /work ghcr.io/yannh/kubeconform -summary -ignore-missing-schemas k8s/` → **✅ 10/11 recursos válidos** contra el esquema k8s. El único "error" es `prometheus-values.yaml` (*missing kind*): es un archivo de **valores Helm**, no un manifest → falso positivo esperable.
- **ansible-lint** (`ansible/`): correr **desde `ansible/`** (para que tome `ansible.cfg` con `roles_path = ./roles`): `docker run --rm -v "$PWD/ansible:/data" -w /data cytopia/ansible-lint playbooks/deploy-all.yml`.
  - ⚠️ Correrlo **desde la raíz da un falso positivo** ("role 'docker'/'k3s'/'nginx' not found") porque no aplica el `ansible.cfg`. Verificado: desde `ansible/` los roles resuelven bien.
  - **✅ Resultado real (2026-07-24):** 0 errores funcionales/sintaxis; solo **estilo** (48 trailing-spaces, 28 acciones sin FQCN, 2 `truthy` `yes/no`, 1 line-length). Baja severidad.
- **Capa:** 3 (DevOps).

---

## Descartadas (y por qué)
- **SchemaSpy** — potente, pero salida HTML; tbls da Markdown que encaja mejor con Diátaxis.
- **Knip / dependency-cruiser / madge** — son para *limpiar* código muerto, no para *auditar cómo está hecho*. Van en una fase de limpieza posterior, si se hace.
