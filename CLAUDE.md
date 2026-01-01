# Claude Code Notify Hooks - 安裝指南

這是一個 Claude Code 的 hooks 套件，當 Claude Code 完成任務或等待用戶輸入時，會用 Edge TTS 語音和桌面通知提醒用戶。

## 當用戶要求安裝時，請執行以下步驟：

### 1. 安裝 edge-tts Python 套件

```powershell
py -m pip install edge-tts
```

### 2. 建立 hooks 目錄

```powershell
mkdir -p "$env:USERPROFILE\.claude\hooks"
```

### 3. 複製 hooks 檔案

將本專案中的以下檔案複製到用戶的 `.claude/hooks/` 目錄：
- `hooks/claude-notify.ps1` → `%USERPROFILE%\.claude\hooks\claude-notify.ps1`
- `hooks/notify-config.json` → `%USERPROFILE%\.claude\hooks\notify-config.json`

### 4. 更新 settings.json

在 `%USERPROFILE%\.claude\settings.json` 中加入 hooks 配置：

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File \"C:\\Users\\USERNAME\\.claude\\hooks\\claude-notify.ps1\" waiting",
            "timeout": 15
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File \"C:\\Users\\USERNAME\\.claude\\hooks\\claude-notify.ps1\" complete",
            "timeout": 15
          }
        ]
      }
    ]
  }
}
```

**注意**：請將 `USERNAME` 替換為用戶的 Windows 用戶名。

### 5. 測試

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\hooks\claude-notify.ps1" waiting
```

### 6. 重啟 Claude Code

告知用戶需要重啟 Claude Code 讓 hooks 生效。

---

## 自訂設定

用戶可以編輯 `%USERPROFILE%\.claude\hooks\notify-config.json` 來自訂：

- `waiting_message`: 等待輸入時的提示訊息
- `complete_message`: 任務完成時的提示訊息
- `voice`: Edge TTS 語音（預設：`zh-CN-XiaoyiNeural`）

### 可用語音選項

| Voice | 說明 |
|-------|------|
| `zh-TW-HsiaoChenNeural` | 台灣女聲，自然溫柔 |
| `zh-TW-HsiaoYuNeural` | 台灣女聲 |
| `zh-TW-YunJheNeural` | 台灣男聲 |
| `zh-CN-XiaoxiaoNeural` | 中國女聲，活潑可愛 |
| `zh-CN-XiaoyiNeural` | 中國女聲，溫柔（預設）|
| `zh-CN-YunyangNeural` | 中國男聲，主播風格 |
| `en-US-JennyNeural` | 英文女聲 |
| `en-US-GuyNeural` | 英文男聲 |

---

## 快速安裝（替代方案）

如果用戶不想手動安裝，可以直接執行：

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

這會自動完成所有安裝步驟。
