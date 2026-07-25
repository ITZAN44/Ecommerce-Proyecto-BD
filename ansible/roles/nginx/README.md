# 🌐 Rol Ansible: Nginx

Instala y configura Nginx como reverse proxy para el ecommerce.

## 📋 Requisitos

- Ubuntu 20.04, 22.04 o 24.04
- Acceso sudo
- Backend funcionando (K3s Service en 10.43.7.181:80)

## 🎯 Tareas que realiza

1. ✅ Instala Nginx
2. ✅ Elimina configuración por defecto
3. ✅ Crea configuración de reverse proxy desde template
4. ✅ Habilita el sitio (symlink)
5. ✅ Valida configuración (nginx -t)
6. ✅ Recarga Nginx automáticamente
7. ✅ Configura logs personalizados

## 🚀 Uso

### En un playbook:

```yaml
- name: Configurar Nginx
  hosts: production
  become: yes
  roles:
    - nginx
```

### Standalone:

```bash
ansible-playbook playbooks/deploy-nginx.yml
```

## 📝 Variables configurables

Ver `defaults/main.yml`:

```yaml
nginx_port: 80
nginx_backend_host: "10.43.7.181"  # K3s Service ClusterIP
nginx_backend_port: 80
nginx_server_name: "{{ ansible_host }}"
```

## 🔧 Personalizar backend

Si tu backend K3s cambia de IP, actualiza en `inventory/group_vars/production.yml`:

```yaml
nginx_backend_host: "10.43.x.x"
```

## ✅ Verificación

```bash
# En la VM:
sudo nginx -t
sudo systemctl status nginx
curl http://localhost/nginx-health
```

## 📂 Archivo generado

- `/etc/nginx/sites-available/ecommerce` - Configuración del sitio
- `/etc/nginx/sites-enabled/ecommerce` - Symlink habilitado
