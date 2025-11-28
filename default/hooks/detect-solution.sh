#!/usr/bin/env bash
# shellcheck disable=SC2034  # Unused variables OK for exported config
# detect-solution.sh - Detect solution confirmation phrases and suggest codify skill
# Called by UserPromptSubmit hook to auto-suggest documentation after fixes
#
# Hook Order: This hook runs AFTER claude-md-reminder.sh in UserPromptSubmit sequence
# See hooks.json for the full hook chain configuration

set -euo pipefail

# Configuration constants
readonly MAX_INPUT_SIZE=100000  # Limit input size to prevent resource exhaustion

# Read hook input from stdin with size limit BEFORE storing in memory
# This prevents memory exhaustion from maliciously large inputs
HOOK_INPUT=$(head -c "$MAX_INPUT_SIZE")

# Extract user message from JSON input with proper error handling
USER_MESSAGE=$(echo "$HOOK_INPUT" | jq -r '.userMessage // empty' 2>/dev/null)
JQ_EXIT_CODE=$?
if [[ $JQ_EXIT_CODE -ne 0 ]]; then
    echo '{"error": "jq parsing failed", "exitCode": '$JQ_EXIT_CODE'}' >&2
    exit 0
fi

# Exit silently if no message
[[ -z "$USER_MESSAGE" ]] && exit 0

# Convert to lowercase for case-insensitive matching
MSG_LOWER=$(echo "$USER_MESSAGE" | tr '[:upper:]' '[:lower:]')

# Detection patterns for solution confirmation
# These phrases typically indicate a problem was just solved
# NOTE: Single-word patterns removed to reduce false positives (M4 fix)
PATTERNS=(
    # Explicit confirmation phrases (high confidence)
    "that worked"
    "it's fixed"
    "its fixed"
    "fixed it"
    "working now"
    "problem solved"
    "solved it"
    "that did it"
    "all good now"
    "issue resolved"
    "finally working"
    "works now"
    "that was it"
    "got it working"
    "issue fixed"
    # Gratitude with confirmation (high confidence)
    "thank you, it works"
    "thanks, working"
    "thanks, that fixed"
    # Note: Removed single-word patterns ("perfect", "awesome", "excellent", "nice", "great")
    # and ambiguous short phrases ("looks good", "all good", "good to go")
    # to reduce false positives from general positive feedback
)

# Check if any pattern matches
MATCHED=false
for pattern in "${PATTERNS[@]}"; do
    if [[ "$MSG_LOWER" == *"$pattern"* ]]; then
        MATCHED=true
        break
    fi
done

# If matched, output suggestion via additionalContext
if [[ "$MATCHED" == "true" ]]; then
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "<codify-suggestion>\nIt looks like you've solved a problem! Would you like to document this solution for future reference?\n\nRun: /ring-default:codify\nOr say: 'yes, document this' to capture the solution.\n\nThis builds a searchable knowledge base in docs/solutions/ that helps future debugging.\n</codify-suggestion>"
  }
}
EOF
fi

exit 0
