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

[[ "$FILE_PATH" == *"current-work.json" ]] || exit 0
if [[ -z "$CONTENT" && -f "$FILE_PATH" ]]; then
  CONTENT="$(jq -c . "$FILE_PATH" 2>/dev/null || true)"
fi
printf '%s' "$CONTENT" | jq -e 'type == "object" and (.items | type == "array")' >/dev/null 2>&1 || exit 0

SUMMARY="$(printf '%s' "$CONTENT" | jq -c '
  .items as $items |
  {
    total: ($items | length),
    by_lane: ($items | map(.lane // .status // "unknown") | group_by(.) | map({key: .[0], value: length}) | from_entries),
    by_status: ($items | map(.status // "unknown") | group_by(.) | map({key: .[0], value: length}) | from_entries)
  }
' 2>/dev/null || printf '{}')"

SESSION_JSON="$(jq -c 'select(type == "object") | .structured = true' "$SESSION_FILE" 2>/dev/null)"
printf '%s' "$SESSION_JSON" | jq -e 'type == "object"' >/dev/null 2>&1 || exit 0
ring_telemetry_write_session_json "$SESSION_JSON"

PAYLOAD="$(jq -n \
  --arg state_path "$FILE_PATH" \
  --argjson state "$CONTENT" \
  --argjson summary "$SUMMARY" \
  '{work_id:($state.work_id // $state.id // $state.metadata.work_id // null),workflow:($state.workflow // $state.type // null),status:($state.status // null),state_path:($state.state_path // $state_path),legacy_state_path:($state.legacy_state_path // null),items:$state.items,summary:$summary,state:$state}' 2>/dev/null)"
printf '%s' "$PAYLOAD" | jq -e 'type == "object" and (.items | type == "array")' >/dev/null 2>&1 || exit 0

EVENT="$(ring_telemetry_envelope_json 'work.state_update' "$PAYLOAD")"
ring_telemetry_debug "work.state_update path=$FILE_PATH"
ring_telemetry_post_background "$EVENT"
exit 0
