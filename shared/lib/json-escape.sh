#!/usr/bin/env bash
# shellcheck disable=SC2034  # Unused variables OK for exported config
# Shared JSON escaping utility for Ring hooks
# Usage: source this file, then call json_escape "string"

json_escape() {
    local input="$1"
    if command -v jq &>/dev/null; then
        printf '%s' "$input" | jq -Rs . | sed 's/^"//;s/"$//'
    else
        # WARNING: BSD sed limitation on macOS
        # The newline escaping (:a;N;$!ba;s/\n/\\n/g) uses GNU sed syntax.
        # BSD sed (macOS default) may not handle multiline content correctly.
        # For full compatibility, ensure jq is installed: brew install jq

        # Runtime warning on macOS when multiline content detected
        if [[ "$(uname)" == "Darwin" ]] && [[ "$input" == *$'\n'* ]]; then
            echo "Warning: JSON escaping of multiline content may be incomplete without jq. Install: brew install jq" >&2
        fi

        printf '%s' "$input" | sed \
            -e 's/\\/\\\\/g' \
            -e 's/"/\\"/g' \
            -e 's/\t/\\t/g' \
            -e 's/\r/\\r/g' \
            -e ':a;N;$!ba;s/\n/\\n/g'
    fi
}

# Export for subshells
export -f json_escape 2>/dev/null || true
