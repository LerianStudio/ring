#!/usr/bin/env bash
# shellcheck disable=SC2034  # Unused variables OK for exported config
# Ring Multi-Platform Installer
# Installs Ring skills to Claude Code, Codex, Factory AI, Cursor, Cline, and/or OpenCode
set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export PYTHONPATH="$RING_ROOT/installer${PYTHONPATH:+:$PYTHONPATH}"

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

# Detect Python (requires 3.10+ for dataclass slots=True)
detect_python() {
    local VENV_PY="$SCRIPT_DIR/.venv/bin/python"
    local MIN_MAJOR=3 MIN_MINOR=10

    _py_ok() {
        local ver
        ver=$("$1" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null) || return 1
        local major minor
        major=${ver%%.*}; minor=${ver##*.}
        [[ $major -ge $MIN_MAJOR && $minor -ge $MIN_MINOR ]]
    }

    # 1. Persistent venv (created once, survives across runs)
    if [[ -x "$VENV_PY" ]] && _py_ok "$VENV_PY"; then
        echo "$VENV_PY"; return
    fi

    # 2. Homebrew / newer system python3
    for candidate in python3 python3.14 python3.13 python3.12 python3.11 python3.10 python; do
        if command -v "$candidate" &>/dev/null && _py_ok "$candidate"; then
            echo "$candidate"; return
        fi
    done

    # 3. Bootstrap a venv from the best available Python 3.10+
    for candidate in /opt/homebrew/bin/python3.14 /opt/homebrew/bin/python3.13 /opt/homebrew/bin/python3.12 /opt/homebrew/bin/python3.11 /opt/homebrew/bin/python3.10 /usr/local/bin/python3; do
        if [[ -x "$candidate" ]] && _py_ok "$candidate"; then
            echo "${YELLOW:-}Bootstrapping venv with $candidate (system python < 3.10)…${RESET:-}" >&2
            "$candidate" -m venv "$SCRIPT_DIR/.venv" && \
                "$VENV_PY" -m pip install -q PyYAML 2>/dev/null
            if [[ -x "$VENV_PY" ]] && _py_ok "$VENV_PY"; then
                echo "$VENV_PY"; return
            fi
        fi
    done
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
    # Validate args for obvious shell metacharacters
    for arg in "$@"; do
        if [[ "$arg" == *[\\\;\&\|\`\$\>]* ]]; then
            echo "${RED}Error: Unsupported characters in argument: $arg${RESET}"
            exit 1
        fi
    done

    # Verify module exists before exec
    if [ ! -f "$RING_ROOT/installer/ring_installer/__main__.py" ]; then
        echo "${RED}Error: ring_installer module not found at $RING_ROOT/installer/ring_installer${RESET}"
        exit 1
    fi

    # Optional integrity check for marketplace.json when checksum provided
    if [ -n "${MARKETPLACE_JSON_SHA256:-}" ]; then
        if [ -f "$RING_ROOT/.claude-plugin/marketplace.json" ]; then
            ACTUAL_HASH=$(openssl dgst -sha256 "$RING_ROOT/.claude-plugin/marketplace.json" | awk '{print $2}')
            if [ "$ACTUAL_HASH" != "$MARKETPLACE_JSON_SHA256" ]; then
                echo "${RED}marketplace.json integrity check failed${RESET}"
                exit 1
            fi
        fi
    fi

    # Direct passthrough to Python module.
    # If the first arg is a flag (--*), prepend "install" as the default subcommand.
    # Known subcommands are passed through as-is.
    cd "$RING_ROOT"
    case "$1" in
        install|update|rebuild|check|sync|uninstall|list|detect|platforms)
            exec "$PYTHON_CMD" -m installer.ring_installer "$@"
            ;;
        *)
            exec "$PYTHON_CMD" -m installer.ring_installer install "$@"
            ;;
    esac
fi

# Interactive mode - platform selection
echo "Select platforms to install Ring:"
echo ""
echo "  ${BLUE}1)${RESET} Claude Code     (recommended, native format)"
echo "  ${BLUE}2)${RESET} Codex           (native format)"
echo "  ${BLUE}3)${RESET} Factory AI      (droids, transformed)"
echo "  ${BLUE}4)${RESET} Cursor          (skills/agents/commands)"
echo "  ${BLUE}5)${RESET} Cline           (prompts, transformed)"
echo "  ${BLUE}6)${RESET} OpenCode        (native format)"
echo "  ${BLUE}7)${RESET} All supported platforms"
echo "  ${BLUE}8)${RESET} Auto-detect and install"
echo ""

read -p "Enter choice(s) separated by comma (e.g., 1,2,3) [default: 8]: " choices

# Validate input only contains expected characters (locale-independent)
LC_ALL=C
if [[ -n "$choices" ]] && ! [[ "$choices" =~ ^[1-8,\ ]*$ ]]; then
    echo "${RED}Error: Invalid input. Please enter numbers 1-8 separated by commas.${RESET}"
    exit 1
fi

# Default to auto-detect
if [ -z "$choices" ]; then
    choices="8"
fi

# Check for conflicting options (auto-detect with specific platforms)
if [[ "$choices" =~ [78] ]] && [[ "$choices" =~ [1-6] ]]; then
    echo "${YELLOW}Note: Auto/all selected - ignoring specific platform selections.${RESET}"
fi

# Parse choices
PLATFORMS=""
case "$choices" in
    *1*) PLATFORMS="${PLATFORMS}claude," ;;
esac
case "$choices" in
    *2*) PLATFORMS="${PLATFORMS}codex," ;;
esac
case "$choices" in
    *3*) PLATFORMS="${PLATFORMS}factory," ;;
esac
case "$choices" in
    *4*) PLATFORMS="${PLATFORMS}cursor," ;;
esac
case "$choices" in
    *5*) PLATFORMS="${PLATFORMS}cline," ;;
esac
case "$choices" in
    *6*) PLATFORMS="${PLATFORMS}opencode," ;;
esac
case "$choices" in
    *7*) PLATFORMS="claude,codex,factory,cursor,cline,opencode" ;;
esac
case "$choices" in
    *8*) PLATFORMS="auto" ;;
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
read -p "Use symlink mode? (builds in-repo, symlinks to config) (y/N): " use_link
read -p "Enable verbose output? (y/N): " verbose
read -p "Perform dry-run first? (y/N): " dry_run

EXTRA_ARGS=()
if [[ "$use_link" =~ ^[Yy]$ ]]; then
    EXTRA_ARGS+=("--link" "--force")
fi
if [[ "$verbose" =~ ^[Yy]$ ]]; then
    EXTRA_ARGS+=("--verbose")
fi

# Run dry-run if requested
if [[ "$dry_run" =~ ^[Yy]$ ]]; then
    echo ""
    echo "${YELLOW}=== Dry Run ===${RESET}"
    cd "$RING_ROOT"
    "$PYTHON_CMD" -m installer.ring_installer install --platforms "$PLATFORMS" --dry-run "${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}"
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
"$PYTHON_CMD" -m installer.ring_installer install --platforms "$PLATFORMS" "${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}"

echo ""
echo "${GREEN}================================================${RESET}"
echo "${GREEN}Installation Complete!${RESET}"
echo "${GREEN}================================================${RESET}"
echo ""
echo "Next steps:"
echo "  1. Restart your AI tool or start a new session"
echo "  2. Skills will auto-load (Claude Code) or be available as configured"
if [[ "$use_link" =~ ^[Yy]$ ]]; then
    echo "  3. After git pull, run: ./installer/install-ring.sh rebuild"
fi
echo ""
echo "Commands:"
echo "  ./installer/install-ring.sh                    # Interactive install"
echo "  ./installer/install-ring.sh --platforms claude # Direct install"
echo "  ./installer/install-ring.sh --platforms opencode --link  # Symlink install"
echo "  ./installer/install-ring.sh update             # Update installation"
echo "  ./installer/install-ring.sh rebuild            # Rebuild after git pull"
echo "  ./installer/install-ring.sh list               # List installed"
echo ""
