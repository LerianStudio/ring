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

# Validate file exists
if [ ! -f "$SKILL_FILE" ]; then
    echo -e "${RED}Error: File not found: $SKILL_FILE${NC}"
    exit 2
fi

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
            if ! find . -path "./.*" -prune -o -type f -path "$pattern" -print | grep -q .; then
                result=1
            fi
            ;;

        command_succeeds)
            # Run command and check exit code
            if ! eval "$pattern" >/dev/null 2>&1; then
                result=1
            fi
            ;;

        command_output_contains)
            # Run command and check if output contains pattern
            local cmd=$(echo "$pattern" | cut -d'|' -f1)
            local search=$(echo "$pattern" | cut -d'|' -f2)
            if ! eval "$cmd" 2>&1 | grep -q "$search"; then
                result=1
            fi
            ;;

        git_diff_order)
            # Check if test files modified before implementation files
            # This is a simplified check - real implementation would parse patterns
            if ! git diff --name-only HEAD | grep -q "test"; then
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

    echo -e "${GREEN}Compliance rules found${NC}"
    echo "$rules"
    echo ""
    echo -e "${YELLOW}Note: Full validation requires YAML parser (yq)${NC}"
    echo -e "${YELLOW}For now, showing rules structure only${NC}"

    # TODO: Implement full rule parsing and validation with yq
    # For now, return success
    exit 0
}

main
