@echo off
chcp 65001 >nul
echo 正在啟動 Antigravity Turbo Guard 解除安裝程式...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
pause
