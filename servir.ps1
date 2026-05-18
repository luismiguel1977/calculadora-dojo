# Servidor local para probar la PWA (http://localhost:8080)
$root = $PSScriptRoot
Set-Location $root
Write-Host "Calculadora Dojo en http://localhost:8080/dojo-v2.1.html"
Write-Host "Desde el movil (misma WiFi): http://<IP-de-tu-PC>:8080/dojo-v2.1.html"
Write-Host "Pulsa Ctrl+C para detener."
python -m http.server 8080
