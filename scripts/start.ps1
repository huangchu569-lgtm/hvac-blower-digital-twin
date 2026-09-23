# start.ps1 - One-click start for HVAC Blower Digital Twin

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "===== HVAC Blower Digital Twin =====" -ForegroundColor Cyan
Write-Host "Project root: $root" -ForegroundColor Gray

# 1. Check Docker engine
Write-Host "`n[1/4] Checking Docker engine..." -ForegroundColor Yellow
try {
    docker version --format '{{.Server.Version}}' | Out-Null
    Write-Host "  Docker engine OK" -ForegroundColor Green
} catch {
    Write-Host "  Docker not running. Trying to launch Docker Desktop..." -ForegroundColor Yellow
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -ErrorAction SilentlyContinue
    Write-Host "  Waiting for Docker (up to 60s)..." -ForegroundColor Yellow
    $ok = $false
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 2
        try {
            docker version --format '{{.Server.Version}}' | Out-Null
            $ok = $true
            break
        } catch {}
    }
    if (-not $ok) {
        Write-Host "  Docker failed to start. Please open Docker Desktop manually." -ForegroundColor Red
        exit 1
    }
    Write-Host "  Docker engine ready" -ForegroundColor Green
}

# 2. Start all services
Write-Host "`n[2/4] Starting services..." -ForegroundColor Yellow
docker compose up -d mqtt influxdb python-edge node-red grafana

# 3. Wait for containers
Write-Host "`n[3/4] Waiting for containers..." -ForegroundColor Yellow
Start-Sleep -Seconds 8
docker compose ps

# 4. Print access URLs
Write-Host "`n[4/4] Access URLs:" -ForegroundColor Cyan
Write-Host "  Node-RED editor:  http://localhost:1880" -ForegroundColor White
Write-Host "  Node-RED UI:      http://localhost:1880/ui" -ForegroundColor White
Write-Host "  Grafana:          http://localhost:3000   (admin/admin)" -ForegroundColor White
Write-Host "  InfluxDB:         http://localhost:8086   (admin/adminpass)" -ForegroundColor White
Write-Host "  MQTT broker:      localhost:1883" -ForegroundColor White
Write-Host "`nStartup complete." -ForegroundColor Green