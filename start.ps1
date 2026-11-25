
# Barcode World - Chatwoot Development Startup
# File: start.ps1

# to run 
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# .\start.ps1

$ErrorActionPreference = "Stop"

Set-Location $PSScriptRoot

Write-Host "`n==================================" -ForegroundColor Cyan
Write-Host "  BARCODE WORLD - CHATWOOT" -ForegroundColor Cyan
Write-Host "==================================`n" -ForegroundColor Cyan

# Check Docker installation
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Docker is not installed." -ForegroundColor Red
    exit 1
}

# Check Docker Desktop
docker info *> $null

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Start Docker Desktop first." -ForegroundColor Red
    exit 1
}

# Check Docker Compose
docker compose version

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker Compose is unavailable." -ForegroundColor Red
    exit 1
}

# Check environment configuration
if (-not (Test-Path ".env")) {
    Write-Host "ERROR: .env file is missing." -ForegroundColor Red
    Write-Host "Copy .env.example to .env and configure it."
    exit 1
}

# Check Compose configuration
docker compose config --quiet

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Invalid Docker Compose configuration." -ForegroundColor Red
    exit 1
}

Write-Host "`nStarting Chatwoot services..." -ForegroundColor Yellow

docker compose up -d postgres redis mailhog

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Infrastructure services failed." -ForegroundColor Red
    exit 1
}

docker compose up -d rails sidekiq vite

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Application services failed." -ForegroundColor Red
    exit 1
}

Write-Host "`nContainer status:" -ForegroundColor Cyan
docker compose ps

Write-Host "`n==================================" -ForegroundColor Green
Write-Host "  Startup commands completed!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green

Write-Host "`nChatwoot: http://localhost:3000"
Write-Host "MailHog:  http://localhost:8025"

Write-Host "`nThe application may need time to become ready."
Write-Host "To inspect logs:"
Write-Host "docker compose logs -f rails vite sidekiq"
