#!/usr/bin/env python3
"""
Notification Hook for Claude Code
Sends desktop notifications for file operations and tool usage.
"""

import json
import os
import subprocess
import sys
from pathlib import Path


def send_notification(title: str, message: str, urgency: str = "normal"):
    try:
        subprocess.run(
            [
                "notify-send",
                "--urgency",
                urgency,
                "--app-name",
                "Claude Code",
                "--icon",
                "text-editor",
                title,
                message,
            ],
            check=False,
            timeout=5,
        )
    except (subprocess.TimeoutExpired, FileNotFoundError):
        log_file = Path.home() / ".claude" / "notifications.log"
        log_file.parent.mkdir(exist_ok=True)
        with open(log_file, "a") as f:
            f.write(f"[{title}] {message}\n")


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
        sys.exit(1)

    hook_event = input_data.get("hook_event_name", "")
    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    tool_response = input_data.get("tool_response", {})

    if hook_event != "PostToolUse":
        sys.exit(0)

    if tool_name in ["Write", "Edit", "MultiEdit"]:
        file_path = tool_input.get("file_path", "")
        if file_path:
            filename = os.path.basename(file_path)

            if tool_name == "Write":
                title = "File Created ◉"
                message = f"Created: {filename}"
            else:
                title = "File Modified ◉"
                message = f"Modified: {filename}"

            send_notification(title, message)

    elif tool_name == "Bash":
        command = tool_input.get("command", "")
        success = tool_response.get("success", True)

        important_commands = [
            "npm install",
            "npm run",
            "yarn",
            "git",
            "docker",
            "pytest",
            "jest",
        ]
        if any(cmd in command.lower() for cmd in important_commands):
            if success:
                title = "Command Completed ◉"
                message = (
                    f"Executed: {command[:50]}{'...' if len(command) > 50 else ''}"
                )
                urgency = "normal"
            else:
                title = "Command Failed ◉"
                message = f"Failed: {command[:50]}{'...' if len(command) > 50 else ''}"
                urgency = "critical"

            send_notification(title, message, urgency)

    elif tool_name == "Task":
        description = tool_input.get("description", "")
        if description:
            title = "Subagent Task Started ◉"
            message = f"Task: {description}"
            send_notification(title, message)

    sys.exit(0)


if __name__ == "__main__":
    main()
