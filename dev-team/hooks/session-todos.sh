#!/usr/bin/env bash
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/telemetry-config.sh" 2>/dev/null || exit 0
ring_telemetry_init || exit 0

SESSION_FILE="$(ring_telemetry_session_file)"
[[ -f "$SESSION_FILE" ]] || exit 0

INPUT="$(ring_telemetry_read_stdin)"
RAW_TOOL="$(printf '%s' "$INPUT" | jq -r '.tool_name // .tool // .name // .toolName // "unknown"' 2>/dev/null || printf 'unknown')"
TOOL_KEY="$(printf '%s' "$RAW_TOOL" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_')"

case "$TOOL_KEY" in
  todowrite|todoread|todo_write|todo_read) ;;
  *) exit 0 ;;
esac

TODOS_JSON="$(printf '%s' "$INPUT" | jq -c '
  (.tool_input.todos // .args.todos // .todos // .output.todos // .result.todos)
  | select(type == "array")
' 2>/dev/null)" || exit 0
[[ -n "$TODOS_JSON" ]] || exit 0

NORMALIZED_TODOS="$(printf '%s' "$TODOS_JSON" | jq -c '
  def norm_status:
    tostring | ascii_downcase as $value
    | if ["pending", "in_progress", "completed", "cancelled"] | index($value) then $value else "unknown" end;
  def norm_priority:
    tostring | ascii_downcase as $value
    | if ["high", "medium", "low"] | index($value) then $value else "unknown" end;
  [to_entries[]
    | .key as $index
    | .value
    | select(type == "object")
    | (.content // "") as $content
    | (.status // "unknown" | norm_status) as $status
    | (.priority // "unknown" | norm_priority) as $priority
    | {
        id: ((.id // "todo-\($index)") | tostring | gsub("[^A-Za-z0-9_.:-]"; "") | .[0:120]),
        content: ($content | tostring),
        status: $status,
        priority: $priority
      }
    | select(.content != "")
    | .id = (if .id == "" then "todo-\($index)" else .id end)
  ]
' 2>/dev/null)" || exit 0

printf '%s' "$NORMALIZED_TODOS" | jq -e 'type == "array" and length > 0' >/dev/null 2>&1 || exit 0

SUMMARY_JSON="$(printf '%s' "$NORMALIZED_TODOS" | jq -c '
  reduce .[] as $todo ({pending:0,in_progress:0,completed:0,cancelled:0,unknown:0};
    .[$todo.status] = ((.[$todo.status] // 0) + 1)
  )
' 2>/dev/null)" || exit 0

SESSION_JSON="$(jq -c \
  --argjson todos "$NORMALIZED_TODOS" \
  --argjson summary "$SUMMARY_JSON" \
  'select(type == "object") | .todos = $todos | .todo_summary = $summary' \
  "$SESSION_FILE" 2>/dev/null)" || exit 0
printf '%s' "$SESSION_JSON" | jq -e 'type == "object"' >/dev/null 2>&1 || exit 0
ring_telemetry_write_session_json "$SESSION_JSON"

PAYLOAD="$(jq -n --argjson todos "$NORMALIZED_TODOS" --argjson summary "$SUMMARY_JSON" '{todos:$todos,summary:$summary}' 2>/dev/null)" || exit 0
EVENT="$(ring_telemetry_envelope_json 'session.todos_update' "$PAYLOAD")"
ring_telemetry_debug "session.todos_update count=$(printf '%s' "$NORMALIZED_TODOS" | jq -r 'length' 2>/dev/null) tool=$TOOL_KEY"
ring_telemetry_post_background "$EVENT"
exit 0
