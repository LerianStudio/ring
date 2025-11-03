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
        */*)
            # Path contains directory separator - ok
            ;;
        *)
            echo -e "${RED}Error: File path must be relative or absolute path${NC}"
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
            # Security: Pattern should be pre-validated command, not user input
            if ! bash -c "$pattern" >/dev/null 2>&1; then
                result=1
            fi
            ;;

        command_output_contains)
            # Run command and check if output contains pattern
            local cmd=$(echo "$pattern" | cut -d'|' -f1)
            local search=$(echo "$pattern" | cut -d'|' -f2)
            if ! bash -c "$cmd" 2>&1 | grep -q "$search"; then
                result=1
            fi
            ;;

        git_diff_order)
            # Check if test files modified before implementation files
            # Pattern format: "test_pattern|impl_pattern"
            local test_pattern=$(echo "$pattern" | cut -d'|' -f1)
            local impl_pattern=$(echo "$pattern" | cut -d'|' -f2)

            # Get file modification timestamps (for uncommitted changes, use mtime)
            local latest_test_time=0
            local latest_impl_time=0

            # Find most recent test file modification
            local changed_files=$(git diff --name-only HEAD 2>/dev/null)
            while IFS= read -r file; do
                [ -z "$file" ] && continue
                # Use case for pattern matching (bash 3.2 compatible)
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
                # Use case for pattern matching (bash 3.2 compatible)
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
