#!/usr/bin/env bash
# shellcheck disable=SC2034  # Unused variables OK for exported config
# Enhanced SessionStart hook for ring plugin
# Provides comprehensive skill overview and status

set -euo pipefail

# Capture original working directory BEFORE any cd operations
# This is the user's project directory (where Claude Code was launched)
ORIGINAL_CWD="$PWD"

# Determine plugin root directory BEFORE any cd operations
# Uses BASH_SOURCE which is always the script's own path regardless of cwd
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Debug logging (enable with RING_DEBUG=true)
debug_log() { [[ "${RING_DEBUG:-false}" == "true" ]] && echo "[$(date '+%H:%M:%S')] $*" >> /tmp/ring-hook-debug.log || true; }
debug_log "Hook started: PWD=$PWD ORIGINAL_CWD=$ORIGINAL_CWD PLUGIN_ROOT=$PLUGIN_ROOT CLAUDE_PROJECT_DIR=${CLAUDE_PROJECT_DIR:-unset} CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT:-<not set>}"

# Validate CLAUDE_PLUGIN_ROOT is set and reasonable (when used via hooks)
# Note: This script can run standalone via SCRIPT_DIR detection or via CLAUDE_PLUGIN_ROOT
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    if ! cd "${CLAUDE_PLUGIN_ROOT}" 2>/dev/null; then
        echo '{"error": "Invalid CLAUDE_PLUGIN_ROOT path"}'
        exit 1
    fi
fi

# Auto-install PyYAML if Python is available but PyYAML is not
# Set RING_AUTO_INSTALL_DEPS=false to disable automatic dependency installation
if [[ "${RING_AUTO_INSTALL_DEPS:-true}" == "true" ]]; then
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
- "draw a diagram", "explain architecture", "visualize", "comparison table" → Load ring:visualize skill

**If you think "this task is small" or "I can handle 5 files":**
WRONG. Count > 3 = agent. No exceptions. Task size is irrelevant.

**Full rules:** Use Skill tool with "ring:using-ring" if needed.
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
    echo "Run: \`Skill tool: ring:using-ring\` to see available workflows."
    echo ""
    echo "To fix: Install Python 3.x or ensure generate-skills-ref.sh is executable."
}

skills_overview=$(generate_skills_overview || echo "Error generating skills quick reference")
debug_log "Skills overview generated: ${#skills_overview} chars"

# Source shared JSON escaping utility
SHARED_LIB="${PLUGIN_ROOT}/../shared/lib"
if [[ -f "${SHARED_LIB}/json-escape.sh" ]]; then
    # shellcheck source=/dev/null
    source "${SHARED_LIB}/json-escape.sh"
else
    # Fallback: define json_escape locally if shared lib not found
    # Mirrors shared/lib/json-escape.sh implementation
    json_escape() {
        local input="$1"
        if command -v jq &>/dev/null; then
            printf '%s' "$input" | jq -Rs . | sed 's/^"//;s/"$//'
        else
            # Cross-platform fallback using awk (works on both BSD and GNU)
            printf '%s' "$input" | awk '
                BEGIN { ORS="" }
                {
                    gsub(/\\/, "\\\\")
                    gsub(/"/, "\\\"")
                    gsub(/\t/, "\\t")
                    gsub(/\r/, "\\r")
                    if (NR > 1) printf "\\n"
                    print
                }
            '
        fi
    }
fi

# Escape outputs for JSON using RFC 8259 compliant escaping
# Note: using-ring content is already included in skills_overview via generate-skills-ref.py
overview_escaped=$(json_escape "$skills_overview")
critical_rules_escaped=$(json_escape "$CRITICAL_RULES")
doubt_questions_escaped=$(json_escape "$DOUBT_QUESTIONS")
debug_log "Escaped: overview=${#overview_escaped}c rules=${#critical_rules_escaped}c doubt=${#doubt_questions_escaped}c"

# Handoff auto-resume removed: now handled natively via Plan Mode (see /ring:create-handoff)

# Build additionalContext
additional_context="<ring-critical-rules>\n${critical_rules_escaped}\n</ring-critical-rules>\n\n<ring-doubt-questions>\n${doubt_questions_escaped}\n</ring-doubt-questions>\n\n<ring-skills-system>\n${overview_escaped}\n</ring-skills-system>"

debug_log "Output: context=${#additional_context}c"

# Build JSON output using printf to avoid heredoc variable expansion issues
printf '{\n  "hookSpecificOutput": {\n    "hookEventName": "SessionStart",\n    "additionalContext": "%s"\n  }\n}\n' "$additional_context"
debug_log "Hook complete, exit 0"

exit 0
