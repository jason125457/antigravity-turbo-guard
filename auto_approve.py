#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Antigravity Turbo Guard - Auto Approve Hook
Automatically allows non-destructive operations while enforcing hard confirmation (force_ask)
for dangerous commands and sensitive file accesses even in Turbo / Auto-Execution mode.
"""

import sys
import json
import os
import re

if sys.platform == "win32":
    import io
    sys.stdin = io.TextIOWrapper(sys.stdin.buffer, encoding="utf-8")
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

def main():
    try:
        input_data = sys.stdin.read()
        if not input_data:
            print(json.dumps({"decision": "allow"}))
            return
            
        event_data = json.loads(input_data)
        
        # Log event for audit and troubleshooting
        log_dir = os.path.expanduser(r"~/.gemini/antigravity/scratch")
        if os.path.exists(log_dir):
            try:
                with open(os.path.join(log_dir, "hook_log.txt"), "a", encoding="utf-8") as f:
                    f.write(json.dumps(event_data, ensure_ascii=False) + "\n")
            except Exception:
                pass
        
        tool_call = event_data.get("toolCall", {})
        tool_name = tool_call.get("name", "")
        args = tool_call.get("args", {})
        
        # 1. Block/Prompt for sensitive credentials & secret files
        sensitive_files = [
            ".env", ".npmrc", ".git-credentials", 
            "id_rsa", "id_ed25519", "id_ecdsa", "id_dsa",
            ".pem", ".key", ".pfx", ".p12", ".keystore"
        ]
        file_tools = (
            "read_file", "view_file", "write_file", "write_to_file", 
            "replace_file_content", "multi_replace_file_content"
        )
        if tool_name in file_tools:
            target_path = (args.get("TargetFile") or args.get("AbsolutePath") or "").lower()
            if any(sf in target_path for sf in sensitive_files):
                print(json.dumps({
                    "decision": "force_ask",
                    "reason": f"Sensitive file access detected ({target_path})."
                }))
                return
                
        # 2. Block/Prompt for dangerous shell commands
        if tool_name == "run_command":
            cmd = args.get("CommandLine", "").lower()
            dangerous_cmds = [
                "rm ", "rmdir", "del ", "erase ", "rd ", "mkfs", 
                "remove-item", "drop database", "drop table", "shutdown", "reboot"
            ]
            
            # Check for direct destructive commands
            is_destructive = any(dc in cmd for dc in dangerous_cmds)
            
            # Check disk formatting specifically (e.g., format c: or format-volume, avoiding npm run format)
            is_disk_format = bool(re.search(r"\bformat\s+[a-z]:", cmd)) or ("format-volume" in cmd)
            
            if is_destructive or is_disk_format:
                print(json.dumps({
                    "decision": "force_ask",
                    "reason": f"Potentially destructive command detected ({cmd})."
                }))
                return
                
        # Non-destructive operation: auto-approve
        print(json.dumps({"decision": "allow"}))
        
    except Exception:
        # Fail-safe: if script fails, always prompt user for safety
        print(json.dumps({"decision": "force_ask"}))

if __name__ == "__main__":
    main()
