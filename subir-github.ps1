# Sube el proyecto a GitHub y activa Pages
$ErrorActionPreference = "Stop"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

Set-Location $PSScriptRoot

gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "No hay sesion en GitHub. Ejecuta primero:" -ForegroundColor Red
  Write-Host "  .\conectar-github.ps1" -ForegroundColor Yellow
  Write-Host ""
  exit 1
}

gh auth setup-git 2>$null

$repoName = "calculadora-dojo"
$owner = gh api user -q .login

Write-Host "Subiendo a github.com/$owner/$repoName ..." -ForegroundColor Cyan

$hasRemote = git remote get-url origin 2>$null
if ($LASTEXITCODE -ne 0) {
  gh repo view "$owner/$repoName" 2>$null
  if ($LASTEXITCODE -eq 0) {
    git remote add origin "https://github.com/$owner/$repoName.git"
  } else {
    gh repo create $repoName --private --source=. --remote=origin --push --description "Calculadora comercial Dojo (PWA + propuesta PDF)"
    if ($LASTEXITCODE -ne 0) { throw "No se pudo crear el repositorio." }
  }
}

if (-not (git remote get-url origin 2>$null)) {
  git remote add origin "https://github.com/$owner/$repoName.git"
}

git branch -M main 2>$null
git push -u origin main

gh api -X POST "repos/$owner/$repoName/pages" -f "build_type=legacy" -f "source[branch]=main" -f "source[path]=/" 2>$null

$pagesUrl = "https://$owner.github.io/$repoName/dojo-v2.1.html"
Write-Host ""
Write-Host "Repositorio: https://github.com/$owner/$repoName" -ForegroundColor Green
Write-Host "Calculadora (Pages, 1-2 min): $pagesUrl" -ForegroundColor Green
Write-Host ""
