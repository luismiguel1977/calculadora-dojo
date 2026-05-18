# Conectar este PC con tu cuenta de GitHub (sin contraseña por email)
$ErrorActionPreference = "Stop"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

Write-Host ""
Write-Host "=== Conectar con GitHub ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "GitHub NO envia ninguna clave por correo." -ForegroundColor Yellow
Write-Host "Si te pidio contrasena al hacer push, es normal que falle:" -ForegroundColor Yellow
Write-Host "ya no se usa la contrasena de la cuenta para Git." -ForegroundColor Yellow
Write-Host ""
Write-Host "Pasos que veras ahora:" -ForegroundColor White
Write-Host "  1. Pregunta: GitHub.com -> Enter"
Write-Host "  2. HTTPS -> Enter"
Write-Host "  3. Login with a web browser -> Enter (recomendado)"
Write-Host "  4. Se abre el navegador O te da un codigo de 8 caracteres"
Write-Host "  5. En https://github.com/login/device pegas el codigo"
Write-Host "  6. Autorizas la app GitHub CLI"
Write-Host ""
Write-Host "Si no se abre el navegador, copia el codigo y abre:" -ForegroundColor White
Write-Host "  https://github.com/login/device" -ForegroundColor Green
Write-Host ""
Read-Host "Pulsa Enter para empezar"

gh auth login -h github.com -p https -w

Write-Host ""
Write-Host "Configurando Git para usar GitHub CLI..." -ForegroundColor Cyan
gh auth setup-git

Write-Host ""
gh auth status
Write-Host ""
Write-Host "Listo. Ahora ejecuta:  .\subir-github.ps1" -ForegroundColor Green
Write-Host ""
