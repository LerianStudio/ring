#!/usr/bin/env bash
# Compatibility wrapper. Installed hooks source dev-team/hooks/telemetry-config.sh.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
HELPER="$SCRIPT_DIR/../../dev-team/hooks/telemetry-config.sh"

if [[ -f "$HELPER" ]]; then
  # shellcheck source=/dev/null
  source "$HELPER"
fi
