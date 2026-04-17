#!/usr/bin/env bash
# shellcheck disable=SC2034  # Unused variables OK for exported config
# UserPromptSubmit hook to periodically re-inject instruction files
# Combats context drift in long-running sessions by re-surfacing project instructions
# Supports: CLAUDE.md, AGENTS.md, PROJECT_RULES.md (dedupes symlinks to avoid double-injection)

set -euo pipefail

# Configuration constants
# Re-inject every 3 prompts - balances context freshness with token overhead
# Lower values = more frequent reminders but higher token cost
# Higher values = less overhead but risk of context being forgotten
readonly THROTTLE_INTERVAL=3

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# File types to discover
# PROJECT_RULES.md replaced RULES.md per Lerian standard (2026-04)
INSTRUCTION_FILES=("CLAUDE.md" "AGENTS.md" "PROJECT_RULES.md")

# Context window usage threshold (percentage). When harness reports context ≥ this value,
# force a refresh. Calibrated for 1M-token context windows: 15% ≈ 150k tokens consumed,
# which is already substantial drift territory. Lower = more aggressive refresh (safer,
# higher token cost). Raise if re-injection overhead becomes visible.
readonly CTX_PCT_THRESHOLD=15

# Transcript byte delta threshold (fallback when context_window field unavailable).
# ~200KB of transcript growth ≈ 50k tokens at 4 chars/token estimate.
readonly BYTE_THRESHOLD=200000

# Cooldown: non-temporal triggers require at least this many prompts since last injection.
# Prevents tight loops — a single injection adds 70KB+, context_pct would re-trigger immediately.
readonly MIN_PROMPT_COOLDOWN=2

# Use session-specific state files (per-session, not persistent)
# CLAUDE_SESSION_ID should be provided by Claude Code, fallback to PPID for session isolation
SESSION_ID="${CLAUDE_SESSION_ID:-$PPID}"
STATE_FILE="/tmp/claude-instruction-reminder-${SESSION_ID}.state"
BYTES_FILE="/tmp/claude-instruction-reminder-${SESSION_ID}.bytes"
LAST_INJECT_FILE="/tmp/claude-instruction-reminder-${SESSION_ID}.lastinject"

# Read UserPromptSubmit event JSON from stdin (non-blocking if no stdin).
# Claude Code provides: session_id, transcript_path, cwd, user_prompt, hook_event_name,
# and (recently added) context_window with .used_percentage / .used_tokens / .total_tokens.
hook_input=""
if [ ! -t 0 ]; then
  hook_input=$(cat)
fi

# Extract context metrics from hook event JSON.
# PRIMARY signal: context_window.used_percentage (direct from harness, authoritative).
# SECONDARY signal: transcript_path → byte delta (heuristic fallback for older harness versions).
ctx_pct=0
ctx_tokens=0
transcript_path=""
if [ -n "$hook_input" ] && command -v jq >/dev/null 2>&1; then
  ctx_pct=$(echo "$hook_input" | jq -r '.context_window.used_percentage // 0' 2>/dev/null || echo 0)
  ctx_tokens=$(echo "$hook_input" | jq -r '.context_window.used_tokens // 0' 2>/dev/null || echo 0)
  transcript_path=$(echo "$hook_input" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")
fi

# Transcript byte measurement (fallback proxy when context_window unavailable).
current_bytes=0
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  current_bytes=$(wc -c < "$transcript_path" 2>/dev/null | tr -d ' ' || echo 0)
fi
last_bytes=0
if [ -f "$BYTES_FILE" ]; then
  last_bytes=$(cat "$BYTES_FILE" 2>/dev/null || echo 0)
fi
delta_bytes=$((current_bytes - last_bytes))

# Cumulative prompt count (for display and temporal trigger).
if [ -f "$STATE_FILE" ]; then
  PROMPT_COUNT=$(cat "$STATE_FILE")
else
  PROMPT_COUNT=0
fi
PROMPT_COUNT=$((PROMPT_COUNT + 1))
echo "$PROMPT_COUNT" > "$STATE_FILE"

# Prompts since last injection (for cooldown enforcement on non-temporal triggers).
LAST_INJECT_PROMPT=0
if [ -f "$LAST_INJECT_FILE" ]; then
  LAST_INJECT_PROMPT=$(cat "$LAST_INJECT_FILE" 2>/dev/null || echo 0)
fi
prompts_since_inject=$((PROMPT_COUNT - LAST_INJECT_PROMPT))

# Trigger cascade (first match wins; order reflects signal quality and priority):
#   1. Temporal floor — guaranteed baseline, fires every THROTTLE_INTERVAL prompts.
#   2. Context-window saturation — most accurate signal, uses harness-reported usage.
#   3. Volumetric fallback — proxy via transcript bytes when context_window missing.
# Cooldown applies to (2) and (3) to prevent re-injection on consecutive prompts.
should_inject=false
trigger_reason=""
if [ $((PROMPT_COUNT % THROTTLE_INTERVAL)) -eq 0 ]; then
  should_inject=true
  trigger_reason="temporal (prompt ${PROMPT_COUNT})"
elif [ "$prompts_since_inject" -ge "$MIN_PROMPT_COOLDOWN" ] && [ "${ctx_pct:-0}" -ge "$CTX_PCT_THRESHOLD" ] 2>/dev/null; then
  should_inject=true
  trigger_reason="context-window (${ctx_pct}% used, ${ctx_tokens} tokens)"
elif [ "$prompts_since_inject" -ge "$MIN_PROMPT_COOLDOWN" ] && [ "$current_bytes" -gt 0 ] && [ "$delta_bytes" -gt "$BYTE_THRESHOLD" ]; then
  should_inject=true
  trigger_reason="volumetric (+${delta_bytes} bytes since last inject)"
fi

if [ "$should_inject" != true ]; then
  # Not time to inject, return empty response.
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit"
  }
}
EOF
  exit 0
fi

# Injecting — record state for next invocation's delta/cooldown calculations.
echo "$PROMPT_COUNT" > "$LAST_INJECT_FILE"
if [ "$current_bytes" -gt 0 ]; then
  echo "$current_bytes" > "$BYTES_FILE"
fi

# Time to inject! Find all instruction files

# Array to store all instruction file paths
declare -a instruction_files=()

# For each file type, discover global, project root, and subdirectories
for file_name in "${INSTRUCTION_FILES[@]}"; do
  # 1. Global file (~/.claude/CLAUDE.md, ~/.claude/AGENTS.md, etc.)
  global_file="${HOME}/.claude/${file_name}"
  if [ -f "$global_file" ]; then
    instruction_files+=("$global_file")
  fi

  # 2. Project root file
  if [ -f "${PROJECT_DIR}/${file_name}" ]; then
    instruction_files+=("${PROJECT_DIR}/${file_name}")
  fi

  # 3. All subdirectory files
  # Use find to discover files in project tree (exclude hidden dirs and common ignores)
  while IFS= read -r -d '' file; do
    instruction_files+=("$file")
  done < <(find "$PROJECT_DIR" \
    -type f -not -type l \
    -name "$file_name" \
    -not -path "*/\.*" \
    -not -path "*/node_modules/*" \
    -not -path "*/vendor/*" \
    -not -path "*/.venv/*" \
    -not -path "*/dist/*" \
    -not -path "*/build/*" \
    -print0 2>/dev/null)
done

# Canonicalize path for symlink-aware dedup.
# Tries coreutils `realpath`, then Python, then raw path. Graceful fallback ensures
# the hook still functions (just without symlink-dedup) on minimal environments.
canonicalize_path() {
  if command -v realpath >/dev/null 2>&1; then
    realpath "$1" 2>/dev/null || echo "$1"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$1" 2>/dev/null || echo "$1"
  else
    echo "$1"
  fi
}

# JSON-encode file content for safe embedding in hook output.
# RFC 8259 mandates escaping all control characters U+0000..U+001F as \uXXXX when they
# lack short-form escapes (\n \r \t \b \f). Hand-rolled awk regex misses vertical tab,
# null bytes, ESC, etc. — CLAUDE.md files in the wild contain these (415 lines in Ring's
# project CLAUDE.md had unescaped control chars when audited). Cascade: jq → python3 → awk.
# jq -Rs: raw input, slurped as single string; `.` emits it as a JSON string literal.
# We strip the outer quotes to splice into a larger JSON string being built by the hook.
escape_for_json() {
  local f="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -Rs '.' < "$f" | sed -e '1s/^"//' -e '$s/"$//'
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c '
import sys, json
with open(sys.argv[1], "r", encoding="utf-8", errors="replace") as fh:
    # json.dumps wraps in quotes; strip them to match jq -Rs behavior
    sys.stdout.write(json.dumps(fh.read())[1:-1])
' "$f"
  else
    # Last-resort awk escape. Known to miss some control characters — see RFC 8259.
    awk '
      BEGIN { ORS="" }
      {
        gsub(/\\/, "\\\\")
        gsub(/"/, "\\\"")
        gsub(/\t/, "\\t")
        gsub(/\r/, "\\r")
        gsub(/\f/, "\\f")
        if (NR > 1) printf "\\n"
        printf "%s", $0
      }
      END { printf "\\n" }
    ' "$f"
  fi
}

# Dedup by canonical path to handle two cases:
# 1. Same file discovered via different methods (project root + find)
# 2. Symlinks (e.g., Ring convention: AGENTS.md -> CLAUDE.md) — avoid double-injection
# First occurrence wins, which preserves INSTRUCTION_FILES priority order
# (CLAUDE.md displayed before AGENTS.md when they share the same inode).
if [ "${#instruction_files[@]}" -gt 0 ]; then
  unique_files=()
  seen_paths=""
  for f in "${instruction_files[@]}"; do
    real_f=$(canonicalize_path "$f")
    # Newline delimiters avoid substring collisions between similar paths
    case "${seen_paths}" in
      *$'\n'"${real_f}"$'\n'*)
        # Already seen (likely symlink target) — skip silently
        ;;
      *)
        unique_files+=("$f")
        seen_paths="${seen_paths}"$'\n'"${real_f}"$'\n'
        ;;
    esac
  done
  instruction_files=("${unique_files[@]}")
fi

# Build reminder context
reminder="<instruction-files-reminder>\n"
reminder="${reminder}Re-reading instruction files to combat context drift — trigger: ${trigger_reason}\n\n"

for file in "${instruction_files[@]}"; do
  # Get relative path for display
  file_name=$(basename "$file")

  if [[ "$file" == "${HOME}/.claude/"* ]]; then
    display_path="~/.claude/${file_name} (global)"
  else
    # Create relative path (cross-platform compatible)
    display_path="${file#$PROJECT_DIR/}"
    # If the file IS the project dir (no relative path created), just show filename
    if [[ "$display_path" == "$file" ]]; then
      display_path="$file_name"
    fi
  fi

  # Choose emoji based on file type
  case "$file_name" in
    CLAUDE.md)
      emoji="📋"
      ;;
    AGENTS.md)
      emoji="🤖"
      ;;
    PROJECT_RULES.md)
      emoji="📜"
      ;;
    *)
      emoji="📄"
      ;;
  esac

  reminder="${reminder}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
  reminder="${reminder}${emoji} ${display_path}\n"
  reminder="${reminder}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

  # JSON-encode file content (RFC 8259 compliant via jq/python3 cascade).
  escaped_content=$(escape_for_json "$file")

  reminder="${reminder}${escaped_content}\n\n"
done

reminder="${reminder}</instruction-files-reminder>\n"

# Add agent usage reminder (compact, ~200 tokens)
agent_reminder="<agent-usage-reminder>\n"
agent_reminder="${agent_reminder}CONTEXT CHECK: Before using Glob/Grep/Read chains, consider agents:\n\n"
agent_reminder="${agent_reminder}| Task | Agent |\n"
agent_reminder="${agent_reminder}|------|-------|\n"
agent_reminder="${agent_reminder}| Explore codebase | Explore |\n"
agent_reminder="${agent_reminder}| Multi-file search | Explore |\n"
agent_reminder="${agent_reminder}| Complex research | general-purpose |\n"
agent_reminder="${agent_reminder}| Code review | ALL 8 reviewers in PARALLEL (code, business-logic, security, test, nil-safety, consequences, dead-code, performance) |\n"
agent_reminder="${agent_reminder}| Implementation plan | ring:write-plan |\n"
agent_reminder="${agent_reminder}| Deep architecture | ring:codebase-explorer |\n\n"
agent_reminder="${agent_reminder}**3-File Rule:** If reading >3 files, use an agent instead. 15x more context-efficient.\n"
agent_reminder="${agent_reminder}</agent-usage-reminder>\n"

reminder="${reminder}${agent_reminder}"

# Add duplication prevention reminder
duplication_guard="<duplication-prevention-guard>\n"
duplication_guard="${duplication_guard}**BEFORE ADDING CONTENT** to any file:\n"
duplication_guard="${duplication_guard}1. SEARCH FIRST: \`grep -r 'keyword' --include='*.md'\`\n"
duplication_guard="${duplication_guard}2. If exists -> REFERENCE it, don't copy\n"
duplication_guard="${duplication_guard}3. Canonical sources: CLAUDE.md (rules), docs/*.md (details)\n"
duplication_guard="${duplication_guard}4. NEVER duplicate - always link to single source of truth\n"
duplication_guard="${duplication_guard}</duplication-prevention-guard>\n"

reminder="${reminder}${duplication_guard}"

# Output hook response with injected context
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "${reminder}"
  }
}
EOF

exit 0
