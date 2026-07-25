# Script para exportar tu base de datos real a Docker
# Ejecuta este script cuando tu PostgreSQL del puerto 5501 esté corriendo

Write-Host "🔍 Buscando pg_dump..." -ForegroundColor Cyan

# Buscar pg_dump en las ubicaciones comunes
$pgDumpPaths = @(
    "C:\Users\User\Documents\Universidad\BS2\BD_01\pgsql\bin\pg_dump.exe",
    "C:\Program Files\PostgreSQL\16\bin\pg_dump.exe",
    "C:\Program Files\PostgreSQL\15\bin\pg_dump.exe",
    "C:\Program Files\PostgreSQL\14\bin\pg_dump.exe",
    "C:\Program Files (x86)\PostgreSQL\16\bin\pg_dump.exe",
    "C:\Program Files (x86)\PostgreSQL\15\bin\pg_dump.exe"
)

$pgDump = $null
foreach ($path in $pgDumpPaths) {
    if (Test-Path $path) {
        $pgDump = $path
        Write-Host "✅ Encontrado: $pgDump" -ForegroundColor Green
        break
    }
}

if (-not $pgDump) {
    Write-Host "❌ No se encontró pg_dump. Por favor instala PostgreSQL o agrega pg_dump al PATH" -ForegroundColor Red
    Read-Host "Presiona Enter para salir"
    exit 1
}

Write-Host "`n📤 Exportando base de datos del puerto 5501..." -ForegroundColor Yellow
Write-Host "Puede pedirte la contraseña de PostgreSQL (12345678)`n" -ForegroundColor Yellow

$outputFile = "$PSScriptRoot\database\backup_bd_real.sql"

# Exportar la base de datos
& $pgDump -h 127.0.0.1 -p 5501 -U postgres -d ecommerce_db -F p -f $outputFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ ¡Exportación exitosa!" -ForegroundColor Green
    Write-Host "📁 Archivo guardado en: database\backup_bd_real.sql" -ForegroundColor Cyan
    Write-Host "`n📋 Siguiente paso:" -ForegroundColor Yellow
    Write-Host "   Ejecuta: docker-compose down -v" -ForegroundColor White
    Write-Host "   Luego:   docker-compose up" -ForegroundColor White
    Write-Host "`n   Docker cargará automáticamente tus datos reales 🚀" -ForegroundColor Green
} else {
    Write-Host "`n❌ Error al exportar. Verifica:" -ForegroundColor Red
    Write-Host "   1. PostgreSQL está corriendo en el puerto 5501" -ForegroundColor Yellow
    Write-Host "   2. La base de datos 'ecommerce_db' existe" -ForegroundColor Yellow
    Write-Host "   3. Usuario 'postgres' con contraseña '12345678'" -ForegroundColor Yellow
}

Read-Host "`nPresiona Enter para salir"
