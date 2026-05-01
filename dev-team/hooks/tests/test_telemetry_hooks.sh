#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TESTS_RUN=0
TESTS_FAILED=0
TEST_TMP_DIR=""

setup_test_env() {
  TEST_TMP_DIR="$(mktemp -d)"
  export HOME="$TEST_TMP_DIR/home"
  export TMPDIR="$TEST_TMP_DIR/tmp"
  export RING_TELEMETRY_CONFIG="$HOME/.ring/telemetry.json"
  mkdir -p "$HOME/.ring" "$TMPDIR"
}

teardown_test_env() {
  if [[ -n "$TEST_TMP_DIR" && -d "$TEST_TMP_DIR" ]]; then
    rm -rf "$TEST_TMP_DIR"
  fi
  unset RING_TELEMETRY_CONFIG RING_TELEMETRY_TOOL RING_TELEMETRY_ENDPOINT RING_TELEMETRY_DEVELOPER_EMAIL RING_TELEMETRY_API_TOKEN RING_TELEMETRY_ALLOW_REMOTE_HTTP TMPDIR HOME
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$expected" == "$actual" ]]; then
    printf 'ok - %s\n' "$test_name"
  else
    printf 'not ok - %s\n  expected: %s\n  actual: %s\n' "$test_name" "$expected" "$actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_file_count() {
  local expected="$1"
  local pattern="$2"
  local test_name="$3"
  local files=($pattern)
  local count=0
  if [[ -e "${files[0]:-}" ]]; then
    count="${#files[@]}"
  fi
  assert_equals "$expected" "$count" "$test_name"
}

write_config() {
  cat > "$RING_TELEMETRY_CONFIG" <<'JSON'
{
  "enabled": true,
  "endpoint": "http://127.0.0.1:4800",
  "developer_email": "dev@example.com",
  "heartbeat_interval_writes": 10,
  "heartbeat_interval_seconds": 300,
  "activity_interval_tools": 5,
  "activity_interval_seconds": 30,
  "debug": false
}
JSON
}

test_missing_config_noop() {
  setup_test_env
  rm -f "$RING_TELEMETRY_CONFIG"
  printf '{}' | bash "$HOOK_DIR/session-tracker-start.sh"
  assert_file_count 0 "$TMPDIR/ring-session-*.json" "missing config does not create session"
  teardown_test_env
}

test_user_prompt_submit_hook_registered() {
  local command timeout
  command="$(jq -r '.hooks.UserPromptSubmit[0].hooks[0].command // empty' "$HOOK_DIR/hooks.json")"
  timeout="$(jq -r '.hooks.UserPromptSubmit[0].hooks[0].timeout // empty' "$HOOK_DIR/hooks.json")"
  assert_equals '${CLAUDE_PLUGIN_ROOT}/hooks/user-prompt-submit.sh' "$command" "user prompt submit hook command registered"
  assert_equals "2" "$timeout" "user prompt submit hook timeout registered"
}

test_user_prompt_submit_missing_config_noop() {
  setup_test_env
  rm -f "$RING_TELEMETRY_CONFIG"
  local stdout_file stderr_file status
  stdout_file="$TEST_TMP_DIR/stdout.txt"
  stderr_file="$TEST_TMP_DIR/stderr.txt"
  status=0
  printf '{"prompt":"raw prompt secret"}' | bash "$HOOK_DIR/user-prompt-submit.sh" >"$stdout_file" 2>"$stderr_file" || status=$?
  assert_equals "0" "$status" "user prompt missing config exits zero"
  assert_equals "" "$(cat "$stdout_file")" "user prompt missing config stdout empty"
  assert_equals "" "$(cat "$stderr_file")" "user prompt missing config stderr empty"
  teardown_test_env
}

test_user_prompt_submit_noop_inputs() {
  setup_test_env
  write_config
  local stdout_file stderr_file status
  stdout_file="$TEST_TMP_DIR/stdout.txt"
  stderr_file="$TEST_TMP_DIR/stderr.txt"
  status=0
  printf '{not json' | bash "$HOOK_DIR/user-prompt-submit.sh" >"$stdout_file" 2>"$stderr_file" || status=$?
  assert_equals "0" "$status" "user prompt malformed json exits zero"
  assert_equals "" "$(cat "$stdout_file")" "user prompt malformed json stdout empty"
  assert_equals "" "$(cat "$stderr_file")" "user prompt malformed json stderr empty"
  status=0
  printf '{"prompt":"   "}' | bash "$HOOK_DIR/user-prompt-submit.sh" >"$stdout_file" 2>"$stderr_file" || status=$?
  assert_equals "0" "$status" "user prompt blank prompt exits zero"
  assert_equals "" "$(cat "$stdout_file")" "user prompt blank prompt stdout empty"
  assert_equals "" "$(cat "$stderr_file")" "user prompt blank prompt stderr empty"
  teardown_test_env
}

test_user_prompt_submit_payload_constructs_raw_prompt() {
  setup_test_env
  export RING_USER_PROMPT_SUBMIT_TEST_MODE=1
  source "$HOOK_DIR/user-prompt-submit.sh"
  local prompt prompt_json input_file payload expected_hash expected_length
  prompt=$'raw prompt secret\nsecond line\n'
  prompt_json="$(printf '%s' "$prompt" | jq -Rs .)"
  input_file="$TEST_TMP_DIR/prompt.json"
  printf '{"prompt":%s}' "$prompt_json" >"$input_file"
  payload="$(ring_prompt_payload_json_from_file "$input_file")"
  expected_hash="$(printf '%s' "$prompt" | shasum -a 256 | cut -d' ' -f1)"
  expected_length="$(printf '%s' "$prompt" | jq -Rs 'length')"
  assert_equals "claude-code" "$(printf '%s' "$payload" | jq -r '.source')" "user prompt payload source"
  assert_equals "UserPromptSubmit" "$(printf '%s' "$payload" | jq -r '.runtime_event')" "user prompt payload runtime event"
  assert_equals "user" "$(printf '%s' "$payload" | jq -r '.message_role')" "user prompt payload message role"
  assert_equals "$prompt_json" "$(printf '%s' "$payload" | jq -c '.prompt_text')" "user prompt payload preserves raw prompt including trailing newline"
  assert_equals "$expected_hash" "$(printf '%s' "$payload" | jq -r '.prompt_hash')" "user prompt payload hash"
  assert_equals "$expected_length" "$(printf '%s' "$payload" | jq -r '.prompt_length')" "user prompt payload length"
  assert_equals "3" "$(printf '%s' "$payload" | jq -r '.prompt_line_count')" "user prompt payload line count"
  assert_equals "1" "$(printf '%s' "$payload" | jq -r '.part_counts.text')" "user prompt payload text part count"
  assert_equals "0" "$(printf '%s' "$payload" | jq -r '.part_counts.file + .part_counts.agent + .part_counts.subtask + .part_counts.synthetic_text')" "user prompt payload non-text part counts"
  unset RING_USER_PROMPT_SUBMIT_TEST_MODE
  teardown_test_env
}

test_user_prompt_submit_stdout_empty_and_stderr_no_prompt() {
  setup_test_env
  write_config
  local prompt stdout_file stderr_file status leaked_stderr
  prompt="raw prompt secret"
  stdout_file="$TEST_TMP_DIR/stdout.txt"
  stderr_file="$TEST_TMP_DIR/stderr.txt"
  status=0
  jq -n --arg prompt "$prompt" '{prompt:$prompt}' | bash "$HOOK_DIR/user-prompt-submit.sh" >"$stdout_file" 2>"$stderr_file" || status=$?
  leaked_stderr="$(jq -n --arg stderr "$(cat "$stderr_file")" --arg prompt "$prompt" '$stderr | contains($prompt)')"
  assert_equals "0" "$status" "user prompt post failure exits zero"
  assert_equals "" "$(cat "$stdout_file")" "user prompt stdout is empty"
  assert_equals "false" "$leaked_stderr" "user prompt stderr does not leak raw prompt"
  teardown_test_env
}

test_user_prompt_submit_posts_to_prompt_endpoint() {
  setup_test_env
  write_config
  local previous_path fake_bin args_file body_file stdout_file stderr_file status endpoint_has_prompts endpoint_has_events
  previous_path="$PATH"
  fake_bin="$TEST_TMP_DIR/bin"
  args_file="$TEST_TMP_DIR/curl-args.txt"
  body_file="$TEST_TMP_DIR/curl-body.json"
  stdout_file="$TEST_TMP_DIR/stdout.txt"
  stderr_file="$TEST_TMP_DIR/stderr.txt"
  mkdir -p "$fake_bin"
  cat >"$fake_bin/curl" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >"$RING_FAKE_CURL_ARGS"
cat >"$RING_FAKE_CURL_BODY"
SH
  chmod +x "$fake_bin/curl"
  export PATH="$fake_bin:$PATH"
  export RING_FAKE_CURL_ARGS="$args_file"
  export RING_FAKE_CURL_BODY="$body_file"

  status=0
  printf '{"prompt":"raw prompt secret"}' | bash "$HOOK_DIR/user-prompt-submit.sh" >"$stdout_file" 2>"$stderr_file" || status=$?
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    [[ -f "$args_file" && -f "$body_file" ]] && break
    sleep 0.1
  done

  endpoint_has_prompts="false"
  endpoint_has_events="false"
  [[ -f "$args_file" && "$(cat "$args_file")" == *"/api/prompts"* ]] && endpoint_has_prompts="true"
  [[ -f "$args_file" && "$(cat "$args_file")" == *"/api/events"* ]] && endpoint_has_events="true"
  assert_equals "0" "$status" "user prompt endpoint post exits zero"
  assert_equals "true" "$endpoint_has_prompts" "user prompt posts to /api/prompts"
  assert_equals "false" "$endpoint_has_events" "user prompt does not post to /api/events"
  assert_equals "prompt.submitted" "$(jq -r '.event_type' "$body_file" 2>/dev/null || true)" "user prompt post body is prompt event"

  export PATH="$previous_path"
  unset RING_FAKE_CURL_ARGS RING_FAKE_CURL_BODY
  teardown_test_env
}

test_helper_config_enabled_parsing() {
  setup_test_env
  write_config
  source "$HOOK_DIR/telemetry-config.sh"
  ring_telemetry_init
  assert_equals "http://127.0.0.1:4800" "$RING_TELEMETRY_ENDPOINT" "helper parses endpoint"
  assert_equals "dev@example.com" "$RING_TELEMETRY_DEVELOPER_EMAIL" "helper parses developer email"
  assert_equals "5" "$RING_TELEMETRY_ACTIVITY_TOOLS" "helper parses activity tool interval"
  assert_equals "30" "$RING_TELEMETRY_ACTIVITY_SECONDS" "helper parses activity seconds interval"
  teardown_test_env
}

test_remote_https_requires_token() {
  setup_test_env
  write_config
  jq '.endpoint = "https://telemetry.example.com"' "$RING_TELEMETRY_CONFIG" >"$RING_TELEMETRY_CONFIG.tmp" && mv "$RING_TELEMETRY_CONFIG.tmp" "$RING_TELEMETRY_CONFIG"
  source "$HOOK_DIR/telemetry-config.sh"
  if ring_telemetry_init; then
    assert_equals "blocked" "allowed" "remote https without token is blocked"
  else
    assert_equals "blocked" "blocked" "remote https without token is blocked"
  fi
  teardown_test_env
}

test_remote_http_requires_token_and_opt_in() {
  setup_test_env
  write_config
  jq '.endpoint = "http://telemetry.example.com" | .api_token = "secret"' "$RING_TELEMETRY_CONFIG" >"$RING_TELEMETRY_CONFIG.tmp" && mv "$RING_TELEMETRY_CONFIG.tmp" "$RING_TELEMETRY_CONFIG"
  source "$HOOK_DIR/telemetry-config.sh"
  if ring_telemetry_init; then
    assert_equals "blocked" "allowed" "remote http without opt-in is blocked"
  else
    assert_equals "blocked" "blocked" "remote http without opt-in is blocked"
  fi
  teardown_test_env
}

test_token_log_rejects_non_object() {
  setup_test_env
  write_config
  printf '{}' | bash "$HOOK_DIR/session-tracker-start.sh"
  local token_log="$TEST_TMP_DIR/token-log.jsonl"
  printf '[1,2,3]\n' > "$token_log"
  printf '{"tool_input":{"file_path":"%s","content":"[1,2,3]\n"}}' "$token_log" | bash "$HOOK_DIR/report-token-log.sh"
  assert_file_count 1 "$TMPDIR/ring-session-*.json" "token log non-object is ignored without deleting session"
  teardown_test_env
}

test_cycle_state_rejects_non_object() {
  setup_test_env
  write_config
  printf '{}' | bash "$HOOK_DIR/session-tracker-start.sh"
  local state_file="$TEST_TMP_DIR/current-cycle.json"
  printf '[1,2,3]' > "$state_file"
  printf '{"tool_input":{"file_path":"%s","content":"[1,2,3]"}}' "$state_file" | bash "$HOOK_DIR/report-cycle-state.sh"
  assert_file_count 0 "$TMPDIR/ring-cycle-state-*.json" "cycle state non-object does not persist previous state"
  teardown_test_env
}

test_work_state_requires_items_array() {
  setup_test_env
  write_config
  printf '{}' | bash "$HOOK_DIR/session-tracker-start.sh"
  local state_file="$TEST_TMP_DIR/current-work.json"
  printf '{"work_id":"work-1","status":"in_progress"}' > "$state_file"
  printf '{"tool_input":{"file_path":"%s","content":"{\"work_id\":\"work-1\",\"status\":\"in_progress\"}"}}' "$state_file" | bash "$HOOK_DIR/report-work-state.sh"
  local session_file
  session_file=($TMPDIR/ring-session-*.json)
  assert_equals "false" "$(jq -r '.structured // false' "${session_file[0]}")" "work state without items does not mark structured"
  teardown_test_env
}

test_work_state_marks_session_structured() {
  setup_test_env
  write_config
  printf '{}' | bash "$HOOK_DIR/session-tracker-start.sh"
  local state_file="$TEST_TMP_DIR/docs/ring-tracking/ring:dev-cycle/current-work.json"
  mkdir -p "$(dirname "$state_file")"
  local content='{"workflow":"ring:dev-cycle","work_id":"work-1","status":"in_progress","items":[{"id":"task-1","kind":"task","title":"Implement","status":"in_progress","lane":"in_progress","order":10}]}'
  printf '%s' "$content" > "$state_file"
  printf '{"tool_input":{"file_path":"%s","content":%s}}' "$state_file" "$(printf '%s' "$content" | jq -Rs .)" | bash "$HOOK_DIR/report-work-state.sh"
  local session_file
  session_file=($TMPDIR/ring-session-*.json)
  assert_equals "true" "$(jq -r '.structured // false' "${session_file[0]}")" "canonical work state marks session structured"
  teardown_test_env
}

test_session_start_creates_session_file() {
  setup_test_env
  write_config
  printf '{"matcher":"startup"}' | bash "$HOOK_DIR/session-tracker-start.sh"
  assert_file_count 1 "$TMPDIR/ring-session-*.json" "session start creates scoped session file"
  teardown_test_env
}

test_session_activity_tracks_safe_tool_counts() {
  setup_test_env
  write_config
  printf '{"matcher":"startup"}' | bash "$HOOK_DIR/session-tracker-start.sh"
  printf '{"tool_name":"Bash unsafe /path","tool_input":{"command":"secret command","file_path":"/secret/path"}}' | bash "$HOOK_DIR/session-activity.sh"
  local session_file
  session_file=($TMPDIR/ring-session-*.json)
  local activity_count last_tool leaked_command leaked_path
  activity_count="$(jq -r '.activity_count // 0' "${session_file[0]}")"
  last_tool="$(jq -r '.last_activity_tool // ""' "${session_file[0]}")"
  leaked_command="$(jq -r 'tostring | contains("secret command")' "${session_file[0]}")"
  leaked_path="$(jq -r 'tostring | contains("/secret/path")' "${session_file[0]}")"
  assert_equals "1" "$activity_count" "activity increments counter"
  assert_equals "Bashunsafepath" "$last_tool" "activity sanitizes tool name"
  assert_equals "1" "$(jq -r '.tool_counts.Bashunsafepath // 0' "${session_file[0]}")" "activity records safe tool count"
  assert_equals "false" "$leaked_command" "activity does not store command content"
  assert_equals "false" "$leaked_path" "activity does not store file path"
  teardown_test_env
}

test_missing_config_noop
test_user_prompt_submit_hook_registered
test_user_prompt_submit_missing_config_noop
test_user_prompt_submit_noop_inputs
test_user_prompt_submit_payload_constructs_raw_prompt
test_user_prompt_submit_stdout_empty_and_stderr_no_prompt
test_user_prompt_submit_posts_to_prompt_endpoint
test_helper_config_enabled_parsing
test_remote_https_requires_token
test_remote_http_requires_token_and_opt_in
test_token_log_rejects_non_object
test_cycle_state_rejects_non_object
test_work_state_requires_items_array
test_work_state_marks_session_structured
test_session_start_creates_session_file
test_session_activity_tracks_safe_tool_counts

if [[ "$TESTS_FAILED" -gt 0 ]]; then
  printf '%s/%s tests failed\n' "$TESTS_FAILED" "$TESTS_RUN"
  exit 1
fi

printf '%s tests passed\n' "$TESTS_RUN"
