#!/usr/bin/env bash
# shellcheck disable=SC2034  # Unused variables OK for exported config

# Ralph Loop Setup Script
# Creates state file for in-session Ralph loop

set -euo pipefail

# Configuration constants (SYNC-POINT: keep in sync with stop-hook.sh)
readonly MIN_PROMPT_LENGTH=10
readonly MAX_PROMPT_LENGTH=100000

# Parse arguments
PROMPT_PARTS=()
MAX_ITERATIONS=0
COMPLETION_PROMISE="null"

# Parse options and positional arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
Ralph Loop - Interactive self-referential development loop

USAGE:
  /ralph-loop [PROMPT...] [OPTIONS]

ARGUMENTS:
  PROMPT...    Initial prompt to start the loop (10-100,000 characters)

OPTIONS:
  --max-iterations <n>           Maximum iterations before auto-stop (default: unlimited)
  --completion-promise '<text>'  Promise phrase (USE QUOTES for multi-word)
  -h, --help                     Show this help message

DESCRIPTION:
  Starts a Ralph Wiggum loop in your CURRENT session. The stop hook prevents
  exit and feeds your output back as input until completion or iteration limit.

  To signal completion, you must output: <promise>YOUR_PHRASE</promise>

  Use this for:
  - Interactive iteration where you want to see progress
  - Tasks requiring self-correction and refinement
  - Learning how Ralph works

EXAMPLES:
  /ralph-loop Build a todo API --completion-promise 'DONE' --max-iterations 20
  /ralph-loop --max-iterations 10 Fix the auth bug
  /ralph-loop Refactor cache layer  (runs forever)
  /ralph-loop --completion-promise 'TASK COMPLETE' Create a REST API

STOPPING:
  Only by reaching --max-iterations or detecting --completion-promise
  No manual stop - Ralph runs infinitely by default!

MONITORING:
  # View current iteration (finds session-based state file):
  grep '^iteration:' .claude/ralph-loop-*.local.md

  # View full state:
  head -10 .claude/ralph-loop-*.local.md
HELP_EOF
      exit 0
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]]; then
        echo "❌ Error: --max-iterations requires a number argument" >&2
        echo "" >&2
        echo "   Valid examples:" >&2
        echo "     --max-iterations 10" >&2
        echo "     --max-iterations 50" >&2
        echo "     --max-iterations 0  (unlimited)" >&2
        echo "" >&2
        echo "   You provided: --max-iterations (with no number)" >&2
        exit 1
      fi
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "❌ Error: --max-iterations must be a positive integer or 0, got: $2" >&2
        echo "" >&2
        echo "   Valid examples:" >&2
        echo "     --max-iterations 10" >&2
        echo "     --max-iterations 50" >&2
        echo "     --max-iterations 0  (unlimited)" >&2
        echo "" >&2
        echo "   Invalid: decimals (10.5), negative numbers (-5), text" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --completion-promise)
      if [[ -z "${2:-}" ]]; then
        echo "❌ Error: --completion-promise requires a text argument" >&2
        echo "" >&2
        echo "   Valid examples:" >&2
        echo "     --completion-promise 'DONE'" >&2
        echo "     --completion-promise 'TASK COMPLETE'" >&2
        echo "     --completion-promise 'All tests passing'" >&2
        echo "" >&2
        echo "   You provided: --completion-promise (with no text)" >&2
        echo "" >&2
        echo "   Note: Multi-word promises must be quoted!" >&2
        exit 1
      fi
      # Normalize whitespace: trim leading/trailing and collapse internal whitespace
      # This ensures "TASK  COMPLETE" matches "TASK COMPLETE" during detection
      COMPLETION_PROMISE=$(echo "$2" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/[[:space:]]\+/ /g')
      if [[ -z "$COMPLETION_PROMISE" ]]; then
        echo "❌ Error: --completion-promise cannot be only whitespace" >&2
        exit 1
      fi
      shift 2
      ;;
    *)
      # Non-option argument - collect all as prompt parts
      PROMPT_PARTS+=("$1")
      shift
      ;;
  esac
done

# Join all prompt parts with spaces
PROMPT="${PROMPT_PARTS[*]}"

# Validate prompt is non-empty
if [[ -z "$PROMPT" ]]; then
  echo "❌ Error: No prompt provided" >&2
  echo "" >&2
  echo "   Ralph needs a task description to work on." >&2
  echo "" >&2
  echo "   Examples:" >&2
  echo "     /ralph-loop Build a REST API for todos" >&2
  echo "     /ralph-loop Fix the auth bug --max-iterations 20" >&2
  echo "     /ralph-loop --completion-promise 'DONE' Refactor code" >&2
  echo "" >&2
  echo "   For all options: /ralph-loop --help" >&2
  exit 1
fi

# Validate prompt length
PROMPT_LENGTH=${#PROMPT}
if [[ $PROMPT_LENGTH -lt $MIN_PROMPT_LENGTH ]]; then
  echo "❌ Error: Prompt too short (${PROMPT_LENGTH} characters, minimum ${MIN_PROMPT_LENGTH})" >&2
  echo "" >&2
  echo "   Your prompt should describe the task clearly." >&2
  echo "" >&2
  echo "   Examples of good prompts:" >&2
  echo "     'Build a REST API for todos with CRUD operations'" >&2
  echo "     'Fix the authentication bug in login.ts'" >&2
  echo "     'Refactor the cache layer to use Redis'" >&2
  exit 1
fi

if [[ $PROMPT_LENGTH -gt $MAX_PROMPT_LENGTH ]]; then
  echo "❌ Error: Prompt too long (${PROMPT_LENGTH} characters, maximum ${MAX_PROMPT_LENGTH})" >&2
  echo "" >&2
  echo "   Consider:" >&2
  echo "     - Breaking down the task into smaller steps" >&2
  echo "     - Moving detailed requirements to a file and referencing it" >&2
  echo "     - Using a more concise description" >&2
  exit 1
fi

# Use file locking to prevent TOCTOU race condition when checking/creating loops
mkdir -p .claude
LOCK_FILE=".claude/ralph-loop.lock"

# Check if flock is available
HAS_FLOCK=true
if ! command -v flock &>/dev/null; then
  HAS_FLOCK=false
  # Only warn once per session
  if [[ ! -f ".claude/.ralph-flock-warned" ]]; then
    echo "⚠️  'flock' not found - file locking disabled." >&2
    echo "   Install with: brew install flock (macOS) or apt install util-linux (Linux)" >&2
    touch ".claude/.ralph-flock-warned" 2>/dev/null || true
  fi
fi

if [[ "$HAS_FLOCK" = true ]]; then
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    echo "⚠️  Another Ralph setup in progress. Please wait..." >&2
    flock 9  # Wait for lock
  fi
fi

# Check for existing active loop (any ralph-loop-*.local.md file)
EXISTING_LOOP=$(find .claude -maxdepth 1 -name 'ralph-loop-*.local.md' -type f 2>/dev/null | head -1)
if [[ -n "$EXISTING_LOOP" ]]; then
  CURRENT_ITERATION=$(grep '^iteration:' "$EXISTING_LOOP" 2>/dev/null | awk '{print $2}' || echo "?")
  # Sanitize session ID display (only alphanumeric)
  EXISTING_SESSION_ID=$(basename "$EXISTING_LOOP" | sed 's/ralph-loop-//' | sed 's/.local.md//' | tr -cd 'a-z0-9')
  echo "⚠️  Ralph loop already active!" >&2
  echo "" >&2
  echo "   State file: $EXISTING_LOOP" >&2
  echo "   Session ID: $EXISTING_SESSION_ID" >&2
  echo "   Current iteration: $CURRENT_ITERATION" >&2
  echo "" >&2
  echo "   To cancel the existing loop first:" >&2
  echo "     /ralph-wiggum:cancel-ralph" >&2
  echo "" >&2
  echo "   Or manually remove the state file:" >&2
  echo "     rm $EXISTING_LOOP" >&2
  # Release lock if we acquired one
  if [[ "$HAS_FLOCK" = true ]]; then
    exec 9>&-
    rm -f "$LOCK_FILE"
  fi
  exit 1
fi

# Generate unique session ID (8 random alphanumeric chars)
SESSION_ID=$(head -c 100 /dev/urandom 2>/dev/null | LC_ALL=C tr -dc 'a-z0-9' | head -c 8)
if [[ -z "$SESSION_ID" ]]; then
  # Fallback for systems without /dev/urandom (macOS date doesn't support %N)
  # Use multiple entropy sources for better randomness
  SESSION_ID=$(printf '%s%s%s' "$$" "$(date +%s)" "$RANDOM" | shasum -a 256 2>/dev/null | head -c 8)
  if [[ -z "$SESSION_ID" ]]; then
    # Ultimate fallback combining multiple entropy sources:
    # - $$ (process ID), $RANDOM, $SECONDS (shell uptime), date
    # XOR combines entropy sources for improved randomness
    SESSION_ID=$(printf '%08x' "$((RANDOM ^ $$ ^ ${SECONDS:-0} ^ $(date +%s)))" | head -c 8)
  fi
fi

# Create state file for stop hook (markdown with YAML frontmatter)
RALPH_STATE_FILE=".claude/ralph-loop-${SESSION_ID}.local.md"

# Escape completion promise for safe YAML embedding (prevents YAML injection)
# Escapes backslashes first, then double quotes
escape_yaml() {
  local str="$1"
  str="${str//\\/\\\\}"  # Escape backslashes
  str="${str//\"/\\\"}"  # Escape double quotes
  str="${str//$'\n'/\\n}"  # Escape newlines
  printf '%s' "$str"
}

if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  ESCAPED_PROMISE=$(escape_yaml "$COMPLETION_PROMISE")
  COMPLETION_PROMISE_YAML="\"$ESCAPED_PROMISE\""
else
  COMPLETION_PROMISE_YAML="null"
fi

# Create state file with restricted permissions using atomic write pattern
# Write to temp file first, then rename (atomic on POSIX filesystems)
create_state_file() {
    local temp_file
    temp_file=$(mktemp ".claude/ralph-loop-${SESSION_ID}.XXXXXX")

    # Write content to temp file with restrictive permissions
    chmod 600 "$temp_file"
    cat > "$temp_file" <<EOF
---
active: true
session_id: "$SESSION_ID"
iteration: 1
max_iterations: $MAX_ITERATIONS
completion_promise: $COMPLETION_PROMISE_YAML
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
---

$PROMPT
EOF

    # Sync to disk before rename for durability
    # Note: sync behavior varies by OS (Linux syncs file, macOS syncs all disks)
    # The || true ensures graceful degradation if sync is unavailable
    sync "$temp_file" 2>/dev/null || true

    # Atomic rename
    if ! mv "$temp_file" "$RALPH_STATE_FILE" 2>/dev/null; then
        echo "❌ Error: Failed to create state file" >&2
        rm -f "$temp_file" 2>/dev/null || true
        # Release lock if held
        if [[ "$HAS_FLOCK" = true ]]; then
            exec 9>&-
            rm -f "$LOCK_FILE"
        fi
        exit 1
    fi
}

create_state_file

# Output setup message
# SYNC-POINT: "Session ID: $SESSION_ID" format must match stop-hook.sh grep pattern
cat <<EOF
🔄 Ralph loop activated in this session!

Session ID: $SESSION_ID
Iteration: 1
Max iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)
Completion promise: $(if [[ "$COMPLETION_PROMISE" != "null" ]]; then echo "${COMPLETION_PROMISE//\"/} (ONLY output when TRUE - do not lie!)"; else echo "none (runs forever)"; fi)

The stop hook is now active. When you try to exit, the SAME PROMPT will be
fed back to you. You'll see your previous work in files, creating a
self-referential loop where you iteratively improve on the same task.

State file: $RALPH_STATE_FILE
To monitor: head -10 $RALPH_STATE_FILE

⚠️  WARNING: This loop cannot be stopped manually! It will run infinitely
    unless you set --max-iterations or --completion-promise.

🔄
EOF

# Release lock after state file is created (if we acquired one)
if [[ "$HAS_FLOCK" = true ]]; then
  exec 9>&-
  rm -f "$LOCK_FILE"
fi

# Output the initial prompt if provided
if [[ -n "$PROMPT" ]]; then
  echo ""
  echo "$PROMPT"
fi
