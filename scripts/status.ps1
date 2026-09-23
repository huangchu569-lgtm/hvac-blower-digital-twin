# status.ps1 - Show system status

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "===== Container status =====" -ForegroundColor Cyan
docker compose ps

Write-Host "`n===== Recent python-edge logs =====" -ForegroundColor Cyan
docker compose logs --tail=10 python-edge | Select-String "DATA|ALERT"
