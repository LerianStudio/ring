#!/usr/bin/env bash
set -euo pipefail
# Session start hook for ralph-wiggum plugin
# Dynamically generates quick reference for Ralph Wiggum commands

# Find the monorepo root (where shared/ directory exists)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MONOREPO_ROOT="$(cd "$PLUGIN_ROOT/.." && pwd)"

# Path to shared utility
SHARED_UTIL="$MONOREPO_ROOT/shared/lib/generate-reference.py"

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

    # Escape for JSON using jq
    if command -v jq &>/dev/null; then
      context_escaped=$(echo "$context" | jq -Rs . | sed 's/^"//;s/"$//')
    else
      # Fallback: more complete escaping (handles tabs, carriage returns, form feeds)
      # Note: Still not RFC 8259 compliant for all control chars - jq is strongly recommended
      context_escaped=$(printf '%s' "$context" | \
        sed 's/\\/\\\\/g' | \
        sed 's/"/\\"/g' | \
        sed 's/	/\\t/g' | \
        sed $'s/\r/\\\\r/g' | \
        sed 's/\f/\\f/g' | \
        awk '{printf "%s\\n", $0}')
    fi

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
