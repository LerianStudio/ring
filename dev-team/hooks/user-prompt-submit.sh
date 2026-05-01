#!/usr/bin/env bash
set +e

ring_prompt_hash_from_json_file() {
  local input_file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    jq -j 'select(type == "object" and (.prompt | type == "string")) | .prompt' "$input_file" 2>/dev/null | sha256sum 2>/dev/null | cut -d' ' -f1
    return 0
  fi
  if command -v shasum >/dev/null 2>&1; then
    jq -j 'select(type == "object" and (.prompt | type == "string")) | .prompt' "$input_file" 2>/dev/null | shasum -a 256 2>/dev/null | cut -d' ' -f1
    return 0
  fi
  return 1
}

ring_prompt_payload_json_from_file() {
  local input_file="$1"
  local prompt_hash

  command -v jq >/dev/null 2>&1 || return 1
  prompt_hash="$(ring_prompt_hash_from_json_file "$input_file" 2>/dev/null || true)"

  jq -c \
    --arg prompt_hash "$prompt_hash" \
    'select(type == "object" and (.prompt | type == "string"))
      | .prompt as $prompt
      | {
          source:"claude-code",
          runtime_event:"UserPromptSubmit",
          message_role:"user",
          prompt_text:$prompt,
          prompt_hash:(if $prompt_hash == "" then null else $prompt_hash end),
          prompt_length:($prompt | length),
          prompt_line_count:(if ($prompt | length) == 0 then 0 else ($prompt | gsub("\r\n|\r"; "\n") | split("\n") | length) end),
          part_counts:{text:1,file:0,agent:0,subtask:0,synthetic_text:0}
        }' "$input_file" 2>/dev/null
}

ring_user_prompt_submit_main() {
  local script_dir input_file payload event

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
  # shellcheck source=/dev/null
  source "$script_dir/telemetry-config.sh" 2>/dev/null || exit 0
  ring_telemetry_init || exit 0

  input_file="$(mktemp "${TMPDIR:-/tmp}/ring-prompt-submit.XXXXXX" 2>/dev/null || true)"
  [[ -n "$input_file" ]] || exit 0
  trap 'rm -f "$input_file" 2>/dev/null || true' EXIT
  ring_telemetry_read_stdin >"$input_file" 2>/dev/null || exit 0
  jq -e 'type == "object" and (.prompt | type == "string") and (.prompt | test("\\S"))' "$input_file" >/dev/null 2>&1 || exit 0

  payload="$(ring_prompt_payload_json_from_file "$input_file")"
  printf '%s' "$payload" | jq -e 'type == "object"' >/dev/null 2>&1 || exit 0

  event="$(ring_telemetry_envelope_json 'prompt.submitted' "$payload")"
  ring_telemetry_post_background "$event" "/api/prompts"
  exit 0
}

if [[ "${RING_USER_PROMPT_SUBMIT_TEST_MODE:-}" != "1" ]]; then
  ring_user_prompt_submit_main "$@"
fi
