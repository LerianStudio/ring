#!/usr/bin/env bash
# Ring telemetry helpers. Hooks source this file and must exit 0 on errors.

RING_TELEMETRY_CONFIG="${RING_TELEMETRY_CONFIG:-$HOME/.ring/telemetry.json}"
RING_TELEMETRY_DEBUG_LOG="${RING_TELEMETRY_DEBUG_LOG:-$HOME/.ring/telemetry-debug.log}"

ring_telemetry_config_value() {
  local jq_filter="$1"
  local fallback="$2"
  jq -r "$jq_filter // \"$fallback\"" "$RING_TELEMETRY_CONFIG" 2>/dev/null || printf '%s' "$fallback"
}

ring_telemetry_is_local_http_endpoint() {
  case "$1" in
    http://localhost|http://localhost:*|http://localhost/*|http://localhost:*/*) return 0 ;;
    http://127.0.0.1|http://127.0.0.1:*|http://127.0.0.1/*|http://127.0.0.1:*/*) return 0 ;;
    http://[::1]|http://[::1]:*|http://[::1]/*|http://[::1]:*/*) return 0 ;;
    *) return 1 ;;
  esac
}

ring_telemetry_is_local_endpoint() {
  case "$1" in
    http://localhost|http://localhost:*|http://localhost/*|http://localhost:*/*|https://localhost|https://localhost:*|https://localhost/*|https://localhost:*/*) return 0 ;;
    http://127.0.0.1|http://127.0.0.1:*|http://127.0.0.1/*|http://127.0.0.1:*/*|https://127.0.0.1|https://127.0.0.1:*|https://127.0.0.1/*|https://127.0.0.1:*/*) return 0 ;;
    http://[::1]|http://[::1]:*|http://[::1]/*|http://[::1]:*/*|https://[::1]|https://[::1]:*|https://[::1]/*|https://[::1]:*/*) return 0 ;;
    *) return 1 ;;
  esac
}

ring_telemetry_init() {
  if [[ ! -f "$RING_TELEMETRY_CONFIG" ]]; then
    return 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    return 1
  fi

  RING_TELEMETRY_ENABLED="$(ring_telemetry_config_value '.enabled' 'true')"
  if [[ "$RING_TELEMETRY_ENABLED" != "true" ]]; then
    return 1
  fi

  RING_TELEMETRY_ENDPOINT="$(ring_telemetry_config_value '.endpoint' 'http://127.0.0.1:4800')"
  RING_TELEMETRY_DEVELOPER_EMAIL="$(ring_telemetry_config_value '.developer_email' 'auto')"
  RING_TELEMETRY_HEARTBEAT_WRITES="$(ring_telemetry_config_value '.heartbeat_interval_writes' '10')"
  RING_TELEMETRY_HEARTBEAT_SECONDS="$(ring_telemetry_config_value '.heartbeat_interval_seconds' '300')"
  RING_TELEMETRY_ACTIVITY_TOOLS="$(ring_telemetry_config_value '.activity_interval_tools' '5')"
  RING_TELEMETRY_ACTIVITY_SECONDS="$(ring_telemetry_config_value '.activity_interval_seconds' '30')"
  RING_TELEMETRY_DEBUG="$(ring_telemetry_config_value '.debug' 'false')"
  RING_TELEMETRY_API_TOKEN="$(ring_telemetry_config_value '.api_token' '')"
  RING_TELEMETRY_ALLOW_REMOTE_HTTP="$(ring_telemetry_config_value '.allow_remote_http' 'false')"

  if ! ring_telemetry_is_local_endpoint "$RING_TELEMETRY_ENDPOINT" && [[ -z "$RING_TELEMETRY_API_TOKEN" ]]; then
    ring_telemetry_debug "dropping remote telemetry endpoint without api_token: $RING_TELEMETRY_ENDPOINT"
    return 1
  fi

  if [[ "$RING_TELEMETRY_ENDPOINT" == http://* ]] && ! ring_telemetry_is_local_http_endpoint "$RING_TELEMETRY_ENDPOINT" && [[ "$RING_TELEMETRY_ALLOW_REMOTE_HTTP" != "true" ]]; then
    ring_telemetry_debug "dropping remote cleartext telemetry endpoint: $RING_TELEMETRY_ENDPOINT"
    return 1
  fi

  if [[ "$RING_TELEMETRY_DEVELOPER_EMAIL" == "auto" || -z "$RING_TELEMETRY_DEVELOPER_EMAIL" ]]; then
    RING_TELEMETRY_DEVELOPER_EMAIL="$(git config user.email 2>/dev/null || git config --global user.email 2>/dev/null || true)"
  fi
  if [[ -z "$RING_TELEMETRY_DEVELOPER_EMAIL" ]]; then
    RING_TELEMETRY_DEVELOPER_EMAIL="unknown"
  fi
  return 0
}

ring_telemetry_debug() {
  if [[ "${RING_TELEMETRY_DEBUG:-false}" != "true" ]]; then
    return 0
  fi
  mkdir -p "$(dirname "$RING_TELEMETRY_DEBUG_LOG")" 2>/dev/null || true
  printf '%s %s\n' "$(ring_telemetry_timestamp)" "$*" >>"$RING_TELEMETRY_DEBUG_LOG" 2>/dev/null || true
}

ring_telemetry_uuid() {
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen | tr '[:upper:]' '[:lower:]'
  else
    printf '%s-%s-%s\n' "$(date +%s 2>/dev/null || printf '0')" "${PPID:-0}" "$RANDOM"
  fi
}

ring_telemetry_timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ"
}

ring_telemetry_epoch() {
  date +%s 2>/dev/null || printf '0'
}

ring_telemetry_repo_path() {
  git rev-parse --show-toplevel 2>/dev/null || pwd 2>/dev/null || printf 'unknown'
}

ring_telemetry_session_file() {
  local repo_path repo_hash tool developer tmp_dir
  repo_path="$(ring_telemetry_repo_path)"
  if command -v shasum >/dev/null 2>&1; then
    repo_hash="$(printf '%s' "$repo_path" | shasum -a 256 2>/dev/null | cut -d' ' -f1)"
  else
    repo_hash="$(printf '%s' "$repo_path" | cksum 2>/dev/null | awk '{print $1}')"
  fi
  tool="${RING_TELEMETRY_TOOL:-claude-code}"
  developer="${RING_TELEMETRY_DEVELOPER_EMAIL:-unknown}"
  tmp_dir="${TMPDIR:-/tmp}"
  printf '%s/ring-session-%s-%s-%s-%s.json' "${tmp_dir%/}" "${PPID:-$$}" "${repo_hash:-unknown}" "${tool//[^A-Za-z0-9_.-]/_}" "${developer//[^A-Za-z0-9_.@-]/_}"
}

ring_telemetry_repo_context_json() {
  local repo_path repo branch hostname_value
  repo_path="$(ring_telemetry_repo_path)"
  repo="$(basename "$repo_path" 2>/dev/null || printf 'unknown')"
  branch="$(git -C "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'unknown')"
  hostname_value="$(hostname 2>/dev/null || printf 'unknown')"
  jq -n \
    --arg repo "$repo" \
    --arg repo_path "$repo_path" \
    --arg branch "$branch" \
    --arg hostname "$hostname_value" \
    '{repo:$repo, repo_path:$repo_path, branch:$branch, hostname:$hostname}'
}

ring_telemetry_current_session_json() {
  local session_file
  session_file="$(ring_telemetry_session_file)"
  if [[ -f "$session_file" ]]; then
    jq -c 'select(type == "object")' "$session_file" 2>/dev/null || printf '{}'
  else
    printf '{}'
  fi
}

ring_telemetry_envelope_json() {
  local event_type="$1"
  local payload_json="$2"
  local session_json repo_context context_file session_file payload_file
  session_json="$(ring_telemetry_current_session_json)"
  repo_context="$(ring_telemetry_repo_context_json)"
  context_file="$(mktemp "${TMPDIR:-/tmp}/ring-context.XXXXXX" 2>/dev/null || true)"
  session_file="$(mktemp "${TMPDIR:-/tmp}/ring-session-json.XXXXXX" 2>/dev/null || true)"
  payload_file="$(mktemp "${TMPDIR:-/tmp}/ring-payload.XXXXXX" 2>/dev/null || true)"
  if [[ -z "$context_file" || -z "$session_file" || -z "$payload_file" ]]; then
    rm -f "$context_file" "$session_file" "$payload_file" 2>/dev/null || true
    printf '{}'
    return 0
  fi
  trap 'rm -f "$context_file" "$session_file" "$payload_file" 2>/dev/null || true' RETURN
  printf '%s' "$repo_context" >"$context_file" 2>/dev/null || printf '{}' >"$context_file" 2>/dev/null || true
  printf '%s' "$session_json" >"$session_file" 2>/dev/null || printf '{}' >"$session_file" 2>/dev/null || true
  printf '%s' "$payload_json" >"$payload_file" 2>/dev/null || printf '{}' >"$payload_file" 2>/dev/null || true
  jq -n \
    --arg schema_version "1.0" \
    --arg event_type "$event_type" \
    --arg timestamp "$(ring_telemetry_timestamp)" \
    --arg developer_email "${RING_TELEMETRY_DEVELOPER_EMAIL:-unknown}" \
    --slurpfile context_file "$context_file" \
    --slurpfile session_file "$session_file" \
    --slurpfile payload_file "$payload_file" \
    '($context_file[0] // {}) as $context | ($session_file[0] // {}) as $session | ($payload_file[0] // {}) as $payload |
    {schema_version:$schema_version,event_type:$event_type,timestamp:$timestamp,developer:{email:$developer_email,hostname:$context.hostname},context:{repo:$context.repo,repo_path:$context.repo_path,branch:$context.branch},session:{id:($session.id // "unknown"),tool:($session.tool // "unknown"),model:($session.model // "unknown")},payload:$payload}' 2>/dev/null || printf '{}'
}

ring_telemetry_post_background() {
  local event_json="$1"
  local api_path="${2:-/api/events}"
  if [[ -z "${RING_TELEMETRY_ENDPOINT:-}" || "$event_json" == "{}" ]]; then
    return 0
  fi
  if ! command -v curl >/dev/null 2>&1; then
    ring_telemetry_debug "curl unavailable; dropping telemetry event"
    return 0
  fi
  (
    local curl_config=""
    trap '[[ -n "$curl_config" ]] && rm -f "$curl_config" 2>/dev/null || true' EXIT
    if [[ -n "${RING_TELEMETRY_API_TOKEN:-}" ]]; then
      curl_config="$(mktemp "${TMPDIR:-/tmp}/ring-telemetry-curl.XXXXXX" 2>/dev/null || true)"
      if [[ -n "$curl_config" ]]; then
        chmod 600 "$curl_config" 2>/dev/null || true
        if ! printf 'header = "authorization: Bearer %s"\n' "$RING_TELEMETRY_API_TOKEN" >"$curl_config" 2>/dev/null; then
          rm -f "$curl_config" 2>/dev/null || true
          curl_config=""
        fi
      fi
      [[ -n "$curl_config" ]] || exit 0
    fi
    local config_args=()
    [[ -n "$curl_config" ]] && config_args=(--config "$curl_config")
    curl -fsS --connect-timeout 1 --max-time 2 \
      -H 'content-type: application/json' \
      "${config_args[@]}" \
      -X POST \
      --data-binary @- \
      "${RING_TELEMETRY_ENDPOINT%/}${api_path}" >/dev/null 2>&1 || true
  ) <<<"$event_json" >/dev/null 2>&1 &
}

ring_telemetry_write_session_json() {
  local session_json="$1"
  local session_file tmp_file
  printf '%s' "$session_json" | jq -e 'type == "object"' >/dev/null 2>&1 || return 0
  session_file="$(ring_telemetry_session_file)"
  tmp_file="${session_file}.$$"
  printf '%s\n' "$session_json" >"$tmp_file" 2>/dev/null && mv "$tmp_file" "$session_file" 2>/dev/null || true
}

ring_telemetry_read_stdin() {
  cat 2>/dev/null || true
}
