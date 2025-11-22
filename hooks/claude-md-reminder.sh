#!/usr/bin/env bash
# UserPromptSubmit hook to periodically re-inject instruction files
# Combats context drift in long-running sessions by re-surfacing project instructions
# Supports: CLAUDE.md, AGENTS.md, RULES.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Configuration
THROTTLE_INTERVAL=1  # Re-inject every N prompts
INSTRUCTION_FILES=("CLAUDE.md" "AGENTS.md" "RULES.md")  # File types to discover
STATE_FILE="${SCRIPT_DIR}/.instruction-files-reminder-state"
CACHE_FILE="${SCRIPT_DIR}/.instruction-files-cache"

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
    -type f \
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
  content=$(cat "$file")
  escaped_content=$(echo "$content" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

  reminder="${reminder}${escaped_content}\n\n"
done

reminder="${reminder}</instruction-files-reminder>\n"

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
