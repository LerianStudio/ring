#!/usr/bin/env bash
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/telemetry-config.sh" 2>/dev/null || exit 0
ring_telemetry_init || exit 0

SESSION_FILE="$(ring_telemetry_session_file)"
[[ -f "$SESSION_FILE" ]] || exit 0

INPUT="$(ring_telemetry_read_stdin)"
RAW_TOOL="$(printf '%s' "$INPUT" | jq -r '.tool_name // .tool // .name // "unknown"' 2>/dev/null || printf 'unknown')"
TOOL_NAME="$(printf '%s' "$RAW_TOOL" | tr -cd 'A-Za-z0-9_.:-' | cut -c 1-80)"
[[ -n "$TOOL_NAME" ]] || TOOL_NAME="unknown"

NOW_EPOCH="$(ring_telemetry_epoch)"
NOW_ISO="$(ring_telemetry_timestamp)"
SESSION_JSON="$(jq -c \
  --arg tool_name "$TOOL_NAME" \
  --arg now_iso "$NOW_ISO" \
  --argjson now_epoch "$NOW_EPOCH" '
  select(type == "object")
  |
  .activity_count = ((.activity_count // 0) + 1)
  | .last_activity_at = $now_iso
  | .last_activity_tool = $tool_name
  | .tool_counts = ((.tool_counts // {}) as $counts | $counts + {($tool_name): (($counts[$tool_name] // 0) + 1)})
  | .last_activity_epoch = $now_epoch
' "$SESSION_FILE" 2>/dev/null)" || exit 0
printf '%s' "$SESSION_JSON" | jq -e 'type == "object"' >/dev/null 2>&1 || exit 0

ACTIVITY_COUNT="$(printf '%s' "$SESSION_JSON" | jq -r '.activity_count // 0' 2>/dev/null)"
LAST_ACTIVITY_COUNT="$(printf '%s' "$SESSION_JSON" | jq -r '.last_activity_count // 0' 2>/dev/null)"
LAST_ACTIVITY_EMIT_AT="$(printf '%s' "$SESSION_JSON" | jq -r '.last_activity_emit_at // 0' 2>/dev/null)"
ACTIVITY_DELTA=$((ACTIVITY_COUNT - LAST_ACTIVITY_COUNT))
TIME_DELTA=$((NOW_EPOCH - LAST_ACTIVITY_EMIT_AT))

if [[ "$ACTIVITY_DELTA" -lt "${RING_TELEMETRY_ACTIVITY_TOOLS:-5}" && "$TIME_DELTA" -lt "${RING_TELEMETRY_ACTIVITY_SECONDS:-30}" ]]; then
  ring_telemetry_write_session_json "$SESSION_JSON"
  exit 0
fi

SESSION_JSON="$(printf '%s' "$SESSION_JSON" | jq -c --argjson now "$NOW_EPOCH" '.last_activity_emit_at = $now | .last_activity_count = (.activity_count // 0)' 2>/dev/null)"
printf '%s' "$SESSION_JSON" | jq -e 'type == "object"' >/dev/null 2>&1 || exit 0
ring_telemetry_write_session_json "$SESSION_JSON"
PAYLOAD="$(printf '%s' "$SESSION_JSON" | jq -c '{activity_count:(.activity_count // 0),tool_counts:(.tool_counts // {}),last_activity_at:(.last_activity_at // null),last_activity_tool:(.last_activity_tool // "unknown")}' 2>/dev/null)"
EVENT="$(ring_telemetry_envelope_json 'session.activity' "$PAYLOAD")"
ring_telemetry_debug "session.activity count=$ACTIVITY_COUNT tool=$TOOL_NAME"
ring_telemetry_post_background "$EVENT"
exit 0
