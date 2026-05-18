# Sube el proyecto a GitHub y activa Pages (ejecutar tras: gh auth login)
$ErrorActionPreference = "Stop"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

Set-Location $PSScriptRoot

gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Primero inicia sesion en GitHub:" -ForegroundColor Yellow
  gh auth login -h github.com -p https -w
}

$repoName = "calculadora-dojo"
$exists = gh repo view $repoName 2>$null
if ($LASTEXITCODE -ne 0) {
  gh repo create $repoName --public --source=. --remote=origin --description "Calculadora comercial Dojo (PWA + propuesta PDF)"
  git push -u origin main
} else {
  git remote get-url origin 2>$null
  if ($LASTEXITCODE -ne 0) { gh repo set-default $repoName; git remote add origin (gh repo view $repoName --json url -q .url) }
  git push -u origin main
}

$owner = gh api user -q .login
gh api -X POST "repos/$owner/$repoName/pages" -f "build_type=legacy" -f "source[branch]=main" -f "source[path]=/" 2>$null

$pagesUrl = "https://$owner.github.io/$repoName/dojo-v2.1.html"
Write-Host ""
Write-Host "Repositorio: https://github.com/$owner/$repoName" -ForegroundColor Green
Write-Host "App (Pages, puede tardar 1-2 min): $pagesUrl" -ForegroundColor Green
