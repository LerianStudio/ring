#!/usr/bin/env bash
# shellcheck disable=SC2034  # Unused variables OK for exported config

# Ralph Wiggum Stop Hook
# Prevents session exit when a ralph-loop is active
# Feeds Claude's output back as input to continue the loop

set -euo pipefail

# Configuration constants
readonly MAX_OUTPUT_SIZE_BYTES=1048576  # 1MB limit to prevent OOM
readonly SESSION_ID_LENGTH=8
readonly LOCK_TIMEOUT_SECONDS=5
readonly MIN_PROMPT_LENGTH=10
readonly MAX_PROMPT_LENGTH=100000

# Cleanup function for temp files with robust resource handling
cleanup_lock() {
    if [[ -n "${LOCK_FD:-}" ]]; then
        exec {LOCK_FD}>&- 2>/dev/null || true
    fi
    [[ -f "${LOCK_FILE:-}" ]] && rm -f "$LOCK_FILE" || true
}

cleanup() {
  [[ -n "${TEMP_FILE:-}" ]] && [[ -f "$TEMP_FILE" ]] && rm -f "$TEMP_FILE" || true
  cleanup_lock
}
trap cleanup EXIT

# Check for required dependency: jq
if ! command -v jq &>/dev/null; then
  echo "⚠️  Ralph loop: Missing required dependency 'jq'" >&2
  echo "   Install with: brew install jq (macOS) or apt install jq (Linux)" >&2
  echo "   Ralph loop cannot function without jq. Allowing exit." >&2
  echo '{"decision": "approve"}'
  exit 0
fi

# Check for optional dependencies and set flags
HAS_PERL=true
HAS_FLOCK=true

if ! command -v perl &>/dev/null; then
  HAS_PERL=false
  # Only warn once per session by checking if we've warned before
  if [[ ! -f ".claude/.ralph-perl-warned" ]]; then
    echo "⚠️  Ralph loop: 'perl' not found - using basic promise detection." >&2
    echo "   Install perl for better multiline promise support." >&2
    touch ".claude/.ralph-perl-warned" 2>/dev/null || true
  fi
fi

if ! command -v flock &>/dev/null; then
  HAS_FLOCK=false
  # Only warn once per session
  if [[ ! -f ".claude/.ralph-flock-warned" ]]; then
    echo "⚠️  Ralph loop: 'flock' not found - file locking disabled." >&2
    echo "   Install with: brew install flock (macOS) or apt install util-linux (Linux)" >&2
    echo "   Without flock, concurrent operations may cause issues." >&2
    touch ".claude/.ralph-flock-warned" 2>/dev/null || true
  fi
fi

# Read hook input from stdin (advanced stop hook API)
HOOK_INPUT=$(cat)

# Check if ralph-loop is active (find any ralph-loop-*.local.md file)
# Note: Use || true to prevent set -e from exiting if .claude directory doesn't exist
RALPH_STATE_FILE=$(find .claude -maxdepth 1 -name 'ralph-loop-*.local.md' -type f 2>/dev/null | head -1 || true)

if [[ -z "$RALPH_STATE_FILE" ]] || [[ ! -f "$RALPH_STATE_FILE" ]]; then
  # No active loop - allow exit
  echo '{"decision": "approve"}'
  exit 0
fi

# Security: Validate state file is not a symlink (prevents symlink attacks)
if [[ -L "$RALPH_STATE_FILE" ]]; then
  echo "⚠️  Ralph loop: State file is a symlink - refusing to operate for security" >&2
  echo '{"decision": "approve", "reason": "Security: symlink detected in state files"}'
  exit 0
fi

# Get transcript path from hook input EARLY to verify session ownership
TRANSCRIPT_PATH_CHECK=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')

# Validate transcript path is a reasonable location (defense-in-depth, fail-secure)
if [[ -n "$TRANSCRIPT_PATH_CHECK" ]] && [[ "$TRANSCRIPT_PATH_CHECK" != "null" ]]; then
  # Resolve to absolute path and verify it's under expected directories
  RESOLVED_PATH=$(realpath -q "$TRANSCRIPT_PATH_CHECK" 2>/dev/null || echo "")
  # Fail-secure: if realpath fails or path is outside expected directories, allow exit
  if [[ -z "$RESOLVED_PATH" ]]; then
    echo "⚠️  Ralph loop: Could not resolve transcript path. Allowing exit." >&2
    echo '{"decision": "approve"}'
    exit 0
  fi
  if [[ ! "$RESOLVED_PATH" =~ ^(/Users/|/home/|/tmp/|/var/|/private/) ]]; then
    echo "⚠️  Ralph loop: Unexpected transcript path location. Allowing exit." >&2
    echo '{"decision": "approve"}'
    exit 0
  fi
fi

# CRITICAL: Verify this loop was started in THIS session, not a stale file from another session
# Extract session_id from state file (handles various YAML quote formats)
# SYNC-POINT: Format must match setup-ralph-loop.sh output "Session ID: <8-char-alphanumeric>"
STATE_SESSION_ID=$(grep '^session_id:' "$RALPH_STATE_FILE" | sed 's/^session_id: *//' | sed 's/^["'"'"']//; s/["'"'"']$//' | tr -cd 'a-z0-9')

# Defense-in-depth: Validate session ID length (should be exactly SESSION_ID_LENGTH chars)
# This catches corrupted state files or injection attempts
if [[ -n "$STATE_SESSION_ID" ]] && [[ ${#STATE_SESSION_ID} -ne $SESSION_ID_LENGTH ]]; then
  echo "⚠️  Ralph loop: Invalid session ID length (got ${#STATE_SESSION_ID}, expected $SESSION_ID_LENGTH)" >&2
  echo "   File: $RALPH_STATE_FILE" >&2
  echo "   This may indicate state file corruption or tampering." >&2
  echo "   Ralph loop is stopping." >&2
  rm "$RALPH_STATE_FILE"
  echo '{"decision": "approve"}'
  exit 0
fi

if [[ -n "$TRANSCRIPT_PATH_CHECK" ]] && [[ -f "$TRANSCRIPT_PATH_CHECK" ]] && [[ -n "$STATE_SESSION_ID" ]]; then
  # Check if this session's transcript contains evidence of starting this specific loop
  # SYNC-POINT: grep pattern must match setup-ralph-loop.sh line ~229 output format
  if ! grep -qF "Session ID: $STATE_SESSION_ID" "$TRANSCRIPT_PATH_CHECK" 2>/dev/null; then
    # This state file was created by a DIFFERENT session - it's stale
    echo "⚠️  Found stale Ralph state file from another session (ID: $STATE_SESSION_ID)" >&2
    echo "   This session did not start the loop. Cleaning up stale file..." >&2
    rm "$RALPH_STATE_FILE"
    echo '{"decision": "approve"}'
    exit 0
  fi
fi

# Parse markdown frontmatter (YAML between ---) and extract values
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$RALPH_STATE_FILE")
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//')
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//')
# Extract completion_promise and strip surrounding quotes if present
COMPLETION_PROMISE=$(echo "$FRONTMATTER" | grep '^completion_promise:' | sed 's/completion_promise: *//' | sed 's/^"\(.*\)"$/\1/')

# Validate numeric fields before arithmetic operations
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "⚠️  Ralph loop: State file corrupted" >&2
  echo "   File: $RALPH_STATE_FILE" >&2
  echo "   Problem: 'iteration' field is not a valid number (got: '$ITERATION')" >&2
  echo "" >&2
  echo "   This usually means the state file was manually edited or corrupted." >&2
  echo "   Ralph loop is stopping. Run /ralph-loop again to start fresh." >&2
  rm "$RALPH_STATE_FILE"
  echo '{"decision": "approve"}'
  exit 0
fi

if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "⚠️  Ralph loop: State file corrupted" >&2
  echo "   File: $RALPH_STATE_FILE" >&2
  echo "   Problem: 'max_iterations' field is not a valid number (got: '$MAX_ITERATIONS')" >&2
  echo "" >&2
  echo "   This usually means the state file was manually edited or corrupted." >&2
  echo "   Ralph loop is stopping. Run /ralph-loop again to start fresh." >&2
  rm "$RALPH_STATE_FILE"
  echo '{"decision": "approve"}'
  exit 0
fi

# Check if max iterations reached
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "🛑 Ralph loop: Max iterations ($MAX_ITERATIONS) reached."
  rm "$RALPH_STATE_FILE"
  echo '{"decision": "approve"}'
  exit 0
fi

# Get transcript path from hook input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "⚠️  Ralph loop: Transcript file not found" >&2
  echo "   Expected: $TRANSCRIPT_PATH" >&2
  echo "   This is unusual and may indicate a Claude Code internal issue." >&2
  echo "   Ralph loop is stopping." >&2
  rm "$RALPH_STATE_FILE"
  echo '{"decision": "approve"}'
  exit 0
fi

# Read last assistant message from transcript (JSONL format - one JSON per line)
# First check if there are any assistant messages
if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH"; then
  echo "⚠️  Ralph loop: No assistant messages found in transcript" >&2
  echo "   Transcript: $TRANSCRIPT_PATH" >&2
  echo "   This is unusual and may indicate a transcript format issue" >&2
  echo "   Ralph loop is stopping." >&2
  rm "$RALPH_STATE_FILE"
  echo '{"decision": "approve"}'
  exit 0
fi

# Extract last assistant message with explicit error handling
LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)
if [[ -z "$LAST_LINE" ]]; then
  echo "⚠️  Ralph loop: Failed to extract last assistant message" >&2
  echo "   Ralph loop is stopping." >&2
  rm "$RALPH_STATE_FILE"
  echo '{"decision": "approve"}'
  exit 0
fi

# Parse JSON with proper error handling
# Note: $? after assignment always returns 0, so we use if ! pattern
JQ_ERROR=""
if ! LAST_OUTPUT=$(echo "$LAST_LINE" | jq -r '
  .message.content |
  map(select(.type == "text")) |
  map(.text) |
  join("\n")
' 2>&1); then
  JQ_ERROR="$LAST_OUTPUT"
  echo "⚠️  Ralph loop: Failed to parse assistant message JSON" >&2
  echo "   Error: $JQ_ERROR" >&2
  echo "   This may indicate a transcript format issue." >&2
  echo "   Ralph loop is stopping." >&2
  rm "$RALPH_STATE_FILE"
  echo '{"decision": "approve"}'
  exit 0
fi

# Limit output size to prevent OOM
if [[ ${#LAST_OUTPUT} -gt $MAX_OUTPUT_SIZE_BYTES ]]; then
  LAST_OUTPUT="${LAST_OUTPUT:0:$MAX_OUTPUT_SIZE_BYTES}"
fi

if [[ -z "$LAST_OUTPUT" ]]; then
  echo "⚠️  Ralph loop: Assistant message contained no text content." >&2
  echo "   Ralph loop is stopping." >&2
  rm "$RALPH_STATE_FILE"
  echo '{"decision": "approve"}'
  exit 0
fi

# Check for completion promise (only if set)
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  # Extract text from <promise> tags
  PROMISE_TEXT=""

  if [[ "$HAS_PERL" = true ]]; then
    # Perl method: supports multiline, non-greedy matching
    # -0777 slurps entire input, s flag makes . match newlines
    # .*? is non-greedy (takes FIRST tag), whitespace normalized
    PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' 2>/dev/null || echo "")
  else
    # Fallback: grep-based extraction (single-line only, but works without perl)
    # Uses grep -oP for Perl-compatible regex if available, else sed
    if echo "" | grep -oP '' &>/dev/null 2>&1; then
      PROMISE_TEXT=$(echo "$LAST_OUTPUT" | grep -oP '(?<=<promise>)[^<]+(?=</promise>)' | head -1 | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/[[:space:]]\+/ /g')
    else
      # Ultimate fallback: sed-based (limited but portable)
      PROMISE_TEXT=$(echo "$LAST_OUTPUT" | sed -n 's/.*<promise>\([^<]*\)<\/promise>.*/\1/p' | head -1 | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/[[:space:]]\+/ /g')
    fi
  fi

  # Normalize stored promise whitespace for comparison (handles "TASK  COMPLETE" vs "TASK COMPLETE")
  NORMALIZED_PROMISE=$(echo "$COMPLETION_PROMISE" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/[[:space:]]\+/ /g')

  # Use = for literal string comparison (not pattern matching)
  # == in [[ ]] does glob pattern matching which breaks with *, ?, [ characters
  if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "$NORMALIZED_PROMISE" ]]; then
    echo "✅ Ralph loop: Detected <promise>$COMPLETION_PROMISE</promise>"
    rm "$RALPH_STATE_FILE"
    echo '{"decision": "approve"}'
    exit 0
  fi
fi

# Not complete - continue loop with SAME PROMPT
NEXT_ITERATION=$((ITERATION + 1))

# Extract prompt (everything after the closing ---)
# Skip first --- line, skip until second --- line, then print everything after
# Use i>=2 instead of i==2 to handle --- in prompt content
PROMPT_TEXT=$(awk '/^---$/{i++; next} i>=2' "$RALPH_STATE_FILE")

if [[ -z "$PROMPT_TEXT" ]]; then
  echo "⚠️  Ralph loop: State file corrupted or incomplete." >&2
  echo "   File: $RALPH_STATE_FILE" >&2
  echo "   Problem: No prompt text found." >&2
  echo "   This usually means the state file was manually edited or corrupted." >&2
  echo "   Ralph loop is stopping. Run /ralph-wiggum:ralph-loop again to start fresh." >&2
  rm "$RALPH_STATE_FILE"
  echo '{"decision": "approve"}'
  exit 0
fi

# Validate prompt length (defense against corrupted/malicious state files)
PROMPT_LENGTH=${#PROMPT_TEXT}
if [[ $PROMPT_LENGTH -lt $MIN_PROMPT_LENGTH ]]; then
  echo "⚠️  Ralph loop: Prompt too short (${PROMPT_LENGTH} chars, min ${MIN_PROMPT_LENGTH})." >&2
  echo "   File: $RALPH_STATE_FILE" >&2
  echo "   This may indicate state file corruption." >&2
  echo "   Ralph loop is stopping. Run /ralph-wiggum:ralph-loop again." >&2
  rm "$RALPH_STATE_FILE"
  echo '{"decision": "approve"}'
  exit 0
fi

if [[ $PROMPT_LENGTH -gt $MAX_PROMPT_LENGTH ]]; then
  echo "⚠️  Ralph loop: Prompt too long (${PROMPT_LENGTH} chars, max ${MAX_PROMPT_LENGTH})." >&2
  echo "   File: $RALPH_STATE_FILE" >&2
  echo "   Truncating prompt to continue (may affect results)." >&2
  PROMPT_TEXT="${PROMPT_TEXT:0:$MAX_PROMPT_LENGTH}"
fi

# Update iteration in frontmatter with file locking (if available) and secure temp file
LOCK_FILE="${RALPH_STATE_FILE}.lock"

# Atomic file update with proper locking and timeout
update_state_file() {
  local lock_acquired=false

  if [[ "$HAS_FLOCK" = true ]]; then
    # Use flock with timeout to prevent deadlocks
    exec {LOCK_FD}>"$LOCK_FILE"
    if flock -w "$LOCK_TIMEOUT_SECONDS" "$LOCK_FD" 2>/dev/null; then
      lock_acquired=true
    else
      echo "⚠️  Ralph loop: Could not acquire lock within ${LOCK_TIMEOUT_SECONDS}s. Proceeding without lock." >&2
    fi
  fi

  # Use mktemp for secure temp file creation (prevents symlink attacks)
  # Set restrictive umask for temp file (consistent with generate-skills-ref.sh)
  local old_umask
  old_umask=$(umask)
  umask 077
  TEMP_FILE=$(mktemp "${RALPH_STATE_FILE}.XXXXXX")
  umask "$old_umask"

  # Atomic write: write to temp file then rename (atomic on POSIX)
  if sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$RALPH_STATE_FILE" > "$TEMP_FILE" 2>/dev/null; then
    # Sync to disk before rename to ensure durability
    # Note: sync behavior varies by OS (Linux syncs file, macOS syncs all disks)
    # The || true ensures graceful degradation if sync is unavailable
    sync "$TEMP_FILE" 2>/dev/null || true
    if mv "$TEMP_FILE" "$RALPH_STATE_FILE" 2>/dev/null; then
      # Success
      :
    else
      echo "⚠️  Ralph loop: Failed to update state file. Cleaning up." >&2
      rm -f "$TEMP_FILE" 2>/dev/null || true
    fi
  else
    echo "⚠️  Ralph loop: Failed to write temp file. Cleaning up." >&2
    rm -f "$TEMP_FILE" 2>/dev/null || true
  fi

  # Release lock if we acquired one
  if [[ "$lock_acquired" = true ]]; then
    exec {LOCK_FD}>&-
    rm -f "$LOCK_FILE" 2>/dev/null || true
  fi
}

update_state_file

# Build system message with iteration count and completion promise info
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  SYSTEM_MSG="🔄 Ralph iteration $NEXT_ITERATION | To stop: output <promise>$COMPLETION_PROMISE</promise> (ONLY when statement is TRUE - do not lie to exit!)"
else
  SYSTEM_MSG="🔄 Ralph iteration $NEXT_ITERATION | No completion promise set - loop runs infinitely"
fi

# Output JSON to block the stop and feed prompt back
# The "reason" field contains the prompt that will be sent back to Claude
jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

# Exit 0 for successful hook execution
exit 0
