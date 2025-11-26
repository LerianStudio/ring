#!/usr/bin/env bash
set -euo pipefail
# Session start hook for ring-finops-team plugin
# Dynamically generates quick reference for FinOps regulatory agents

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
    context="<ring-finops-team-system>
**FinOps & Regulatory Compliance**

Brazilian financial compliance specialists:

${agents_table}

Workflow: Setup → Analyzer (compliance) → Automation (templates)
Supported: BACEN, RFB, Open Banking, DIMP, APIX

For full details: Skill tool with \"ring-finops-team:using-finops-team\"
</ring-finops-team-system>"

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
    "additionalContext": "<ring-finops-team-system>\n**FinOps & Regulatory Compliance**\n\n2 specialist agents for Brazilian financial compliance:\n\n| Agent | Purpose |\n|-------|----------|\n| `ring-finops-team:finops-analyzer` | Field mapping & compliance analysis (Gates 1-2) |\n| `ring-finops-team:finops-automation` | Template generation in .tpl format (Gate 3) |\n\nWorkflow: Setup → Analyzer (compliance) → Automation (templates)\nSupported: BACEN, RFB, Open Banking, DIMP, APIX\n\nFor full details: Skill tool with \"ring-finops-team:using-finops-team\"\n</ring-finops-team-system>"
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
    "additionalContext": "<ring-finops-team-system>\n**FinOps & Regulatory Compliance** (2 agents)\n\nFor full list: Skill tool with \"ring-finops-team:using-finops-team\"\n</ring-finops-team-system>"
  }
}
EOF
fi
