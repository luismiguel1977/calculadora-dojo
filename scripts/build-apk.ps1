# Reempaqueta y firma el APK (v2) con los cambios de www/index.html
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

$bt = Get-ChildItem "$env:LOCALAPPDATA\Android\Sdk\build-tools" | Sort-Object Name -Descending | Select-Object -First 1
$zipalign = Join-Path $bt.FullName "zipalign.exe"
$apksigner = Join-Path $bt.FullName "apksigner.bat"
$jdk = "C:\Program Files\Java\jdk-25.0.2\bin"

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

$py = @"
import zipfile, os, sys
base = sys.argv[1]
html_path = sys.argv[2]
out = sys.argv[3]
with open(html_path, 'rb') as f:
    new_html = f.read()
with zipfile.ZipFile(base, 'r') as zin:
    with zipfile.ZipFile(out, 'w') as zout:
        for item in zin.infolist():
            if item.filename.startswith('META-INF/'):
                continue
            data = zin.read(item.filename)
            if item.filename == 'assets/public/index.html':
                data = new_html
            zout.writestr(item, data)
print('written', out, os.path.getsize(out))
"@

$pyFile = Join-Path $workDir "repack.py"
Set-Content -Path $pyFile -Value $py -Encoding UTF8
python $pyFile $baseApk $html $unsigned
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
