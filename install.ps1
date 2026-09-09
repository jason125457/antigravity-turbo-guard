# Antigravity Turbo Guard - Windows One-Click Installer
# Run in PowerShell: irm https://raw.githubusercontent.com/jason125457/antigravity-turbo-guard/main/install.ps1 | iex
# Or run locally: powershell -ExecutionPolicy Bypass -File .\install.ps1

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   🚀 Antigravity Turbo Guard 安裝程式 (Windows)   " -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan

# 1. 偵測 Python
Write-Host "`n[1/6] 檢查 Python 環境..." -ForegroundColor Yellow
$pythonCmd = $null
if (Get-Command "python" -ErrorAction SilentlyContinue) {
    $pythonCmd = "python"
} elseif (Get-Command "py" -ErrorAction SilentlyContinue) {
    $pythonCmd = "py -3"
} else {
    Write-Host "❌ 找不到 Python！請先安裝 Python 並將其加入系統 PATH。" -ForegroundColor Red
    Exit 1
}
Write-Host "  ✅ 找到 Python: $pythonCmd" -ForegroundColor Green

# 2. 定位目錄路徑
Write-Host "`n[2/6] 準備 Antigravity 設定目錄..." -ForegroundColor Yellow
$userHome = [System.Environment]::GetFolderPath('UserProfile')
$geminiConfigDir = Join-Path $userHome ".gemini\config"
$pluginDir = Join-Path $geminiConfigDir "plugins\custom-commands"
$scratchDir = Join-Path $userHome ".gemini\antigravity\scratch"

foreach ($dir in @($geminiConfigDir, $pluginDir, $scratchDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}
Write-Host "  ✅ 目錄就緒: $pluginDir" -ForegroundColor Green

# 3. 複製/下載檔案
Write-Host "`n[3/6] 安裝審查核心..." -ForegroundColor Yellow
$scriptDir = $null
if ($MyInvocation.MyCommand.Path) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$autoApproveSrc = if ($scriptDir) { Join-Path $scriptDir "auto_approve.py" } else { $null }
$pluginJsonSrc = if ($scriptDir) { Join-Path $scriptDir "plugin.json" } else { $null }
$autoApproveDest = Join-Path $pluginDir "auto_approve.py"
$pluginJsonDest = Join-Path $pluginDir "plugin.json"

if ($autoApproveSrc -and (Test-Path $autoApproveSrc)) {
    Copy-Item $autoApproveSrc $autoApproveDest -Force
    Copy-Item $pluginJsonSrc $pluginJsonDest -Force
} else {
    Write-Host "  🌐 從 GitHub 下載最新版本..." -ForegroundColor Cyan
    $baseUrl = "https://raw.githubusercontent.com/jason125457/antigravity-turbo-guard/main"
    Invoke-WebRequest -Uri "$baseUrl/auto_approve.py" -OutFile $autoApproveDest -UseBasicParsing
    Invoke-WebRequest -Uri "$baseUrl/plugin.json" -OutFile $pluginJsonDest -UseBasicParsing
}
Write-Host "  ✅ 核心檔案已成功部署！" -ForegroundColor Green

# 4. 註冊 hooks.json
Write-Host "`n[4/6] 註冊 PreToolUse Hook (hooks.json)..." -ForegroundColor Yellow
$normalizedPath = $autoApproveDest.Replace('\', '/')
$hooksContent = @"
{
  "auto-approve": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "$pythonCmd $normalizedPath"
          }
        ]
      }
    ]
  }
}
"@

$globalHooksPath = Join-Path $geminiConfigDir "hooks.json"
$pluginHooksPath = Join-Path $pluginDir "hooks.json"

[System.IO.File]::WriteAllText($globalHooksPath, $hooksContent, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($pluginHooksPath, $hooksContent, [System.Text.Encoding]::UTF8)
Write-Host "  ✅ 全域生命週期 Hook 註冊完成！" -ForegroundColor Green

# 5. 更新 config.json (啟用插件與 Turbo 模式)
Write-Host "`n[5/6] 同步全域 Turbo 模式與權限原則 (config.json)..." -ForegroundColor Yellow
$configPath = Join-Path $geminiConfigDir "config.json"
$config = @{}

if (Test-Path $configPath) {
    try {
        $raw = Get-Content $configPath -Raw -Encoding UTF8
        $config = $raw | ConvertFrom-Json -AsHashtable
    } catch {
        $config = @{}
    }
}

if (-not $config.ContainsKey("plugins")) { $config["plugins"] = @{} }
if (-not $config["plugins"].ContainsKey("custom-commands")) { $config["plugins"]["custom-commands"] = @{} }
$config["plugins"]["custom-commands"]["enabled"] = $true

if (-not $config.ContainsKey("userSettings")) { $config["userSettings"] = @{} }
$config["userSettings"]["autoExecutionPolicy"] = "CASCADE_COMMANDS_AUTO_EXECUTION_EAGER"
$config["userSettings"]["artifactReviewMode"] = "ARTIFACT_REVIEW_MODE_TURBO"

$jsonOut = $config | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText($configPath, $jsonOut, [System.Text.Encoding]::UTF8)
Write-Host "  ✅ 全域 Turbo 模式已自動啟用！" -ForegroundColor Green

# 6. 自檢自測
Write-Host "`n[6/6] 執行自動安全測試..." -ForegroundColor Yellow
$testAllow = '{"toolCall": {"name": "run_command", "args": {"CommandLine": "git status"}}}' | & python $autoApproveDest
$testBlock = '{"toolCall": {"name": "run_command", "args": {"CommandLine": "del test.txt"}}}' | & python $autoApproveDest
$testEnv = '{"toolCall": {"name": "view_file", "args": {"AbsolutePath": ".env"}}}' | & python $autoApproveDest

$pass1 = $testAllow -match '"decision":\s*"allow"'
$pass2 = $testBlock -match '"decision":\s*"force_ask"'
$pass3 = $testEnv -match '"decision":\s*"force_ask"'

if ($pass1 -and $pass2 -and $pass3) {
    Write-Host "  ✅ 測試通過：一般指令自動放行 (allow)" -ForegroundColor Green
    Write-Host "  ✅ 測試通過：危險刪除指令強制彈窗把關 (force_ask)" -ForegroundColor Green
    Write-Host "  ✅ 測試通過：敏感金鑰存取強制彈窗把關 (force_ask)" -ForegroundColor Green
} else {
    Write-Host "  ⚠️ 警告：測試回傳非預期，請檢查日誌。" -ForegroundColor Yellow
}

Write-Host "`n==================================================" -ForegroundColor Green
Write-Host "   🎉 恭喜！Antigravity Turbo Guard 安裝成功！   " -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host "`n💡 提示：請在 Antigravity 中開啟新對話 (+ New Conversation) 即可生效！`n" -ForegroundColor Cyan
