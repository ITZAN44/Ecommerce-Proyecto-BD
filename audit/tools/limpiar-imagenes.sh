#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Limpieza de las imágenes Docker del tooling de auditoría.
#
# Por qué existe este script:
#   Docker guarda las imágenes de forma GLOBAL al daemon, no por proyecto.
#   `docker images` no dice qué proyecto usa cada imagen (no hay label de
#   proyecto en imágenes sueltas). Por eso mantenemos ACÁ la lista exacta de
#   las imágenes que esta auditoría descargó/construyó, para poder borrarlas
#   sin tocar las de otros proyectos.
#
#   NO usar `docker system prune -a` a ciegas: borraría imágenes ajenas.
#   `docker image prune` no las toca (tienen tag, no son "dangling").
#
# Uso:
#   bash audit/tools/limpiar-imagenes.sh          # lista lo que ocupa (dry-run)
#   bash audit/tools/limpiar-imagenes.sh --borrar  # borra las imágenes
# ---------------------------------------------------------------------------
set -euo pipefail

# Imágenes del tooling de auditoría (ver audit/HERRAMIENTAS.md y docs/adr/0007).
IMAGENES=(
  "audit-ast-grep"                    # construida acá — mapeo endpoint→SQL (ADR 0004)
  "k1low/tbls"                        # reference estructural de la BD (ADR 0003)
  "ghcr.io/gitleaks/gitleaks"        # scan de secretos (Capa seguridad)
  "semgrep/semgrep"                  # SAST / SQL injection (Capa seguridad) — la más pesada (~1.5 GB)
  "hadolint/hadolint"                # lint del Dockerfile (Capa DevOps)
  "ghcr.io/yannh/kubeconform"        # validación de manifests k8s (Capa DevOps)
  "cytopia/ansible-lint"             # lint de playbooks Ansible (Capa DevOps)
)

BORRAR="${1:-}"

echo "== Imágenes del tooling de auditoría =="
for img in "${IMAGENES[@]}"; do
  # Muestra repo:tag y tamaño si la imagen existe localmente.
  linea=$(docker images --format '{{.Repository}}:{{.Tag}}\t{{.Size}}' | grep -E "^${img}:" || true)
  if [ -n "$linea" ]; then
    echo "  presente : $linea"
  else
    echo "  ausente  : $img (no está descargada)"
  fi
done

if [ "$BORRAR" != "--borrar" ]; then
  echo ""
  echo "Dry-run. Para borrarlas de verdad:  bash audit/tools/limpiar-imagenes.sh --borrar"
  exit 0
fi

echo ""
echo "== Borrando =="
for img in "${IMAGENES[@]}"; do
  if docker image inspect "$img" >/dev/null 2>&1; then
    docker image rm "$img" && echo "  borrada: $img"
  else
    echo "  saltada: $img (no estaba)"
  fi
done
echo "Listo. Se pueden volver a descargar/construir cuando se necesiten (ver audit/HERRAMIENTAS.md)."
