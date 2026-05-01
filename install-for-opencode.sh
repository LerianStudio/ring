#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================================"
echo "Ring OpenCode Installer"
echo "================================================"
echo ""

echo "Redirecting to: ./installer/install-ring.sh --platforms opencode --link --force $*"
"$SCRIPT_DIR/installer/install-ring.sh" --platforms opencode --link --force "$@"

echo ""
echo "================================================"
echo "OpenCode installation complete"
echo "================================================"
echo ""
echo "Restart OpenCode so it reloads Ring skills, agents, commands, and runtime plugins."
