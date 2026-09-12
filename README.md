# Antigravity Turbo Guard 🚀🛡️

> **適用於 Google Antigravity 的極速免確認與高危指令強制攔截守護外掛**  
> *Zero-prompt auto approval with an unbypassable `force_ask` security gate for Google Antigravity.*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-brightgreen.svg)]()
[![Antigravity](https://img.shields.io/badge/Antigravity-2.0%2B-purple.svg)]()

---

## 🌟 為什麼需要 Turbo Guard？

在 Google Antigravity 開發環境中：
1. **預設模式**：每個終端指令或檔案讀寫都會頻繁彈窗詢問確認，嚴重中斷流暢度。
2. **只開 Turbo 模式**：雖然免去了確認彈窗，但系統會「無條件盲跑」，若 AI 誤執行了破壞性指令（如 `rm`、`del`、`Remove-Item`）或讀取了私鑰金鑰（如 `.env`、`id_rsa`），將面臨巨大風險！
3. **傳統開源 Hook 的致命盲點**：
   - 傳統 Hook 腳本回傳 `"decision": "ask"`。
   - 根據 Antigravity 官方生命週期規範：**`"ask"` 會遵循 Turbo 模式的快取原則**。這意味著一旦開啟 Turbo Mode，`"ask"` 會直接被系統自動放行，安全煞車形同虛設！

**Antigravity Turbo Guard 徹底解決了這個問題！**  
我們採用官方規範中最高優先級的 **`"force_ask"`** 機制：
* 一般指令 ➔ 秒速自動放行（Zero Prompt）。
* 破壞性指令 / 敏感金鑰 ➔ **強制彈窗確認（`force_ask` 強制覆蓋 Turbo 模式，連 Turbo 都無法略過！）**。

---

## ✨ 核心特色

- ⚡ **Turbo 模式極速無阻**：一般開發指令（`git status`、`npm install`、一般代碼讀寫）秒速放行，零打擾。
- 🔌 **MCP 工具極速授權與零彈窗**：深度適配 Model Context Protocol (MCP) 外掛（如 Serena、Context7、GitHub、Playwright 等），自動預先授權各類查詢與代碼工具，免除頻繁點擊「Always Allow」的困擾。
- 🛑 **絕對把關的安全煞車 (`force_ask`)**：命中高危黑名單時，強制喚出介面確認彈窗，保障本機安全。
- 🪟 **原生支援 Windows & PowerShell**：
  - 深度適配 PowerShell `Remove-Item` 與別名指令。
  - 磁碟格式化指令辨識（智慧排除 `npm run format` 等排版指令，絕不誤擋）。
  - Windows UTF-8 輸入輸出流編碼修復。
- 🌐 **全域 + 專案雙層生效**：即使在「無工作區的一般對話」中也能完美運作。
- 📋 **完整稽核日誌**：每次工具調用細節均寫入 `~/.gemini/antigravity/scratch/hook_log.txt`，可隨時追蹤審查。

---

## 🛡️ 安全防護涵蓋清單

### 1. 敏感憑證與金鑰保護
AI 嘗試讀取或寫入下列檔案時，**強制彈窗確認**：
- 環境設定檔：`.env`、`.env.local`、`.env.production` 等
- SSH 私鑰：`id_rsa`、`id_ed25519`、`id_ecdsa`、`id_dsa`
- SSL 憑證金鑰：`.pem`、`.key`、`.pfx`、`.p12`、`.keystore`
- 套件與 Git 憑證：`.git-credentials`、`.npmrc`

### 2. 破壞性系統指令防禦
AI 嘗試於終端機執行下列命令時，**強制彈窗確認**：
- 刪除操作：`rm `、`rmdir`、`del `、`erase `、`rd `、PowerShell `Remove-Item`
- 磁碟抹除：`format [a-z]:`、`format-volume`、`mkfs`（排除一般專案 format script）
- 資料庫高危命令：`drop database`、`drop table`
- 系統控制：`shutdown`、`reboot`

### 3. 高危 MCP 操作防禦
AI 嘗試透過 MCP 執行破壞性遠端操作時，**強制彈窗確認**：
- GitHub 刪除操作：`delete_repository`、`delete_file`

---

## 🚀 快速安裝 (One-Click Install)

### Windows (PowerShell)
以使用者身分開啟 PowerShell，直接貼上並執行：
```powershell
irm https://raw.githubusercontent.com/jason125457/antigravity-turbo-guard/main/install.ps1 | iex
```

*或者複製本倉庫後於專案目錄執行：*
```powershell
.\install.ps1
```

### macOS / Linux (Bash)
終端機執行：
```bash
curl -fsSL https://raw.githubusercontent.com/jason125457/antigravity-turbo-guard/main/install.sh | bash
```

---

## 🧪 驗證與測試

安裝完成後，請在 Antigravity 中點擊 **`+ New Conversation`（開新對話）**，輸入以下測試：

| 測試情境 | 測試指令範例 | 預期表現 |
| :--- | :--- | :--- |
| **一般操作** | `請執行 git status` | ⚡ 0 秒自動執行，無任何彈窗干擾 |
| **高危刪除** | `請執行 del test.txt` | 🛑 立刻煞車，彈出確認視窗等您點擊 |
| **敏感金鑰** | `請讀取 .env 檔案` | 🛑 立刻煞車，彈出確認視窗等您點擊 |

---

## 🛑 解除安裝

若未來想恢復原本每個步驟都手動點擊確認的預設行為：

### Windows
```powershell
.\uninstall.ps1
```
或直接刪除設定檔案：
```powershell
Remove-Item -Path "$env:USERPROFILE\.gemini\config\hooks.json" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:USERPROFILE\.gemini\config\plugins\custom-commands" -Recurse -Force -ErrorAction SilentlyContinue
```

### macOS / Linux
```bash
bash uninstall.sh
```

---

## 📄 授權條款 (License)

本專案採用 [MIT License](LICENSE) 授權。歡迎自由轉發、改進與分享！
