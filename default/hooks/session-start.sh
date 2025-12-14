#!/usr/bin/env bash
# shellcheck disable=SC2034  # Unused variables OK for exported config
# Enhanced SessionStart hook for ring plugin
# Provides comprehensive skill overview and status

set -euo pipefail

# Validate CLAUDE_PLUGIN_ROOT is set and reasonable (when used via hooks)
# Note: This script can run standalone via SCRIPT_DIR detection or via CLAUDE_PLUGIN_ROOT
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    if ! cd "${CLAUDE_PLUGIN_ROOT}" 2>/dev/null; then
        echo '{"error": "Invalid CLAUDE_PLUGIN_ROOT path"}'
        exit 1
    fi
fi

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Auto-update Ring marketplace and plugins (using safe git pull, not destructive CLI)
marketplace_updated="false"
if command -v git &> /dev/null; then
    # Detect marketplace path (common locations)
    marketplace_path=""
    for path in ~/.claude/plugins/marketplaces/ring ~/.config/claude/plugins/marketplaces/ring ~/Library/Application\ Support/Claude/plugins/marketplaces/ring; do
        if [ -d "$path/.git" ]; then
            marketplace_path="$path"
            break
        fi
    done

    if [ -n "$marketplace_path" ]; then
        # Safe update using git pull (non-destructive)
        # Get current commit hash before update
        before_hash=$(git -C "$marketplace_path" rev-parse HEAD 2>/dev/null || echo "none")

        # Use git pull directly - NEVER use 'claude plugin marketplace update' as it deletes before cloning
        # Try to fetch and pull (fast-forward only to avoid merge conflicts)
        if git -C "$marketplace_path" fetch --quiet 2>/dev/null; then
            # Only pull if we're on a branch (not detached HEAD)
            current_branch=$(git -C "$marketplace_path" symbolic-ref --short HEAD 2>/dev/null || echo "")
            if [ -n "$current_branch" ]; then
                git -C "$marketplace_path" pull --ff-only --quiet 2>/dev/null || true
            fi
        fi

        # Get commit hash after update
        after_hash=$(git -C "$marketplace_path" rev-parse HEAD 2>/dev/null || echo "none")

        # If hashes differ, marketplace was actually updated
        if [ "$before_hash" != "$after_hash" ] && [ "$after_hash" != "none" ]; then
            marketplace_updated="true"
            # Reinstall all plugins to get new versions (only if claude CLI available)
            if command -v claude &> /dev/null; then
                claude plugin install ring-default &> /dev/null || true
                claude plugin install ring-dev-team &> /dev/null || true
                claude plugin install ring-finops-team &> /dev/null || true
                claude plugin install ring-pm-team &> /dev/null || true
                claude plugin install ring-tw-team &> /dev/null || true
            fi
        fi
    fi
    # NOTE: If marketplace not found, do NOT try to install it automatically.
    # The destructive 'claude plugin marketplace update' command can fail and leave
    # the user with no marketplace at all. User should manually run:
    #   claude plugin marketplace add lerianstudio/ring
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

# Doubt-triggered questions pattern - when agents should ask vs proceed
DOUBT_QUESTIONS='## 🤔 DOUBT-TRIGGERED QUESTIONS (WHEN TO ASK)

**Resolution hierarchy (check BEFORE asking):**
1. User dispatch context → Did they already specify?
2. CLAUDE.md / repo conventions → Is there a standard?
3. Codebase patterns → What does existing code do?
4. Best practice → Is one approach clearly superior?
5. **→ ASK** → Only if ALL above fail AND affects correctness

**Genuine doubt criteria (ALL must be true):**
- Cannot resolve from hierarchy above
- Multiple approaches genuinely viable
- Choice significantly impacts correctness
- Getting it wrong wastes substantial effort

**Question quality - show your work:**
```
✅ "Found PostgreSQL in docker-compose but MongoDB in docs.
    This feature needs time-series. Which should I extend?"
❌ "Which database should I use?"
```

**If proceeding without asking:**
State assumption → Explain why → Note what would change it

**Full pattern:** See shared-patterns/doubt-triggered-questions.md
'

# CLI Discovery - Natural language component search
CLI_DISCOVERY='## 🔍 Ring CLI - Component Discovery

**Can'"'"'t find the right skill/agent/command?**

```bash
ring-cli "what you need"
```

**Examples:**
- `ring-cli "code review"` → finds all review-related components
- `ring-cli --type agent "backend Go"` → finds Go backend specialists
- `ring-cli --json "debugging"` → JSON output for scripting

**Setup:** `cd tools/ring-cli && ./build.sh` then add to PATH
**Docs:** See `tools/ring-cli/README.md`
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

# Source shared JSON escaping utility
SHARED_LIB="${PLUGIN_ROOT}/../shared/lib"
if [[ -f "${SHARED_LIB}/json-escape.sh" ]]; then
    # shellcheck source=/dev/null
    source "${SHARED_LIB}/json-escape.sh"
else
    # Fallback: define json_escape locally if shared lib not found
    json_escape() {
        local input="$1"
        if command -v jq &>/dev/null; then
            printf '%s' "$input" | jq -Rs . | sed 's/^"//;s/"$//'
        else
            # Fallback sed-based escaping (handles common cases)
            printf '%s' "$input" | sed \
                -e 's/\\/\\\\/g' \
                -e 's/"/\\"/g' \
                -e 's/\t/\\t/g' \
                -e 's/\r/\\r/g' \
                -e ':a;N;$!ba;s/\n/\\n/g'
        fi
    }
fi

# Escape outputs for JSON using RFC 8259 compliant escaping
# Note: using-ring content is already included in skills_overview via generate-skills-ref.py
overview_escaped=$(json_escape "$skills_overview")
critical_rules_escaped=$(json_escape "$CRITICAL_RULES")
doubt_questions_escaped=$(json_escape "$DOUBT_QUESTIONS")
cli_discovery_escaped=$(json_escape "$CLI_DISCOVERY")

# Build JSON output - include update notification if marketplace was updated
if [ "$marketplace_updated" = "true" ]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<ring-marketplace-updated>\nThe Ring marketplace was just updated to a new version. New skills and agents have been installed but won't be available until the session is restarted. Inform the user they should restart their session (type 'clear' or restart Claude Code) to load the new capabilities.\n</ring-marketplace-updated>\n\n<ring-critical-rules>\n${critical_rules_escaped}\n</ring-critical-rules>\n\n<ring-cli-discovery>\n${cli_discovery_escaped}\n</ring-cli-discovery>\n\n<ring-doubt-questions>\n${doubt_questions_escaped}\n</ring-doubt-questions>\n\n<ring-skills-system>\n${overview_escaped}\n</ring-skills-system>"
  }
}
EOF
else
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<ring-critical-rules>\n${critical_rules_escaped}\n</ring-critical-rules>\n\n<ring-cli-discovery>\n${cli_discovery_escaped}\n</ring-cli-discovery>\n\n<ring-doubt-questions>\n${doubt_questions_escaped}\n</ring-doubt-questions>\n\n<ring-skills-system>\n${overview_escaped}\n</ring-skills-system>"
  }
}
EOF
fi

exit 0
