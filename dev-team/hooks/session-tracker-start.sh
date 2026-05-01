#!/usr/bin/env bash
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/telemetry-config.sh" 2>/dev/null || exit 0
ring_telemetry_init || exit 0

INPUT="$(ring_telemetry_read_stdin)"
TRIGGER="$(printf '%s' "$INPUT" | jq -r '.matcher // .source // .event // "startup"' 2>/dev/null || printf 'startup')"
TOOL="${RING_TELEMETRY_TOOL:-claude-code}"
MODEL="${ANTHROPIC_MODEL:-${CLAUDE_MODEL:-${MODEL:-unknown}}}"
SESSION_ID="$(ring_telemetry_uuid)"
NOW="$(ring_telemetry_epoch)"
CONTEXT_JSON="$(ring_telemetry_repo_context_json)"

SESSION_JSON="$(jq -n \
  --arg id "$SESSION_ID" \
  --arg tool "$TOOL" \
  --arg model "$MODEL" \
  --argjson context "$CONTEXT_JSON" \
  --arg started_at "$(ring_telemetry_timestamp)" \
  --argjson now "$NOW" \
  '{id:$id,tool:$tool,model:$model,started_at:$started_at,writes_count:0,last_heartbeat_writes:0,last_heartbeat_at:$now,files_touched:[],structured:false,activity_count:0,last_activity_count:0,last_activity_at:null,last_activity_tool:null,last_activity_emit_at:$now,tool_counts:{},context:$context}' 2>/dev/null)"

ring_telemetry_write_session_json "$SESSION_JSON"
printf '%s' "$SESSION_JSON" | jq -e 'type == "object"' >/dev/null 2>&1 || exit 0
PAYLOAD="$(jq -n --arg trigger "$TRIGGER" '{trigger:$trigger}' 2>/dev/null)"
EVENT="$(ring_telemetry_envelope_json 'session.start' "$PAYLOAD")"
ring_telemetry_debug "session.start $SESSION_ID trigger=$TRIGGER"
ring_telemetry_post_background "$EVENT"
exit 0
