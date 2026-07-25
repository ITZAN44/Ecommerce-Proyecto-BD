# Flujo DevOps Completo (PASO 1 → PASO 6)

Este documento conecta de forma “end-to-end” todo el flujo DevOps implementado en el proyecto Ecommerce, explicando qué hace cada herramienta y cómo se encadenan entre sí.

Referencias principales (los informes por paso):
- [devops.md/PASO_01_DOCKER_CONTAINERIZACION.md](devops.md/PASO_01_DOCKER_CONTAINERIZACION.md)
- [devops.md/PASO_02_NGINX_REVERSE_PROXY.md](devops.md/PASO_02_NGINX_REVERSE_PROXY.md)
- [devops.md/PASO_03_KUBERNETES_K3S.md](devops.md/PASO_03_KUBERNETES_K3S.md)
- [devops.md/PASO_04_CI_CD_JENKINS.md](devops.md/PASO_04_CI_CD_JENKINS.md)
- [devops.md/PASO_05_IAC_ANSIBLE.md](devops.md/PASO_05_IAC_ANSIBLE.md)
- [devops.md/PASO_06_MONITOREO.md](devops.md/PASO_06_MONITOREO.md)

---

## 1) La idea central: una cadena de “capas”

En un proyecto DevOps real, rara vez se usa una sola herramienta. Lo que ustedes lograron es una cadena donde cada herramienta resuelve un problema específico:

1. Docker (PASO 1) convierte tu app y DB en “unidades empaquetadas” reproducibles.
2. Nginx (PASO 2) ordena el tráfico HTTP y profesionaliza la entrada (reverse proxy).
3. K3s/Kubernetes (PASO 3) reemplaza el despliegue manual por orquestación: réplicas, auto-healing, ingress.
4. Jenkins (PASO 4) automatiza el “ciclo de despliegue”: build → deploy → verificación.
5. Ansible (PASO 5) automatiza el “ciclo de infraestructura”: prepara servidores y deja todo instalado con 1 comando.
6. Prometheus/Grafana (PASO 6) te da observabilidad: ver qué pasa y detectar problemas antes de que exploten.

El resultado final es: Infra reproducible + despliegue automático + operación observable.

---

## 2) Dónde vive cada cosa (mapa mental de artefactos)

- Aplicación y base:
  - Imagen de la app construida con Dockerfile (PASO 1) y usada tanto en Docker como en K3s.
  - PostgreSQL con datos reales (restauración del backup) como parte del flujo (PASO 3).

- Infra Kubernetes:
  - Manifiestos en carpeta k8s/ (namespace, deployments, services, ingress, secrets, PVC).
  - K3s incluye Traefik como Ingress Controller (PASO 3).

- CI/CD:
  - Jenkinsfile define el pipeline (PASO 4): build + import a containerd + rollout + health check.

- IaC:
  - Estructura ansible/ con roles por herramienta (docker/nginx/k3s/jenkins) (PASO 5).

- Observabilidad:
  - Config del stack de monitoreo via Helm values (PASO 6) y dashboards en Grafana.

---

## 3) Flujo de ejecución real: “Hago un cambio y llega a producción”

Este es el flujo que conecta GitHub → Jenkins → K3s:

### 3.1 Commit y disparo del pipeline
- Tu código está versionado en GitHub.
- Jenkins usa Poll SCM (PASO 4) para revisar el repo cada 2 minutos.
- Cuando hay un commit nuevo, Jenkins corre el pipeline automáticamente.

Qué problema resuelve: no dependes de “hacer deploy manual”. El deploy se vuelve un proceso repetible.

### 3.2 Build: de código a imagen Docker
- Jenkins clona el repo.
- Ejecuta docker build usando el Dockerfile.
- Taggea la imagen con el hash corto del commit (ej. abc1234) y también latest.

Qué problema resuelve: cada despliegue queda identificado por versión/commit.

### 3.3 Puente clave: Docker vs Kubernetes (containerd)
En K3s, el runtime real es containerd (no Docker). Por eso el pipeline hace:
- docker save para exportar la imagen a un .tar
- k3s ctr images import para importar esa imagen al containerd de K3s

Qué problema resuelve: hace que Kubernetes pueda ejecutar la imagen que Jenkins construyó.

Nota importante del diseño: Jenkins corre en un contenedor Docker (PASO 4), pero necesita “ver”:
- el socket de Docker (para construir imágenes)
- el socket de containerd de K3s (para importar imágenes)
- kubectl/k3s + kubeconfig (para hablar con el API de Kubernetes)

### 3.4 Deploy: rolling update en Kubernetes
- Jenkins ejecuta kubectl set image en el deployment ecommerce-app.
- Kubernetes hace rolling update: reemplaza pods antiguos por pods nuevos sin bajar todo.
- Jenkins espera el rollout status.

Qué problema resuelve: despliegue sin downtime y con control de estado.

### 3.5 Verificación: health check HTTP
- Jenkins corre un curl a http://localhost/api/analytics/dashboard
- Si responde 200, el deploy se marca como exitoso.

Qué significa “localhost” aquí:
- El pipeline está pensado para que el tráfico HTTP esté disponible en el host (puerto 80).
- En K3s, eso normalmente lo entrega Traefik (Ingress Controller) (PASO 3).

---

## 4) Flujo de entrada HTTP: por qué Nginx fue clave y por qué luego Traefik

### 4.1 PASO 2 (Nginx) — la idea de Reverse Proxy
En Docker “puro” (PASO 1), la app vivía en un puerto no estándar (4321).
Nginx (PASO 2) se colocó delante como puerta de entrada:
- expone el puerto 80
- reenvía a localhost:4321
- agrega gzip, caching de assets, headers, logs, endpoint /health, etc.

Qué problema resuelve: profesionaliza la entrada y centraliza el tráfico.

### 4.2 PASO 3 (K3s) — el reemplazo natural de Nginx en Kubernetes
Cuando migras a Kubernetes, la forma “nativa” de exponer HTTP es Ingress.
K3s trae Traefik listo (PASO 3). Por eso:
- Traefik ocupa el puerto 80 como Ingress Controller
- Nginx se deshabilita para evitar conflicto en el mismo puerto

Qué problema resuelve: en vez de un proxy “del sistema”, tienes un gateway controlado por Kubernetes (Ingress) que entiende servicios/pods.

### 4.3 ¿Y por qué aparece Nginx en Ansible (PASO 5)?
En PASO 5, el rol de Nginx está automatizado y parametrizado.
Se ve una configuración tipo proxy_pass a un backend (por ejemplo un ClusterIP de K3s).

Cómo interpretarlo en el flujo global:
- Nginx fue parte del aprendizaje y de la evolución del stack.
- En el estado final descrito en PASO 3 y PASO 4, el “entrypoint” principal es Traefik en K3s.
- Si en algún momento quisieras volver a usar Nginx como gateway externo, tendrías que evitar el choque de puertos (no es el objetivo de este documento; el flujo final queda con Traefik).

---

## 5) Flujo de datos: PostgreSQL persistente y restauración

En Kubernetes (PASO 3):
- PostgreSQL corre en un deployment/stateful setup con PVC (persistencia).
- La app depende de funciones/procedimientos en la base.

Aprendizaje clave del incidente:
- Los pods de la app estaban “Running” pero no “Ready” porque la DB no tenía el schema/funciones.
- Se solucionó restaurando el backup real.

Qué problema resuelve la persistencia:
- Los datos sobreviven reinicios de pods.
- Lo mismo aplica luego para Prometheus/Grafana (PASO 6) con PersistentVolumes.

---

## 6) IaC (Ansible): cómo se conecta con todo lo anterior

Ansible (PASO 5) no reemplaza a Kubernetes ni a Jenkins.
Ansible se encarga del “día 0” y “día 1” de infraestructura:

- Día 0: dejar la VM lista.
  - instalar Docker
  - instalar/asegurar Nginx (si aplica)
  - instalar K3s
  - instalar Jenkins (contenedorizado)
  - configurar firewall y prerequisitos

- Día 1: ejecutar el playbook “deploy-all” para reproducir la infraestructura completa.

Qué problema resuelve:
- evita instalar todo “a mano” en cada VM
- hace el proceso repetible e idempotente
- deja la infraestructura versionada en Git

---

## 7) Observabilidad (Prometheus + Grafana): cómo se conecta con K3s

El monitoreo (PASO 6) se instaló dentro del cluster:
- Namespace monitoring
- Helm instala kube-prometheus-stack (Prometheus Operator + Prometheus + Grafana + exporters)

Conexión clave:
- Prometheus descubre targets dentro del cluster (ServiceMonitors) y scrapea métricas.
- Grafana consulta a Prometheus y presenta dashboards.

Acceso desde Windows:
- Grafana se expone como NodePort 30080, por eso se accede por http://192.168.0.119:30080

Qué problema resuelve:
- no solo “desplegar”, sino operar: CPU, RAM, pods, errores, salud del cluster.

---

## 8) Qué pasa si apagas y vuelves a prender (operación post-reboot)

En el estado actual documentado:
- K3s está habilitado para arrancar en boot.
- kubectl ya no depende del kubeconfig de /etc con permisos restrictivos (se usa ~/.kube/config).
- Grafana/Prometheus arrancan como pods (y mantienen datos por PV/PVC).

El aprendizaje del incidente:
- /run/k3s es runtime (temporal). Si se corrompe, puede impedir que containerd cree su socket.
- La solución fue limpiar /run/k3s y reiniciar K3s.

---

## 9) Resumen final en una frase

Ustedes construyeron un flujo donde:
- Ansible prepara la VM,
- Jenkins convierte commits en despliegues automáticos en K3s,
- Kubernetes (Traefik + deployments + PVC) mantiene la app disponible,
- y Prometheus/Grafana te muestran en vivo si todo está sano.
