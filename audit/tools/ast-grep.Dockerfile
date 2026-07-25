# Herramienta de auditoría: ast-grep (búsqueda estructural por AST)
# ---------------------------------------------------------------------------
# Por qué este archivo existe:
#   ast-grep NO se versiona como binario en el repo (los binarios nunca van al
#   repo). Lo que SÍ se versiona es ESTA declaración: qué herramienta y qué
#   versión exacta usamos. `docker build` produce siempre lo mismo -> reproducible.
#
# Por qué no como devDependency de la app:
#   el contenedor de la app (ecommerce_app) es Alpine (musl) y @ast-grep/cli
#   solo publica binarios Linux glibc (-gnu). Por eso corre sobre node:20-slim
#   (Debian, glibc), aislado del runtime de la app.
#
# Construir (una sola vez):
#   docker build -f audit/tools/ast-grep.Dockerfile -t audit-ast-grep .
#
# Usar (sobre el código del repo, solo lectura):
#   docker run --rm -v "$PWD:/work" -w /work audit-ast-grep run -p 'PATRON' -l ts src/pages/api
#   docker run --rm -v "$PWD:/work" -w /work audit-ast-grep --version
# ---------------------------------------------------------------------------
FROM node:20-slim

# Versión FIJADA para reproducibilidad (verificada: existe binario linux-x64-gnu).
RUN npm install -g @ast-grep/cli@0.45.0

# 'ast-grep' es el binario; también expone el alias 'sg'.
ENTRYPOINT ["ast-grep"]
