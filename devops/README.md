# 📚 DevOps — Índice de Informes

Este directorio contiene los informes paso a paso del flujo DevOps aplicado al proyecto.

## ✅ Pasos completados

- [PASO_01_DOCKER_CONTAINERIZACION.md](PASO_01_DOCKER_CONTAINERIZACION.md)
- [PASO_02_NGINX_REVERSE_PROXY.md](PASO_02_NGINX_REVERSE_PROXY.md)
- [PASO_03_KUBERNETES_K3S.md](PASO_03_KUBERNETES_K3S.md)
- [PASO_04_CI_CD_JENKINS.md](PASO_04_CI_CD_JENKINS.md)

## 🚀 Comandos rápidos (VM)

### Docker (Paso 01)
- `docker compose -f docker-compose.production.yml up -d`
- `docker ps`

### Nginx (Paso 02)
- `sudo systemctl status nginx`
- `sudo nginx -t && sudo systemctl reload nginx`

### Kubernetes/K3s (Paso 03)
- `sudo systemctl status k3s`
- `sudo k3s kubectl get nodes`
- `sudo k3s kubectl get all -n ecommerce`

### Jenkins CI/CD (Paso 04)
- `docker compose -f docker-compose.jenkins.yml up -d`
- `docker logs jenkins_server -f`
- Jenkins UI: `http://192.168.0.119:8080`
- `kubectl rollout history deployment/ecommerce-app -n ecommerce`

## 🧭 Siguiente paso sugerido

- Paso 05: Monitoreo con Prometheus + Grafana
- Paso 06: Logs centralizados con ELK Stack o Loki
