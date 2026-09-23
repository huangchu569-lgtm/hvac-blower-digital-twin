# stop.ps1 - Stop all services (keep data volumes)

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "===== Stopping HVAC Blower Digital Twin =====" -ForegroundColor Cyan
docker compose down
Write-Host "`nAll containers stopped. Data volumes preserved." -ForegroundColor Green