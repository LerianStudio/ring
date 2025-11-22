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
log_info "No CLAUDE.md found. Starting auto-generation process..."

# Check if Python orchestrator exists
if [ ! -f "${SCRIPT_DIR}/claude-md-bootstrap.py" ]; then
    log_error "Python orchestrator not found at ${SCRIPT_DIR}/claude-md-bootstrap.py"
    log_info "Creating minimal fallback template..."

    if create_fallback_template; then
        log_success "Created minimal CLAUDE.md template"
    else
        log_error "Failed to create fallback template"
        # Continue to output standard JSON (fail gracefully)
    fi
else
    # Run the Python bootstrap orchestrator
    # Temporarily disable exit-on-error to capture exit code
    set +e
    bootstrap_output=$("${SCRIPT_DIR}/claude-md-bootstrap.py" 2>&1)
    bootstrap_exit_code=$?
    set -e

    # Check result
    if [ $bootstrap_exit_code -eq 0 ]; then
        # Verify file was actually created (addresses inconsistent error recovery)
        if [ -f "${PROJECT_DIR}/CLAUDE.md" ]; then
            line_count=$(wc -l < "${PROJECT_DIR}/CLAUDE.md")
            log_success "Generated CLAUDE.md (${line_count} lines)"
        else
            log_warning "Bootstrap completed but CLAUDE.md not created"
            log_info "Creating minimal fallback template..."
            if create_fallback_template; then
                log_success "Created minimal CLAUDE.md template as fallback"
            else
                log_error "Failed to create fallback template"
            fi
        fi
    else
        log_error "Failed to generate CLAUDE.md (exit code: ${bootstrap_exit_code})"
        log_info "Creating minimal fallback template..."

        if create_fallback_template; then
            log_success "Created minimal CLAUDE.md template as fallback"
        else
            log_error "Failed to create fallback template"
        fi
    fi
fi

# Return standard SessionStart output
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart"
  }
}
EOF

exit 0
