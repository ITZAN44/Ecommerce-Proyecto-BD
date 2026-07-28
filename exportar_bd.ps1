<#
.SYNOPSIS
    Exporta la base de datos viva a database/backup_bd_real.sql, en un formato
    compatible con PostgreSQL gestionado (Neon, Render, RDS).

.DESCRIPTION
    Ejecuta pg_dump DENTRO del contenedor de PostgreSQL, de modo que no hace
    falta tener las client tools de PostgreSQL instaladas en el host.

    El dump se genera con tres flags que no son opcionales si el destino es una
    base gestionada:

      --no-owner       El rol neon_superuser no puede ejecutar ALTER ... OWNER TO.
                       Como el dump es de formato plano y se carga con psql,
                       esto NO se puede corregir en el momento de la carga:
                       tiene que salir bien del export.
      --no-privileges  Evita GRANT/REVOKE sobre roles que no existen en el destino.
      --encoding=UTF8  El export previo salia en WIN1252 y arriesgaba los acentos.

    El archivo solo se reemplaza si el export termina bien Y pasa las
    verificaciones. Si algo falla, el dump anterior queda intacto.

.PARAMETER Container
    Nombre del contenedor de PostgreSQL. Por defecto: ecommerce_db.

.PARAMETER Database
    Nombre de la base a exportar. Por defecto: ecommerce_db.

.PARAMETER User
    Rol de PostgreSQL con el que se conecta pg_dump. Por defecto: postgres.

.PARAMETER OutputPath
    Ruta del archivo de salida. Por defecto: database/backup_bd_real.sql
    junto a este script.

.EXAMPLE
    .\exportar_bd.ps1

.EXAMPLE
    .\exportar_bd.ps1 -Container otro_pg -Database otra_db

.NOTES
    Este archivo se mantiene deliberadamente en ASCII puro (sin acentos ni
    emoji): un .ps1 sin BOM con caracteres no-ASCII se corrompe al ejecutarse
    en Windows PowerShell 5.1.

    Este script NO pide ni imprime contrasenas. pg_dump se autentica por el
    socket local dentro del contenedor.
#>

[CmdletBinding()]
param(
    [string]$Container  = 'ecommerce_db',
    [string]$Database   = 'ecommerce_db',
    [string]$User       = 'postgres',
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

# $PSScriptRoot no siempre esta poblado al evaluar los valores por defecto del
# bloque param(), asi que la ruta de salida se resuelve aca con fallbacks.
if (-not $OutputPath) {
    $scriptDir = $PSScriptRoot
    if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
    if (-not $scriptDir) { $scriptDir = (Get-Location).Path }
    $OutputPath = Join-Path $scriptDir 'database\backup_bd_real.sql'
}

function Write-Step  { param([string]$m) Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok    { param([string]$m) Write-Host "    OK   $m" -ForegroundColor Green }
function Write-Warn2 { param([string]$m) Write-Host "    WARN $m" -ForegroundColor Yellow }
function Write-Fail  { param([string]$m) Write-Host "    FAIL $m" -ForegroundColor Red }

# --------------------------------------------------------------------------
# 1. Precondiciones
# --------------------------------------------------------------------------
Write-Step 'Verificando precondiciones'

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Fail 'Docker no esta disponible en el PATH.'
    exit 1
}
Write-Ok 'docker disponible'

$running = (docker ps --filter "name=^/$Container$" --filter 'status=running' --format '{{.Names}}')
if ($running -ne $Container) {
    Write-Fail "El contenedor '$Container' no esta corriendo."
    Write-Host "         Levantalo con: docker compose up -d postgres" -ForegroundColor Yellow
    exit 1
}
Write-Ok "contenedor '$Container' corriendo"

docker exec $Container pg_isready -U $User -d $Database *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Fail "PostgreSQL no acepta conexiones en '$Container' (base '$Database')."
    exit 1
}
Write-Ok "PostgreSQL acepta conexiones sobre '$Database'"

$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# --------------------------------------------------------------------------
# 2. Export a un archivo temporal
# --------------------------------------------------------------------------
# Se escribe primero en un temporal: si pg_dump falla a mitad de camino, el
# dump anterior no queda pisado por un archivo incompleto.
Write-Step "Exportando '$Database' desde el contenedor"

$tempPath = "$OutputPath.tmp"
$errPath  = "$OutputPath.err"

try {
    # cmd /c permite redirigir stdout y stderr por separado sin que PowerShell
    # reinterprete la salida binaria del dump.
    $cmd = "docker exec $Container pg_dump -U $User -d $Database " +
           "--no-owner --no-privileges --encoding=UTF8 -F p " +
           "> `"$tempPath`" 2> `"$errPath`""
    cmd /c $cmd
    $dumpExit = $LASTEXITCODE

    # Get-Content -Raw devuelve $null (no cadena vacia) si el archivo esta
    # vacio, que es justamente el caso normal: pg_dump sin errores.
    [string]$stderr = if (Test-Path $errPath) { (Get-Content $errPath -Raw) } else { '' }

    if ($dumpExit -ne 0) {
        Write-Fail "pg_dump termino con codigo $dumpExit"
        if ($stderr.Trim()) { Write-Host $stderr -ForegroundColor Red }
        exit 1
    }

    if ($stderr.Trim()) {
        Write-Warn2 'pg_dump escribio en stderr:'
        Write-Host $stderr -ForegroundColor Yellow
    }

    $sizeKB = [math]::Round((Get-Item $tempPath).Length / 1KB, 1)
    Write-Ok "export completado ($sizeKB KB)"

    # ----------------------------------------------------------------------
    # 3. Verificaciones sobre el dump generado
    # ----------------------------------------------------------------------
    # Un export con exit 0 no garantiza un dump utilizable. Se comprueba lo
    # que efectivamente rompe una carga en Neon.
    Write-Step 'Verificando el dump generado'

    [string]$content = Get-Content $tempPath -Raw
    if (-not $content) {
        Write-Fail 'El dump salio vacio. NO se reemplazo el archivo anterior.'
        exit 1
    }
    $checks = @()

    $owners = ([regex]::Matches($content, 'OWNER TO')).Count
    $checks += [pscustomobject]@{
        Nombre = 'sin sentencias OWNER TO'
        Ok     = ($owners -eq 0)
        Detalle = "$owners encontradas"
    }

    $checks += [pscustomobject]@{
        Nombre = 'codificacion UTF8'
        Ok     = ($content -match "client_encoding = 'UTF8'")
        Detalle = if ($content -match "client_encoding = '([^']+)'") { $Matches[1] } else { 'no declarada' }
    }

    $grants = ([regex]::Matches($content, '(?m)^(GRANT|REVOKE)\b')).Count
    $checks += [pscustomobject]@{
        Nombre = 'sin GRANT/REVOKE'
        Ok     = ($grants -eq 0)
        Detalle = "$grants encontrados"
    }

    $tablas = ([regex]::Matches($content, '(?m)^CREATE TABLE\b')).Count
    $checks += [pscustomobject]@{
        Nombre = 'contiene tablas'
        Ok     = ($tablas -gt 0)
        Detalle = "$tablas CREATE TABLE"
    }

    $checks += [pscustomobject]@{
        Nombre = 'dump completo'
        Ok     = ($content -match 'PostgreSQL database dump complete')
        Detalle = if ($content -match 'PostgreSQL database dump complete') { 'marca final presente' } else { 'FALTA la marca final' }
    }

    foreach ($c in $checks) {
        if ($c.Ok) { Write-Ok "$($c.Nombre) -- $($c.Detalle)" }
        else       { Write-Fail "$($c.Nombre) -- $($c.Detalle)" }
    }

    if ($checks | Where-Object { -not $_.Ok }) {
        Write-Fail 'El dump no paso las verificaciones. NO se reemplazo el archivo anterior.'
        Write-Host "         Dump rechazado en: $tempPath" -ForegroundColor Yellow
        exit 1
    }

    # pg_dump 16.10+ emite los meta-comandos \restrict / \unrestrict como
    # proteccion contra inyeccion de meta-comandos desde un servidor
    # comprometido. Solo los entienden clientes psql recientes: es un aviso,
    # no un error.
    if ($content -match '(?m)^\\restrict ') {
        Write-Warn2 'el dump incluye \restrict / \unrestrict (pg_dump 16.10+)'
        Write-Host  '         Cargalo con un cliente psql reciente. Ver docs/deploy/spec-render-neon.md seccion 6.4' -ForegroundColor Yellow
    }

    # ----------------------------------------------------------------------
    # 4. Reemplazo
    # ----------------------------------------------------------------------
    Move-Item -Path $tempPath -Destination $OutputPath -Force
    Write-Step 'Listo'
    Write-Ok "dump guardado en: $OutputPath"

    Write-Host ''
    Write-Host 'Siguientes pasos sugeridos:' -ForegroundColor Cyan
    Write-Host '  - Revisar el cambio:  git diff --stat database/backup_bd_real.sql'
    Write-Host '  - Cargarlo en Neon:   ver docs/deploy/spec-render-neon.md seccion 6.6'
    Write-Host ''
    Write-Host 'Nota: este dump solo se carga automaticamente en un contenedor NUEVO' -ForegroundColor DarkGray
    Write-Host '      (volumen vacio). No hace falta recrear el entorno actual.' -ForegroundColor DarkGray
}
finally {
    Remove-Item $errPath  -ErrorAction SilentlyContinue
    Remove-Item $tempPath -ErrorAction SilentlyContinue
}
