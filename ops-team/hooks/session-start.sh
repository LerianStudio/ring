#!/usr/bin/env bash
# shellcheck disable=SC2034  # Unused variables OK for exported config
set -euo pipefail
# Session start hook for ring-ops-team plugin
# Dynamically generates quick reference for operations specialist agents

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

# Generate agent reference
if [ -f "$SHARED_UTIL" ] && command -v python3 &>/dev/null; then
  # Use || true to prevent set -e from exiting on non-zero return
  agents_table=$(python3 "$SHARED_UTIL" agents "$PLUGIN_ROOT/agents" 2>/dev/null) || true

  if [ -n "$agents_table" ]; then
    # Build the context message
    context="<ring-ops-team-system>
**Operations Specialists Available**

Use via Task tool with \`subagent_type\`:

${agents_table}

**Domain Focus:**
- **Production Operations**: Incident response, platform engineering
- **Cost Management**: Cloud cost optimization, resource efficiency
- **Infrastructure Lifecycle**: Capacity planning, DR, migrations
- **Security Operations**: Security audits, compliance validation

**Commands Available:**
- \`/ring-ops-team:incident\` - Production incident management
- \`/ring-ops-team:capacity-review\` - Infrastructure capacity review
- \`/ring-ops-team:cost-analysis\` - Cloud cost analysis
- \`/ring-ops-team:security-audit\` - Security audit workflow

For full details: Skill tool with \"ring-ops-team:using-ops-team\"
</ring-ops-team-system>"

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
    # Fallback to static output if script fails
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart"
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
    "additionalContext": "<ring-ops-team-system>\n**Operations Specialists Available**\n\n5 agents for production operations, incident response, cost optimization, infrastructure architecture, and security operations.\n\nFor full list: Skill tool with \"ring-ops-team:using-ops-team\"\n</ring-ops-team-system>"
  }
}
EOF
fi
