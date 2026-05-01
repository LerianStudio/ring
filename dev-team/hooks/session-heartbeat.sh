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
[[ -n "$FILE_PATH" ]] || exit 0

NOW="$(ring_telemetry_epoch)"
SESSION_JSON="$(jq -c --arg file_path "$FILE_PATH" --argjson now "$NOW" '
  select(type == "object")
  |
  .writes_count = ((.writes_count // 0) + 1)
  | .files_touched = (((.files_touched // []) + [$file_path]) | unique)
  | .last_write_at = $now
' "$SESSION_FILE" 2>/dev/null)" || exit 0
printf '%s' "$SESSION_JSON" | jq -e 'type == "object"' >/dev/null 2>&1 || exit 0

WRITES_COUNT="$(printf '%s' "$SESSION_JSON" | jq -r '.writes_count // 0' 2>/dev/null)"
LAST_HEARTBEAT_WRITES="$(printf '%s' "$SESSION_JSON" | jq -r '.last_heartbeat_writes // 0' 2>/dev/null)"
LAST_HEARTBEAT_AT="$(printf '%s' "$SESSION_JSON" | jq -r '.last_heartbeat_at // 0' 2>/dev/null)"
WRITE_DELTA=$((WRITES_COUNT - LAST_HEARTBEAT_WRITES))
TIME_DELTA=$((NOW - LAST_HEARTBEAT_AT))

if [[ "$WRITE_DELTA" -lt "${RING_TELEMETRY_HEARTBEAT_WRITES:-10}" && "$TIME_DELTA" -lt "${RING_TELEMETRY_HEARTBEAT_SECONDS:-300}" ]]; then
  ring_telemetry_write_session_json "$SESSION_JSON"
  exit 0
fi

SESSION_JSON="$(printf '%s' "$SESSION_JSON" | jq -c --argjson now "$NOW" '.last_heartbeat_at = $now | .last_heartbeat_writes = (.writes_count // 0)' 2>/dev/null)"
printf '%s' "$SESSION_JSON" | jq -e 'type == "object"' >/dev/null 2>&1 || exit 0
ring_telemetry_write_session_json "$SESSION_JSON"
PAYLOAD="$(printf '%s' "$SESSION_JSON" | jq -c '{writes_count:(.writes_count // 0),files_touched:(.files_touched // []),structured:(.structured // false)}' 2>/dev/null)"
EVENT="$(ring_telemetry_envelope_json 'session.heartbeat' "$PAYLOAD")"
ring_telemetry_debug "session.heartbeat writes=$WRITES_COUNT file=$FILE_PATH"
ring_telemetry_post_background "$EVENT"
exit 0
