# 🔧 Rol Ansible: Jenkins

Instala Jenkins en Docker con integración a K3s para CI/CD.

## 📋 Requisitos

- Ubuntu 20.04, 22.04 o 24.04
- Docker instalado
- K3s instalado (para integración kubectl)
- Mínimo 2GB RAM disponible

## 🎯 Tareas que realiza

### Parte 1: Preparación
1. ✅ Crea directorios para Jenkins
2. ✅ Configura permisos

### Parte 2: Docker Compose
3. ✅ Genera docker-compose.jenkins.yml desde template
4. ✅ Configura Jenkins LTS + Agent

### Parte 3: Integración K3s
5. ✅ Copia kubeconfig de K3s
6. ✅ Actualiza server URL para acceso desde container
7. ✅ Monta kubeconfig en Jenkins

### Parte 4: Systemd Service
8. ✅ Crea servicio systemd para auto-start
9. ✅ Habilita servicio

### Parte 5: Deployment
10. ✅ Inicia contenedores con Docker Compose
11. ✅ Espera a que Jenkins esté disponible

### Parte 6: Setup Inicial
12. ✅ Obtiene password inicial de Jenkins
13. ✅ Muestra password en consola

## 🚀 Uso

### En un playbook:

```yaml
- name: Instalar Jenkins
  hosts: production
  become: yes
  roles:
    - jenkins
```

### Standalone:

```bash
ansible-playbook playbooks/deploy-jenkins.yml
```

## 📝 Variables configurables

Ver `defaults/main.yml`:

```yaml
jenkins_port: 8080
jenkins_version: "lts"
jenkins_home_dir: "/home/{{ ansible_user }}/jenkins"
```

## 🔐 Obtener password inicial

El playbook muestra el password automáticamente, pero también puedes:

```bash
# En la VM:
cat ~/jenkins/jenkins_home/secrets/initialAdminPassword
```

## ✅ Verificación

```bash
# Ver contenedores
docker ps -f name=jenkins

# Ver logs
docker logs jenkins -f

# Verificar acceso a K3s desde Jenkins
docker exec jenkins kubectl get nodes
```

## 🔧 Configuración post-instalación

1. Acceder a `http://192.168.0.119:8080`
2. Ingresar password inicial
3. Instalar plugins recomendados
4. Crear usuario admin
5. Configurar credenciales de K3s (ya montado en `/root/.kube/config`)

## 📦 Servicios desplegados

- **jenkins** - Jenkins LTS (puerto 8080)
- **jenkins-agent** - Agente para builds distribuidos
- **jenkins-docker.service** - Systemd service para auto-start

## 🔗 Integración con K3s

El rol automáticamente:
- Copia kubeconfig de K3s
- Actualiza IP del servidor
- Monta kubeconfig en container Jenkins
- Permite usar `kubectl` desde pipelines
