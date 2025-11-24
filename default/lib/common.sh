#!/usr/bin/env bash
#
# Common Library
# Shared functions for logging, error handling, and utilities
#
# Source this file at the start of scripts:
#   source "$(dirname "$0")/common.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get timestamp in ISO format
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Structured logging with levels
# Usage: log_info "message"
#        log_error "message" "context"
log_message() {
    local level="$1"
    local message="$2"
    local context="${3:-}"
    local timestamp=$(get_timestamp)

    local color=""
    case "$level" in
        ERROR)   color="$RED" ;;
        WARN)    color="$YELLOW" ;;
        INFO)    color="$GREEN" ;;
        DEBUG)   color="$CYAN" ;;
        *)       color="$NC" ;;
    esac

    if [ -n "$context" ]; then
        echo -e "${color}[$timestamp] $level: $message${NC}" >&2
        echo -e "${color}  Context: $context${NC}" >&2
    else
        echo -e "${color}[$timestamp] $level: $message${NC}" >&2
    fi
}

log_info() {
    log_message "INFO" "$1" "${2:-}"
}

log_warn() {
    log_message "WARN" "$1" "${2:-}"
}

log_error() {
    log_message "ERROR" "$1" "${2:-}"
}

log_debug() {
    if [ "${DEBUG:-0}" = "1" ]; then
        log_message "DEBUG" "$1" "${2:-}"
    fi
}

# Error exit with context
# Usage: die "error message" "file:line" "additional context"
die() {
    local message="$1"
    local location="${2:-unknown}"
    local context="${3:-}"

    log_error "$message" "$location${context:+; $context}"
    exit 2
}

# Check command exists
require_command() {
    local cmd="$1"
    local install_hint="${2:-}"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        die "Required command not found: $cmd" "$(basename "$0")" "$install_hint"
    fi
}

# Validate file path (no path traversal, readable)
validate_file_path() {
    local file="$1"
    local label="${2:-file}"

    # Check for path traversal
    case "$file" in
        *..*)
            die "Invalid $label path (contains ..)" "$(basename "$0")" "Path: $file"
            ;;
    esac

    # Check exists and readable
    if [ ! -f "$file" ]; then
        die "$label not found" "$(basename "$0")" "Path: $file"
    fi

    if [ ! -r "$file" ]; then
        die "$label not readable" "$(basename "$0")" "Path: $file"
    fi
}

# Validate directory path
validate_dir_path() {
    local dir="$1"
    local label="${2:-directory}"

    if [ ! -d "$dir" ]; then
        die "$label not found" "$(basename "$0")" "Path: $dir"
    fi
}

# Validate string format (alphanumeric, hyphens, underscores)
validate_identifier() {
    local str="$1"
    local label="${2:-identifier}"

    if ! echo "$str" | grep -qE '^[a-zA-Z0-9_-]+$'; then
        die "Invalid $label format" "$(basename "$0")" "Value: $str; Expected: alphanumeric, hyphens, underscores"
    fi
}
