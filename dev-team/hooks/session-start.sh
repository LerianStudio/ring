#!/usr/bin/env bash
set -euo pipefail
# Session start hook for ring-dev-team plugin
# Dynamically generates quick reference for developer specialist agents

# Find the monorepo root (where shared/ directory exists)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MONOREPO_ROOT="$(cd "$PLUGIN_ROOT/.." && pwd)"

# Path to shared utility
SHARED_UTIL="$MONOREPO_ROOT/shared/lib/generate-reference.py"

# Generate agent reference
if [ -f "$SHARED_UTIL" ] && command -v python3 &>/dev/null; then
  # Use || true to prevent set -e from exiting on non-zero return
  agents_table=$(python3 "$SHARED_UTIL" agents "$PLUGIN_ROOT/agents" 2>/dev/null) || true

  if [ -n "$agents_table" ]; then
    # Build the context message
    context="<ring-dev-team-system>
**Developer Specialists Available**

Use via Task tool with \`subagent_type\`:

${agents_table}

For full details: Skill tool with \"ring-dev-team:using-dev-team\"
</ring-dev-team-system>"

    # Escape for JSON using jq (requires jq to be installed)
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
    # Fallback to static output if script fails
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<ring-dev-team-system>\n**Developer Specialists Available**\n\nUse via Task tool with `subagent_type`:\n\n| Agent | Expertise |\n|-------|----------|\n| `ring-dev-team:backend-engineer` | Language-agnostic backend |\n| `ring-dev-team:backend-engineer-golang` | Go specialist |\n| `ring-dev-team:backend-engineer-typescript` | TypeScript/Node.js specialist |\n| `ring-dev-team:backend-engineer-python` | Python specialist |\n| `ring-dev-team:frontend-engineer` | Language-agnostic frontend |\n| `ring-dev-team:frontend-engineer-typescript` | React/Next.js specialist |\n| `ring-dev-team:frontend-designer` | Visual design specialist |\n| `ring-dev-team:devops-engineer` | CI/CD, infrastructure |\n| `ring-dev-team:qa-analyst` | Testing, automation |\n| `ring-dev-team:sre` | Monitoring, reliability |\n\nFor full details: Skill tool with \"ring-dev-team:using-dev-team\"\n</ring-dev-team-system>"
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
    "additionalContext": "<ring-dev-team-system>\n**Developer Specialists Available**\n\nFor full list: Skill tool with \"ring-dev-team:using-dev-team\"\n</ring-dev-team-system>"
  }
}
EOF
fi
