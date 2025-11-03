#!/usr/bin/env bash
#
# Compliance Validator
# Validates skill adherence to compliance rules defined in frontmatter
#
# Usage: ./lib/compliance-validator.sh <skill-file> [rule-id]
#
# Exit codes:
#   0 - All rules pass
#   1 - One or more rules fail
#   2 - Invalid usage or file not found

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Security: Whitelisted commands for command_succeeds check
# Only these base commands are allowed for security
WHITELISTED_COMMANDS=(
    "git"
    "npm"
    "yarn"
    "pytest"
    "jest"
    "make"
    "cargo"
    "go"
    "python"
    "python3"
    "node"
)

# Maximum command execution timeout (seconds)
COMMAND_TIMEOUT=30

# Usage
if [ $# -lt 1 ]; then
    echo "Usage: $0 <skill-file> [rule-id]"
    echo "Example: $0 skills/test-driven-development/SKILL.md"
    echo "Example: $0 skills/test-driven-development/SKILL.md test_before_code"
    exit 2
fi

SKILL_FILE="$1"
SPECIFIC_RULE="${2:-}"

# Input validation and sanitization
validate_inputs() {
    # Check for path traversal attempts
    case "$SKILL_FILE" in
        *..*)
            echo -e "${RED}Error: Invalid file path (contains ..)${NC}"
            exit 2
            ;;
    esac

    # Validate file exists and is readable
    if [ ! -f "$SKILL_FILE" ]; then
        echo -e "${RED}Error: File not found: $SKILL_FILE${NC}"
        exit 2
    fi

    if [ ! -r "$SKILL_FILE" ]; then
        echo -e "${RED}Error: File not readable: $SKILL_FILE${NC}"
        exit 2
    fi

    # Sanitize rule ID if provided
    if [ -n "$SPECIFIC_RULE" ]; then
        # Rule ID should only contain alphanumeric and underscore
        if ! echo "$SPECIFIC_RULE" | grep -qE '^[a-zA-Z0-9_-]+$'; then
            echo -e "${RED}Error: Invalid rule ID format${NC}"
            exit 2
        fi
    fi
}

validate_inputs

# Security: Validate command against whitelist
# Returns 0 if command is whitelisted, 1 otherwise
validate_command() {
    local cmd="$1"

    # Extract the base command (first word)
    local base_cmd=$(echo "$cmd" | awk '{print $1}')

    # Check if base command is in whitelist
    for allowed in "${WHITELISTED_COMMANDS[@]}"; do
        if [ "$base_cmd" = "$allowed" ]; then
            return 0
        fi
    done

    return 1
}

# Security: Validate and sanitize glob pattern
# Ensures pattern doesn't contain command injection characters
validate_pattern() {
    local pattern="$1"

    # Reject patterns with dangerous characters
    # Allow: alphanumeric, -, _, /, *, ., |, space
    # Reject: ; & $ ` ( ) < > \ newline tab
    if echo "$pattern" | grep -qE '[;&$`()<>\\]'; then
        return 1
    fi

    # Validate pipe-separated patterns (format: "pattern1|pattern2")
    if echo "$pattern" | grep -q '|'; then
        local left=$(echo "$pattern" | cut -d'|' -f1)
        local right=$(echo "$pattern" | cut -d'|' -f2-)

        # Both sides must be valid glob patterns
        if ! echo "$left" | grep -qE '^[a-zA-Z0-9*_./-]+$'; then
            return 1
        fi
        if ! echo "$right" | grep -qE '^[a-zA-Z0-9*_./ |-]+$'; then
            return 1
        fi
    fi

    return 0
}

# Security: Run command with timeout and validation
safe_run_command() {
    local cmd="$1"
    local timeout_sec="${2:-$COMMAND_TIMEOUT}"

    # Validate command against whitelist
    if ! validate_command "$cmd"; then
        echo -e "${RED}Security: '$cmd' not in whitelist${NC}" >&2
        return 1
    fi

    # Run with timeout (macOS compatible)
    if command -v timeout >/dev/null 2>&1; then
        # GNU timeout available
        timeout "$timeout_sec" bash -c "$cmd" 2>/dev/null
    elif command -v gtimeout >/dev/null 2>&1; then
        # GNU coreutils on macOS (brew install coreutils)
        gtimeout "$timeout_sec" bash -c "$cmd" 2>/dev/null
    else
        # Fallback: use bash built-in with background job
        (
            bash -c "$cmd" 2>/dev/null &
            local pid=$!
            local count=0
            while kill -0 $pid 2>/dev/null && [ $count -lt $timeout_sec ]; do
                sleep 1
                count=$((count + 1))
            done
            if kill -0 $pid 2>/dev/null; then
                kill -9 $pid 2>/dev/null
                return 124  # timeout exit code
            fi
            wait $pid
        )
    fi
}

# Extract YAML frontmatter
extract_frontmatter() {
    local file="$1"
    sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d'
}

# Check if skill has compliance rules
has_compliance_rules() {
    local frontmatter="$1"
    echo "$frontmatter" | grep -q "compliance_rules:"
}

# Parse compliance rules from frontmatter
parse_compliance_rules() {
    local frontmatter="$1"
    # Extract compliance_rules section
    echo "$frontmatter" | sed -n '/compliance_rules:/,/^[a-z_]*:/p' | sed '$d'
}

# Run a single compliance check
run_check() {
    local rule_id="$1"
    local check_type="$2"
    local pattern="$3"
    local severity="$4"
    local failure_msg="$5"

    local result=0

    case "$check_type" in
        file_exists)
            # Check if any files match pattern
            # Prune common large directories for performance
            if ! find . \( -path "./.*" -o -path "*/node_modules" -o -path "*/vendor" \) -prune -o -type f -path "$pattern" -print | grep -q .; then
                result=1
            fi
            ;;

        command_succeeds)
            # Run command and check exit code
            # Security: Validate command against whitelist and run with timeout
            if ! validate_command "$pattern"; then
                echo -e "${RED}Security: '$pattern' not in whitelist${NC}" >&2
                result=1
            elif ! safe_run_command "$pattern" >/dev/null 2>&1; then
                result=1
            fi
            ;;

        command_output_contains)
            # Run command and check if output contains pattern
            # Security: Validate pattern format and command
            if ! validate_pattern "$pattern"; then
                echo -e "${RED}Security: Invalid pattern format${NC}" >&2
                result=1
            else
                local cmd=$(echo "$pattern" | cut -d'|' -f1)
                local search=$(echo "$pattern" | cut -d'|' -f2)

                # Validate command against whitelist
                if ! validate_command "$cmd"; then
                    echo -e "${RED}Security: '$cmd' not in whitelist${NC}" >&2
                    result=1
                elif ! safe_run_command "$cmd" 2>&1 | grep -q "$search"; then
                    result=1
                fi
            fi
            ;;

        git_diff_order)
            # Check if test files modified before implementation files
            # Pattern format: "test_pattern|impl_pattern"
            # Security: Validate pattern format to prevent injection
            if ! validate_pattern "$pattern"; then
                echo -e "${RED}Error: Invalid pattern format${NC}" >&2
                result=1
            else
                local test_pattern=$(echo "$pattern" | cut -d'|' -f1)
                local impl_pattern=$(echo "$pattern" | cut -d'|' -f2)

                # Sanitize patterns - remove any remaining dangerous chars
                test_pattern=$(echo "$test_pattern" | tr -d ';$`\\')
                impl_pattern=$(echo "$impl_pattern" | tr -d ';$`\\')

                # Get file modification timestamps (for uncommitted changes, use mtime)
                local latest_test_time=0
                local latest_impl_time=0

                # Find most recent test file modification
                local changed_files=$(git diff --name-only HEAD 2>/dev/null)
                while IFS= read -r file; do
                    [ -z "$file" ] && continue
                    # Use case for pattern matching with proper quoting (bash 3.2 compatible)
                    # Note: Patterns are sanitized above, but we still quote for safety
                    case "$file" in
                        $test_pattern)
                            # For uncommitted changes, use file modification time
                            if [ -f "$file" ]; then
                                # macOS/BSD stat: -f %m gets modification time
                                # Linux stat: -c %Y gets modification time
                                local file_time=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null || echo 0)
                                if [ "$file_time" -gt "$latest_test_time" ]; then
                                    latest_test_time=$file_time
                                fi
                            fi
                            ;;
                    esac
                done <<EOF
$changed_files
EOF

                # Find most recent implementation file modification
                while IFS= read -r file; do
                    [ -z "$file" ] && continue
                    # Use case for pattern matching with proper quoting (bash 3.2 compatible)
                    case "$file" in
                        $impl_pattern)
                            # For uncommitted changes, use file modification time
                            if [ -f "$file" ]; then
                                # macOS/BSD stat: -f %m gets modification time
                                # Linux stat: -c %Y gets modification time
                                local file_time=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null || echo 0)
                                if [ "$file_time" -gt "$latest_impl_time" ]; then
                                    latest_impl_time=$file_time
                                fi
                            fi
                            ;;
                    esac
                done <<EOF
$changed_files
EOF

                # Test files should be modified before or at same time as impl files
                if [ "$latest_test_time" -eq 0 ] || [ "$latest_impl_time" -eq 0 ] || [ "$latest_test_time" -gt "$latest_impl_time" ]; then
                    result=1
                fi
            fi
            ;;

        file_contains)
            # Check if file contains pattern
            local file_path=$(echo "$pattern" | cut -d'|' -f1)
            local search_pattern=$(echo "$pattern" | cut -d'|' -f2)
            if [ ! -f "$file_path" ] || ! grep -q "$search_pattern" "$file_path"; then
                result=1
            fi
            ;;

        *)
            echo -e "${YELLOW}Warning: Unknown check type: $check_type${NC}"
            result=0
            ;;
    esac

    if [ $result -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $rule_id: PASS"
        return 0
    else
        echo -e "${RED}✗${NC} $rule_id: FAIL"
        echo -e "  ${RED}→${NC} $failure_msg"
        if [ "$severity" = "blocking" ]; then
            return 1
        else
            return 0  # Warning doesn't fail overall check
        fi
    fi
}

# Main validation logic
main() {
    echo "Validating compliance for: $SKILL_FILE"
    echo ""

    local frontmatter=$(extract_frontmatter "$SKILL_FILE")

    if ! has_compliance_rules "$frontmatter"; then
        echo -e "${YELLOW}No compliance rules defined in this skill${NC}"
        exit 0
    fi

    # Simple parsing (in production, use yq or proper YAML parser)
    # For now, we'll just report that rules exist
    local rules=$(parse_compliance_rules "$frontmatter")

    if [ -z "$rules" ]; then
        echo -e "${YELLOW}No compliance rules found${NC}"
        exit 0
    fi

    # Check if yq is available for full YAML parsing
    if ! command -v yq >/dev/null 2>&1; then
        echo -e "${RED}Error: yq is required for compliance validation${NC}"
        echo "Install with: brew install yq (macOS) or see https://github.com/mikefarah/yq"
        exit 2
    fi

    echo -e "${GREEN}Compliance rules found - validating...${NC}"
    echo ""

    # Parse rules using yq
    local overall_result=0
    local rule_count=0

    # Extract rule IDs from compliance_rules
    local rule_ids=$(echo "$frontmatter" | yq eval '.compliance_rules | keys | .[]' - 2>/dev/null)

    if [ -z "$rule_ids" ]; then
        echo -e "${YELLOW}No rules could be parsed${NC}"
        exit 0
    fi

    # Process each rule
    while IFS= read -r rule_id; do
        [ -z "$rule_id" ] && continue
        rule_count=$((rule_count + 1))

        local check_type=$(echo "$frontmatter" | yq eval ".compliance_rules.\"$rule_id\".check" - 2>/dev/null)
        local pattern=$(echo "$frontmatter" | yq eval ".compliance_rules.\"$rule_id\".pattern" - 2>/dev/null)
        local severity=$(echo "$frontmatter" | yq eval ".compliance_rules.\"$rule_id\".severity" - 2>/dev/null)
        local failure_msg=$(echo "$frontmatter" | yq eval ".compliance_rules.\"$rule_id\".failure_message" - 2>/dev/null)

        # Skip if we're filtering for specific rule
        if [ -n "$SPECIFIC_RULE" ] && [ "$rule_id" != "$SPECIFIC_RULE" ]; then
            continue
        fi

        if ! run_check "$rule_id" "$check_type" "$pattern" "$severity" "$failure_msg"; then
            overall_result=1
        fi
    done <<< "$rule_ids"

    echo ""
    if [ $rule_count -eq 0 ]; then
        echo -e "${YELLOW}No rules to validate${NC}"
        exit 0
    elif [ $overall_result -eq 0 ]; then
        echo -e "${GREEN}✓ All compliance checks passed${NC}"
        exit 0
    else
        echo -e "${RED}✗ One or more compliance checks failed${NC}"
        exit 1
    fi
}

main
