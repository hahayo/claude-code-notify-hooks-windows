# Claude Code Notify Hooks (Windows)

> **Edge TTS 語音 + 桌面通知提醒**，讓你在多開 Claude Code sessions 時不再錯過任何等待輸入的狀態！

靈感來源：[@ateku129 的 Threads 貼文](https://www.threads.com/@ateku129/post/DS4KbEZj_1H)（原作者是 MacOS 版本，本專案為 Windows 移植版）

---

## Demo

當 Claude Code 完成任務或等待你輸入時：

- 播放 Edge TTS 語音：「Claude 在等你回覆喔」（自然人聲）
- 顯示 Windows 桌面通知

---

## 功能特色

| 功能 | 說明 |
|------|------|
| **Edge TTS 語音** | 使用 Microsoft Edge 神經網路語音，聲音自然不機械 |
| **多種聲線** | 支援台灣中文、中國中文、英文等多種聲線 |
| **桌面通知** | Windows Balloon Notification |
| **可自訂訊息** | 修改 JSON 配置檔即可自訂提醒文字 |
| **一鍵安裝** | PowerShell 腳本自動安裝 edge-tts 並配置 |

---

## 系統需求

- Windows 10 / 11
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- **Python 3.8+**（用於 edge-tts）
- 網路連線（Edge TTS 需要連網）

### 安裝 Python

如果尚未安裝 Python：
1. 前往 [python.org/downloads](https://www.python.org/downloads/)
2. 下載並安裝 Python
3. **重要**：安裝時勾選 `Add Python to PATH`

---

## 安裝方式

### 方法一：快速安裝（推薦）

```powershell
# 1. Clone 專案
git clone https://github.com/hahayo/claude-code-notify-hooks-windows.git

# 2. 進入資料夾
cd claude-code-notify-hooks-windows

# 3. 執行安裝腳本（會自動安裝 edge-tts）
powershell -ExecutionPolicy Bypass -File install.ps1
```

### 方法二：手動下載

1. 點擊本頁面右上角的 **Code** → **Download ZIP**
2. 解壓縮到任意位置
3. 開啟 PowerShell，進入解壓縮的資料夾
4. 執行：
   ```powershell
   powershell -ExecutionPolicy Bypass -File install.ps1
   ```

### 方法三：完全手動安裝

<details>
<summary>點擊展開手動安裝步驟</summary>

1. 安裝 edge-tts：
   ```powershell
   pip install edge-tts --user
   ```

2. 建立資料夾：`%USERPROFILE%\.claude\hooks\`

3. 複製 `hooks/claude-notify.ps1` 和 `hooks/notify-config.json` 到上述資料夾

4. 編輯 `%USERPROFILE%\.claude\settings.json`，加入以下內容：

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File \"C:\\Users\\YOUR_USERNAME\\.claude\\hooks\\claude-notify.ps1\" waiting",
            "timeout": 15
          }
        ]
      },
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File \"C:\\Users\\YOUR_USERNAME\\.claude\\hooks\\claude-notify.ps1\" permission",
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
            "command": "powershell -ExecutionPolicy Bypass -File \"C:\\Users\\YOUR_USERNAME\\.claude\\hooks\\claude-notify.ps1\" complete",
            "timeout": 15
          }
        ]
      }
    ]
  }
}
```

> 記得把 `YOUR_USERNAME` 換成你的 Windows 使用者名稱

</details>

---

## 安裝完成後

**重新啟動 Claude Code** 讓 hooks 生效。

之後每當 Claude Code：
- **等待你輸入** → 語音說「Claude 在等你回覆喔」
- **需要確認命令** → 語音說「Claude 需要你的確認喔」
- **完成任務** → 語音說「Claude 完成任務囉」

---

## 自訂設定

編輯 `%USERPROFILE%\.claude\hooks\notify-config.json`：

```json
{
  "waiting_message": "Claude 在等你回覆喔",
  "complete_message": "Claude 完成任務囉",
  "permission_message": "Claude 需要你的確認喔",
  "title": "Claude Code",
  "voice": "zh-CN-XiaoyiNeural"
}
```

---

## Edge TTS 可用聲線

### 台灣中文 (Traditional Chinese)

| Voice | 說明 |
|-------|------|
| `zh-TW-HsiaoChenNeural` | 女聲，自然溫柔 |
| `zh-TW-HsiaoYuNeural` | 女聲 |
| `zh-TW-YunJheNeural` | 男聲 |

### 中國中文 (Simplified Chinese)

| Voice | 說明 |
|-------|------|
| `zh-CN-XiaoxiaoNeural` | 女聲，活潑可愛 |
| `zh-CN-XiaoyiNeural` | 女聲，溫柔 **(預設)** |
| `zh-CN-YunyangNeural` | 男聲，新聞主播風格 |

### 英文 (English)

| Voice | 說明 |
|-------|------|
| `en-US-JennyNeural` | Female |
| `en-US-GuyNeural` | Male |

### 試聽聲音

可以在以下網站試聽各種聲線：
- [tts.travisvn.com](https://tts.travisvn.com/)
- [edge-tts.com](https://edge-tts.com/)
- [Hugging Face Demo](https://huggingface.co/spaces/innoai/Edge-TTS-Text-to-Speech)

---

## 解除安裝

```powershell
powershell -ExecutionPolicy Bypass -File uninstall.ps1
```

或手動刪除：
1. 刪除 `%USERPROFILE%\.claude\hooks\claude-notify.ps1`
2. 刪除 `%USERPROFILE%\.claude\hooks\notify-config.json`
3. 從 `%USERPROFILE%\.claude\settings.json` 移除 `hooks` 區塊

---

## 檔案結構

```
claude-code-notify-hooks-windows/
├── install.ps1               # 一鍵安裝腳本（含 edge-tts 安裝）
├── uninstall.ps1             # 一鍵解除安裝腳本
├── README.md                 # 本文件
├── LICENSE                   # MIT License
└── hooks/
    ├── claude-notify.ps1     # 主要通知腳本
    └── notify-config.json    # 訊息與聲線設定檔
```

---

## 常見問題

### Q: 沒有聽到語音？

**A:**
1. 確認有網路連線（Edge TTS 需要連網）
2. 確認 Python 已安裝且在 PATH 中
3. 嘗試手動測試：
   ```powershell
   edge-tts --voice zh-CN-XiaoyiNeural --text "測試" --write-media test.mp3
   ```

### Q: 安裝時顯示 Python not found？

**A:**
1. 安裝 Python：[python.org/downloads](https://www.python.org/downloads/)
2. 安裝時務必勾選 `Add Python to PATH`
3. 重新開啟 PowerShell 後再執行安裝腳本

### Q: 通知沒有顯示？

**A:** 確認 Windows 通知已開啟：
- 設定 → 系統 → 通知

### Q: 想暫時關閉提醒？

**A:** 在 `%USERPROFILE%\.claude\settings.json` 中刪除 `hooks` 區塊，然後重啟 Claude Code。

### Q: 如何只要通知不要語音？

**A:** 編輯 `claude-notify.ps1`，在最後面把 `Play-EdgeTTS` 那行註解掉：
```powershell
# Play-EdgeTTS -Text $Message -VoiceName $Voice
Show-Notification -NotifyTitle $Title -NotifyMessage $Message
```

---

## 相關連結

- [Claude Code 官方文件](https://docs.anthropic.com/en/docs/claude-code)
- [Claude Code Hooks 文件](https://docs.anthropic.com/en/docs/claude-code/hooks)
- [edge-tts GitHub](https://github.com/rany2/edge-tts)
- [原始靈感 - @ateku129 Threads](https://www.threads.com/@ateku129/post/DS4KbEZj_1H)

---

## Contributing

歡迎提交 Issue 和 Pull Request！

---

## License

MIT License - 詳見 [LICENSE](LICENSE) 檔案
