# Antigravity Turbo Guard：Claude Code 工作規則

Google Antigravity 的 hook 外掛：一般操作自動放行，高危指令與敏感檔案強制跳確認。核心是 `auto_approve.py`，其餘是三個平台的安裝與解除安裝腳本。說明見 `README.md`。

## 不能違反

- 攔截一律回傳 `force_ask`，不能用 `ask`（Turbo 模式下 `ask` 會被自動放行，等於沒攔）。
- 這是安全工具，拿不準時寧可多攔：新增放行規則之前，先確認不會放過刪除、格式化、讀取金鑰這幾類。調整黑名單時，同時檢查誤擋（例如 `npm run format` 不該被當成磁碟格式化）。
- 所有 JSON 輸出不帶 UTF-8 BOM；Windows 的輸入輸出編碼要維持 UTF-8。
- 這個 repo 是公開的，README 的一鍵安裝直接抓 `main` 的 raw 檔：推到 `main` 就等於發布給所有使用者，推之前要使用者同意。

## 改完要做

- `install.ps1`、`install.sh`、`install.bat` 三者行為要一致；改一個就檢查另外兩個，解除安裝腳本也要能還原新寫入的設定。
- 沒有自動化測試。用 README「驗證與測試」的三個情境（一般操作、高危刪除、敏感金鑰）在 Antigravity 開新對話實測；改 `auto_approve.py` 時另外用假的 hook 輸入直接餵腳本，確認回傳的 decision。
- 雲端 session 沒有 Antigravity，只能做腳本層的檢查，實機驗證要請使用者做。

## 慣例

- commit：英文 Conventional Commits（`feat:`、`fix:`）。
- README 的防護清單要與 `auto_approve.py` 的實際規則一致，改規則就同步改 README。
