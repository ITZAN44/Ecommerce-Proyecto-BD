# 🤖 Ansible - Infrastructure as Code

Este directorio contiene la automatización completa del proyecto usando Ansible.

## 📁 Estructura

```
ansible/
├── ansible.cfg                 # Configuración de Ansible
├── inventory/
│   ├── hosts.ini              # Lista de servidores
│   └── group_vars/            # Variables por grupo
├── playbooks/                 # Playbooks de deployment
├── roles/                     # Roles reutilizables
└── files/                     # Archivos estáticos
```

## 🚀 Inicio Rápido

### 1. Instalar Ansible

**En WSL/Ubuntu:**
```bash
sudo apt update
sudo apt install -y ansible
```

**Verificar instalación:**
```bash
ansible --version
```

### 2. Configurar SSH

**Copiar tu clave SSH a la VM:**
```bash
ssh-copy-id clark@192.168.0.119
```

O manualmente:
```bash
# Generar clave si no tienes
ssh-keygen -t rsa -b 4096

# Copiar a VM
cat ~/.ssh/id_rsa.pub | ssh clark@192.168.0.119 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### 3. Probar Conectividad

```bash
cd ansible/
ansible-playbook playbooks/ping-test.yml
```

**Salida esperada:**
```yaml
TASK [Ping básico de Ansible] ******
ok: [vm-ubuntu]

TASK [Mostrar información del sistema operativo] ******
ok: [vm-ubuntu] => 
  msg: |-
    ========================================
    Host: vm-ubuntu
    OS: Ubuntu 24.04
    Arquitectura: x86_64
    Python: 3.12.3
    ========================================
```

## 📚 Comandos Útiles

### Inventario

```bash
# Ver todos los hosts
ansible all --list-hosts

# Ver hosts del grupo production
ansible production --list-hosts

# Hacer ping a todos
ansible all -m ping
```

### Playbooks

```bash
# Ejecutar playbook de prueba
ansible-playbook playbooks/ping-test.yml

# Ejecutar con verbose (debug)
ansible-playbook playbooks/ping-test.yml -v

# Ejecutar solo en un host específico
ansible-playbook playbooks/ping-test.yml --limit vm-ubuntu

# Dry run (no hace cambios reales)
ansible-playbook playbooks/ping-test.yml --check
```

### Comandos Ad-Hoc

```bash
# Ejecutar comando en todos los hosts
ansible all -a "uptime"

# Ver uso de disco
ansible production -a "df -h"

# Reiniciar servicio
ansible production -m service -a "name=nginx state=restarted"
```

## 🔐 Seguridad

### Ansible Vault (Encriptar Secrets)

```bash
# Encriptar archivo de variables
ansible-vault encrypt inventory/group_vars/production.yml

# Editar archivo encriptado
ansible-vault edit inventory/group_vars/production.yml

# Ejecutar playbook con vault
ansible-playbook playbooks/deploy-all.yml --ask-vault-pass
```

## 🚀 Deployment Completo (Playbook Maestro)

### Opción 1: Todo desde cero (RECOMENDADO)

```bash
# Deployar TODA la infraestructura automáticamente
ansible-playbook playbooks/deploy-all.yml
```

**Esto instalará:**
- ✅ Docker Engine + Docker Compose
- ✅ Nginx (Reverse Proxy)
- ✅ K3s (Kubernetes) + PostgreSQL
- ✅ Ecommerce App (2 réplicas)
- ✅ Jenkins (CI/CD)

**Tiempo:** ~15-20 minutos

---

### Opción 2: Deployment por componentes

```bash
# Solo Docker
ansible-playbook playbooks/deploy-docker.yml

# Solo Nginx
ansible-playbook playbooks/deploy-nginx.yml

# Solo K3s
ansible-playbook playbooks/deploy-k3s.yml

# Solo Jenkins
ansible-playbook playbooks/deploy-jenkins.yml
```

---

### Opción 3: Destruir todo (Reset completo)

```bash
# ⚠️ CUIDADO: Elimina toda la configuración
ansible-playbook playbooks/destroy-all.yml
```

---

## 📚 Próximos Pasos

1. ✅ Crear estructura básica
2. ✅ Crear rol `docker`
3. ✅ Crear rol `nginx`
4. ✅ Crear rol `k3s`
5. ✅ Crear rol `jenkins`
6. ✅ Crear playbook maestro
7. ✅ **¡PROYECTO COMPLETADO!**

## 📚 Documentación

- [PASO_05_IAC_ANSIBLE.md](../devops.md/PASO_05_IAC_ANSIBLE.md) - Guía completa paso a paso
- [Ansible Docs](https://docs.ansible.com/)
- [Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
