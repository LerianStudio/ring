#!/usr/bin/env bash
# shellcheck disable=SC2034  # Unused variables OK for exported config
# Fallback skill reference generator when Python is unavailable
# Requires bash 3.2+ (uses [[ ]], ${BASH_SOURCE}, ${var:0:n})
# Tools used: sed, awk, grep (standard on macOS/Linux/Git Bash)
#
# This script provides a degraded but functional skills quick reference
# when Python or PyYAML are not available on the system.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILLS_DIR="${PLUGIN_ROOT}/skills"

# Parse a single field from YAML frontmatter
# Uses the proven sed pattern from ralph-wiggum/hooks/stop-hook.sh
extract_field() {
    local frontmatter="$1"
    local field="$2"

    # For simple fields: fieldname: value
    # For block scalars: fieldname: | followed by indented lines
    echo "$frontmatter" | awk -v field="$field" '
        BEGIN { found = 0; value = "" }

        # Match the field we want
        $0 ~ "^" field ":" {
            found = 1
            # Check for inline value (not block scalar)
            sub("^" field ":[[:space:]]*\\|?[[:space:]]*", "")
            if (length($0) > 0 && $0 !~ /^\|[[:space:]]*$/) {
                value = $0
                exit
            }
            next
        }

        # If we found our field and this line is indented, capture it
        found && /^[[:space:]]+[^[:space:]]/ {
            gsub(/^[[:space:]]+/, "")
            gsub(/[[:space:]]+$/, "")
            # Skip list markers for cleaner output
            gsub(/^-[[:space:]]+/, "")
            if (length($0) > 0 && value == "") {
                value = $0
                exit
            }
        }

        # If we hit another field definition, stop
        found && /^[a-z_]+:/ && $0 !~ "^" field ":" {
            exit
        }

        END { print value }
    '
}

# Parse YAML frontmatter from SKILL.md
parse_skill() {
    local skill_file="$1"
    local skill_dir
    skill_dir=$(basename "$(dirname "$skill_file")")

    # Skip shared-patterns directory
    if [[ "$skill_dir" == "shared-patterns" ]]; then
        return
    fi

    # Extract frontmatter between --- delimiters
    # Pattern proven portable in ralph-wiggum/hooks/stop-hook.sh
    local frontmatter
    frontmatter=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$skill_file" 2>/dev/null) || return

    if [[ -z "$frontmatter" ]]; then
        echo "Warning: No frontmatter in $skill_file" >&2
        return
    fi

    # Extract fields
    local name description trigger
    name=$(extract_field "$frontmatter" "name")
    description=$(extract_field "$frontmatter" "description")
    trigger=$(extract_field "$frontmatter" "trigger")

    # Fallback: use when_to_use if trigger not set (backward compat)
    if [[ -z "$trigger" ]]; then
        trigger=$(extract_field "$frontmatter" "when_to_use")
    fi

    # Use directory name if name field missing
    if [[ -z "$name" ]]; then
        name="$skill_dir"
    fi

    # Default description if missing
    if [[ -z "$description" ]]; then
        description="(no description)"
    fi

    # Truncate long descriptions for quick reference
    if [[ ${#description} -gt 100 ]]; then
        description="${description:0:97}..."
    fi

    # Output as TSV for reliable parsing (dir, name, description, trigger)
    printf '%s\t%s\t%s\t%s\n' "$skill_dir" "$name" "$description" "$trigger"
}

# Categorize skill based on directory name
categorize_skill() {
    local dir="$1"
    case "$dir" in
        pre-dev-*) echo "Pre-Dev Workflow" ;;
        test-*|*-debugging|condition-*|defense-*|root-cause*) echo "Testing & Debugging" ;;
        *-review|dispatching-*|sharing-*) echo "Collaboration" ;;
        brainstorming|writing-plans|executing-plans|*-worktrees|subagent-driven*) echo "Planning & Execution" ;;
        using-*|writing-skills|testing-skills*|testing-agents*) echo "Meta Skills" ;;
        *) echo "Other" ;;
    esac
}

# Generate markdown output
generate_markdown() {
    echo "# Ring Skills Quick Reference"
    echo ""
    echo "> **Note:** Python unavailable. Using bash fallback parser."
    echo "> Install Python + PyYAML for full output with categories."
    echo ""

    local skill_count=0
    local current_category=""

    # Sort by category, then by name
    while IFS=$'\t' read -r dir name desc trigger; do
        local category
        category=$(categorize_skill "$dir")

        # Print category header if changed
        if [[ "$category" != "$current_category" ]]; then
            if [[ -n "$current_category" ]]; then
                echo ""
            fi
            echo "## $category"
            echo ""
            current_category="$category"
        fi

        # Combine description with trigger hint if available
        local display_desc="$desc"
        if [[ -n "$trigger" && "$trigger" != "$desc" ]]; then
            display_desc="$trigger"
        fi

        echo "- **${name}**: ${display_desc}"
        skill_count=$((skill_count + 1))
    done

    echo ""
    echo "## Usage"
    echo ""
    echo "To use a skill: Use the Skill tool with skill name"
    echo "Example: \`ring-default:brainstorming\`"

    # Output stats to stderr (like Python version)
    echo "" >&2
    echo "Generated reference for ${skill_count} skills (bash fallback)" >&2
}

# Main execution
main() {
    if [[ ! -d "$SKILLS_DIR" ]]; then
        echo "Error: Skills directory not found: $SKILLS_DIR" >&2
        exit 1
    fi

    # Collect all skills with categories, then sort and generate markdown
    local tmpfile
    # Set restrictive umask before creating temp file (prevents race condition)
    local old_umask
    old_umask=$(umask)
    umask 077
    tmpfile=$(mktemp)
    umask "$old_umask"
    trap "rm -f '$tmpfile'" EXIT INT TERM HUP

    for skill_dir in "$SKILLS_DIR"/*/; do
        # Skip if not a directory
        [[ -d "$skill_dir" ]] || continue

        local skill_file="${skill_dir}SKILL.md"
        if [[ -f "$skill_file" ]]; then
            local skill_line
            skill_line=$(parse_skill "$skill_file")
            if [[ -n "$skill_line" ]]; then
                # Add category as first field for sorting
                local dir name desc trigger cat
                IFS=$'\t' read -r dir name desc trigger <<< "$skill_line"
                cat=$(categorize_skill "$dir")
                printf '%s\t%s\t%s\t%s\t%s\n' "$cat" "$dir" "$name" "$desc" "$trigger" >> "$tmpfile"
            fi
        else
            echo "Warning: No SKILL.md in $(basename "$skill_dir")" >&2
        fi
    done

    # Sort by category, then by name, remove category column, generate markdown
    sort -t$'\t' -k1,1 -k3,3 "$tmpfile" | cut -f2- | generate_markdown
}

main "$@"
