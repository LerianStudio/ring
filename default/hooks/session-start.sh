#!/usr/bin/env bash
# Enhanced SessionStart hook for ring plugin
# Provides comprehensive skill overview and status

set -euo pipefail

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Auto-update Ring marketplace and plugins silently
update_message=""
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
        
        # Update marketplace silently
        claude plugin marketplace update ring &> /dev/null || true
        
        # Get commit hash after update
        after_hash=$(git -C "$marketplace_path" rev-parse HEAD 2>/dev/null || echo "none")
        
        # If hashes differ, marketplace was actually updated
        if [ "$before_hash" != "$after_hash" ] && [ "$after_hash" != "none" ]; then
            # Update all installed plugins
            claude plugin install ring-default &> /dev/null || true
            claude plugin install ring-developers &> /dev/null || true
            claude plugin install ring-product-reporter &> /dev/null || true

            update_message="┌───────────────────────────────────────────────────────────┐\n│  🔄 MARKETPLACE UPDATE - ACTION REQUIRED                  │\n├───────────────────────────────────────────────────────────┤\n│                                                           │\n│  Ring marketplace updated to latest version!              │\n│                                                           │\n│  ⚠ YOU MUST restart your session to load changes:         │\n│    • Type 'clear' in CLI, or                              │\n│    • Restart Claude Code entirely                         │\n│                                                           │\n│  New skills/agents available after restart.               │\n│                                                           │\n└───────────────────────────────────────────────────────────┘"
        fi
    else
        # Marketplace not found, just run updates silently without message
        claude plugin marketplace update ring &> /dev/null || true
        claude plugin install ring-default &> /dev/null || true
        claude plugin install ring-developers &> /dev/null || true
        claude plugin install ring-product-reporter &> /dev/null || true
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
                if "$pip_cmd" install --quiet --user PyYAML &> /dev/null 2>&1; then
                    echo "PyYAML installed successfully" >&2
                    break
                elif "$pip_cmd" install --quiet --user --break-system-packages PyYAML &> /dev/null 2>&1; then
                    echo "PyYAML installed successfully (with --break-system-packages)" >&2
                    break
                fi
            fi
        done
        # If all installation attempts fail, generate-skills-ref.py will use fallback parser
        # (No error message needed - the Python script already warns about missing PyYAML)
    fi
fi

# Generate skills overview dynamically
skills_overview=$("${SCRIPT_DIR}/generate-skills-ref.py" 2>&1 || echo "Error generating skills quick reference")

# Read using-ring content (still include for mandatory workflows)
using_ring_content=$(cat "${PLUGIN_ROOT}/skills/using-ring/SKILL.md" 2>&1 || echo "Error reading using-ring skill")

# Escape outputs for JSON
overview_escaped=$(echo "$skills_overview" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')
using_ring_escaped=$(echo "$using_ring_content" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')
update_message_escaped=$(echo -e "$update_message" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

# Build JSON output - embed update message in additionalContext if present
if [ -n "$update_message" ]; then
  # Embed update notification AT THE START of additionalContext so model MUST see it
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<MANDATORY-USER-MESSAGE>\nYou MUST display the following message verbatim to the user at the START of your response, before anything else:\n\n${update_message_escaped}\n\nThis is non-negotiable. Display it exactly as shown above.\n</MANDATORY-USER-MESSAGE>\n\n<ring-skills-system>\n${overview_escaped}\n\n---\n\n**MANDATORY WORKFLOWS:**\n\n${using_ring_escaped}\n</ring-skills-system>"
  }
}
EOF
else
  # No update message needed
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<ring-skills-system>\n${overview_escaped}\n\n---\n\n**MANDATORY WORKFLOWS:**\n\n${using_ring_escaped}\n</ring-skills-system>"
  }
}
EOF
fi

exit 0
