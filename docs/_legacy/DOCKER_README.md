# 🐳 Guía de Docker para E-commerce Proyecto

## 📦 ¿Qué incluye esta configuración?

- **PostgreSQL 16**: Base de datos con todo tu esquema, funciones y datos de prueba
- **Astro App**: Tu aplicación web conectada automáticamente a la BD
- **Inicialización automática**: Todos los SQL se ejecutan en orden al crear el contenedor

## 🚀 Comandos Básicos

### Iniciar todo el proyecto
```powershell
docker-compose up
```
- PostgreSQL estará en `localhost:5432`
- Tu app en `http://localhost:4321`

### Iniciar en segundo plano (sin ver logs)
```powershell
docker-compose up -d
```

### Ver logs en tiempo real
```powershell
docker-compose logs -f
```

### Detener todo
```powershell
docker-compose down
```

### Detener Y borrar datos de la BD (empezar de cero)
```powershell
docker-compose down -v
```

### Reconstruir después de cambios en código
```powershell
docker-compose up --build
```

## 🔧 Desarrollo con Docker

### Si modificas archivos SQL:
1. Detener y borrar datos: `docker-compose down -v`
2. Volver a iniciar: `docker-compose up`

### Si modificas código Astro:
- Los cambios se reflejan automáticamente (hot-reload activo)

## 📊 Conectar a PostgreSQL desde fuera de Docker

Puedes usar herramientas como pgAdmin, DBeaver o Azure Data Studio:

- **Host**: `localhost`
- **Puerto**: `5432`
- **Base de datos**: `ecommerce_db`
- **Usuario**: `postgres`
- **Contraseña**: `12345678`

## 🐛 Solución de Problemas

### Puerto 5432 ya en uso
Si ya tienes PostgreSQL local corriendo:
```powershell
# Opción 1: Detener tu PostgreSQL local
Stop-Service postgresql-x64-16

# Opción 2: Cambiar puerto en docker-compose.yml
# Línea 16: "5433:5432" en lugar de "5432:5432"
```

### Ver qué contenedores están corriendo
```powershell
docker ps
```

### Entrar al contenedor de PostgreSQL
```powershell
docker exec -it ecommerce_db psql -U postgres -d ecommerce_db
```

### Entrar al contenedor de la app
```powershell
docker exec -it ecommerce_app sh
```

## 📁 Estructura de lo que Docker hace

1. **Crea contenedor PostgreSQL** con imagen oficial
2. **Monta tus archivos SQL** en `/docker-entrypoint-initdb.d/`
3. **Ejecuta init.sql** que llama a todos los demás en orden:
   - schema.sql
   - functions_procedures_LIMPIO.sql
   - seed.sql
   - Todas las mejoras de fase1, fase2, fase3
4. **Crea contenedor Astro** con tu app
5. **Conecta ambos** mediante red interna de Docker

## 🎯 Ventajas

✅ No necesitas instalar PostgreSQL manualmente
✅ BD se configura sola con todos tus datos
✅ Tus compañeros/profesor solo hacen `docker-compose up`
✅ Mismo entorno en cualquier máquina
✅ Datos persisten entre reinicios (en volumen Docker)

## 💡 Tips

- **Primera vez**: Tardará unos segundos en descargar imágenes
- **Datos persisten**: Aunque cierres Docker, los datos quedan guardados
- **Empezar de cero**: `docker-compose down -v` borra todo y reinicia
- **Ver espacio usado**: `docker system df`
- **Limpiar todo Docker**: `docker system prune -a` (¡cuidado!)

## 🔄 Flujo de trabajo recomendado

1. Iniciar proyecto: `docker-compose up`
2. Desarrollar normalmente (cambios se reflejan automáticamente)
3. Al terminar: `docker-compose down`
4. Al día siguiente: `docker-compose up` (datos siguen ahí)

---

**¿Dudas?** Revisa los logs con `docker-compose logs -f` para ver qué está pasando.
