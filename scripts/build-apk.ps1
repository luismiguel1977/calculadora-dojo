# Reempaqueta y firma el APK (v3) con los cambios de www/
# v3.0: sincroniza TODOS los assets de www/ (no solo 3 archivos) y preserva el compress_type de cada archivo del APK base
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

# --- Autodetección de JDK ---
$javac = (Get-Command javac -ErrorAction SilentlyContinue).Source
if (-not $javac) { Write-Error "javac no encontrado. Instala JDK 17+ y asegurate de que este en PATH."; exit 1 }
$jdk = Split-Path -Parent (Split-Path -Parent $javac)
if (-not (Test-Path (Join-Path $jdk "bin\keytool.exe"))) { Write-Error "keytool.exe no encontrado en $jdk\bin. Verifica que el JDK este completo."; exit 1 }
Write-Host "JDK: $jdk"

# --- Autodetección de Android SDK ---
$sdk = $null
if ($env:ANDROID_HOME)        { $sdk = $env:ANDROID_HOME }
elseif ($env:ANDROID_SDK_ROOT) { $sdk = $env:ANDROID_SDK_ROOT }
elseif ($env:LOCALAPPDATA)     { $sdk = Join-Path $env:LOCALAPPDATA "Android\Sdk" }
elseif ($env:ANDROID_SDK_HOME) { $sdk = $env:ANDROID_SDK_HOME }
elseif ($env:HOME)             { $sdk = Join-Path $env:HOME "Android/Sdk" }
if (-not $sdk -or -not (Test-Path $sdk)) { Write-Error "Android SDK no encontrado. Define ANDROID_HOME, ANDROID_SDK_ROOT o instala el SDK."; exit 1 }
Write-Host "Android SDK: $sdk"

# --- Autodetección de build-tools (última versión) ---
$btDir = Join-Path $sdk "build-tools"
$bt = Get-ChildItem $btDir -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
if (-not $bt) { Write-Error "No se encontraron build-tools en $btDir."; exit 1 }
Write-Host "Build-tools: $($bt.FullName)"
$zipalign  = Join-Path $bt.FullName "zipalign.exe"
$apksigner = Join-Path $bt.FullName "apksigner.bat"
foreach ($tool in @($zipalign, $apksigner)) { if (-not (Test-Path $tool)) { Write-Error "Herramienta SDK no encontrada: $tool."; exit 1 } }

# --- Localizar APK base ---
$candidates = @(
  (Join-Path $root "build-apk\app.zip"),
  (Join-Path $root "build-apk\base.apk"),
  (Join-Path $root "x1kk4c.apk"),
  (Join-Path $root "Dojo_v-2.8-original.apk")
)
$baseApk = $null
foreach ($c in $candidates) {
  if ((Test-Path $c) -and ([IO.File]::ReadAllBytes($c)[0] -eq 0x50)) { $baseApk = $c; break }
}
if (-not $baseApk) { throw "No hay APK base valido (ZIP). Restaura build-apk/app.zip, x1kk4c.apk o Dojo_v-2.8-original.apk." }
Write-Host "Base: $baseApk"

$outApk = Join-Path $root "apk\calculadora-dojo.apk"
$workDir = Join-Path $root "build-apk"
$unsigned = Join-Path $workDir "unsigned.apk"
$aligned = Join-Path $workDir "aligned.apk"
$ks = Join-Path $workDir "dojo-debug.keystore"
New-Item -ItemType Directory -Force (Split-Path $outApk) | Out-Null
New-Item -ItemType Directory -Force $workDir | Out-Null

if (-not (Test-Path $ks)) {
  & "$jdk\bin\keytool.exe" -genkeypair -v -keystore $ks -alias dojo -keyalg RSA -keysize 2048 -validity 10000 `
    -storepass dojo1234 -keypass dojo1234 -dname "CN=Dojo Debug, OU=Dev, O=Dojo, L=ES, ST=ES, C=ES"
}

# --- 1) Sincronizar www/ desde fuentes del repo ---
# (Asume que ya se ha ejecutado npm run sync:web, que actualiza index.html y los assets fijos)
Write-Host "Sincronizando www/ desde fuentes..."
$wwwDir = Join-Path $root "www"
if (-not (Test-Path (Join-Path $wwwDir "index.html"))) { throw "www/index.html no existe. Ejecuta 'npm run sync:web' primero." }

# --- 2) Reempaquetar preservando compress_type ---
$py = @"
import zipfile, os, sys
from io import BytesIO

base = sys.argv[1]
www_dir = sys.argv[2]
out = sys.argv[3]

# 1) Leer TODOS los archivos de www/ (NO solo 3)
www_files = {}
for r, _, files in os.walk(www_dir):
    for name in files:
        full = os.path.join(r, name)
        rel = os.path.relpath(full, www_dir).replace('\\\\', '/')
        apk_path = 'assets/public/' + rel
        with open(full, 'rb') as f:
            www_files[apk_path] = f.read()

# 2) Leer compress_type de cada archivo del APK base (CRÍTICO para Android 11+)
with zipfile.ZipFile(base, 'r') as zin:
    storage = {info.filename: info.compress_type for info in zin.infolist()}

# 3) Reempaquetar: para cada archivo del APK base, si está en www_files sobrescribir;
#    si no, mantener el original. PRESERVAR compress_type.
with zipfile.ZipFile(base, 'r') as zin:
    with zipfile.ZipFile(out, 'w') as zout:
        for item in zin.infolist():
            if item.filename.startswith('META-INF/'):
                continue  # borrar firma anterior
            if item.filename in www_files:
                data = www_files[item.filename]
            else:
                data = zin.read(item.filename)
            comp = storage.get(item.filename, zipfile.ZIP_DEFLATED)
            zout.writestr(item.filename, data, compress_type=comp)

# 4) A\u00f1adir archivos de www/ que NO estaban en el APK base
with zipfile.ZipFile(out, 'a', zipfile.ZIP_STORED) as zout:
    existing = set(zout.namelist())
    added = 0
    for path, data in www_files.items():
        if path not in existing:
            zout.writestr(path, data, compress_type=zipfile.ZIP_STORED)
            added += 1
print('written', out, os.path.getsize(out), 'www files', len(www_files), 'new added', added)
"@

$pyFile = Join-Path $workDir "repack.py"
[System.IO.File]::WriteAllText($pyFile, $py, [System.Text.UTF8Encoding]::new($false))
& python $pyFile $baseApk $wwwDir $unsigned
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $unsigned)) { throw "Fallo al reempaquetar APK." }

# --- 3) zipalign + apksigner ---
& $zipalign -f -p 4 $unsigned $aligned
if ($LASTEXITCODE -ne 0) { throw "Fallo zipalign." }

& $apksigner sign --ks $ks --ks-key-alias dojo --ks-pass pass:dojo1234 --key-pass pass:dojo1234 --out $outApk $aligned
if ($LASTEXITCODE -ne 0) { throw "Fallo apksigner sign." }

& $apksigner verify --verbose $outApk
if ($LASTEXITCODE -ne 0) { throw "APK no verifica correctamente." }

Write-Host ""
Write-Host "APK listo: $outApk" -ForegroundColor Green
Write-Host "Desinstala la app anterior antes de instalar (firma puede ser distinta)." -ForegroundColor Yellow
