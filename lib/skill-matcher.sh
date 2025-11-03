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

echo "Finding skills for: \"$TASK_DESC\""
echo ""

# Convert task to lowercase for matching
task_lower=$(echo "$TASK_DESC" | tr '[:upper:]' '[:lower:]')

# Create temp file for skill data (bash 3.2 compatible - no associative arrays)
TMPFILE=$(mktemp)
trap "rm -f $TMPFILE" EXIT

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

# Sort by score (descending)
sorted_skills=$(sort -t'|' -k1 -rn "$TMPFILE")

count=0
echo "$sorted_skills" | while IFS='|' read -r score skill desc; do
    # Skip empty lines or invalid entries
    if [ -z "$score" ] || [ -z "$skill" ]; then
        continue
    fi

    # Skip skills with score 0
    if [ "$score" -eq 0 ] 2>/dev/null; then
        continue
    fi

    # Determine confidence level
    confidence="LOW"
    if [ "$score" -ge 50 ] 2>/dev/null; then
        confidence="HIGH"
    elif [ "$score" -ge 20 ] 2>/dev/null; then
        confidence="MEDIUM"
    fi

    echo -e "$((count + 1)). ${CYAN}$skill${NC} (${confidence} confidence - score: $score)"
    echo "   $desc"
    echo ""

    count=$((count + 1))

    # Limit to top 5
    if [ $count -ge 5 ]; then
        break
    fi
done

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
