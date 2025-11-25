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
            
            update_message="🔄 **Ring marketplace updated to latest version!**\n⚠️  Please restart your Claude session (type 'clear' or restart CLI) for changes to take effect.\n\n"
        fi
    else
        # Marketplace not found, just run updates silently without message
        claude plugin marketplace update ring &> /dev/null || true
        claude plugin install ring-default &> /dev/null || true
        claude plugin install ring-developers &> /dev/null || true
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

# Output context injection as JSON
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${update_message}<ring-skills-system>\n${overview_escaped}\n\n---\n\n**MANDATORY WORKFLOWS:**\n\n${using_ring_escaped}\n</ring-skills-system>"
  }
}
EOF

exit 0