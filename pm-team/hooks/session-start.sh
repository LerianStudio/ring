#!/usr/bin/env bash
# shellcheck disable=SC2034  # Unused variables OK for exported config
set -euo pipefail
# Session start hook for ring-pm-team plugin
# Dynamically generates quick reference for pre-dev planning skills

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

# Output file mapping: skill name -> output filename
# This is structural knowledge not derivable from frontmatter
# NOTE: Using function instead of associative array for bash 3.x compatibility (macOS default)
get_output_file() {
  local skill_name="$1"
  case "$skill_name" in
    researching-features)            echo "research.md" ;;
    writing-prds)                    echo "PRD.md" ;;
    mapping-feature-relationships)   echo "feature-map.md" ;;
    writing-trds)                    echo "TRD.md" ;;
    designing-api-contracts)         echo "API.md" ;;
    designing-data-model)            echo "data-model.md" ;;
    pinning-dependency-versions)     echo "dependencies.md" ;;
    decomposing-phases-and-epics)    echo "tasks.md" ;;
    detailing-tasks)                 echo "tasks.md" ;;
    validating-ux-completeness)      echo "design-validation.md" ;;
    planning-delivery)               echo "delivery-planning.md" ;;
    *)                               echo "${skill_name}.md" ;;
  esac
}

# Extract gate number from skill description.
# Gate skills declare their own gate as "Gate N of ring:..."; some descriptions
# also reference an upstream gate first (e.g. data-model says "from the Gate 4 API
# design ... Gate 5 of ..."), so prefer the "Gate N of" form and only fall back to
# the first "Gate N" token when that canonical phrasing is absent.
extract_gate() {
  local skill_dir="$1"
  local skill_file="$skill_dir/SKILL.md"
  local desc gate
  if [ -f "$skill_file" ]; then
    # Collect the full description field value (frontmatter line + continuations)
    desc=$(grep -A3 "^description:" "$skill_file" 2>/dev/null | tr '\n' ' ')
    gate=$(printf '%s' "$desc" | grep -oE "Gate [0-9.]+ of " | head -1 | grep -oE "[0-9.]+")
    if [ -z "$gate" ]; then
      gate=$(printf '%s' "$desc" | grep -oE "Gate [0-9.]+" | head -1 | grep -oE "[0-9.]+")
    fi
    printf '%s' "$gate"
  fi
}

# Build dynamic table from discovered skills
build_skills_table() {
  local skills_dir="$1"
  local table_rows=""

  # Discover all skills; the "has a Gate N" description filter selects gate skills
  for skill_dir in "$skills_dir"/*/; do
    [ -d "$skill_dir" ] || continue
    local skill_name
    skill_name=$(basename "$skill_dir")
    local gate
    gate=$(extract_gate "$skill_dir")
    local output
    output=$(get_output_file "$skill_name")

    if [ -n "$gate" ]; then
      # Append row with gate for sorting (format: gate|skill|gate|output)
      table_rows="${table_rows}${gate}|\`ring:${skill_name}\`|${gate}|${output}"$'\n'
    fi
  done

  # Sort by gate number and format as table rows
  echo "$table_rows" | sort -t'|' -k1 -n | while IFS='|' read -r _ skill gate output; do
    [ -n "$skill" ] && echo "| ${skill} | ${gate} | ${output} |"
  done
}

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

# Generate skills reference
if [ -d "$PLUGIN_ROOT/skills" ]; then
  # Build table dynamically
  table_content=$(build_skills_table "$PLUGIN_ROOT/skills")
  skill_count=$(echo "$table_content" | grep -c "ring:" || echo "0")

  if [ -n "$table_content" ] && [ "$skill_count" -gt 0 ]; then
    # Build the context message with dynamically discovered skills
    context="<ring-pm-team-system>
**Pre-Dev Planning Skills**

${skill_count}-gate structured feature planning (use via Skill tool):

| Skill | Gate | Output |
|-------|------|--------|
${table_content}

For full details: Skill tool with \"ring:using-pm-team\"
</ring-pm-team-system>"

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
    # Fallback to static output if dynamic discovery fails
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<ring-pm-team-system>\n**Pre-Dev Planning Skills**\n\n11-gate structured feature planning (use via Skill tool):\n\n| Skill | Gate | Output |\n|-------|------|--------|\n| `ring:researching-features` | 0 | research.md |\n| `ring:writing-prds` | 1 | PRD.md |\n| `ring:validating-ux-completeness` | 1.5 | design-validation.md |\n| `ring:mapping-feature-relationships` | 2 | feature-map.md |\n| `ring:writing-trds` | 3 | TRD.md |\n| `ring:designing-api-contracts` | 4 | API.md |\n| `ring:designing-data-model` | 5 | data-model.md |\n| `ring:pinning-dependency-versions` | 6 | dependencies.md |\n| `ring:decomposing-phases-and-epics` | 7 | tasks.md |\n| `ring:detailing-tasks` | 8 | tasks.md |\n| `ring:planning-delivery` | 9 | delivery-planning.md |\n\n**Standalone Discovery Skills** (use via Skill tool):\n\n| Skill | Output |\n|-------|--------|\n| `ring:mapping-streaming-events` | docs/streaming/event-catalog.md, instrumentation-map.json |\n\nFor full details: Skill tool with \"ring:using-pm-team\"\n</ring-pm-team-system>"
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
    "additionalContext": "<ring-pm-team-system>\n**Pre-Dev Planning Skills** (11 gates)\n\nFor full list: Skill tool with \"ring:using-pm-team\"\n</ring-pm-team-system>"
  }
}
EOF
fi
