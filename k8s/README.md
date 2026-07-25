# 🚀 Manifiestos Kubernetes - Ecommerce

Archivos YAML para desplegar el ecommerce en Kubernetes (K3s).

## 📂 Estructura

```
k8s/
├── namespace.yaml              # Namespace "ecommerce"
├── postgres-secret.yaml        # Credenciales DB (Secret)
├── postgres-pvc.yaml           # Volumen persistente 2Gi
├── postgres-deployment.yaml    # PostgreSQL 16-alpine
├── postgres-service.yaml       # Service ClusterIP:5432
├── app-configmap.yaml          # Variables de entorno
├── app-deployment.yaml         # Ecommerce App (2 réplicas)
├── app-service.yaml            # Service ClusterIP:80
└── ingress.yaml                # Traefik Ingress HTTP
```

## 🔧 Orden de Aplicación

```bash
# 1. Namespace
kubectl apply -f namespace.yaml

# 2. Secrets y ConfigMaps
kubectl apply -f postgres-secret.yaml
kubectl apply -f app-configmap.yaml

# 3. Storage
kubectl apply -f postgres-pvc.yaml

# 4. Database
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml

# 5. Application
kubectl apply -f app-deployment.yaml
kubectl apply -f app-service.yaml

# 6. Ingress
kubectl apply -f ingress.yaml
```

## ⚡ Deploy Rápido

```bash
# Aplicar todo de una vez
kubectl apply -f k8s/

# Ver estado
kubectl get all -n ecommerce

# Ver logs
kubectl logs -n ecommerce -l app=ecommerce-app --tail=50 -f
```

## 🎯 Características

### Alta Disponibilidad
- **2 réplicas** de la app
- **RollingUpdate** sin downtime
- **Liveness/Readiness** probes

### Seguridad
- Secrets para credenciales
- ConfigMaps para configuración
- Namespace isolation

### Performance
- Resource requests/limits
- PersistentVolume para DB
- Probes optimizados

### Observabilidad
- Labels consistentes
- Health checks
- Logs centralizados

## 📊 Recursos Solicitados

| Componente | CPU Request | CPU Limit | RAM Request | RAM Limit |
|------------|-------------|-----------|-------------|-----------|
| PostgreSQL | 250m | 500m | 256Mi | 512Mi |
| App (x2) | 200m | 500m | 256Mi | 512Mi |
| **Total** | **650m** | **1500m** | **768Mi** | **1536Mi** |

## 🔍 Comandos Útiles

```bash
# Ver pods
kubectl get pods -n ecommerce -o wide

# Describir deployment
kubectl describe deployment ecommerce-app -n ecommerce

# Logs en tiempo real
kubectl logs -n ecommerce deployment/ecommerce-app -f

# Entrar a un pod
kubectl exec -it -n ecommerce deployment/ecommerce-app -- sh

# Ver eventos
kubectl get events -n ecommerce --sort-by='.lastTimestamp'

# Escalar réplicas
kubectl scale deployment ecommerce-app -n ecommerce --replicas=3

# Reiniciar deployment (rolling restart)
kubectl rollout restart deployment ecommerce-app -n ecommerce

# Ver historial de deployments
kubectl rollout history deployment ecommerce-app -n ecommerce

# Rollback a versión anterior
kubectl rollout undo deployment ecommerce-app -n ecommerce
```

## 🗑️ Limpiar Todo

```bash
# Eliminar namespace (elimina todo dentro)
kubectl delete namespace ecommerce

# O eliminar recursos individuales
kubectl delete -f k8s/
```
