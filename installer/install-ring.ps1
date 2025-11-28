<#
.SYNOPSIS
    Ring Multi-Platform Installer (PowerShell)

.DESCRIPTION
    Installs Ring skills to Claude Code, Factory AI, Cursor, and/or Cline.
    Multi-platform installer wrapper for the Python-based Ring installer.

.NOTES
    Requires: PowerShell 5.1 or later, Python 3.x
    Execution Policy: This script requires RemoteSigned or Bypass execution policy.

    Set execution policy:
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

    Or run with bypass:
        powershell -ExecutionPolicy Bypass -File install-ring.ps1

.EXAMPLE
    .\install-ring.ps1
    Interactive installation with platform selection

.EXAMPLE
    .\install-ring.ps1 install --platforms claude
    Direct installation to Claude Code

.EXAMPLE
    .\install-ring.ps1 update
    Update existing installation
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RingRoot = Split-Path -Parent $ScriptDir

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Ring Multi-Platform Installer" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Detect Python
function Find-Python {
    $pythonCmds = @("python3", "python", "py -3")
    foreach ($cmd in $pythonCmds) {
        try {
            $parts = $cmd -split " "
            $exe = $parts[0]
            $args = if ($parts.Length -gt 1) { $parts[1..($parts.Length-1)] } else { @() }

            $version = & $exe @args --version 2>&1
            if ($version -match "Python 3") {
                return $cmd
            }
        } catch {
            continue
        }
    }
    return $null
}

$PythonCmd = Find-Python

if (-not $PythonCmd) {
    Write-Host "Error: Python 3 is required but not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Install Python 3:"
    Write-Host "  Windows: https://python.org/downloads/"
    Write-Host "  Or: winget install Python.Python.3.12"
    exit 1
}

$parts = $PythonCmd -split " "
$pythonExe = $parts[0]
$pythonArgs = if ($parts.Length -gt 1) { $parts[1..($parts.Length-1)] } else { @() }

$version = & $pythonExe @pythonArgs --version 2>&1
Write-Host "Found Python: $version" -ForegroundColor Green
Write-Host ""

# Check if running with arguments (non-interactive mode)
if ($args.Count -gt 0) {
    try {
        Set-Location $RingRoot
        & $pythonExe @pythonArgs -m installer.ring_installer @args
        exit $LASTEXITCODE
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
        exit 1
    }
}

# Interactive mode - platform selection
Write-Host "Select platforms to install Ring:"
Write-Host ""
Write-Host "  1) Claude Code     (recommended, native format)" -ForegroundColor Blue
Write-Host "  2) Factory AI      (droids, transformed)" -ForegroundColor Blue
Write-Host "  3) Cursor          (rules/workflows, transformed)" -ForegroundColor Blue
Write-Host "  4) Cline           (prompts, transformed)" -ForegroundColor Blue
Write-Host "  5) All detected platforms" -ForegroundColor Blue
Write-Host "  6) Auto-detect and install" -ForegroundColor Blue
Write-Host ""

$choices = Read-Host "Enter choice(s) separated by comma (e.g., 1,2,3) [default: 6]"

# Default to auto-detect
if ([string]::IsNullOrWhiteSpace($choices)) {
    $choices = "6"
}

# Validate input - only allow digits 1-6, commas, and whitespace
if ($choices -notmatch '^[1-6,\s]*$') {
    Write-Host "Error: Invalid input. Please enter numbers 1-6 separated by commas." -ForegroundColor Red
    exit 1
}

# Parse choices - split by comma and check for exact matches
$platforms = @()
$choiceList = $choices -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

# Check for conflicting options (auto-detect with specific platforms)
$hasAuto = ($choiceList -contains "5") -or ($choiceList -contains "6")
$hasSpecific = ($choiceList -contains "1") -or ($choiceList -contains "2") -or ($choiceList -contains "3") -or ($choiceList -contains "4")
if ($hasAuto -and $hasSpecific) {
    Write-Host "Note: Auto-detect selected - ignoring specific platform selections." -ForegroundColor Yellow
}

if ($choiceList -contains "1") { $platforms += "claude" }
if ($choiceList -contains "2") { $platforms += "factory" }
if ($choiceList -contains "3") { $platforms += "cursor" }
if ($choiceList -contains "4") { $platforms += "cline" }
if ($choiceList -contains "5") { $platforms = @("claude", "factory", "cursor", "cline") }
if ($choiceList -contains "6") { $platforms = @("auto") }

if ($platforms.Count -eq 0) {
    Write-Host "Error: No valid platforms selected." -ForegroundColor Red
    exit 1
}

$platformString = $platforms -join ","

Write-Host ""
Write-Host "Installing to: $platformString" -ForegroundColor Green
Write-Host ""

# Additional options
$verbose = Read-Host "Enable verbose output? (y/N)"
$dryRun = Read-Host "Perform dry-run first? (y/N)"

$extraArgs = @()
if ($verbose -match "^[Yy]$") {
    $extraArgs += "--verbose"
}

# Run dry-run if requested
try {
    if ($dryRun -match "^[Yy]$") {
        Write-Host ""
        Write-Host "=== Dry Run ===" -ForegroundColor Yellow
        Set-Location $RingRoot
        & $pythonExe @pythonArgs -m installer.ring_installer install --platforms $platformString --dry-run @extraArgs

        if ($LASTEXITCODE -ne 0) {
            throw "Dry-run failed with exit code $LASTEXITCODE"
        }

        Write-Host ""
        $proceed = Read-Host "Proceed with actual installation? (Y/n)"
        if ($proceed -match "^[Nn]$") {
            Write-Host "Installation cancelled."
            exit 0
        }
    }

    # Run actual installation
    Write-Host ""
    Write-Host "=== Installing ===" -ForegroundColor Green
    Set-Location $RingRoot
    & $pythonExe @pythonArgs -m installer.ring_installer install --platforms $platformString @extraArgs

    if ($LASTEXITCODE -ne 0) {
        throw "Installation failed with exit code $LASTEXITCODE"
    }

    Write-Host ""
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "Installation Complete!" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Restart your AI tool or start a new session"
    Write-Host "  2. Skills will auto-load (Claude Code) or be available as configured"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  .\installer\install-ring.ps1                    # Interactive install"
    Write-Host "  .\installer\install-ring.ps1 --platforms claude # Direct install"
    Write-Host "  .\installer\install-ring.ps1 update             # Update installation"
    Write-Host "  .\installer\install-ring.ps1 list               # List installed"
    Write-Host ""
} catch {
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Installation failed. Please check the error message above." -ForegroundColor Red
    exit 1
}
