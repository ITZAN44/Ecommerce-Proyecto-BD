# ADR 0003 — `tbls` vía Docker para la reference estructural de la BD

- **Estado**: Aceptado
- **Fecha**: 2026-07-24

## Contexto

Necesitábamos generar la **reference estructural** de la base (tablas, columnas, tipos, PKs, constraints, índices, triggers y diagrama ER) de forma reproducible y sin calcarla a mano (ver ADR 0002). La herramienta elegida fue [`tbls`](https://github.com/k1LoW/tbls), que introspecciona una base viva y emite Markdown.

La pregunta era **cómo instalarla**: binario global en la máquina, o contenedor.

## Decisión

Correr `tbls` como **contenedor Docker** (imagen oficial `k1low/tbls`), **no** como binario global. La configuración vive versionada en [`audit/tools/.tbls.yml`](../../audit/tools/.tbls.yml).

Comando (la base debe estar levantada; se corre desde la raíz del repo):

```bash
docker run --rm --network ecommers-proyecto_default -v "$PWD:/work" -w /work k1low/tbls doc -c audit/tools/.tbls.yml --force
```

Config clave (verificada en `.tbls.yml`): `docPath: docs/reference/database`, diagramas ER embebidos como **mermaid** (sin `.svg` sueltos), DSN contra `ecommerce_db` en la red de compose.

## Alternativas consideradas

- **Binario global** (`go install` / release): contamina la máquina, difícil de fijar versión por proyecto, no reproducible entre máquinas. Rechazada.
- **Escribir la reference a mano**: viola el single-source-of-truth del ADR 0002. Rechazada.
- **ER como `.svg`**: genera archivos binarios sueltos; mermaid se embebe en el `.md` y GitHub lo renderiza nativo. Se eligió mermaid.

## Consecuencias

- ✅ Reproducible: cualquiera con Docker regenera la reference idéntica.
- ✅ Sin ensuciar la máquina con binarios globales.
- ✅ La versión/imagen queda citable en este ADR.
- ⚠️ Requiere Docker y la base en la red `ecommers-proyecto_default`.
- ⚠️ `docPath` se resuelve **relativo al cwd** (la raíz), no al `.tbls.yml`; por eso hay que correr desde la raíz y pasar `-c audit/tools/.tbls.yml`. Documentado en el propio `.tbls.yml`.
