#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/ring-telemetry-server"

if [ ! -d "$SERVER_DIR" ]; then
  echo "Telemetry server not found at: $SERVER_DIR" >&2
  echo "Create it first or check that ring-telemetry-server is beside the ring repo." >&2
  exit 1
fi

cd "$SERVER_DIR"

if [ ! -d "node_modules" ]; then
  echo "Installing telemetry server dependencies..."
  npm ci
fi

echo "Starting Ring telemetry server without auth on http://127.0.0.1:4800"
HOST="127.0.0.1" RING_TELEMETRY_TOKEN="" npm start
