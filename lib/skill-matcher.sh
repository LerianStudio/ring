#!/usr/bin/env bash
#
# Skill Matcher
# Maps task descriptions to relevant skills using keyword matching
#
# Usage: ./lib/skill-matcher.sh "<task description>"
#
# Exit codes:
#   0 - Success (skills found or not found)
#   2 - Invalid usage

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ $# -lt 1 ]; then
    echo "Usage: $0 \"<task description>\""
    echo "Example: $0 \"debug this authentication error\""
    exit 2
fi

TASK_DESC="$1"
SKILLS_DIR="${SKILLS_DIR:-skills}"

# Input validation
validate_inputs() {
    # Check task description is not empty and reasonable length
    if [ -z "$TASK_DESC" ]; then
        echo -e "${RED}Error: Task description cannot be empty${NC}"
        exit 2
    fi

    local desc_len=${#TASK_DESC}
    if [ "$desc_len" -gt 1000 ]; then
        echo -e "${RED}Error: Task description too long (max 1000 chars)${NC}"
        exit 2
    fi

    # Validate SKILLS_DIR exists
    if [ ! -d "$SKILLS_DIR" ]; then
        echo -e "${RED}Error: Skills directory not found: $SKILLS_DIR${NC}"
        exit 2
    fi
}

validate_inputs

echo "Finding skills for: \"$TASK_DESC\""
echo ""

# Convert task to lowercase for matching
task_lower=$(echo "$TASK_DESC" | tr '[:upper:]' '[:lower:]')

# Create temp file for skill data (bash 3.2 compatible - no associative arrays)
TMPFILE=$(mktemp)
trap 'rm -f $TMPFILE' EXIT

# Scan all skills
for skill_dir in "$SKILLS_DIR"/*/; do
    if [ ! -f "$skill_dir/SKILL.md" ]; then
        continue
    fi

    skill_file="$skill_dir/SKILL.md"
    skill_name=$(basename "$skill_dir")

    # Extract description from frontmatter
    desc=$(sed -n '/^description:/p' "$skill_file" | sed 's/^description: *"\?\(.*\)"\?$/\1/' | tr '[:upper:]' '[:lower:]')

    # Calculate match score based on keyword overlap
    score=0

    # Check for exact phrase matches (high score)
    phrase=$(echo "$task_lower" | cut -d' ' -f1-3)
    if echo "$desc" | grep -qF "$phrase"; then
        score=$((score + 50))
    fi

    # Check for individual keyword matches
    for word in $task_lower; do
        # Skip common words
        case "$word" in
            the|a|an|to|for|with|this|that|is|are)
                continue
                ;;
        esac

        if echo "$desc" | grep -qw "$word"; then
            score=$((score + 10))
        fi
    done

    # Store: score|skill_name|description
    echo "$score|$skill_name|$desc" >> "$TMPFILE"
done

# Sort and display results
echo "Relevant skills:"
echo ""

# Sort by score (descending) and filter out zero scores
sorted_skills=$(sort -t'|' -k1 -rn "$TMPFILE" | awk -F'|' '$1 > 0')

# Count total matching skills
total_matches=$(echo "$sorted_skills" | wc -l | tr -d ' ')

# Limit to top 5 using heredoc to avoid subshell (bash 3.2 compatible)
count=0
top_five=$(echo "$sorted_skills" | head -5)
while IFS='|' read -r score skill desc; do
    # Skip empty lines or invalid entries
    if [ -z "$score" ] || [ -z "$skill" ]; then
        continue
    fi

    count=$((count + 1))

    # Determine confidence level
    confidence="LOW"
    if [ "$score" -ge 50 ] 2>/dev/null; then
        confidence="HIGH"
    elif [ "$score" -ge 20 ] 2>/dev/null; then
        confidence="MEDIUM"
    fi

    echo -e "$count. ${CYAN}$skill${NC} (${confidence} confidence - score: $score)"
    echo "   $desc"
    echo ""
done <<EOF
$top_five
EOF

# Warn if showing only top results
if [ "$total_matches" -gt 5 ]; then
    echo -e "${YELLOW}Note: Showing top 5 of $total_matches matching skills${NC}"
    echo ""
fi

# Check if any skills found
if [ ! -s "$TMPFILE" ] || [ "$(awk -F'|' '$1 > 0' "$TMPFILE" | wc -l)" -eq 0 ]; then
    echo -e "${YELLOW}No matching skills found${NC}"
    echo "Try rephrasing your task or check available skills manually:"
    echo "  ls skills/"
else
    # Show recommendation
    top_skill=$(echo "$sorted_skills" | head -1 | cut -d'|' -f2)
    echo -e "${GREEN}Recommended:${NC} Start with ${CYAN}$top_skill${NC}"
fi

exit 0
