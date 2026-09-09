@echo off
chcp 65001 >nul
echo 正在啟動 Antigravity Turbo Guard 安裝程式...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
pause
