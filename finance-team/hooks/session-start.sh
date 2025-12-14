#!/usr/bin/env bash
# shellcheck disable=SC2034  # Unused variables OK for exported config
set -euo pipefail
# Session start hook for ring-finance-team plugin
# Dynamically generates quick reference for financial specialist agents

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
    context="<ring-finance-team-system>
**Financial Specialists Available**

Use via Task tool with \`subagent_type\`:

${agents_table}

**Domain Distinction:**
- **ring-finance-team**: Financial operations, analysis, planning, modeling
- **ring-finops-team**: Brazilian regulatory compliance (BACEN, RFB, Open Banking)

**Available Skills:**
- \`financial-analysis\`: Comprehensive financial statement analysis
- \`budget-creation\`: Budget planning and forecasting
- \`financial-modeling\`: DCF, LBO, M&A, operating models
- \`cash-flow-analysis\`: Treasury and liquidity management
- \`financial-reporting\`: Report preparation and distribution
- \`metrics-dashboard\`: KPI definition and dashboard design
- \`financial-close\`: Month-end and year-end close procedures

**Available Commands:**
- \`/ring-finance-team:analyze-financials\`: Run financial analysis
- \`/ring-finance-team:create-budget\`: Create budget or forecast
- \`/ring-finance-team:build-model\`: Build financial model

For full details: Skill tool with \"ring-finance-team:using-finance-team\"
</ring-finance-team-system>"

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
    "hookEventName": "SessionStart",
    "additionalContext": "<ring-finance-team-system>\n**Financial Specialists Available**\n\n6 specialists for financial analysis, budgeting, modeling, treasury, accounting, and metrics.\n\n**Domain Distinction:**\n- ring-finance-team: Financial operations, analysis, planning, modeling\n- ring-finops-team: Brazilian regulatory compliance (BACEN, RFB)\n\nFor full list: Skill tool with \"ring-finance-team:using-finance-team\"\n</ring-finance-team-system>"
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
    "additionalContext": "<ring-finance-team-system>\n**Financial Specialists Available**\n\n6 specialists: financial-analyst, budget-planner, financial-modeler, treasury-specialist, accounting-specialist, metrics-analyst\n\n**Domain Distinction:**\n- ring-finance-team: Financial operations, analysis, planning, modeling\n- ring-finops-team: Brazilian regulatory compliance (BACEN, RFB)\n\nFor full list: Skill tool with \"ring-finance-team:using-finance-team\"\n</ring-finance-team-system>"
  }
}
EOF
fi
