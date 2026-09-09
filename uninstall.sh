#!/usr/bin/env bash
# Antigravity Turbo Guard - macOS/Linux Uninstaller

echo "Uninstalling Antigravity Turbo Guard..."

rm -f "$HOME/.gemini/config/hooks.json"
rm -rf "$HOME/.gemini/config/plugins/custom-commands"

echo "✅ Successfully uninstalled Antigravity Turbo Guard."
