#!/usr/bin/env bash
#
# Skill Composer
# Suggests next skill based on current context
#
# Usage: ./lib/skill-composer.sh <current-skill> <context>
#
# Exit codes:
#   0 - Success
#   2 - Invalid usage

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ $# -lt 2 ]; then
    echo "Usage: $0 <current-skill> <context>"
    echo "Example: $0 test-driven-development \"test revealed unexpected behavior\""
    exit 2
fi

CURRENT_SKILL="$1"
CONTEXT="$2"

echo "Suggesting next skill after: ${CYAN}$CURRENT_SKILL${NC}"
echo "Context: $CONTEXT"
echo ""

# Extract composition metadata from skill frontmatter
SKILLS_DIR="${SKILLS_DIR:-skills}"
SKILL_FILE="$SKILLS_DIR/$CURRENT_SKILL/SKILL.md"

if [ ! -f "$SKILL_FILE" ]; then
    echo -e "${YELLOW}Skill file not found: $SKILL_FILE${NC}"
    echo "Cannot provide composition suggestions."
    exit 0
fi

# Check for composition metadata in frontmatter
if grep -q "works_well_with:" "$SKILL_FILE"; then
    echo -e "${GREEN}Composition suggestions found:${NC}"
    echo ""

    # Extract works_well_with section
    sed -n '/works_well_with:/,/^[a-z_]*:/p' "$SKILL_FILE" | sed '$d' | sed 's/^/  /'
    echo ""
else
    echo -e "${YELLOW}No composition metadata defined in this skill${NC}"
    echo ""
    echo "Common next skills to consider:"
    echo "  - verification-before-completion (before marking work complete)"
    echo "  - systematic-debugging (when encountering unexpected behavior)"
    echo "  - requesting-code-review (after completing implementation)"
fi

exit 0
