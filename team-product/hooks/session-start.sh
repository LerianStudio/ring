#!/bin/bash
# Session start hook for ring-team-product plugin
# Injects quick reference for pre-dev planning workflow

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<ring-team-product-system>\n**Pre-Dev Planning Workflow**\n\n2 planning tracks available:\n\n**Small Track** (<2 days)\n- Gate 1: PRD → business requirements\n- Gate 2: TRD → technical architecture\n- Gate 3: Tasks → work breakdown\n\n**Large Track** (≥2 days)\n- Gates 1-3: PRD → TRD → Tasks\n- Gate 4: API → component contracts\n- Gate 5: Data → entity models\n- Gate 6: Dependencies → tech selection\n- Gate 7-8: Task/Subtask breakdown\n\nStart with: /ring:pre-dev-feature (small) or /ring:pre-dev-full (large)\nFull details: Skill tool with \"ring-team-product:using-team-product\"\n</ring-team-product-system>"
  }
}
EOF
