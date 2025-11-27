#!/usr/bin/env bash
# Enhanced SessionStart hook for ring plugin
# Provides comprehensive skill overview and status

set -euo pipefail

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Auto-update Ring marketplace and plugins
marketplace_updated="false"
if command -v claude &> /dev/null && command -v git &> /dev/null; then
    # Detect marketplace path (common locations)
    marketplace_path=""
    for path in ~/.claude/plugins/marketplaces/ring ~/.config/claude/plugins/marketplaces/ring ~/Library/Application\ Support/Claude/plugins/marketplaces/ring; do
        if [ -d "$path/.git" ]; then
            marketplace_path="$path"
            break
        fi
    done

    if [ -n "$marketplace_path" ]; then
        # Get current commit hash before update
        before_hash=$(git -C "$marketplace_path" rev-parse HEAD 2>/dev/null || echo "none")

        # Update marketplace
        claude plugin marketplace update ring &> /dev/null || true

        # Get commit hash after update
        after_hash=$(git -C "$marketplace_path" rev-parse HEAD 2>/dev/null || echo "none")

        # If hashes differ, marketplace was actually updated
        if [ "$before_hash" != "$after_hash" ] && [ "$after_hash" != "none" ]; then
            marketplace_updated="true"
            # Reinstall all plugins to get new versions
            claude plugin install ring-default &> /dev/null || true
            claude plugin install ring-dev-team &> /dev/null || true
            claude plugin install ring-finops-team &> /dev/null || true
            claude plugin install ring-pm-team &> /dev/null || true
            claude plugin install ralph-wiggum &> /dev/null || true
        fi
    else
        # Marketplace not found, just run updates silently
        claude plugin marketplace update ring &> /dev/null || true
        claude plugin install ring-default &> /dev/null || true
        claude plugin install ring-dev-team &> /dev/null || true
        claude plugin install ring-finops-team &> /dev/null || true
        claude plugin install ralph-wiggum &> /dev/null || true
    fi
fi

# Auto-install PyYAML if Python is available but PyYAML is not
if command -v python3 &> /dev/null; then
    if ! python3 -c "import yaml" &> /dev/null 2>&1; then
        # PyYAML not installed, try to install it
        # Try different pip commands (pip3 preferred, then pip)
        for pip_cmd in pip3 pip; do
            if command -v "$pip_cmd" &> /dev/null; then
                # Strategy: Try --user first, then --user --break-system-packages
                # (--break-system-packages only exists in pip 22.1+, needed for PEP 668)
                if "$pip_cmd" install --quiet --user 'PyYAML>=6.0,<7.0' &> /dev/null 2>&1; then
                    echo "PyYAML installed successfully" >&2
                    break
                elif "$pip_cmd" install --quiet --user --break-system-packages 'PyYAML>=6.0,<7.0' &> /dev/null 2>&1; then
                    echo "PyYAML installed successfully (with --break-system-packages)" >&2
                    break
                fi
            fi
        done
        # If all installation attempts fail, generate-skills-ref.py will use fallback parser
        # (No error message needed - the Python script already warns about missing PyYAML)
    fi
fi

# Critical rules that MUST survive compact (injected directly, not via skill file)
# These are the most-violated rules that need to be in immediate context
CRITICAL_RULES='## ⛔ ORCHESTRATOR CRITICAL RULES (SURVIVE COMPACT)

**3-FILE RULE: HARD GATE**
DO NOT read/edit >3 files directly. This is a PROHIBITION.
- >3 files → STOP. Launch specialist agent. DO NOT proceed manually.
- Already touched 3 files? → At gate. Dispatch agent NOW.

**AUTO-TRIGGER PHRASES → MANDATORY AGENT:**
- "fix issues/remaining/findings" → Launch specialist agent
- "apply fixes", "fix the X issues" → Launch specialist agent
- "find where", "search for", "understand how" → Launch Explore agent

**If you think "this task is small" or "I can handle 5 files":**
WRONG. Count > 3 = agent. No exceptions. Task size is irrelevant.

**Full rules:** Use Skill tool with "ring-default:using-ring" if needed.
'

# Generate skills overview with cascading fallback
# Priority: Python+PyYAML > Python regex > Bash fallback > Error message
generate_skills_overview() {
    local python_cmd=""

    # Try python3 first, then python
    for cmd in python3 python; do
        if command -v "$cmd" &> /dev/null; then
            python_cmd="$cmd"
            break
        fi
    done

    if [[ -n "$python_cmd" ]]; then
        # Python available - use Python script (handles PyYAML fallback internally)
        "$python_cmd" "${SCRIPT_DIR}/generate-skills-ref.py" 2>&1
        return $?
    fi

    # Python not available - try bash fallback
    if [[ -x "${SCRIPT_DIR}/generate-skills-ref.sh" ]]; then
        echo "Note: Python unavailable, using bash fallback" >&2
        "${SCRIPT_DIR}/generate-skills-ref.sh" 2>&1
        return $?
    fi

    # Ultimate fallback - minimal useful output
    echo "# Ring Skills Quick Reference"
    echo ""
    echo "**Note:** Neither Python nor bash fallback available."
    echo "Skills are still accessible via the Skill tool."
    echo ""
    echo "Run: \`Skill tool: ring-default:using-ring\` to see available workflows."
    echo ""
    echo "To fix: Install Python 3.x or ensure generate-skills-ref.sh is executable."
}

skills_overview=$(generate_skills_overview || echo "Error generating skills quick reference")

# Check jq availability (required for JSON escaping)
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required for JSON escaping but not found" >&2
  echo "Install with: brew install jq (macOS) or apt install jq (Linux)" >&2
  exit 1
fi

# Escape outputs for JSON using jq for RFC 8259 compliant escaping
# Note: jq is required - commonly pre-installed on macOS/Linux, install via package manager if missing
# The -Rs flags: -R (raw input, don't parse as JSON), -s (slurp entire input into single string)
# jq -Rs outputs a properly quoted JSON string including surrounding quotes, so we strip them
# Note: using-ring content is already included in skills_overview via generate-skills-ref.py
overview_escaped=$(echo "$skills_overview" | jq -Rs . | sed 's/^"//;s/"$//' || echo "$skills_overview")
critical_rules_escaped=$(echo "$CRITICAL_RULES" | jq -Rs . | sed 's/^"//;s/"$//' || echo "$CRITICAL_RULES")

# Build JSON output - include update notification if marketplace was updated
if [ "$marketplace_updated" = "true" ]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<ring-marketplace-updated>\nThe Ring marketplace was just updated to a new version. New skills and agents have been installed but won't be available until the session is restarted. Inform the user they should restart their session (type 'clear' or restart Claude Code) to load the new capabilities.\n</ring-marketplace-updated>\n\n<ring-critical-rules>\n${critical_rules_escaped}\n</ring-critical-rules>\n\n<ring-skills-system>\n${overview_escaped}\n</ring-skills-system>"
  }
}
EOF
else
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<ring-critical-rules>\n${critical_rules_escaped}\n</ring-critical-rules>\n\n<ring-skills-system>\n${overview_escaped}\n</ring-skills-system>"
  }
}
EOF
fi

exit 0
