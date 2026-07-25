# 📘 Guía Rápida - Ansible Deployment

## 🚀 Quick Start (5 segundos)

```bash
# Desde WSL Ubuntu:
cd ~/ecommerce-ansible/ansible
ansible-playbook playbooks/deploy-all.yml
```

**¡Listo!** En 15-20 minutos tendrás toda la infraestructura corriendo.

---

## 📋 Verificación Post-Deployment

```bash
# 1. Ver estado de servicios
sudo systemctl status docker nginx k3s

# 2. Ver pods de Kubernetes
kubectl get all -n ecommerce

# 3. Ver contenedores Docker
docker ps

# 4. Ver logs de la aplicación
kubectl logs -n ecommerce -l app=ecommerce-app -f

# 5. Verificar Jenkins
docker logs jenkins -f
```

---

## 🌐 Acceso a Servicios

| Servicio | URL | Descripción |
|----------|-----|-------------|
| **Ecommerce App** | http://192.168.0.119 | Aplicación principal |
| **Jenkins** | http://192.168.0.119:8080 | CI/CD Dashboard |
| **Nginx Status** | http://192.168.0.119/nginx-health | Health check |

---

## 🔧 Comandos Útiles

### Ver todo el inventario
```bash
ansible-inventory --list -y
```

### Test de conectividad
```bash
ansible-playbook playbooks/ping-test.yml
```

### Deploy selectivo (con tags)
```bash
# Solo Docker
ansible-playbook playbooks/deploy-all.yml --tags docker

# Solo Nginx y K3s
ansible-playbook playbooks/deploy-all.yml --tags nginx,k3s
```

### Check mode (simular sin cambios)
```bash
ansible-playbook playbooks/deploy-all.yml --check
```

### Verbose (debug)
```bash
ansible-playbook playbooks/deploy-all.yml -v   # Normal
ansible-playbook playbooks/deploy-all.yml -vv  # Más detalle
ansible-playbook playbooks/deploy-all.yml -vvv # Máximo detalle
```

---

## 🗑️  Limpiar Todo

```bash
# ⚠️ CUIDADO: Esto elimina TODA la configuración
ansible-playbook playbooks/destroy-all.yml
```

---

## 🐛 Troubleshooting

### Error: "host unreachable"
```bash
# Verificar SSH
ssh clark@192.168.0.119

# Verificar inventario
cat inventory/hosts.ini
```

### Error: "sudo password required"
```bash
# En el servidor remoto:
sudo visudo
# Agregar: clark ALL=(ALL) NOPASSWD:ALL
```

### Error: "kubectl command not found"
```bash
# En el servidor remoto:
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

### Pods no arrancan
```bash
kubectl describe pod <pod-name> -n ecommerce
kubectl logs <pod-name> -n ecommerce
```

---

## 📊 Estructura del Proyecto

```
ansible/
├── ansible.cfg              # Configuración global
├── README.md                # Este archivo
├── QUICK_START.md           # Guía rápida
├── inventory/
│   ├── hosts.ini            # Servidores
│   └── group_vars/
│       ├── all.yml          # Variables globales
│       └── production.yml   # Variables de producción
├── playbooks/
│   ├── deploy-all.yml       # 🌟 PLAYBOOK MAESTRO
│   ├── destroy-all.yml      # Limpieza completa
│   ├── ping-test.yml        # Test de conectividad
│   └── deploy-*.yml         # Playbooks individuales
└── roles/
    ├── docker/              # 15 tareas
    ├── nginx/               # 11 tareas
    ├── k3s/                 # 24 tareas
    └── jenkins/             # 19 tareas
```

---

## 🎓 Recursos de Aprendizaje

- **Ansible Docs:** https://docs.ansible.com/
- **Best Practices:** https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html
- **K3s Docs:** https://docs.k3s.io/
- **Docker Docs:** https://docs.docker.com/

---

## ✅ Checklist de Deployment

- [ ] WSL Ubuntu instalado
- [ ] Ansible instalado (`ansible --version`)
- [ ] SSH configurado (passwordless)
- [ ] Inventario configurado
- [ ] Variables de grupo configuradas
- [ ] Test de ping exitoso
- [ ] **Ejecutar:** `ansible-playbook playbooks/deploy-all.yml`
- [ ] Verificar servicios corriendo
- [ ] Acceder a http://192.168.0.119
- [ ] Configurar Jenkins

---

## 🏆 ¡Proyecto Completado!

Este proyecto automatiza completamente el deployment de:
- ✅ **69 tareas** en total
- ✅ **4 roles** independientes
- ✅ **1 comando** para deployar todo
- ✅ **15 minutos** de tiempo de ejecución
- ✅ **100% idempotente** (se puede ejecutar múltiples veces)

**¡Infraestructura como Código dominada! 🎉**
