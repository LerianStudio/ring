#!/usr/bin/env bash
# UserPromptSubmit hook to enforce dev-feedback-loop execution
# Checks state file for completed tasks that haven't had feedback-loop run

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
STATE_FILE="${PROJECT_DIR}/docs/refactor/current-cycle.json"

# Check if state file exists
if [ ! -f "$STATE_FILE" ]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit"
  }
}
EOF
  exit 0
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit"
  }
}
EOF
  exit 0
fi

# Read state and check for tasks needing feedback-loop
# Look for: task completed but feedback_loop_completed is false/null
needs_feedback=$(jq -r '
  .tasks[]? | 
  select(.status == "completed" and (.feedback_loop_completed != true)) |
  .id
' "$STATE_FILE" 2>/dev/null | head -1)

# Also check cycle-level: if status is "completed" but feedback not run
cycle_status=$(jq -r '.status // "unknown"' "$STATE_FILE" 2>/dev/null)
cycle_feedback=$(jq -r '.feedback_loop_completed // false' "$STATE_FILE" 2>/dev/null)

# Determine if enforcement needed
enforce_feedback=false
enforcement_reason=""

if [ -n "$needs_feedback" ] && [ "$needs_feedback" != "null" ]; then
  enforce_feedback=true
  enforcement_reason="Task ${needs_feedback} completed but dev-feedback-loop not executed"
elif [ "$cycle_status" = "completed" ] && [ "$cycle_feedback" != "true" ]; then
  enforce_feedback=true
  enforcement_reason="Cycle completed but dev-feedback-loop not executed"
fi

# If no enforcement needed, return empty
if [ "$enforce_feedback" = false ]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit"
  }
}
EOF
  exit 0
fi

# Build enforcement message
reminder="<feedback-loop-enforcement>\\n"
reminder="${reminder}**⛔ HARD GATE: dev-feedback-loop REQUIRED**\\n\\n"
reminder="${reminder}**Reason:** ${enforcement_reason}\\n\\n"
reminder="${reminder}**YOU MUST EXECUTE THIS TOOL CALL NOW:**\\n\\n"
reminder="${reminder}\\\`\\\`\\\`yaml\\n"
reminder="${reminder}Skill tool:\\n"
reminder="${reminder}  skill_name: \\\"ring-dev-team:dev-feedback-loop\\\"\\n"
reminder="${reminder}\\\`\\\`\\\`\\n\\n"
reminder="${reminder}**After executing feedback-loop, update state file:**\\n"
reminder="${reminder}- Set \\\`feedback_loop_completed: true\\\` on the task/cycle\\n\\n"
reminder="${reminder}| Rationalization | Why It's WRONG |\\n"
reminder="${reminder}|-----------------|----------------|\\n"
reminder="${reminder}| \\\"Will run later\\\" | Later = never. Run NOW. |\\n"
reminder="${reminder}| \\\"Task simple, skip metrics\\\" | Simple tasks still need tracking |\\n"
reminder="${reminder}| \\\"User didn't ask for it\\\" | Feedback-loop is MANDATORY, not optional |\\n"
reminder="${reminder}</feedback-loop-enforcement>\\n"

# Add TodoWrite reminder
reminder="${reminder}\\n<todowrite-enforcement>\\n"
reminder="${reminder}**TodoWrite REQUIRED:** Add feedback-loop to your todo list:\\n\\n"
reminder="${reminder}\\\`\\\`\\\`json\\n"
reminder="${reminder}{\\n"
reminder="${reminder}  \\\"id\\\": \\\"feedback-loop\\\",\\n"
reminder="${reminder}  \\\"content\\\": \\\"Execute dev-feedback-loop skill (MANDATORY)\\\",\\n"
reminder="${reminder}  \\\"status\\\": \\\"in_progress\\\",\\n"
reminder="${reminder}  \\\"priority\\\": \\\"high\\\"\\n"
reminder="${reminder}}\\n"
reminder="${reminder}\\\`\\\`\\\`\\n"
reminder="${reminder}</todowrite-enforcement>"

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "${reminder}"
  }
}
EOF

exit 0
