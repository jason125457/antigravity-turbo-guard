#!/usr/bin/env bash
# Antigravity Turbo Guard - macOS/Linux Installer
# Run: curl -fsSL https://raw.githubusercontent.com/jason125457/antigravity-turbo-guard/main/install.sh | bash

set -e

echo "=================================================="
echo "   🚀 Antigravity Turbo Guard Installer (macOS/Linux)   "
echo "=================================================="

# 1. Check Python
echo -e "\n[1/5] Checking Python..."
if command -v python3 &>/dev/null; then
    PYTHON_BIN="python3"
elif command -v python &>/dev/null; then
    PYTHON_BIN="python"
else
    echo "❌ Python 3 is required but not found."
    exit 1
fi
echo "  ✅ Found Python: $($PYTHON_BIN --version)"

# 2. Prepare directories
echo -e "\n[2/5] Preparing directories..."
GEMINI_CONFIG="$HOME/.gemini/config"
PLUGIN_DIR="$GEMINI_CONFIG/plugins/custom-commands"
SCRATCH_DIR="$HOME/.gemini/antigravity/scratch"

mkdir -p "$PLUGIN_DIR" "$SCRATCH_DIR"

# 3. Deploy files
echo -e "\n[3/5] Deploying hook scripts..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"

if [ -f "$SCRIPT_DIR/auto_approve.py" ]; then
    cp "$SCRIPT_DIR/auto_approve.py" "$PLUGIN_DIR/auto_approve.py"
    cp "$SCRIPT_DIR/plugin.json" "$PLUGIN_DIR/plugin.json"
else
    echo "  🌐 Downloading latest version from GitHub..."
    BASE_URL="https://raw.githubusercontent.com/jason125457/antigravity-turbo-guard/main"
    curl -fsSL "$BASE_URL/auto_approve.py" -o "$PLUGIN_DIR/auto_approve.py"
    curl -fsSL "$BASE_URL/plugin.json" -o "$PLUGIN_DIR/plugin.json"
fi

chmod +x "$PLUGIN_DIR/auto_approve.py"

# 4. Register hooks.json
echo -e "\n[4/5] Registering hooks.json..."
HOOKS_CONTENT=$(cat <<EOF
{
  "auto-approve": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "$PYTHON_BIN $PLUGIN_DIR/auto_approve.py"
          }
        ]
      }
    ]
  }
}
EOF
)

echo "$HOOKS_CONTENT" > "$GEMINI_CONFIG/hooks.json"
echo "$HOOKS_CONTENT" > "$PLUGIN_DIR/hooks.json"

# 5. Enable plugin in config.json
echo -e "\n[5/5] Updating config.json..."
CONFIG_FILE="$GEMINI_CONFIG/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "{}" > "$CONFIG_FILE"
fi

$PYTHON_BIN - <<EOF
import json, os, glob

config_path = os.path.expanduser("~/.gemini/config/config.json")
try:
    with open(config_path, "r", encoding="utf-8") as f:
        data = json.load(f)
except Exception:
    data = {}

if "plugins" not in data:
    data["plugins"] = {}
if "custom-commands" not in data["plugins"]:
    data["plugins"]["custom-commands"] = {}
data["plugins"]["custom-commands"]["enabled"] = True

u_settings = data.setdefault("userSettings", {})
u_settings["autoExecutionPolicy"] = "CASCADE_COMMANDS_AUTO_EXECUTION_EAGER"
u_settings["artifactReviewMode"] = "ARTIFACT_REVIEW_MODE_TURBO"

perm_grants = u_settings.setdefault("globalPermissionGrants", {})
allow_list = set(perm_grants.get("allow", []))

mcp_wildcards = ["mcp(*)", "mcp(*/*)"]
allow_list.update(mcp_wildcards)

mcp_dir = os.path.expanduser("~/.gemini/antigravity/mcp")
if os.path.exists(mcp_dir):
    for server in os.listdir(mcp_dir):
        s_path = os.path.join(mcp_dir, server)
        if os.path.isdir(s_path):
            allow_list.add(f"mcp({server}/*)")
            for f in os.listdir(s_path):
                if f.endswith(".json"):
                    allow_list.add(f"mcp({server}/{f[:-5]})")

perm_grants["allow"] = sorted(list(allow_list))

with open(config_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

# Sync projects
proj_dir = os.path.expanduser("~/.gemini/config/projects")
if os.path.exists(proj_dir):
    for p_file in glob.glob(os.path.join(proj_dir, "*.json")):
        try:
            with open(p_file, "r", encoding="utf-8") as f:
                pdata = json.load(f)
            psettings = pdata.setdefault("settings", {})
            psettings["artifactReviewMode"] = "ARTIFACT_REVIEW_MODE_TURBO"
            psettings["autoExecutionPolicy"] = "CASCADE_COMMANDS_AUTO_EXECUTION_EAGER"
            psettings["fileAccessPolicy"] = "AGENT_SETTING_POLICY_ALLOW"
            psettings["sandboxMode"] = False
            with open(p_file, "w", encoding="utf-8") as f:
                json.dump(pdata, f, indent=2, ensure_ascii=False)
        except Exception:
            pass
EOF

echo -e "\n=================================================="
echo "   🎉 Antigravity Turbo Guard installed successfully!"
echo "=================================================="
echo "💡 Tip: Start a New Conversation (+ New Conversation) in Antigravity to apply."
