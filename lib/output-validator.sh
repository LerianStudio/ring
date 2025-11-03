#!/usr/bin/env bash
#
# Output Format Validator
# Validates agent output against schema defined in frontmatter
#
# Usage: ./lib/output-validator.sh <agent-file> <output-file>
#
# Exit codes:
#   0 - Output valid
#   1 - Output invalid
#   2 - Invalid usage

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ $# -lt 2 ]; then
    echo "Usage: $0 <agent-file> <output-file>"
    echo "Example: $0 agents/code-reviewer.md /tmp/review-output.md"
    exit 2
fi

AGENT_FILE="$1"
OUTPUT_FILE="$2"

# Validate files exist
if [ ! -f "$AGENT_FILE" ]; then
    echo -e "${RED}Error: Agent file not found: $AGENT_FILE${NC}"
    exit 2
fi

if [ ! -f "$OUTPUT_FILE" ]; then
    echo -e "${RED}Error: Output file not found: $OUTPUT_FILE${NC}"
    exit 2
fi

echo "Validating output format for: $(basename "$AGENT_FILE")"
echo ""

# Check for required sections
check_section() {
    local section_name="$1"
    local pattern="$2"
    local required="$3"

    if grep -q "$pattern" "$OUTPUT_FILE"; then
        echo -e "${GREEN}✓${NC} Section found: $section_name"
        return 0
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}✗${NC} Missing required section: $section_name"
            return 1
        else
            echo -e "${YELLOW}⚠${NC} Optional section missing: $section_name"
            return 0
        fi
    fi
}

# Validation checks
overall_result=0

# Check for VERDICT
if ! check_section "VERDICT" "^## VERDICT:" "true"; then
    overall_result=1
fi

# Check VERDICT value is valid
if grep -q "^## VERDICT: \(PASS\|FAIL\|NEEDS_DISCUSSION\)" "$OUTPUT_FILE"; then
    echo -e "${GREEN}✓${NC} VERDICT value is valid"
else
    echo -e "${RED}✗${NC} VERDICT value must be PASS, FAIL, or NEEDS_DISCUSSION"
    overall_result=1
fi

# Check for Summary
if ! check_section "Summary" "^## Summary" "true"; then
    overall_result=1
fi

# Check for Issues Found
if ! check_section "Issues Found" "^## Issues Found" "true"; then
    overall_result=1
fi

# Check for Next Steps
if ! check_section "Next Steps" "^## Next Steps" "true"; then
    overall_result=1
fi

echo ""
if [ $overall_result -eq 0 ]; then
    echo -e "${GREEN}✓ Output format validation: PASS${NC}"
else
    echo -e "${RED}✗ Output format validation: FAIL${NC}"
fi

exit $overall_result
