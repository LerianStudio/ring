#!/usr/bin/env bash
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/telemetry-config.sh" 2>/dev/null || exit 0
ring_telemetry_init || exit 0

SESSION_FILE="$(ring_telemetry_session_file)"
[[ -f "$SESSION_FILE" ]] || exit 0

INPUT="$(ring_telemetry_read_stdin)"
FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // .file_path // empty' 2>/dev/null || true)"
CONTENT="$(printf '%s' "$INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null || true)"
[[ "$FILE_PATH" == *"token-log.jsonl" ]] || exit 0

LAST_ENTRY=""
if [[ -n "$CONTENT" ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] && LAST_ENTRY="$line"
  done <<<"$CONTENT"
elif [[ -f "$FILE_PATH" ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] && LAST_ENTRY="$line"
  done < <(tail -n 200 "$FILE_PATH" 2>/dev/null || true)
fi
printf '%s' "$LAST_ENTRY" | jq -e 'type == "object"' >/dev/null 2>&1 || exit 0

CYCLE_ID="$(printf '%s' "$LAST_ENTRY" | jq -r '.cycle_id // empty' 2>/dev/null || true)"
WORK_ID="$(printf '%s' "$LAST_ENTRY" | jq -r '.work_id // empty' 2>/dev/null || true)"
SEARCH_DIR="$(dirname "$FILE_PATH" 2>/dev/null || pwd)"
while [[ ( -z "$CYCLE_ID" || -z "$WORK_ID" ) && "$SEARCH_DIR" != "/" && -n "$SEARCH_DIR" ]]; do
  if [[ -f "$SEARCH_DIR/current-work.json" ]]; then
    [[ -n "$WORK_ID" ]] || WORK_ID="$(jq -r '.work_id // .id // .metadata.work_id // empty' "$SEARCH_DIR/current-work.json" 2>/dev/null || true)"
    [[ -n "$CYCLE_ID" ]] || CYCLE_ID="$(jq -r '.cycle_id // .metadata.cycle_id // empty' "$SEARCH_DIR/current-work.json" 2>/dev/null || true)"
  fi
  if [[ -z "$CYCLE_ID" && -f "$SEARCH_DIR/current-cycle.json" ]]; then
    CYCLE_ID="$(jq -r '.cycle_id // .id // .metadata.cycle_id // empty' "$SEARCH_DIR/current-cycle.json" 2>/dev/null || true)"
  fi
  SEARCH_DIR="$(dirname "$SEARCH_DIR" 2>/dev/null || printf '/')"
done

PAYLOAD="$(jq -n --argjson entry "$LAST_ENTRY" --arg cycle_id "$CYCLE_ID" --arg work_id "$WORK_ID" '
  $entry + {
    cycle_id: (($entry.cycle_id // null) // (if $cycle_id == "" then null else $cycle_id end)),
    work_id: (($entry.work_id // null) // (if $work_id == "" then null else $work_id end)),
    source: "token-log.jsonl"
  }
' 2>/dev/null)"
printf '%s' "$PAYLOAD" | jq -e 'type == "object"' >/dev/null 2>&1 || exit 0

EVENT="$(ring_telemetry_envelope_json 'cycle.token_report' "$PAYLOAD")"
ring_telemetry_debug "cycle.token_report path=$FILE_PATH cycle_id=$CYCLE_ID work_id=$WORK_ID"
ring_telemetry_post_background "$EVENT"
exit 0
