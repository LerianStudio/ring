#!/usr/bin/env bash
# Enhanced SessionStart hook for ring plugin
# Provides comprehensive skill overview and status

set -euo pipefail

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Generate skills overview dynamically
skills_overview=$("${SCRIPT_DIR}/generate-skills-ref.py" 2>&1 || echo "Error generating skills quick reference")

# Read using-ring content (still include for mandatory workflows)
using_ring_content=$(cat "${PLUGIN_ROOT}/skills/using-ring/SKILL.md" 2>&1 || echo "Error reading using-ring skill")

# Escape outputs for JSON
overview_escaped=$(echo "$skills_overview" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')
using_ring_escaped=$(echo "$using_ring_content" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

# Output context injection as JSON
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<ring-skills-system>\n${overview_escaped}\n\n---\n\n**MANDATORY WORKFLOWS:**\n\n${using_ring_escaped}\n</ring-skills-system>"
  }
}
EOF

exit 0