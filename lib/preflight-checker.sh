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

if [ ! -f "$SKILL_FILE" ]; then
    echo -e "${RED}Error: Skill file not found: $SKILL_FILE${NC}"
    exit 2
fi

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

echo -e "${YELLOW}Prerequisites found - validation pending${NC}"
echo ""
echo "Note: Full prerequisite checking requires YAML parser implementation"
echo "For now, showing prerequisites structure only:"
echo ""
echo "$frontmatter" | sed -n '/prerequisites:/,/^[a-z_]*:/p' | sed '$d'
echo ""
echo -e "${GREEN}✓ Pre-flight check: PASS (placeholder)${NC}"

# TODO: Implement full prerequisite parsing and checking with yq
exit 0
