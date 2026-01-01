# Claude Code Notification Hooks - Windows Uninstaller
# Run: powershell -ExecutionPolicy Bypass -File uninstall.ps1

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Claude Code Notification Hooks" -ForegroundColor Cyan
Write-Host "  Windows Uninstaller" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Paths
$claudeDir = Join-Path $env:USERPROFILE ".claude"
$hooksDir = Join-Path $claudeDir "hooks"
$settingsPath = Join-Path $claudeDir "settings.json"

# 1. Remove hook scripts
Write-Host "[1/2] Removing hook scripts..." -ForegroundColor Yellow

$notifyScript = Join-Path $hooksDir "claude-notify.ps1"
$configFile = Join-Path $hooksDir "notify-config.json"

if (Test-Path $notifyScript) {
    Remove-Item $notifyScript -Force
    Write-Host "      Removed: claude-notify.ps1" -ForegroundColor Green
}

if (Test-Path $configFile) {
    Remove-Item $configFile -Force
    Write-Host "      Removed: notify-config.json" -ForegroundColor Green
}

# 2. Remove hooks from settings.json
Write-Host "[2/2] Removing hooks from settings.json..." -ForegroundColor Yellow

if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json

    # Convert to hashtable
    $settingsHash = @{}
    $settings.PSObject.Properties | ForEach-Object {
        $settingsHash[$_.Name] = $_.Value
    }

    # Remove hooks
    if ($settingsHash.ContainsKey("hooks")) {
        $settingsHash.Remove("hooks")
        $settingsHash | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
        Write-Host "      Removed hooks from settings.json" -ForegroundColor Green
    }
    else {
        Write-Host "      No hooks found in settings.json" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Uninstallation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Restart Claude Code to apply changes." -ForegroundColor Yellow
Write-Host ""
