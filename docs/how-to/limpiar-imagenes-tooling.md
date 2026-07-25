# Cómo limpiar las imágenes Docker del tooling de auditoría

> El tooling de auditoría corre en Docker (ver [ADR 0007](../adr/0007-tooling-en-docker-versionado.md)). Esas imágenes quedan cacheadas en tu disco (~2.86 GB en total). Esta guía explica cómo borrarlas **sin tocar las de otros proyectos**.

## El problema

Docker guarda las imágenes de forma **global al daemon**, no por proyecto. `docker images` no te dice qué proyecto usa cada una — las imágenes sueltas no llevan label de proyecto. Por eso:

- ❌ `docker system prune -a` → borra también imágenes de **otros** proyectos. No lo uses a ciegas.
- ❌ `docker image prune` → solo borra las "dangling" (sin tag). Estas tienen tag, así que no las toca.
- ✅ La lista exacta de las imágenes de esta auditoría está versionada en el script de limpieza.

## Las imágenes (referencia)

| Imagen | Tamaño | Para qué |
|--------|--------|----------|
| `semgrep/semgrep` | ~1.53 GB | SAST / SQL injection |
| `audit-ast-grep` | ~434 MB | mapeo endpoint→SQL (construida acá) |
| `cytopia/ansible-lint` | ~411 MB | lint de playbooks |
| `k1low/tbls` | ~306 MB | reference de la BD |
| `ghcr.io/gitleaks/gitleaks` | ~77 MB | scan de secretos |
| `hadolint/hadolint` | ~67 MB | lint del Dockerfile |
| `ghcr.io/yannh/kubeconform` | ~37 MB | validación de manifests k8s |

## Cómo hacerlo

### 1. Ver qué hay (no borra nada)

```bash
bash audit/tools/limpiar-imagenes.sh
```

Lista cada imagen con su tamaño y marca si está `presente` o `ausente`.

### 2. Borrarlas

```bash
bash audit/tools/limpiar-imagenes.sh --borrar
```

Borra solo las imágenes de la lista. Las que no estén, las saltea.

## Después

No se pierde nada: cuando vuelvas a necesitar una herramienta, se descarga o reconstruye sola con el comando de [`audit/HERRAMIENTAS.md`](../../audit/HERRAMIENTAS.md). La única imagen que se **reconstruye** (no se descarga) es `audit-ast-grep`:

```bash
docker build -f audit/tools/ast-grep.Dockerfile -t audit-ast-grep .
```
