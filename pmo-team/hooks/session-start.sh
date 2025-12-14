#!/usr/bin/env bash
# shellcheck disable=SC2034  # Unused variables OK for exported config
set -euo pipefail
# Session start hook for ring-pmo-team plugin
# Dynamically generates quick reference for PMO specialist agents

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
    context="<ring-pmo-team-system>
**PMO Specialists Available**

Use via Task tool with \`subagent_type\` and \`model=\"opus\"\`:

${agents_table}

**PMO vs PM Distinction:**

| Team | Focus | Scope |
|------|-------|-------|
| \`ring-pm-team\` | Single feature planning | PRD, TRD, task breakdown |
| \`ring-pmo-team\` | Portfolio governance | Multi-project, resources, executive reporting |

**Commands:**
- \`/ring-pmo-team:portfolio-review\` - Full portfolio health review
- \`/ring-pmo-team:executive-summary\` - Generate executive report
- \`/ring-pmo-team:dependency-analysis\` - Cross-project dependencies

For full details: Skill tool with \"ring-pmo-team:using-pmo-team\"
</ring-pmo-team-system>"

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
    "additionalContext": "<ring-pmo-team-system>\n**PMO Specialists Available**\n\n5 specialists for portfolio-level management:\n- portfolio-manager\n- resource-planner\n- governance-specialist\n- risk-analyst\n- executive-reporter\n\nFor full list: Skill tool with \"ring-pmo-team:using-pmo-team\"\n</ring-pmo-team-system>"
  }
}
EOF
fi
