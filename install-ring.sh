#!/bin/bash
set -e

# Check bash version (Bash 3.2+ required, works on macOS default bash)
if ((BASH_VERSINFO[0] < 3 || (BASH_VERSINFO[0] == 3 && BASH_VERSINFO[1] < 2))); then
    echo "❌ Bash 3.2+ required. Current version: ${BASH_VERSION}"
    exit 1
fi

echo "================================================"
echo "Ring Plugin Marketplace Installer"
echo "================================================"
echo ""

MARKETPLACE_SOURCE="lerianstudio/ring"
MARKETPLACE_NAME="ring"
MARKETPLACE_JSON_URL="https://raw.githubusercontent.com/lerianstudio/ring/main/.claude-plugin/marketplace.json"

echo "📦 Adding Ring marketplace from GitHub..."
set +e
marketplace_output=$(claude plugin marketplace add "$MARKETPLACE_SOURCE" 2>&1)
marketplace_exit_code=$?
set -e

if echo "$marketplace_output" | grep -q "already installed"; then
    echo "ℹ️  Ring marketplace already installed"
    read -p "Would you like to update it? (Y/n): " update_marketplace || update_marketplace=""

    if [[ ! "$update_marketplace" =~ ^[Nn]$ ]]; then
        echo "🔄 Updating Ring marketplace..."
        if claude plugin marketplace update "$MARKETPLACE_NAME"; then
            echo "✅ Ring marketplace updated successfully"
        else
            echo "⚠️  Failed to update marketplace, continuing with existing version..."
        fi
    else
        echo "➡️  Continuing with existing marketplace"
    fi
elif echo "$marketplace_output" | grep -q "Failed"; then
    echo "❌ Failed to add Ring marketplace"
    echo "$marketplace_output"
    exit 1
else
    echo "✅ Ring marketplace added successfully"
fi
echo ""

echo "🔧 Installing/updating ring-default (core plugin - required)..."
if claude plugin install ring-default 2>&1; then
    echo "✅ ring-default ready"
else
    echo "❌ Failed to install ring-default"
    exit 1
fi
echo ""

echo "================================================"
echo "Additional Plugins Available"
echo "================================================"
echo ""
echo "📡 Fetching plugin list from marketplace..."

# Download and parse marketplace.json dynamically
if command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    MARKETPLACE_DATA=$(curl -fsSL --connect-timeout 10 --max-time 30 "$MARKETPLACE_JSON_URL" 2>/dev/null)

    if [ -n "$MARKETPLACE_DATA" ]; then
        # Validate JSON structure
        if ! echo "$MARKETPLACE_DATA" | jq -e '.plugins | type == "array"' >/dev/null 2>&1; then
            echo "⚠️  Invalid marketplace data structure"
            MARKETPLACE_DATA=""
        fi
    fi

    if [ -n "$MARKETPLACE_DATA" ]; then
        # Get list of plugins (excluding ring-default which is already installed)
        PLUGIN_COUNT=$(echo "$MARKETPLACE_DATA" | jq '.plugins | length')

        # Validate PLUGIN_COUNT is numeric
        if ! [[ "$PLUGIN_COUNT" =~ ^[0-9]+$ ]]; then
            echo "⚠️  Could not determine plugin count"
            MARKETPLACE_DATA=""
        fi
    fi

    if [ -n "$MARKETPLACE_DATA" ]; then

        # Track installations (Bash 3.2 compatible - using indexed arrays)
        PLUGIN_NAMES=()
        PLUGIN_STATUSES=()

        # Loop through each plugin
        for ((i=0; i<$PLUGIN_COUNT; i++)); do
            PLUGIN_NAME=$(echo "$MARKETPLACE_DATA" | jq -r ".plugins[$i].name")
            PLUGIN_DESC=$(echo "$MARKETPLACE_DATA" | jq -r ".plugins[$i].description")

            # Validate plugin name format (alphanumeric, underscore, hyphen only)
            if [[ ! "$PLUGIN_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                echo "  ⚠️  Skipping invalid plugin name: $PLUGIN_NAME"
                continue
            fi

            # Skip ring-default (already installed)
            if [ "$PLUGIN_NAME" = "ring-default" ]; then
                continue
            fi

            echo ""
            echo "📦 $PLUGIN_NAME"
            echo "   $PLUGIN_DESC"
            echo ""

            read -p "Would you like to install $PLUGIN_NAME? (y/N): " install_choice || install_choice=""

            if [[ "$install_choice" =~ ^[Yy]$ ]]; then
                echo "🔧 Installing/updating $PLUGIN_NAME..."
                if claude plugin install "$PLUGIN_NAME" 2>&1; then
                    echo "✅ $PLUGIN_NAME ready"
                    PLUGIN_NAMES+=("$PLUGIN_NAME")
                    PLUGIN_STATUSES+=("installed")
                else
                    echo "⚠️  Failed to install $PLUGIN_NAME (might not be published yet)"
                    PLUGIN_NAMES+=("$PLUGIN_NAME")
                    PLUGIN_STATUSES+=("failed")
                fi
            else
                PLUGIN_NAMES+=("$PLUGIN_NAME")
                PLUGIN_STATUSES+=("skipped")
            fi
        done

        echo ""
        echo "================================================"
        echo "✨ Setup Complete!"
        echo "================================================"
        echo ""
        echo "Installed plugins:"
        echo "  ✓ ring-default (core - required)"

        # Show installation status for each plugin (Bash 3.2 compatible)
        for ((j=0; j<${#PLUGIN_NAMES[@]}; j++)); do
            plugin_name="${PLUGIN_NAMES[$j]}"
            status="${PLUGIN_STATUSES[$j]}"
            if [ "$status" = "installed" ]; then
                echo "  ✓ $plugin_name"
            elif [ "$status" = "failed" ]; then
                echo "  ⚠ $plugin_name (installation failed)"
            else
                echo "  ○ $plugin_name (not installed)"
            fi
        done

    else
        echo "⚠️  Could not fetch marketplace data, showing static list..."
        echo ""
        echo "Available plugins (manual installation required):"
        echo "  • ring-developers - Developer role agents"
        echo "  • ring-product-reporter - FinOps & regulatory compliance"
        echo "  • ring-team-product - Product planning workflows"
        echo ""
        echo "To install manually: claude plugin install <plugin-name>"
    fi
else
    echo "⚠️  curl or jq not found, showing static list..."
    echo ""
    echo "Available plugins (manual installation required):"
    echo "  • ring-developers - Developer role agents"
    echo "  • ring-product-reporter - FinOps & regulatory compliance"
    echo "  • ring-team-product - Product planning workflows"
    echo ""
    echo "To install manually: claude plugin install <plugin-name>"
fi

echo ""
echo "Next steps:"
echo "  1. Restart Claude Code or start a new session"
echo "  2. Skills will auto-load via SessionStart hook"
echo "  3. Try: /ring:brainstorm or Skill tool: 'ring:using-ring'"
echo ""
echo "Marketplace commands:"
echo "  claude plugin marketplace list    # View configured marketplaces"
echo "  claude plugin install <name>      # Install more plugins"
echo "  claude plugin enable <name>       # Enable a plugin"
echo "  claude plugin disable <name>      # Disable a plugin"
echo ""
