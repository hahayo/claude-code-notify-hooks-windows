# Claude Code Windows Notification Hook
# Play TTS (Edge TTS) and show notification when Claude Code needs attention

param(
    [Parameter(Position=0)]
    [ValidateSet("waiting", "complete")]
    [string]$Mode = "waiting"
)

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $scriptDir "notify-config.json"

# Default config
$config = @{
    waiting_message = "Claude is waiting for your input"
    complete_message = "Claude completed the task"
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
        if ($loadedConfig.title) { $config.title = $loadedConfig.title }
        if ($loadedConfig.voice) { $config.voice = $loadedConfig.voice }
    }
    catch {
        # Use defaults if config fails to load
    }
}

# Select message based on mode
$Message = if ($Mode -eq "complete") { $config.complete_message } else { $config.waiting_message }
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
                # Use Windows Media Player COM object
                Add-Type -AssemblyName presentationCore
                $mediaPlayer = New-Object System.Windows.Media.MediaPlayer
                $mediaPlayer.Open([Uri]$tempFile)
                $mediaPlayer.Play()

                # Wait for audio to start
                Start-Sleep -Milliseconds 500

                # Wait for playback to complete (check duration)
                while ($mediaPlayer.NaturalDuration.HasTimeSpan -eq $false) {
                    Start-Sleep -Milliseconds 100
                }
                $duration = $mediaPlayer.NaturalDuration.TimeSpan.TotalMilliseconds
                Start-Sleep -Milliseconds ($duration + 200)

                $mediaPlayer.Close()

                # Cleanup
                Start-Sleep -Milliseconds 200
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        # Fallback to Windows SAPI if edge-tts fails
        try {
            Add-Type -AssemblyName System.Speech
            $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
            $synth.Speak($Text)
            $synth.Dispose()
        }
        catch {
            # Silent fail
        }
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
        # Silent fail for notification errors
    }
}

# ============ Main ============
Play-EdgeTTS -Text $Message -VoiceName $Voice
Show-Notification -NotifyTitle $Title -NotifyMessage $Message

exit 0
