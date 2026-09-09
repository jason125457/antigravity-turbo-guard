# Antigravity Turbo Guard - Windows Uninstaller
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "正在解除安裝 Antigravity Turbo Guard..." -ForegroundColor Yellow

$userHome = [System.Environment]::GetFolderPath('UserProfile')
$geminiConfigDir = Join-Path $userHome ".gemini\config"
$pluginDir = Join-Path $geminiConfigDir "plugins\custom-commands"
$globalHooksPath = Join-Path $geminiConfigDir "hooks.json"

if (Test-Path $globalHooksPath) {
    Remove-Item -Path $globalHooksPath -Force -ErrorAction SilentlyContinue
}

if (Test-Path $pluginDir) {
    Remove-Item -Path $pluginDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "✅ 已成功移除 Hook 與自訂插件！" -ForegroundColor Green
Write-Host "💡 提示：若需還原預設確認彈窗，請至 Settings 將 Auto-Execution 改回每次確認。" -ForegroundColor Cyan
