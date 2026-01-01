# Claude Code Notification Hooks - Windows Installer
# Run: powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Claude Code Notification Hooks" -ForegroundColor Cyan
Write-Host "  Windows Installer (Edge TTS)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Paths
$claudeDir = Join-Path $env:USERPROFILE ".claude"
$hooksDir = Join-Path $claudeDir "hooks"
$settingsPath = Join-Path $claudeDir "settings.json"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceHooksDir = Join-Path $scriptDir "hooks"

# 1. Check Python and install edge-tts
Write-Host "[1/5] Checking Python and edge-tts..." -ForegroundColor Yellow

$pythonCmd = $null
foreach ($cmd in @("python", "python3", "py")) {
    try {
        $version = & $cmd --version 2>&1
        if ($version -match "Python") {
            $pythonCmd = $cmd
            Write-Host "      Found: $version" -ForegroundColor Green
            break
        }
    }
    catch { }
}

if (-not $pythonCmd) {
    Write-Host "      Python not found!" -ForegroundColor Red
    Write-Host "      Please install Python from https://www.python.org/downloads/" -ForegroundColor Yellow
    Write-Host "      Make sure to check 'Add Python to PATH' during installation." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Install edge-tts
Write-Host "      Installing edge-tts..." -ForegroundColor Gray
& $pythonCmd -m pip install edge-tts --quiet --disable-pip-version-check 2>&1 | Out-Null

# Verify edge-tts installation
$edgeTtsPath = & $pythonCmd -c "import shutil; print(shutil.which('edge-tts') or '')" 2>&1
if (-not $edgeTtsPath -or $edgeTtsPath -eq "None") {
    # Try to find it in Python Scripts folder
    $pythonScripts = & $pythonCmd -c "import sys; print(sys.prefix + '\\Scripts')" 2>&1
    $env:Path = "$pythonScripts;$env:Path"
}

try {
    $null = & edge-tts --version 2>&1
    Write-Host "      edge-tts installed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "      Warning: edge-tts may not be in PATH" -ForegroundColor Yellow
    Write-Host "      You may need to restart your terminal" -ForegroundColor Yellow
}

# 2. Create directories
Write-Host "[2/5] Creating directories..." -ForegroundColor Yellow
if (-not (Test-Path $claudeDir)) {
    New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
    Write-Host "      Created: $claudeDir" -ForegroundColor Green
}
if (-not (Test-Path $hooksDir)) {
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    Write-Host "      Created: $hooksDir" -ForegroundColor Green
}
Write-Host "      Done!" -ForegroundColor Green

# 3. Copy hook scripts
Write-Host "[3/5] Copying hook scripts..." -ForegroundColor Yellow
Copy-Item -Path (Join-Path $sourceHooksDir "claude-notify.ps1") -Destination $hooksDir -Force
Copy-Item -Path (Join-Path $sourceHooksDir "notify-config.json") -Destination $hooksDir -Force
Write-Host "      Copied: claude-notify.ps1" -ForegroundColor Green
Write-Host "      Copied: notify-config.json" -ForegroundColor Green

# 4. Update settings.json
Write-Host "[4/5] Configuring hooks in settings.json..." -ForegroundColor Yellow

$notifyScript = Join-Path $hooksDir "claude-notify.ps1"

$hooksConfig = @{
    Notification = @(
        @{
            matcher = "idle_prompt"
            hooks = @(
                @{
                    type = "command"
                    command = "powershell -ExecutionPolicy Bypass -File `"$notifyScript`" waiting"
                    timeout = 15
                }
            )
        }
    )
    Stop = @(
        @{
            hooks = @(
                @{
                    type = "command"
                    command = "powershell -ExecutionPolicy Bypass -File `"$notifyScript`" complete"
                    timeout = 15
                }
            )
        }
    )
}

if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $settingsHash = @{}
    $settings.PSObject.Properties | ForEach-Object {
        $settingsHash[$_.Name] = $_.Value
    }
    $settingsHash["hooks"] = $hooksConfig
    $settingsHash | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
    Write-Host "      Updated existing settings.json" -ForegroundColor Green
}
else {
    $newSettings = @{
        permissions = @{
            allow = @()
            deny = @()
        }
        hooks = $hooksConfig
    }
    $newSettings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
    Write-Host "      Created new settings.json" -ForegroundColor Green
}

# 5. Test
Write-Host "[5/5] Testing notification..." -ForegroundColor Yellow
Write-Host ""

try {
    & powershell -ExecutionPolicy Bypass -File $notifyScript "waiting"
    Write-Host "      Test passed!" -ForegroundColor Green
}
catch {
    Write-Host "      Test failed: $_" -ForegroundColor Red
    Write-Host "      You may need to restart your terminal and try again." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Restart Claude Code to activate hooks." -ForegroundColor Yellow
Write-Host ""
Write-Host "Customize settings:" -ForegroundColor White
Write-Host "  Edit: $hooksDir\notify-config.json" -ForegroundColor Gray
Write-Host ""
Write-Host "Available Edge TTS voices:" -ForegroundColor White
Write-Host "  Taiwan:  zh-TW-HsiaoChenNeural, zh-TW-HsiaoYuNeural, zh-TW-YunJheNeural" -ForegroundColor Gray
Write-Host "  China:   zh-CN-XiaoxiaoNeural, zh-CN-XiaoyiNeural, zh-CN-YunyangNeural" -ForegroundColor Gray
Write-Host "  English: en-US-JennyNeural, en-US-GuyNeural" -ForegroundColor Gray
Write-Host ""
Write-Host "Current voice: zh-CN-XiaoyiNeural (China Female, gentle)" -ForegroundColor Cyan
Write-Host ""
