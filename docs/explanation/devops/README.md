# DevOps — explicación

> Dominio: la capa de **infraestructura y despliegue** del ecommerce.
> Verificado leyendo los archivos reales (`Dockerfile`, `docker-compose*.yml`, `Jenkinsfile`, `k8s/`, `ansible/`), no la doc existente. Fecha: 2026-07-23.

## Documentos

| Documento | Contenido |
|-----------|-----------|
| [`arquitectura.md`](./arquitectura.md) | La arquitectura DevOps real: Docker, Jenkins, K3s, Ansible y el flujo de despliegue. |
| [`validacion-doc-existente.md`](./validacion-doc-existente.md) | Veredicto de confiabilidad de la doc DevOps previa (`devops.md/`): qué es fiel y qué no. |

## Resumen del stack (verificado)

- **Docker** — Dockerfile multi-stage (build + producción), 3 archivos compose.
- **Jenkins** — pipeline declarativo que construye la imagen y la despliega a K3s.
- **Kubernetes (K3s)** — 11 manifests: app (2 réplicas), PostgreSQL (1 réplica + PVC), ingress Traefik, monitoreo Prometheus/Grafana.
- **Ansible** — IaC: 7 playbooks + 4 roles (docker, nginx, k3s, jenkins) para levantar todo desde cero.

## Confiabilidad de la doc previa

La doc previa (`devops.md/`) es **parcialmente fiel**: los `PASO_0X` operativos coinciden con la realidad; el `ROADMAP_DEVOPS` es material teórico con ejemplos idealizados. Detalle y evidencia en [`validacion-doc-existente.md`](./validacion-doc-existente.md).

## Issues detectados

Los puntos a mejorar de esta capa están en el registro central → [`../../remediacion.md`](../../remediacion.md).
