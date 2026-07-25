# ☸️ Rol Ansible: K3s

Instala K3s (Kubernetes ligero) y despliega la aplicación ecommerce completa.

## 📋 Requisitos

- Ubuntu 20.04, 22.04 o 24.04
- Mínimo 2GB RAM
- Acceso sudo
- Docker instalado (para build de imagen)

## 🎯 Tareas que realiza

### Parte 1: Instalación de K3s
1. ✅ Verifica si K3s está instalado
2. ✅ Descarga e instala K3s con versión específica
3. ✅ Configura permisos de kubeconfig
4. ✅ Verifica servicio K3s

### Parte 2: Preparación de manifiestos
5. ✅ Crea directorio para manifiestos
6. ✅ Copia manifiestos de Kubernetes (8 archivos)

### Parte 3: Deployment en Kubernetes
7. ✅ Aplica namespace
8. ✅ Aplica secrets de PostgreSQL
9. ✅ Aplica PVC para persistencia
10. ✅ Despliega PostgreSQL
11. ✅ Espera a que PostgreSQL esté ready
12. ✅ Despliega aplicación con 2 réplicas
13. ✅ Espera a que pods de app estén ready

### Parte 4: Verificación
14. ✅ Obtiene estado de todos los pods
15. ✅ Obtiene información de services
16. ✅ Muestra ClusterIP de la aplicación

## 🚀 Uso

### En un playbook:

```yaml
- name: Desplegar K3s
  hosts: production
  become: yes
  roles:
    - k3s
```

### Standalone:

```bash
ansible-playbook playbooks/deploy-k3s.yml
```

## 📝 Variables configurables

Ver `defaults/main.yml`:

```yaml
k3s_version: "v1.33.6+k3s1"
app_replicas: 2
postgres_storage: "2Gi"
pod_wait_timeout: 180
```

## 📂 Manifiestos incluidos

En `files/`:
- `namespace.yaml` - Namespace ecommerce
- `postgres-secret.yaml` - Credenciales DB
- `postgres-pvc.yaml` - Almacenamiento persistente
- `postgres-deployment.yaml` - Pod PostgreSQL
- `postgres-service.yaml` - Service interno
- `app-configmap.yaml` - Configuración app
- `app-deployment.yaml` - 2 réplicas de la app
- `app-service.yaml` - Service ClusterIP

## ✅ Verificación

```bash
# En la VM:
kubectl get all -n ecommerce
kubectl get pods -n ecommerce -o wide
kubectl logs -n ecommerce -l app=ecommerce-app
```

## 🔧 Troubleshooting

```bash
# Ver logs de K3s
sudo journalctl -u k3s -f

# Describir pod con problemas
kubectl describe pod <pod-name> -n ecommerce

# Ver eventos
kubectl get events -n ecommerce --sort-by='.lastTimestamp'
```
