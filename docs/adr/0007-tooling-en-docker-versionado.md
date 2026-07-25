# ADR 0007 — Todo el tooling de auditoría corre en Docker versionado, sin binarios globales

- **Estado**: Aceptado
- **Fecha**: 2026-07-24

## Contexto

La auditoría usa varias herramientas externas: `tbls` (reference de BD), `ast-grep` (mapeo endpoint→SQL), y una pasada de verificación con `gitleaks`, `semgrep`, `hadolint`, `kubeconform` y `ansible-lint`. Cada una podía instalarse de dos formas: **binario/paquete global** en la máquina, o **contenedor Docker**.

Los ADR 0003 (tbls) y 0004 (ast-grep) ya habían resuelto ese fork caso por caso. Este ADR **eleva ese criterio a doctrina** para todo el tooling, para no volver a decidirlo cada vez.

## Decisión

**Toda herramienta de auditoría corre como contenedor Docker con imagen/versión explícita, nunca como binario global.** Lo que se versiona en el repo es la **declaración** (imagen + versión + comando), no el binario:

- `tbls` → imagen `k1low/tbls` (config en `audit/tools/.tbls.yml`).
- `ast-grep` → `audit/tools/ast-grep.Dockerfile` (`@ast-grep/cli@0.45.0`).
- `gitleaks` → `ghcr.io/gitleaks/gitleaks`.
- `semgrep` → `semgrep/semgrep` (reglas `p/typescript`, `p/security-audit`, `p/owasp-top-ten`).
- `hadolint` → `hadolint/hadolint`.
- `kubeconform` → `ghcr.io/yannh/kubeconform`.
- `ansible-lint` → `cytopia/ansible-lint`.

El catálogo completo con comandos y resultados vive en [`audit/HERRAMIENTAS.md`](../../audit/HERRAMIENTAS.md) (insumo). Los ADR documentan solo las **decisiones**, no el catálogo.

## Alternativas consideradas

- **Binarios globales**: contaminan la máquina, difíciles de fijar por proyecto, no reproducibles entre equipos. Rechazada.
- **Herramientas como devDependencies de la app**: ya falló con `ast-grep` (incompatibilidad musl/glibc en Alpine, ver ADR 0004) y además mezcla tooling de auditoría con dependencias de runtime. Rechazada.

## Consecuencias

- ✅ Reproducible y portable: cualquiera con Docker corre la misma versión.
- ✅ La máquina queda limpia; el repo solo guarda declaraciones, no binarios.
- ✅ Cada herramienta queda citable (imagen + versión) para el informe.
- ⚠️ Requiere Docker y, en Windows/Git Bash, `MSYS_NO_PATHCONV=1` para los `-v` (montajes de volumen).
- ⚠️ El cwd importa: algunas herramientas resuelven config relativa al directorio de ejecución (ver `tbls` `docPath` en ADR 0003 y el `roles_path` de Ansible en `remediacion.md` A4). Se documenta el cwd correcto en cada comando.

## Lección registrada

La pasada de verificación (2026-07-24) demostró el valor del enfoque **y** del rigor de cruzar fuentes: `ansible-lint` corrido desde el cwd equivocado dio un **falso positivo** ("roles not found") que se desmintió leyendo `ansible.cfg` y re-ejecutando desde `ansible/`. Una herramienta es insumo, no veredicto: su salida siempre se interpreta contra la fuente real.
