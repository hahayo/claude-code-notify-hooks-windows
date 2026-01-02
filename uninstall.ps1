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

# 2. Remove only our hooks from settings.json (preserve user's other hooks)
Write-Host "[2/2] Removing notification hooks from settings.json..." -ForegroundColor Yellow

# Helper function to check if a hook entry belongs to this project
function Test-IsOurHook {
    param($hookEntry)
    if ($hookEntry.hooks) {
        foreach ($h in $hookEntry.hooks) {
            if ($h.command -and $h.command -match "claude-notify\.ps1") {
                return $true
            }
        }
    }
    return $false
}

if (Test-Path $settingsPath) {
    try {
        $settings = Get-Content $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json

        if ($settings.hooks) {
            # Convert to hashtable
            $settingsHash = @{}
            $settings.PSObject.Properties | ForEach-Object {
                $settingsHash[$_.Name] = $_.Value
            }

            # Filter out our hooks from each event type
            $newHooks = @{}
            $removedCount = 0

            foreach ($eventType in $settings.hooks.PSObject.Properties.Name) {
                $filteredEntries = @()
                foreach ($entry in $settings.hooks.$eventType) {
                    if (Test-IsOurHook $entry) {
                        $removedCount++
                    }
                    else {
                        $filteredEntries += $entry
                    }
                }
                if ($filteredEntries.Count -gt 0) {
                    $newHooks[$eventType] = $filteredEntries
                }
            }

            # Update or remove hooks section
            if ($newHooks.Count -gt 0) {
                $settingsHash["hooks"] = $newHooks
            }
            else {
                $settingsHash.Remove("hooks")
            }

            $settingsHash | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8

            if ($removedCount -gt 0) {
                Write-Host "      Removed $removedCount notification hook(s)" -ForegroundColor Green
                Write-Host "      Other hooks preserved" -ForegroundColor Gray
            }
            else {
                Write-Host "      No notification hooks found" -ForegroundColor Gray
            }
        }
        else {
            Write-Host "      No hooks found in settings.json" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "      Error parsing settings.json: $_" -ForegroundColor Red
        Write-Host "      Please manually remove hooks from settings.json" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Uninstallation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Restart Claude Code to apply changes." -ForegroundColor Yellow
Write-Host ""
