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

# Load config from file
if (Test-Path $configPath) {
    try {
        $loadedConfig = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($loadedConfig.waiting_message) { $config.waiting_message = $loadedConfig.waiting_message }
        if ($loadedConfig.complete_message) { $config.complete_message = $loadedConfig.complete_message }
        if ($loadedConfig.permission_message) { $config.permission_message = $loadedConfig.permission_message }
        if ($loadedConfig.title) { $config.title = $loadedConfig.title }
        if ($loadedConfig.voice) { $config.voice = $loadedConfig.voice }
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
            # Use python -m edge_tts
            & $pythonCmd -m edge_tts --voice $VoiceName --text $Text --write-media $tempFile 2>&1 | Out-Null

            if (Test-Path $tempFile) {
                # Use Windows Media Player
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

                # Proper cleanup
                $mediaPlayer.Close()
                $mediaPlayer = $null

                # Cleanup temp file
                Start-Sleep -Milliseconds 200
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
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
        [string]$NotifyMessage
    )

    try {
        Add-Type -AssemblyName System.Windows.Forms
        $balloon = New-Object System.Windows.Forms.NotifyIcon
        $balloon.Icon = [System.Drawing.SystemIcons]::Information
        $balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
        $balloon.BalloonTipTitle = $NotifyTitle
        $balloon.BalloonTipText = $NotifyMessage
        $balloon.Visible = $true
        $balloon.ShowBalloonTip(5000)

        # Wait for notification to show then cleanup
        Start-Sleep -Milliseconds 5100
        $balloon.Dispose()
    }
    catch {
        # Log error instead of silent fail
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [NOTIFY] $_" | Out-File $logPath -Append
    }
}

# ============ Main ============
Play-EdgeTTS -Text $Message -VoiceName $Voice
Show-Notification -NotifyTitle $Title -NotifyMessage $Message

exit 0
