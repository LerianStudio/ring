#!/usr/bin/env bash
# shellcheck disable=SC2034  # Unused variables OK for exported config
set -euo pipefail
# Session start hook for ralph-wiggum plugin
# Dynamically generates quick reference for Ralph Wiggum commands

# Validate CLAUDE_PLUGIN_ROOT is set and reasonable (when used via hooks)
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    if ! cd "${CLAUDE_PLUGIN_ROOT}" 2>/dev/null; then
        echo '{"error": "Invalid CLAUDE_PLUGIN_ROOT path"}'
        exit 1
    fi
fi

# Find the monorepo root (where shared/ directory exists)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MONOREPO_ROOT="$(cd "$PLUGIN_ROOT/.." && pwd)"

# Path to shared utilities
SHARED_UTIL="$MONOREPO_ROOT/shared/lib/generate-reference.py"
SHARED_JSON_ESCAPE="$MONOREPO_ROOT/shared/lib/json-escape.sh"

# Source shared JSON escaping utility
if [[ -f "$SHARED_JSON_ESCAPE" ]]; then
    # shellcheck source=/dev/null
    source "$SHARED_JSON_ESCAPE"
else
    # Fallback: define json_escape locally
    json_escape() {
        local input="$1"
        if command -v jq &>/dev/null; then
            printf '%s' "$input" | jq -Rs . | sed 's/^"//;s/"$//'
        else
            printf '%s' "$input" | sed \
                -e 's/\\/\\\\/g' \
                -e 's/"/\\"/g' \
                -e 's/\t/\\t/g' \
                -e 's/\r/\\r/g' \
                -e ':a;N;$!ba;s/\n/\\n/g'
        fi
    }
fi

# Generate commands reference
if [ -f "$SHARED_UTIL" ] && command -v python3 &>/dev/null; then
  # Use || true to prevent set -e from exiting on non-zero return
  commands_table=$(python3 "$SHARED_UTIL" commands "$PLUGIN_ROOT/commands" 2>/dev/null) || true

  if [ -n "$commands_table" ]; then
    # Build the context message
    context="<ralph-wiggum-system>
**Ralph Wiggum - Iterative AI Development Loops**

Autonomous task refinement using Stop hooks. Claude works on a task until completion.

**Commands:**
${commands_table}

**How it works:**
1. You provide a prompt with clear completion criteria
2. Claude works on the task
3. Stop hook intercepts exit, re-feeds prompt
4. Loop continues until \`<promise>TEXT</promise>\` found or max iterations

**Example:**
\`\`\`
/ralph-wiggum:ralph-loop \"Build REST API. Output <promise>DONE</promise> when tests pass.\" --completion-promise \"DONE\" --max-iterations 20
\`\`\`

For details: \`/ralph-wiggum:help\`
</ralph-wiggum-system>"

    # Escape for JSON using shared utility
    context_escaped=$(json_escape "$context")

    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${context_escaped}"
  }
}
EOF
  else
    # Fallback to static output
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<ralph-wiggum-system>\n**Ralph Wiggum - Iterative AI Development Loops**\n\nAutonomous task refinement using Stop hooks. Claude works on a task until completion.\n\n**Commands:**\n| Command | Purpose |\n|---------|----------|\n| `/ralph-wiggum:ralph-loop PROMPT [--max-iterations N] [--completion-promise TEXT]` | Start iterative loop |\n| `/ralph-wiggum:cancel-ralph` | Cancel active loop |\n| `/ralph-wiggum:help` | Show Ralph technique guide |\n\n**How it works:**\n1. You provide a prompt with clear completion criteria\n2. Claude works on the task\n3. Stop hook intercepts exit, re-feeds prompt\n4. Loop continues until `<promise>TEXT</promise>` found or max iterations\n\n**Example:**\n```\n/ralph-wiggum:ralph-loop \"Build REST API. Output <promise>DONE</promise> when tests pass.\" --completion-promise \"DONE\" --max-iterations 20\n```\n\nFor details: `/ralph-wiggum:help`\n</ralph-wiggum-system>"
  }
}
EOF
  fi
else
  # Fallback if Python not available
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<ralph-wiggum-system>\n**Ralph Wiggum - Iterative AI Development Loops** (3 commands)\n\nFor full list: `/ralph-wiggum:help`\n</ralph-wiggum-system>"
  }
}
EOF
fi
