# 🔧 Configuración de Jenkins

Esta carpeta contiene archivos de configuración y scripts auxiliares para Jenkins.

## Archivos

- `README.md` - Este archivo
- (Aquí irán scripts adicionales si los necesitas)

## Acceso a Jenkins

- **URL:** http://192.168.0.119:8080
- **Puerto:** 8080

## Comandos útiles

### Ver logs de Jenkins
```bash
docker logs -f jenkins_server
```

### Reiniciar Jenkins
```bash
docker restart jenkins_server
```

### Acceder al contenedor de Jenkins
```bash
docker exec -it jenkins_server bash
```

### Ver la contraseña inicial de admin
```bash
docker exec jenkins_server cat /var/jenkins_home/secrets/initialAdminPassword
```
