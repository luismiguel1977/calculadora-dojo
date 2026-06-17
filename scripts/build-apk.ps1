# Reempaqueta y firma el APK (v2) con los cambios de www/index.html
# v2.1: autodetección de JDK (javac en PATH) y Android SDK (ANDROID_HOME / ANDROID_SDK_ROOT / ~/Android/Sdk)
# v2.2: regenera los mipmaps del launcher desde icons/icon-512.png (icons/icon-512.png es la fuente oficial)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

# --- Autodetección de JDK ---
$javac = (Get-Command javac -ErrorAction SilentlyContinue).Source
if (-not $javac) {
  Write-Error "javac no encontrado. Instala JDK 17+ y asegurate de que este en PATH."
  exit 1
}
$jdk = Split-Path -Parent (Split-Path -Parent $javac)
if (-not (Test-Path (Join-Path $jdk "bin\keytool.exe"))) {
  Write-Error "keytool.exe no encontrado en $jdk\bin. Verifica que el JDK este completo."
  exit 1
}
Write-Host "JDK: $jdk"

# --- Autodetección de Android SDK ---
$sdk = $null
if ($env:ANDROID_HOME)        { $sdk = $env:ANDROID_HOME }
elseif ($env:ANDROID_SDK_ROOT) { $sdk = $env:ANDROID_SDK_ROOT }
elseif ($env:LOCALAPPDATA)     { $sdk = Join-Path $env:LOCALAPPDATA "Android\Sdk" }
elseif ($env:ANDROID_SDK_HOME) { $sdk = $env:ANDROID_SDK_HOME }
elseif ($env:HOME)             { $sdk = Join-Path $env:HOME "Android/Sdk" }

if (-not $sdk) {
  Write-Error "Android SDK no encontrado. Define ANDROID_HOME, ANDROID_SDK_ROOT o instala el SDK en ~/Android/Sdk."
  exit 1
}
if (-not (Test-Path $sdk)) {
  Write-Error "Android SDK no existe en: $sdk"
  exit 1
}
Write-Host "Android SDK: $sdk"

# --- Autodetección de build-tools (última versión disponible) ---
$btDir = Join-Path $sdk "build-tools"
if (-not (Test-Path $btDir)) {
  Write-Error "No se encontro la carpeta build-tools en: $btDir"
  exit 1
}
$bt = Get-ChildItem $btDir -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
if (-not $bt) {
  Write-Error "No se encontraron build-tools en $btDir. Instala al menos una version con el SDK Manager."
  exit 1
}
Write-Host "Build-tools: $($bt.FullName)"

$zipalign  = Join-Path $bt.FullName "zipalign.exe"
$apksigner = Join-Path $bt.FullName "apksigner.bat"
$aapt2     = Join-Path $bt.FullName "aapt2.exe"

foreach ($tool in @($zipalign, $apksigner, $aapt2)) {
  if (-not (Test-Path $tool)) {
    Write-Error "Herramienta SDK no encontrada: $tool. Instala build-tools completo."
    exit 1
  }
}
Write-Host "  zipalign:  $zipalign"
Write-Host "  apksigner: $apksigner"
Write-Host "  aapt2:     $aapt2"

# --- Localizar APK base ---
$candidates = @(
  (Join-Path $root "build-apk\app.zip"),
  (Join-Path $root "build-apk\base.apk"),
  (Join-Path $root "x1kk4c.apk")
)
$baseApk = $null
foreach ($c in $candidates) {
  if ((Test-Path $c) -and ([IO.File]::ReadAllBytes($c)[0] -eq 0x50)) { $baseApk = $c; break }
}
if (-not $baseApk) { throw "No hay APK base valido (ZIP). Restaura build-apk/app.zip o x1kk4c.apk original." }
Write-Host "Base: $baseApk"

$html = Join-Path $root "www\index.html"
$outApk = Join-Path $root "apk\calculadora-dojo.apk"
$workDir = Join-Path $root "build-apk"
$unsigned = Join-Path $workDir "unsigned.apk"
$aligned = Join-Path $workDir "aligned.apk"
$ks = Join-Path $workDir "dojo-debug.keystore"

New-Item -ItemType Directory -Force (Split-Path $outApk) | Out-Null
New-Item -ItemType Directory -Force $workDir | Out-Null

if (-not (Test-Path $ks)) {
  & "$jdk\keytool.exe" -genkeypair -v -keystore $ks -alias dojo -keyalg RSA -keysize 2048 -validity 10000 `
    -storepass dojo1234 -keypass dojo1234 -dname "CN=Dojo Debug, OU=Dev, O=Dojo, L=ES, ST=ES, C=ES"
}

$wwwDir = Join-Path $root "www"
$py = @"
import zipfile, os, sys
from PIL import Image

base = sys.argv[1]
www_dir = sys.argv[2]
icon_src = sys.argv[3]  # icons/icon-512.png
out = sys.argv[4]

# 1. Leer www/ files
www_files = {}
for r, _, files in os.walk(www_dir):
    for name in files:
        full = os.path.join(r, name)
        rel = os.path.relpath(full, www_dir).replace('\\\\', '/')
        apk_path = 'assets/public/' + rel
        with open(full, 'rb') as f:
            www_files[apk_path] = f.read()

# 2. Generar mipmaps del icono desde icons/icon-512.png
#    (tamaños Android: mdpi=48, hdpi=72, xhdpi=96, xxhdpi=144, xxxhdpi=192)
sizes = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
icon_files = {
    'mipmap/ic_launcher':           {'mdpi': 'res/9w.png',  'hdpi': 'res/yn.png',  'xhdpi': 'res/FS.png',  'xxhdpi': 'res/RJ.png',  'xxxhdpi': 'res/o-.png'},
    'mipmap/ic_launcher_round':     {'mdpi': 'res/zR.png',  'hdpi': 'res/8c.png',  'xhdpi': 'res/wb.png',  'xxhdpi': 'res/fO.png',  'xxxhdpi': 'res/Gc.png'},
    'mipmap/ic_launcher_foreground':{'mdpi': 'res/QZ.png',  'hdpi': 'res/zr.png',  'xhdpi': 'res/Em.png',  'xxhdpi': 'res/Lf.png',  'xxxhdpi': 'res/as.png'},
}
source_img = Image.open(icon_src).convert('RGBA')
new_icon_bytes = {}  # ruta_en_apk -> bytes
for icon_name, mapping in icon_files.items():
    for density, apk_path in mapping.items():
        size = sizes[density]
        resized = source_img.resize((size, size), Image.LANCZOS)
        from io import BytesIO
        buf = BytesIO()
        resized.save(buf, 'PNG', optimize=True)
        new_icon_bytes[apk_path] = buf.getvalue()

# 3. Reempaquetar el APK sustituyendo los iconos
with zipfile.ZipFile(base, 'r') as zin:
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as zout:
        written = set()
        for item in zin.infolist():
            if item.filename.startswith('META-INF/'):
                continue
            if item.filename in new_icon_bytes:
                # usar el icono nuevo
                data = new_icon_bytes[item.filename]
            else:
                data = www_files.get(item.filename, zin.read(item.filename))
            zout.writestr(item.filename, data)
            written.add(item.filename)
        # anadir nuevos www/ files (los que no estaban en el APK base)
        for path, data in www_files.items():
            if path not in written:
                zout.writestr(path, data)
                written.add(path)
print('written', out, os.path.getsize(out), 'www files', len(www_files), 'icons replaced', len(new_icon_bytes))
"@

$pyFile = Join-Path $workDir "repack.py"
Set-Content -Path $pyFile -Value $py -Encoding UTF8
$iconSrc = Join-Path $root "icons\icon-512.png"
if (-not (Test-Path $iconSrc)) { throw "No se encontro $iconSrc. Verifica que el icono fuente este en su sitio." }
python $pyFile $baseApk $wwwDir $iconSrc $unsigned
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $unsigned)) { throw "Fallo al reempaquetar APK." }

& $zipalign -f -p 4 $unsigned $aligned
if ($LASTEXITCODE -ne 0) { throw "Fallo zipalign." }

& $apksigner sign --ks $ks --ks-key-alias dojo --ks-pass pass:dojo1234 --key-pass pass:dojo1234 --out $outApk $aligned
if ($LASTEXITCODE -ne 0) { throw "Fallo apksigner sign." }

& $apksigner verify --verbose $outApk
if ($LASTEXITCODE -ne 0) { throw "APK no verifica correctamente." }

Write-Host ""
Write-Host "APK listo: $outApk" -ForegroundColor Green
Write-Host "Desinstala la app anterior antes de instalar (firma distinta)." -ForegroundColor Yellow
