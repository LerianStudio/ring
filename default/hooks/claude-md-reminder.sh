#!/usr/bin/env bash
# shellcheck disable=SC2034  # Unused variables OK for exported config
# UserPromptSubmit hook to periodically re-inject instruction files
# Combats context drift in long-running sessions by re-surfacing project instructions
# Supports: CLAUDE.md, AGENTS.md, RULES.md

set -euo pipefail

# Configuration constants
# Re-inject every 3 prompts - balances context freshness with token overhead
# Lower values = more frequent reminders but higher token cost
# Higher values = less overhead but risk of context being forgotten
readonly THROTTLE_INTERVAL=3

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# File types to discover
INSTRUCTION_FILES=("CLAUDE.md" "AGENTS.md" "RULES.md")

# Use session-specific state file (per-session, not persistent)
# CLAUDE_SESSION_ID should be provided by Claude Code, fallback to PPID for session isolation
SESSION_ID="${CLAUDE_SESSION_ID:-$PPID}"
STATE_FILE="/tmp/claude-instruction-reminder-${SESSION_ID}.state"
CACHE_FILE="/tmp/claude-instruction-reminder-${SESSION_ID}.cache"

# Initialize or read state
if [ -f "$STATE_FILE" ]; then
  PROMPT_COUNT=$(cat "$STATE_FILE")
else
  PROMPT_COUNT=0
fi

# Increment prompt count
PROMPT_COUNT=$((PROMPT_COUNT + 1))
echo "$PROMPT_COUNT" > "$STATE_FILE"

# Check if we should inject (every THROTTLE_INTERVAL prompts)
if [ $((PROMPT_COUNT % THROTTLE_INTERVAL)) -ne 0 ]; then
  # Not time to inject, return empty
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit"
  }
}
EOF
  exit 0
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

# Remove duplicates (project root might be found twice)
# Use sort -u with proper handling of paths containing spaces/newlines
if [ "${#instruction_files[@]}" -gt 0 ]; then
  # Create a temporary file to store paths (one per line)
  tmp_file=$(mktemp)
  trap "rm -f '$tmp_file'" EXIT INT TERM HUP
  printf '%s\n' "${instruction_files[@]}" | sort -u > "$tmp_file"

  # Read back into array
  instruction_files=()
  while IFS= read -r file; do
    [ -n "$file" ] && instruction_files+=("$file")
  done < "$tmp_file"

  rm -f "$tmp_file"
fi

# Build reminder context
reminder="<instruction-files-reminder>\n"
reminder="${reminder}Re-reading instruction files to combat context drift (prompt ${PROMPT_COUNT}):\n\n"

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
    RULES.md)
      emoji="📜"
      ;;
    *)
      emoji="📄"
      ;;
  esac

  reminder="${reminder}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
  reminder="${reminder}${emoji} ${display_path}\n"
  reminder="${reminder}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

  # Read entire file content and escape for JSON
  # Proper JSON string escaping for all control characters (RFC 8259)
  # Uses gsub for reliable cross-platform escaping (works on BSD and GNU awk)
  escaped_content=$(awk '
    BEGIN { ORS="" }
    {
      # Order matters: backslash must be escaped first
      gsub(/\\/, "\\\\")
      gsub(/"/, "\\\"")
      gsub(/\t/, "\\t")
      gsub(/\r/, "\\r")
      gsub(/\f/, "\\f")
      # Note: \b (backspace) rarely appears in text files, skip to avoid regex issues
      # Add escaped newline between lines
      if (NR > 1) printf "\\n"
      printf "%s", $0
    }
    END { printf "\\n" }
  ' "$file")

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
agent_reminder="${agent_reminder}| Code review | ring-default:code-reviewer + ring-default:business-logic-reviewer + ring-default:security-reviewer (PARALLEL) |\n"
agent_reminder="${agent_reminder}| Implementation plan | ring-default:write-plan |\n"
agent_reminder="${agent_reminder}| Deep architecture | ring-default:codebase-explorer |\n\n"
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
