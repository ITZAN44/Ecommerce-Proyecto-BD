# Secrets Directory

Esta carpeta contiene información sensible y NO debe ser commiteada a Git.

## Archivos requeridos:

### `db_password.txt`
Contiene el password de PostgreSQL (una sola línea, sin saltos de línea al final).

**Cómo crear en tu VM Ubuntu:**
```bash
echo -n "tu_password_seguro_aqui" > secrets/db_password.txt
chmod 600 secrets/db_password.txt
```

**Importante:**
- NO uses el password por defecto (12345678)
- Usa un password fuerte en producción
- Verifica que `secrets/` esté en `.gitignore`
