#!/usr/bin/env bash
# shellcheck disable=SC2034  # Unused variables OK for exported config
# Fallback skill reference generator when Python is unavailable
# Requires bash 3.2+ (uses [[ ]], ${BASH_SOURCE})
# Tools used: sed, awk, grep, sort, cut (standard on macOS/Linux/Git Bash)
#
# This script provides a degraded but functional skills quick reference
# when Python or PyYAML are not available on the system.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# Script lives in default/hooks/, so repo root is two levels up.
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# MUST stay in sync with generate-skills-ref.py ALL_PLUGINS list.
PLUGINS=("default" "dev-team" "pm-team" "tw-team")

# Parse a single field from YAML frontmatter
# Uses portable sed pattern for YAML parsing
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
    # Portable sed pattern for YAML frontmatter extraction
    local frontmatter
    frontmatter=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$skill_file" 2>/dev/null) || return

    if [[ -z "$frontmatter" ]]; then
        echo "Warning: No frontmatter in $skill_file" >&2
        return
    fi

    # Extract fields
    local name description
    name=$(extract_field "$frontmatter" "name")
    description=$(extract_field "$frontmatter" "description")

    # Use directory name if name field missing
    if [[ -z "$name" ]]; then
        name="$skill_dir"
    fi

    # Default description if missing
    if [[ -z "$description" ]]; then
        description="(no description)"
    fi

    # No truncation: matches generate-skills-ref.py condense_description behavior.

    # Output as TSV for reliable parsing (dir, name, description)
    printf '%s\t%s\t%s\n' "$skill_dir" "$name" "$description"
}

# Categorize skill based on directory name
# MUST stay in sync with generate-skills-ref.py CATEGORIES dict.
categorize_skill() {
    local dir="$1"
    case "$dir" in
        pre-dev-*) echo "Pre-Dev Workflow" ;;
        test-*|*-debugging|condition-*|defense-*|root-cause*) echo "Testing & Debugging" ;;
        *-review|dispatching-*|sharing-*) echo "Collaboration" ;;
        brainstorm|writing-plans|execute-plan|*worktree|subagent-driven*) echo "Planning & Execution" ;;
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
    while IFS=$'\t' read -r dir name desc; do
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

        echo "- **${name}**: ${desc}"
        skill_count=$((skill_count + 1))
    done

    echo ""
    echo "## Usage"
    echo ""
    echo "To use a skill: Use the Skill tool with skill name"
    echo "Example: \`ring:brainstorm\`"

    # Output stats to stderr (like Python version)
    echo "" >&2
    echo "Generated reference for ${skill_count} skills (bash fallback)" >&2
}

# Main execution
main() {
    # Collect all skills with categories, then sort and generate markdown
    local tmpfile
    # Set restrictive umask before creating temp file (prevents race condition)
    local old_umask
    old_umask=$(umask)
    umask 077
    tmpfile=$(mktemp)
    umask "$old_umask"
    trap "rm -f '$tmpfile'" EXIT INT TERM HUP

    local found_any_plugin=0
    local plugin
    for plugin in "${PLUGINS[@]}"; do
        local skills_dir="${REPO_ROOT}/${plugin}/skills"
        # Mirror Python behavior: silently skip plugins without a skills/ dir.
        if [[ ! -d "$skills_dir" ]]; then
            continue
        fi
        found_any_plugin=1

        for skill_dir in "$skills_dir"/*/; do
            # Skip if not a directory (handles empty glob)
            [[ -d "$skill_dir" ]] || continue

            # Skip shared-patterns directory (mirrors Python script)
            local dirname
            dirname=$(basename "$skill_dir")
            if [[ "$dirname" == "shared-patterns" ]]; then
                continue
            fi

            local skill_file="${skill_dir}SKILL.md"
            if [[ -f "$skill_file" ]]; then
                local skill_line
                skill_line=$(parse_skill "$skill_file")
                if [[ -n "$skill_line" ]]; then
                    # Add category as first field for sorting
                    local dir name desc cat
                    IFS=$'\t' read -r dir name desc <<< "$skill_line"
                    cat=$(categorize_skill "$dir")
                    printf '%s\t%s\t%s\t%s\n' "$cat" "$dir" "$name" "$desc" >> "$tmpfile"
                fi
            else
                echo "Warning: No SKILL.md in $(basename "$skill_dir")" >&2
            fi
        done
    done

    if [[ "$found_any_plugin" -eq 0 ]]; then
        echo "Error: No plugin skills directory found under: $REPO_ROOT" >&2
        exit 1
    fi

    # Sort by category, then by name (matches Python: predefined-category order
    # is approximated here by alphabetic — Python's deterministic group order
    # is not perfectly reproducible in pure sort(1), but skills within each
    # category are sorted by name identically).
    sort -t$'\t' -k1,1 -k3,3 "$tmpfile" | cut -f2- | generate_markdown
}

main "$@"
