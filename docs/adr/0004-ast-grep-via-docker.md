# ADR 0004 — `ast-grep` vía Docker para el mapeo endpoint → SQL

- **Estado**: Aceptado
- **Fecha**: 2026-07-24

## Contexto

Para el mapeo **endpoint → SQL** (Capa 2) no bastaba una búsqueda de texto: un `grep` sobre strings había hecho *aparecer* datos engañosos antes (ver la lección de `n_live_tup` en ADR 0001). Necesitábamos búsqueda **estructural por AST** para ubicar con precisión llamadas como `query(...)`, `CALL sp_*`, `fn_*()`. La herramienta elegida fue [`ast-grep`](https://ast-grep.github.io/).

Primero se intentó instalarla como **devDependency** de la app (`@ast-grep/cli`). **Falló**: el `postinstall` no encontraba el binario nativo. Diagnóstico verificado: el contenedor de la app es **Alpine (musl)** y `@ast-grep/cli` solo publica binarios Linux **glibc (`-gnu`)** — no hay build musl.

## Decisión

Correr `ast-grep` como **contenedor Docker** sobre `node:20-slim` (Debian, **glibc**), aislado del runtime Alpine de la app. La declaración vive versionada y con versión fijada en [`audit/tools/ast-grep.Dockerfile`](../../audit/tools/ast-grep.Dockerfile) (`@ast-grep/cli@0.45.0`).

```bash
# construir (una vez)
docker build -f audit/tools/ast-grep.Dockerfile -t audit-ast-grep .
# usar (solo lectura sobre el repo)
docker run --rm -v "$PWD:/work" -w /work audit-ast-grep run -p 'PATRON' -l ts src/pages/api
```

## Alternativas consideradas

- **devDependency `@ast-grep/cli`**: era la opción inicial recomendada. **Rechazada tras evidencia**: incompatibilidad musl/glibc en Alpine. Se corrigió el rumbo con la prueba en mano.
- **Solo `ripgrep` / búsqueda de texto**: insuficiente y ya había demostrado producir falsos hallazgos. El usuario lo rechazó explícitamente por falta de rigor. Rechazada.
- **Binario global en la máquina**: no reproducible ni fijado por proyecto (mismo criterio que ADR 0003). Rechazada.

## Consecuencias

- ✅ Búsqueda estructural real, no textual → el mapeo endpoint→SQL es confiable (cruce `query()` → 68 coincidencias, consistente con el conteo independiente).
- ✅ Versión fijada y reproducible; no deja binarios en el repo (solo la declaración).
- ✅ Aislado del runtime de la app (no toca sus dependencias).
- ⚠️ Requiere `docker build` una vez antes de usar.
- 📌 Lección registrada: **verificar la plataforma del binario (musl vs glibc) antes de recomendar una instalación**.
