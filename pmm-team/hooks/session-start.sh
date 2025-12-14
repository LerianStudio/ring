#!/usr/bin/env bash
# shellcheck disable=SC2034  # Unused variables OK for exported config
set -euo pipefail
# Session start hook for ring-pmm-team plugin
# Generates quick reference for PMM skills and agents

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

# Source shared JSON escaping utility
SHARED_JSON_ESCAPE="$MONOREPO_ROOT/shared/lib/json-escape.sh"
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

# Count skills (excluding shared-patterns and using-pmm-team)
count_skills() {
    local count=0
    for skill_dir in "$PLUGIN_ROOT/skills"/*/; do
        [ -d "$skill_dir" ] || continue
        local skill_name
        skill_name=$(basename "$skill_dir")
        # Skip shared-patterns and using-pmm-team
        if [[ "$skill_name" != "shared-patterns" && "$skill_name" != "using-pmm-team" ]]; then
            if [ -f "$skill_dir/SKILL.md" ]; then
                ((count++)) || true
            fi
        fi
    done
    echo "$count"
}

# Count agents
count_agents() {
    local count=0
    for agent_file in "$PLUGIN_ROOT/agents"/*.md; do
        [ -f "$agent_file" ] || continue
        ((count++)) || true
    done
    echo "$count"
}

# Generate context
if [ -d "$PLUGIN_ROOT/skills" ] && [ -d "$PLUGIN_ROOT/agents" ]; then
    skill_count=$(count_skills)
    agent_count=$(count_agents)

    context="<ring-pmm-team-system>
**Product Marketing Skills & Agents**

${skill_count} PMM skills + ${agent_count} specialist agents for go-to-market strategy:

| Category | Components |
|----------|------------|
| **Skills** | market-analysis, positioning-development, messaging-creation, gtm-planning, launch-execution, pricing-strategy, competitive-intelligence |
| **Agents** | market-researcher, positioning-strategist, messaging-specialist, gtm-planner, launch-coordinator, pricing-analyst |
| **Commands** | /ring-pmm-team:market-analysis, /ring-pmm-team:gtm-plan, /ring-pmm-team:competitive-intel |

**All agents require model: opus**

For full details: Skill tool with \"ring-pmm-team:using-pmm-team\"
</ring-pmm-team-system>"

    # Escape for JSON
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
    # Fallback if directories don't exist
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<ring-pmm-team-system>\n**Product Marketing Skills & Agents**\n\n7 PMM skills + 6 specialist agents for go-to-market strategy.\n\nFor full details: Skill tool with \"ring-pmm-team:using-pmm-team\"\n</ring-pmm-team-system>"
  }
}
EOF
fi
