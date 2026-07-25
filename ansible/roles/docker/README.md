# 🐳 Rol Ansible: Docker

Instala y configura Docker Engine + Docker Compose en Ubuntu.

## 📋 Requisitos

- Ubuntu 20.04, 22.04 o 24.04
- Acceso sudo
- Conexión a internet

## 🎯 Tareas que realiza

1. ✅ Actualiza repositorios del sistema
2. ✅ Instala paquetes prerequisitos
3. ✅ Agrega clave GPG oficial de Docker
4. ✅ Configura repositorio de Docker
5. ✅ Instala Docker Engine, CLI y Compose
6. ✅ Inicia y habilita servicio Docker
7. ✅ Agrega usuario al grupo docker (ejecutar sin sudo)
8. ✅ Verifica instalación con contenedor de prueba

## 🚀 Uso

### En un playbook:

```yaml
- name: Instalar Docker
  hosts: production
  become: yes
  roles:
    - docker
```

### Standalone:

```bash
ansible-playbook playbooks/deploy-docker.yml
```

## 📝 Variables configurables

Ver `defaults/main.yml`:

```yaml
docker_version: "latest"
docker_user: "{{ ansible_user }}"
docker_service_enabled: yes
```

## ⚠️ Post-instalación

Después de ejecutar el rol, el usuario necesita:

1. Cerrar sesión SSH y volver a conectar, O
2. Ejecutar: `newgrp docker`

Esto activa los permisos del grupo docker.

## ✅ Verificación

```bash
# En la VM:
docker --version
docker compose version
docker ps
```
