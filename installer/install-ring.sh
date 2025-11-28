#!/usr/bin/env bash
# shellcheck disable=SC2034  # Unused variables OK for exported config
# Ring Multi-Platform Installer
# Installs Ring skills to Claude Code, Factory AI, Cursor, and/or Cline
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "================================================"
echo "Ring Multi-Platform Installer"
echo "================================================"
echo ""

# Colors (if terminal supports them)
if [[ -t 1 ]] && command -v tput &>/dev/null; then
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    RED=$(tput setaf 1)
    RESET=$(tput sgr0)
else
    GREEN="" YELLOW="" BLUE="" RED="" RESET=""
fi

# Detect Python
detect_python() {
    if command -v python3 &>/dev/null; then
        echo "python3"
    elif command -v python &>/dev/null; then
        # Verify it's Python 3
        if python --version 2>&1 | grep -q "Python 3"; then
            echo "python"
        fi
    fi
}

PYTHON_CMD=$(detect_python)

if [ -z "$PYTHON_CMD" ]; then
    echo "${RED}Error: Python 3 is required but not found.${RESET}"
    echo ""
    echo "Install Python 3:"
    echo "  macOS:   brew install python3"
    echo "  Ubuntu:  sudo apt install python3"
    echo "  Windows: https://python.org/downloads/"
    exit 1
fi

echo "${GREEN}Found Python:${RESET} $("$PYTHON_CMD" --version)"
echo ""

# Check if running with arguments (non-interactive mode)
if [ $# -gt 0 ]; then
    # Direct passthrough to Python module
    cd "$RING_ROOT"
    exec "$PYTHON_CMD" -m installer.ring_installer "$@"
fi

# Interactive mode - platform selection
echo "Select platforms to install Ring:"
echo ""
echo "  ${BLUE}1)${RESET} Claude Code     (recommended, native format)"
echo "  ${BLUE}2)${RESET} Factory AI      (droids, transformed)"
echo "  ${BLUE}3)${RESET} Cursor          (rules/workflows, transformed)"
echo "  ${BLUE}4)${RESET} Cline           (prompts, transformed)"
echo "  ${BLUE}5)${RESET} All detected platforms"
echo "  ${BLUE}6)${RESET} Auto-detect and install"
echo ""

read -p "Enter choice(s) separated by comma (e.g., 1,2,3) [default: 6]: " choices

# Validate input only contains expected characters
if [[ -n "$choices" ]] && ! [[ "$choices" =~ ^[1-6,[:space:]]*$ ]]; then
    echo "${RED}Error: Invalid input. Please enter numbers 1-6 separated by commas.${RESET}"
    exit 1
fi

# Default to auto-detect
if [ -z "$choices" ]; then
    choices="6"
fi

# Check for conflicting options (auto-detect with specific platforms)
if [[ "$choices" =~ [56] ]] && [[ "$choices" =~ [1234] ]]; then
    echo "${YELLOW}Note: Auto-detect selected - ignoring specific platform selections.${RESET}"
fi

# Parse choices
PLATFORMS=""
case "$choices" in
    *1*) PLATFORMS="${PLATFORMS}claude," ;;
esac
case "$choices" in
    *2*) PLATFORMS="${PLATFORMS}factory," ;;
esac
case "$choices" in
    *3*) PLATFORMS="${PLATFORMS}cursor," ;;
esac
case "$choices" in
    *4*) PLATFORMS="${PLATFORMS}cline," ;;
esac
case "$choices" in
    *5*) PLATFORMS="claude,factory,cursor,cline" ;;
esac
case "$choices" in
    *6*) PLATFORMS="auto" ;;
esac

# Remove trailing comma
PLATFORMS="${PLATFORMS%,}"

if [ -z "$PLATFORMS" ]; then
    echo "${RED}No valid platforms selected.${RESET}"
    exit 1
fi

echo ""
echo "Installing to: ${GREEN}${PLATFORMS}${RESET}"
echo ""

# Additional options
read -p "Enable verbose output? (y/N): " verbose
read -p "Perform dry-run first? (y/N): " dry_run

EXTRA_ARGS=()
if [[ "$verbose" =~ ^[Yy]$ ]]; then
    EXTRA_ARGS+=("--verbose")
fi

# Run dry-run if requested
if [[ "$dry_run" =~ ^[Yy]$ ]]; then
    echo ""
    echo "${YELLOW}=== Dry Run ===${RESET}"
    cd "$RING_ROOT"
    "$PYTHON_CMD" -m installer.ring_installer install --platforms "$PLATFORMS" --dry-run "${EXTRA_ARGS[@]}"
    echo ""
    read -p "Proceed with actual installation? (Y/n): " proceed
    if [[ "$proceed" =~ ^[Nn]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
fi

# Run actual installation
echo ""
echo "${GREEN}=== Installing ===${RESET}"
cd "$RING_ROOT"
"$PYTHON_CMD" -m installer.ring_installer install --platforms "$PLATFORMS" "${EXTRA_ARGS[@]}"

echo ""
echo "${GREEN}================================================${RESET}"
echo "${GREEN}Installation Complete!${RESET}"
echo "${GREEN}================================================${RESET}"
echo ""
echo "Next steps:"
echo "  1. Restart your AI tool or start a new session"
echo "  2. Skills will auto-load (Claude Code) or be available as configured"
echo ""
echo "Commands:"
echo "  ./installer/install-ring.sh                    # Interactive install"
echo "  ./installer/install-ring.sh --platforms claude # Direct install"
echo "  ./installer/install-ring.sh update             # Update installation"
echo "  ./installer/install-ring.sh list               # List installed"
echo ""
