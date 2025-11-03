#!/usr/bin/env bash
#
# Pre-flight Checker
# Runs prerequisite checks before skills start
#
# Usage: ./lib/preflight-checker.sh <skill-file>
#
# Exit codes:
#   0 - All checks pass
#   1 - Blocking check failed
#   2 - Invalid usage

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ $# -lt 1 ]; then
    echo "Usage: $0 <skill-file>"
    echo "Example: $0 skills/test-driven-development/SKILL.md"
    exit 2
fi

SKILL_FILE="$1"

# Input validation
validate_inputs() {
    # Check for path traversal
    case "$SKILL_FILE" in
        *..*)
            echo -e "${RED}Error: Invalid file path (contains ..)${NC}"
            exit 2
            ;;
    esac

    # Validate file exists and is readable
    if [ ! -f "$SKILL_FILE" ]; then
        echo -e "${RED}Error: Skill file not found: $SKILL_FILE${NC}"
        exit 2
    fi

    if [ ! -r "$SKILL_FILE" ]; then
        echo -e "${RED}Error: Skill file not readable: $SKILL_FILE${NC}"
        exit 2
    fi
}

validate_inputs

echo "Running pre-flight checks for: $(basename "$SKILL_FILE")"
echo ""

# Extract frontmatter
extract_frontmatter() {
    sed -n '/^---$/,/^---$/p' "$1" | sed '1d;$d'
}

# Check if skill has prerequisites
has_prerequisites() {
    echo "$1" | grep -q "prerequisites:"
}

frontmatter=$(extract_frontmatter "$SKILL_FILE")

if ! has_prerequisites "$frontmatter"; then
    echo -e "${GREEN}✓ No prerequisites defined - ready to proceed${NC}"
    exit 0
fi

# Check if yq is available for YAML parsing
if ! command -v yq >/dev/null 2>&1; then
    echo -e "${RED}Error: yq is required for prerequisite checking${NC}"
    echo "Install with: brew install yq (macOS) or see https://github.com/mikefarah/yq"
    exit 2
fi

echo "Prerequisites found - validating..."
echo ""

# Parse prerequisites using yq
prereq_list=$(echo "$frontmatter" | yq eval '.prerequisites[]' - 2>/dev/null)

if [ -z "$prereq_list" ]; then
    echo -e "${GREEN}✓ No prerequisites to check${NC}"
    exit 0
fi

overall_result=0

# Check each prerequisite
while IFS= read -r prereq; do
    [ -z "$prereq" ] && continue

    echo -n "Checking: $prereq ... "

    # Check if it's a command
    if command -v "$prereq" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        echo "  Required: $prereq"
        overall_result=1
    fi
done <<< "$prereq_list"

echo ""
if [ $overall_result -eq 0 ]; then
    echo -e "${GREEN}✓ All prerequisites satisfied${NC}"
    exit 0
else
    echo -e "${RED}✗ Some prerequisites missing${NC}"
    exit 1
fi
