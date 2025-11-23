#!/usr/bin/env bash
# CLAUDE.md Auto-Bootstrap Hook
# Generates CLAUDE.md for git repos that lack them
# Runs on SessionStart before session-start.sh

set -euo pipefail

# Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Helper function for colored output
log_info() {
    echo -e "\033[0;34m[INFO]\033[0m $1" >&2
}

log_success() {
    echo -e "\033[0;32m✓\033[0m $1" >&2
}

log_warning() {
    echo -e "\033[0;33m⚠\033[0m $1" >&2
}

log_error() {
    echo -e "\033[0;31m✗\033[0m $1" >&2
}

# Function to create fallback CLAUDE.md template
# Addresses: Duplicate code at lines 65-89 and 114-138
# Creates file atomically with secure permissions (600)
# Returns: 0 on success, 1 on failure
create_fallback_template() {
    local temp_file
    temp_file=$(mktemp "${PROJECT_DIR}/.CLAUDE.md.tmp.XXXXXX")

    # Set umask to ensure secure permissions (owner-only rw)
    local old_umask=$(umask)
    umask 077

    # Create template in temporary file (atomic)
    cat > "${temp_file}" <<'TEMPLATE'
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

[TODO: Add description of what this repository does]

## Architecture

[TODO: Describe the main components and how they interact]

## Common Commands

[TODO: List frequently used commands for this project]

## Key Workflows

[TODO: Document important development workflows]

## Important Patterns

[TODO: List coding patterns, conventions, and best practices]
TEMPLATE

    local create_result=$?

    # Restore original umask
    umask "${old_umask}"

    if [ $create_result -ne 0 ]; then
        rm -f "${temp_file}"
        return 1
    fi

    # Atomically move temp file to final location
    # This prevents TOCTOU race condition
    if mv "${temp_file}" "${PROJECT_DIR}/CLAUDE.md" 2>/dev/null; then
        # Ensure secure permissions even if mv doesn't preserve them
        chmod 600 "${PROJECT_DIR}/CLAUDE.md"
        return 0
    else
        rm -f "${temp_file}"
        return 1
    fi
}

# Check if this is a git repository
if [ ! -d "${PROJECT_DIR}/.git" ]; then
    # Not a git repo - skip silently
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart"
  }
}
EOF
    exit 0
fi

# Check if CLAUDE.md already exists
if [ -f "${PROJECT_DIR}/CLAUDE.md" ]; then
    # CLAUDE.md exists - skip silently (idempotent)
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart"
  }
}
EOF
    exit 0
fi

# Log start of bootstrap process
log_info "No CLAUDE.md found. Starting auto-generation in background..."

# Check if Python orchestrator exists
if [ ! -f "${SCRIPT_DIR}/claude-md-bootstrap.py" ]; then
    log_error "Python orchestrator not found at ${SCRIPT_DIR}/claude-md-bootstrap.py"
    log_info "Creating minimal fallback template..."

    if create_fallback_template; then
        log_success "Created minimal CLAUDE.md template"
    else
        log_error "Failed to create fallback template"
    fi
else
    # Create lock file to prevent concurrent executions
    LOCK_FILE="${PROJECT_DIR}/.claude-md-bootstrap.lock"

    if [ -f "$LOCK_FILE" ]; then
        log_warning "Bootstrap already in progress"
    else
        # Create log file for background process
        LOG_FILE="${PROJECT_DIR}/.claude-md-bootstrap.log"

        # Fork Python orchestrator to background (non-blocking)
        # Redirect all stdio to prevent hanging
        {
            # Set lock
            echo $$ > "$LOCK_FILE"

            # Run bootstrap with full stdio redirection
            if "${SCRIPT_DIR}/claude-md-bootstrap.py" </dev/null >>"$LOG_FILE" 2>&1; then
                if [ -f "${PROJECT_DIR}/CLAUDE.md" ]; then
                    line_count=$(wc -l < "${PROJECT_DIR}/CLAUDE.md" 2>/dev/null || echo "0")
                    echo "[$(date)] ✓ Generated CLAUDE.md (${line_count} lines)" >> "$LOG_FILE"
                fi
            else
                exit_code=$?
                echo "[$(date)] ✗ Bootstrap failed (exit code: ${exit_code})" >> "$LOG_FILE"
            fi

            # Remove lock
            rm -f "$LOCK_FILE"
        } </dev/null &>/dev/null &

        # Capture background PID
        bg_pid=$!

        # Detach from current shell
        disown 2>/dev/null || true

        log_success "CLAUDE.md generation running in background (PID: ${bg_pid})"
        log_info "Monitor: tail -f .claude-md-bootstrap.log"

        # Inject user notification into session context
        cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "📋 **CLAUDE.md Bootstrap Running**\n\nA background agent is analyzing this repository to auto-generate CLAUDE.md documentation.\n\n**Status:** In progress (PID: ${bg_pid})\n**Duration:** ~60-120 seconds\n**Monitor:** \`tail -f .claude-md-bootstrap.log\`\n**Result:** CLAUDE.md will be available in your next session or after background completion\n\nYou can start working immediately - the bootstrap won't interrupt your session."
  }
}
EOF
        exit 0
    fi
fi

# Return standard SessionStart output (no bootstrap needed)
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart"
  }
}
EOF

exit 0
