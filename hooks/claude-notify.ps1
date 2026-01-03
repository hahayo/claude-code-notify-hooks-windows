# Claude Code Windows Notification Hook
# Play TTS (Edge TTS) and show notification when Claude Code needs attention

param(
    [Parameter(Position=0)]
    [ValidateSet("waiting", "complete", "permission")]
    [string]$Mode = "waiting"
)

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $scriptDir "notify-config.json"
$logPath = Join-Path $env:TEMP "claude-notify-error.log"

# Default config
$config = @{
    waiting_message = "Claude is waiting for your input"
    complete_message = "Claude completed the task"
    permission_message = "Claude needs your permission"
    title = "Claude Code"
    notification_duration = 5000  # Notification display time in milliseconds
    # ============================================================
    # Edge TTS Voice Options (change "voice" value below)
    # ============================================================
    # Taiwan Chinese (Traditional):
    #   zh-TW-HsiaoChenNeural  - Female, natural and gentle
    #   zh-TW-HsiaoYuNeural    - Female
    #   zh-TW-YunJheNeural     - Male
    #
    # China Chinese (Simplified):
    #   zh-CN-XiaoxiaoNeural   - Female, lively and cute
    #   zh-CN-XiaoyiNeural     - Female, gentle
    #   zh-CN-YunyangNeural    - Male, news anchor style
    #
    # English:
    #   en-US-JennyNeural      - Female
    #   en-US-GuyNeural        - Male
    # ============================================================
    voice = "zh-CN-XiaoyiNeural"
}

# Load config from file with validation
if (Test-Path $configPath) {
    try {
        $loadedConfig = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json

        # Validate and load string values (max 200 chars)
        if ($loadedConfig.waiting_message -and $loadedConfig.waiting_message.Length -le 200) {
            $config.waiting_message = $loadedConfig.waiting_message
        }
        if ($loadedConfig.complete_message -and $loadedConfig.complete_message.Length -le 200) {
            $config.complete_message = $loadedConfig.complete_message
        }
        if ($loadedConfig.permission_message -and $loadedConfig.permission_message.Length -le 200) {
            $config.permission_message = $loadedConfig.permission_message
        }
        if ($loadedConfig.title -and $loadedConfig.title.Length -le 100) {
            $config.title = $loadedConfig.title
        }

        # Validate voice name format (alphanumeric with hyphens only)
        if ($loadedConfig.voice -and $loadedConfig.voice -match '^[a-zA-Z0-9\-]+$') {
            $config.voice = $loadedConfig.voice
        }

        # Validate notification_duration (positive integer, max 60 seconds)
        if ($loadedConfig.notification_duration -and
            $loadedConfig.notification_duration -is [int] -and
            $loadedConfig.notification_duration -gt 0 -and
            $loadedConfig.notification_duration -le 60000) {
            $config.notification_duration = $loadedConfig.notification_duration
        }
    }
    catch {
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [CONFIG] $_" | Out-File $logPath -Append
    }
}

# Select message based on mode
$Message = switch ($Mode) {
    "complete" { $config.complete_message }
    "permission" { $config.permission_message }
    default { $config.waiting_message }
}
$Title = $config.title
$Voice = $config.voice

# ============ Edge TTS Voice ============
function Play-EdgeTTS {
    param(
        [string]$Text,
        [string]$VoiceName
    )

    try {
        # Create temp file for audio
        $tempFile = Join-Path $env:TEMP "claude_notify_$(Get-Random).mp3"

        # Find Python command
        $pythonCmd = $null
        foreach ($cmd in @("py", "python", "python3")) {
            try {
                $testResult = & $cmd --version 2>&1
                if ($testResult -match "Python") {
                    $pythonCmd = $cmd
                    break
                }
            }
            catch { }
        }

        if ($pythonCmd) {
            # Check if edge_tts module is installed
            $moduleCheck = & $pythonCmd -c "import edge_tts" 2>&1
            if ($LASTEXITCODE -ne 0) {
                "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [TTS] edge-tts not installed. Run: pip install edge-tts --user" | Out-File $logPath -Append
                return
            }

            # Use python -m edge_tts
            $ttsOutput = & $pythonCmd -m edge_tts --voice $VoiceName --text $Text --write-media $tempFile 2>&1
            $ttsExitCode = $LASTEXITCODE

            # Validate edge-tts output
            if ($ttsExitCode -ne 0) {
                "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [TTS] edge-tts failed with exit code $ttsExitCode : $ttsOutput" | Out-File $logPath -Append
                return
            }

            if (-not (Test-Path $tempFile)) {
                "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [TTS] edge-tts did not create output file" | Out-File $logPath -Append
                return
            }

            $fileSize = (Get-Item $tempFile).Length
            if ($fileSize -eq 0) {
                "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [TTS] edge-tts created empty file" | Out-File $logPath -Append
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                return
            }

            # Use Windows Media Player with proper resource management
            $mediaPlayer = $null
            try {
                Add-Type -AssemblyName presentationCore
                $mediaPlayer = New-Object System.Windows.Media.MediaPlayer
                $mediaPlayer.Open([Uri]$tempFile)
                $mediaPlayer.Play()

                # Wait for audio to start
                Start-Sleep -Milliseconds 500

                # Wait for playback to complete (with timeout to prevent infinite loop)
                $timeout = 50  # Max 5 seconds
                while ($mediaPlayer.NaturalDuration.HasTimeSpan -eq $false -and $timeout -gt 0) {
                    Start-Sleep -Milliseconds 100
                    $timeout--
                }

                if ($timeout -gt 0 -and $mediaPlayer.NaturalDuration.HasTimeSpan) {
                    $duration = $mediaPlayer.NaturalDuration.TimeSpan.TotalMilliseconds
                    Start-Sleep -Milliseconds ($duration + 200)
                }
            }
            finally {
                # Ensure MediaPlayer is always disposed
                if ($null -ne $mediaPlayer) {
                    $mediaPlayer.Close()
                    # Note: MediaPlayer doesn't implement IDisposable, but setting to null helps GC
                    $mediaPlayer = $null
                }
            }

            # Cleanup temp file with retry mechanism
            $retryCount = 0
            $maxRetries = 5
            while ((Test-Path $tempFile) -and $retryCount -lt $maxRetries) {
                Start-Sleep -Milliseconds 200
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                $retryCount++
            }

            # Log warning if cleanup failed
            if (Test-Path $tempFile) {
                "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [TTS] Warning: Failed to cleanup temp file after $maxRetries attempts: $tempFile" | Out-File $logPath -Append
            }
        }
    }
    catch {
        # Log error instead of silent fail
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [TTS] $_" | Out-File $logPath -Append
    }
}

# ============ Windows Toast Notification ============
function Show-Notification {
    param(
        [string]$NotifyTitle,
        [string]$NotifyMessage,
        [int]$Duration = 5000
    )

    $balloon = $null
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $balloon = New-Object System.Windows.Forms.NotifyIcon
        $balloon.Icon = [System.Drawing.SystemIcons]::Information
        $balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
        $balloon.BalloonTipTitle = $NotifyTitle
        $balloon.BalloonTipText = $NotifyMessage
        $balloon.Visible = $true
        $balloon.ShowBalloonTip($Duration)

        # Wait for notification to show
        Start-Sleep -Milliseconds ($Duration + 100)
    }
    catch {
        # Log error instead of silent fail
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [NOTIFY] $_" | Out-File $logPath -Append
    }
    finally {
        # Ensure NotifyIcon is always disposed
        if ($null -ne $balloon) {
            $balloon.Dispose()
        }
    }
}

# ============ Main ============
Play-EdgeTTS -Text $Message -VoiceName $Voice
Show-Notification -NotifyTitle $Title -NotifyMessage $Message -Duration $config.notification_duration

exit 0
