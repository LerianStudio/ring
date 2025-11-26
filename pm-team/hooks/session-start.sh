#!/bin/bash
set -euo pipefail
# Session start hook for ring-pm-team plugin
# Dynamically generates quick reference for pre-dev planning skills

# Find the monorepo root (where shared/ directory exists)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MONOREPO_ROOT="$(cd "$PLUGIN_ROOT/.." && pwd)"

# Output file mapping: skill name -> output filename
# This is structural knowledge not derivable from frontmatter
declare -A OUTPUT_FILES=(
  ["pre-dev-prd-creation"]="PRD.md"
  ["pre-dev-feature-map"]="feature-map.md"
  ["pre-dev-trd-creation"]="TRD.md"
  ["pre-dev-api-design"]="API.md"
  ["pre-dev-data-model"]="data-model.md"
  ["pre-dev-dependency-map"]="dependencies.md"
  ["pre-dev-task-breakdown"]="tasks.md"
  ["pre-dev-subtask-creation"]="subtasks.md"
)

# Extract gate number from skill description (format: "Gate X: ...")
extract_gate() {
  local skill_dir="$1"
  local skill_file="$skill_dir/SKILL.md"
  if [ -f "$skill_file" ]; then
    # Extract description field and find "Gate X:" pattern
    grep -A1 "^description:" "$skill_file" 2>/dev/null | grep -oE "Gate [0-9]+" | head -1 | grep -oE "[0-9]+" || true
  fi
}

# Build dynamic table from discovered skills
build_skills_table() {
  local skills_dir="$1"
  local table_rows=""

  # Discover pre-dev skills dynamically
  for skill_dir in "$skills_dir"/pre-dev-*/; do
    [ -d "$skill_dir" ] || continue
    local skill_name
    skill_name=$(basename "$skill_dir")
    local gate
    gate=$(extract_gate "$skill_dir")
    local output="${OUTPUT_FILES[$skill_name]:-${skill_name#pre-dev-}.md}"

    if [ -n "$gate" ]; then
      # Append row with gate for sorting (format: gate|skill|gate|output)
      table_rows="${table_rows}${gate}|\`ring-pm-team:${skill_name}\`|${gate}|${output}"$'\n'
    fi
  done

  # Sort by gate number and format as table rows
  echo "$table_rows" | sort -t'|' -k1 -n | while IFS='|' read -r _ skill gate output; do
    [ -n "$skill" ] && echo "| ${skill} | ${gate} | ${output} |"
  done
}

# Generate skills reference
if [ -d "$PLUGIN_ROOT/skills" ]; then
  # Build table dynamically
  table_content=$(build_skills_table "$PLUGIN_ROOT/skills")
  skill_count=$(echo "$table_content" | grep -c "ring-pm-team" || echo "0")

  if [ -n "$table_content" ] && [ "$skill_count" -gt 0 ]; then
    # Build the context message with dynamically discovered skills
    context="<ring-pm-team-system>
**Pre-Dev Planning Skills**

${skill_count}-gate structured feature planning (use via Skill tool):

| Skill | Gate | Output |
|-------|------|--------|
${table_content}
Entry points: \`/ring-default:pre-dev-feature\` (gates 1,3,7) or \`/ring-default:pre-dev-full\` (all 8)

For full details: Skill tool with \"ring-pm-team:using-pm-team\"
</ring-pm-team-system>"

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
    # Fallback to static output if dynamic discovery fails
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<ring-pm-team-system>\n**Pre-Dev Planning Skills**\n\n8 skills for structured feature planning (use via Skill tool):\n\n| Skill | Gate | Output |\n|-------|------|--------|\n| `ring-pm-team:pre-dev-prd-creation` | 1 | PRD.md |\n| `ring-pm-team:pre-dev-feature-map` | 2 | feature-map.md |\n| `ring-pm-team:pre-dev-trd-creation` | 3 | TRD.md |\n| `ring-pm-team:pre-dev-api-design` | 4 | API.md |\n| `ring-pm-team:pre-dev-data-model` | 5 | data-model.md |\n| `ring-pm-team:pre-dev-dependency-map` | 6 | dependencies.md |\n| `ring-pm-team:pre-dev-task-breakdown` | 7 | tasks.md |\n| `ring-pm-team:pre-dev-subtask-creation` | 8 | subtasks.md |\n\nEntry points: `/ring-default:pre-dev-feature` (gates 1,3,7) or `/ring-default:pre-dev-full` (all 8)\n\nFor full details: Skill tool with \"ring-pm-team:using-pm-team\"\n</ring-pm-team-system>"
  }
}
EOF
  fi
else
  # Fallback if skills directory doesn't exist
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<ring-pm-team-system>\n**Pre-Dev Planning Skills** (8 gates)\n\nFor full list: Skill tool with \"ring-pm-team:using-pm-team\"\n</ring-pm-team-system>"
  }
}
EOF
fi
