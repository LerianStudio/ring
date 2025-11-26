# Ring Plugin Marketplace Installer (PowerShell)
$ErrorActionPreference = "Stop"

# Check PowerShell version (3.0+ recommended for Invoke-RestMethod)
if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Host "⚠️  PowerShell 3.0+ recommended. Current version: $($PSVersionTable.PSVersion)"
    Write-Host "Some features may not work correctly."
    Write-Host ""
}

Write-Host "================================================"
Write-Host "Ring Plugin Marketplace Installer"
Write-Host "================================================"
Write-Host ""

$MARKETPLACE_SOURCE = "lerianstudio/ring"
$MARKETPLACE_NAME = "ring"
$MARKETPLACE_JSON_URL = "https://raw.githubusercontent.com/lerianstudio/ring/main/.claude-plugin/marketplace.json"

# Ensure TLS 1.2+ is used for secure connections
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "📦 Adding Ring marketplace from GitHub..."
try {
    $marketplaceOutput = & claude plugin marketplace add $MARKETPLACE_SOURCE 2>&1 | Out-String
    $marketplaceExitCode = $LASTEXITCODE
} catch {
    $marketplaceOutput = $_.Exception.Message
    $marketplaceExitCode = 1
}

if ($marketplaceOutput -match "already installed") {
    Write-Host "ℹ️  Ring marketplace already installed"
    $updateMarketplace = Read-Host "Would you like to update it? (Y/n)"

    if ($updateMarketplace -notmatch "^[Nn]$") {
        Write-Host "🔄 Updating Ring marketplace..."
        try {
            & claude plugin marketplace update $MARKETPLACE_NAME | Out-Null
            Write-Host "✅ Ring marketplace updated successfully"
        } catch {
            Write-Host "⚠️  Failed to update marketplace, continuing with existing version..."
        }
    } else {
        Write-Host "➡️  Continuing with existing marketplace"
    }
} elseif ($marketplaceOutput -match "Failed") {
    Write-Host "❌ Failed to add Ring marketplace"
    Write-Host $marketplaceOutput
    exit 1
} else {
    Write-Host "✅ Ring marketplace added successfully"
}
Write-Host ""

Write-Host "🔧 Installing/updating ring-default (core plugin - required)..."
try {
    & claude plugin install ring-default 2>&1 | Out-Null
    Write-Host "✅ ring-default ready"
} catch {
    Write-Host "❌ Failed to install ring-default"
    exit 1
}
Write-Host ""

Write-Host "================================================"
Write-Host "Additional Plugins Available"
Write-Host "================================================"
Write-Host ""
Write-Host "📡 Fetching plugin list from marketplace..."

# Download and parse marketplace.json dynamically
try {
    $marketplaceData = Invoke-RestMethod -Uri $MARKETPLACE_JSON_URL -TimeoutSec 30 -ErrorAction Stop

    # Validate JSON structure
    if (-not ($marketplaceData.PSObject.Properties.Name -contains 'plugins') -or
        $marketplaceData.plugins -isnot [System.Array]) {
        Write-Host "⚠️  Invalid marketplace data structure"
        throw "Invalid structure"
    }

    if ($marketplaceData -and $marketplaceData.plugins) {
        # Track installations
        $installedPlugins = @{}

        # Loop through each plugin
        foreach ($plugin in $marketplaceData.plugins) {
            $pluginName = $plugin.name
            $pluginDesc = $plugin.description

            # Validate plugin name format (alphanumeric, underscore, hyphen only)
            if ($pluginName -notmatch '^[a-zA-Z0-9_-]+$') {
                Write-Host "  ⚠️  Skipping invalid plugin name: $pluginName"
                continue
            }

            # Skip ring-default (already installed)
            if ($pluginName -eq "ring-default") {
                continue
            }

            # Sanitize description for display (remove potential control characters)
            $pluginDesc = $pluginDesc -replace '[^\x20-\x7E]', ''

            Write-Host ""
            Write-Host "📦 $pluginName"
            Write-Host "   $pluginDesc"
            Write-Host ""

            $installChoice = Read-Host "Would you like to install $pluginName? (y/N)"

            if ($installChoice -match "^[Yy]$") {
                Write-Host "🔧 Installing/updating $pluginName..."
                try {
                    & claude plugin install $pluginName 2>&1 | Out-Null
                    Write-Host "✅ $pluginName ready"
                    $installedPlugins[$pluginName] = "installed"
                } catch {
                    Write-Host "⚠️  Failed to install $pluginName (might not be published yet)"
                    $installedPlugins[$pluginName] = "failed"
                }
            } else {
                $installedPlugins[$pluginName] = "skipped"
            }
        }

        Write-Host ""
        Write-Host "================================================"
        Write-Host "✨ Setup Complete!"
        Write-Host "================================================"
        Write-Host ""
        Write-Host "Installed plugins:"
        Write-Host "  ✓ ring-default (core - required)"

        # Show installation status for each plugin
        foreach ($pluginName in $installedPlugins.Keys) {
            $status = $installedPlugins[$pluginName]
            if ($status -eq "installed") {
                Write-Host "  ✓ $pluginName"
            } elseif ($status -eq "failed") {
                Write-Host "  ⚠ $pluginName (installation failed)"
            } else {
                Write-Host "  ○ $pluginName (not installed)"
            }
        }
    } else {
        Write-Host "⚠️  Could not parse marketplace data, showing static list..."
        Write-Host ""
        Write-Host "Available plugins (manual installation required):"
        Write-Host "  • ring-developers - Developer role agents"
        Write-Host "  • ring-product-reporter - FinOps & regulatory compliance"
        Write-Host "  • ring-team-product - Product planning workflows"
        Write-Host ""
        Write-Host "To install manually: claude plugin install <plugin-name>"
    }
} catch {
    Write-Host "⚠️  Could not fetch marketplace data, showing static list..."
    Write-Host ""
    Write-Host "Available plugins (manual installation required):"
    Write-Host "  • ring-developers - Developer role agents"
    Write-Host "  • ring-product-reporter - FinOps & regulatory compliance"
    Write-Host "  • ring-team-product - Product planning workflows"
    Write-Host ""
    Write-Host "To install manually: claude plugin install <plugin-name>"
}

Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Restart Claude Code or start a new session"
Write-Host "  2. Skills will auto-load via SessionStart hook"
Write-Host "  3. Try: /ring:brainstorm or Skill tool: 'ring:using-ring'"
Write-Host ""
Write-Host "Marketplace commands:"
Write-Host "  claude plugin marketplace list    # View configured marketplaces"
Write-Host "  claude plugin install <name>      # Install more plugins"
Write-Host "  claude plugin enable <name>       # Enable a plugin"
Write-Host "  claude plugin disable <name>      # Disable a plugin"
Write-Host ""
