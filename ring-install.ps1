# ==============================================================================
# Ring - Unified Symlinks Installer (Windows / PowerShell)
# ==============================================================================
# Installs Ring agents/skills/commands/hooks into one or more AI coding tools:
#
#   - Claude Code   -> %USERPROFILE%\.claude\{agents,commands,skills,hooks}  (per-file)
#   - Factory AI    -> %USERPROFILE%\.factory\{agents,commands,skills,hooks} (per-file)
#   - Opencode      -> %USERPROFILE%\.config\opencode\{agent,command,skill}  (top-level)
#   - Codex         -> %USERPROFILE%\.codex\skills                           (top-level)
#
# Usage:
#   .\ring-install.ps1                              # interactive menu
#   .\ring-install.ps1 -Claude                      # Claude Code only
#   .\ring-install.ps1 -Opencode                    # Opencode (auto-builds)
#   .\ring-install.ps1 -All                         # all four tools
#   .\ring-install.ps1 remove                       # remove all symlinks
#   .\ring-install.ps1 doctor                       # verify install
#   .\ring-install.ps1 build                        # rebuild opencode/codex
#   .\ring-install.ps1 all -All                     # clean + build + install
#   .\ring-install.ps1 install C:\path\to\ring      # explicit repo path
#
# Requirements:
#   - PowerShell 5.1+ or PowerShell 7+
#   - Developer Mode enabled OR elevated (Administrator) for symlinks
#   - python (Codex frontmatter transform; only needed for opencode/codex)
#   - (hooks.json merge is done natively in PowerShell — no jq needed)
# ==============================================================================

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("install", "remove", "uninstall", "build", "clean", "doctor", "all")]
    [string]$Subcommand = "install",

    [Parameter(Position = 1)]
    [string]$RepoPath,

    [switch]$Claude,
    [switch]$Factory,
    [switch]$Opencode,
    [switch]$Codex,
    [switch]$All,
    [switch]$DryRun,
    [switch]$Force,
    [switch]$Yes,
    [switch]$Help
)

# ==============================================================================
# Script-scoped variables
# ==============================================================================

# Paths (set by Resolve-RingDir)
$script:RingDir = ""
$script:BuildDir = ""
$script:OpencodeOut = ""
$script:CodexOut = ""
$script:PyHelper = ""
$script:LookupJson = ""

# Target directories
$script:ClaudeDir = "$env:USERPROFILE\.claude"
$script:FactoryDir = "$env:USERPROFILE\.factory"
$script:OpencodeDir = "$env:USERPROFILE\.config\opencode"
$script:CodexDir = "$env:USERPROFILE\.codex"

# Plugin teams
$script:Teams = @("default", "dev-team", "pm-team", "tw-team")

# Target selection
$script:InstallClaude = $false
$script:InstallFactory = $false
$script:InstallOpencode = $false
$script:InstallCodex = $false

# Behavior flags
$script:DryRunMode = $false
$script:VerboseMode = $false
$script:ForceMode = $false
$script:AssumeYes = $false

# Counters
$script:Created = 0
$script:Skipped = 0
$script:Updated = 0
$script:Errors = 0
$script:Removed = 0
$script:Pruned = 0

# ==============================================================================
# Logging helpers
# ==============================================================================

function Write-Info {
    param([string]$Message)
    Write-Host "  " -NoNewline
    Write-Host "INFO" -ForegroundColor Blue -NoNewline
    Write-Host "    $Message"
}

function Write-Ok {
    param([string]$Message)
    Write-Host "  " -NoNewline
    Write-Host "OK" -ForegroundColor Green -NoNewline
    Write-Host "      $Message"
}

function Write-Skip {
    param([string]$Message)
    Write-Host "  " -NoNewline
    Write-Host "SKIP" -ForegroundColor Yellow -NoNewline
    Write-Host "    $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "  " -NoNewline
    Write-Host "WARN" -ForegroundColor Yellow -NoNewline
    Write-Host "    $Message"
}

function Write-Err {
    param([string]$Message)
    Write-Host "  " -NoNewline
    Write-Host "ERROR" -ForegroundColor Red -NoNewline
    Write-Host "   $Message"
}

function Write-Section {
    param([string]$Message)
    Write-Host ""
    Write-Host "  -- $Message --" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Dim {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor DarkGray
}

function Write-VerboseLog {
    param([string]$Message)
    if ($script:VerboseMode) {
        Write-Host "  . $Message" -ForegroundColor DarkGray
    }
}

# ==============================================================================
# Banner and usage
# ==============================================================================

function Show-Banner {
    Write-Host ""
    Write-Host "  +====================================================+" -ForegroundColor Cyan
    Write-Host "  |        Ring - Unified Symlinks Installer            |" -ForegroundColor Cyan
    Write-Host "  +====================================================+" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Usage {
    Write-Host @"

  Ring Installer -- symlink Ring into Claude Code, Factory AI, Opencode, or Codex.

  USAGE:
    .\ring-install.ps1 [SUBCOMMAND] [TARGETS] [FLAGS] [-RepoPath <path>]

  SUBCOMMANDS (default: install):
    install         Install symlinks for selected targets
    remove          Remove all Ring symlinks (alias: uninstall)
    build           Generate .ring-build\{opencode,codex} outputs
    clean           Remove .ring-build\ outputs
    doctor          Verify install symlinks and build outputs
    all             clean + build + install

  TARGET FLAGS (omit to be prompted interactively):
    -Claude         Claude Code        (~\.claude\)
    -Factory        Factory AI         (~\.factory\)
    -Opencode       Opencode           (~\.config\opencode\)
    -Codex          Codex              (~\.codex\)
    -All            All of the above

  BEHAVIOR FLAGS:
    -DryRun         Print intended actions; change nothing
    -Force          Replace non-symlink collisions (timestamped backup)
    -Yes            Skip confirmation in interactive mode
    -Help           Show this message

  EXAMPLES:
    .\ring-install.ps1                        # interactive menu
    .\ring-install.ps1 -Claude                # Claude Code only (no prompt)
    .\ring-install.ps1 -Opencode              # Opencode (auto-builds first)
    .\ring-install.ps1 -All                   # all four tools
    .\ring-install.ps1 remove                 # remove all Ring symlinks
    .\ring-install.ps1 doctor                 # verify install
    .\ring-install.ps1 all -All -Yes          # clean + build + install all

  EXIT CODES:
    0  success
    1  usage error
    2  missing required tool (python / robocopy)
    3  invalid Ring repo (missing CLAUDE.md or default\agents\)
    4  install collision (non-symlink target; re-run with -Force)
    5  build produced zero output

"@
}

# ==============================================================================
# Symlink capability detection
# ==============================================================================

function Test-SymlinkCapability {
    # Check Developer Mode
    $devMode = $false
    try {
        $regValue = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" `
            -Name "AllowDevelopmentWithoutDevLicense" -ErrorAction SilentlyContinue
        if ($null -ne $regValue -and $regValue.AllowDevelopmentWithoutDevLicense -eq 1) {
            $devMode = $true
        }
    }
    catch {
        # Registry key not found; Developer Mode is off
    }

    # Check if running elevated
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    if (-not $devMode -and -not $isAdmin) {
        Write-Err "Cannot create symlinks. You need one of:"
        Write-Err "  1. Enable Developer Mode: Settings > Privacy & Security > For Developers > Developer Mode"
        Write-Err "  2. Run this script as Administrator (elevated PowerShell)"
        exit 1
    }
}

# ==============================================================================
# Repo detection and target directory resolution
# ==============================================================================

function Resolve-RingDir {
    if ($RepoPath) {
        $resolved = Resolve-Path -Path $RepoPath -ErrorAction SilentlyContinue
        if (-not $resolved) {
            Write-Err "Path not found: $RepoPath"
            exit 1
        }
        $script:RingDir = $resolved.Path
    }
    else {
        $script:RingDir = $PSScriptRoot
    }

    $claudeMd = Join-Path $script:RingDir "CLAUDE.md"
    $defaultAgents = Join-Path $script:RingDir "default\agents"

    if (-not (Test-Path $claudeMd) -or -not (Test-Path $defaultAgents)) {
        Write-Err "Not a Ring repo: $($script:RingDir)"
        Write-Err "Missing CLAUDE.md or default\agents\. Provide the correct path."
        exit 3
    }

    $script:BuildDir = Join-Path $script:RingDir ".ring-build"
    $script:OpencodeOut = Join-Path $script:BuildDir "opencode"
    $script:CodexOut = Join-Path $script:BuildDir "codex\skills"
    $script:PyHelper = Join-Path $script:RingDir "scripts\_codex_frontmatter.py"
    $script:LookupJson = Join-Path $script:BuildDir ".codex-lookup.json"
}

function Test-RequiredCommand {
    param(
        [string]$Name,
        [string]$Reason
    )
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Err "$Name is required for $Reason but was not found in PATH"
        switch ($Name) {
            "python" {
                Write-Err "install: winget install Python.Python.3  |  https://www.python.org/downloads/"
            }
        }
        exit 2
    }
}

# ==============================================================================
# Dry-run-aware mutators
# ==============================================================================

function New-DirectoryIfNeeded {
    param([string]$Path)
    if ($script:DryRunMode) {
        Write-VerboseLog "[dry-run] mkdir $Path"
    }
    else {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Remove-SafeItem {
    param([string]$Path)
    if ($script:DryRunMode) {
        Write-VerboseLog "[dry-run] remove $Path"
    }
    else {
        Remove-Item -Path $Path -Force -Recurse -ErrorAction SilentlyContinue
    }
}

function Move-SafeItem {
    param(
        [string]$Source,
        [string]$Destination
    )
    if ($script:DryRunMode) {
        Write-VerboseLog "[dry-run] move $Source -> $Destination"
    }
    else {
        Move-Item -Path $Source -Destination $Destination
    }
}

function Copy-FileForce {
    param(
        [string]$Source,
        [string]$Destination
    )
    if ($script:DryRunMode) {
        Write-VerboseLog "[dry-run] copy $Source -> $Destination"
    }
    else {
        $parentDir = Split-Path -Parent $Destination
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        Copy-Item -Path $Source -Destination $Destination -Force
    }
}

function Copy-MirrorDirectory {
    param(
        [string]$Source,
        [string]$Destination
    )
    if ($script:DryRunMode) {
        Write-VerboseLog "[dry-run] robocopy /MIR $Source -> $Destination"
    }
    else {
        if (-not (Test-Path $Destination)) {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        }
        # robocopy /MIR mirrors source to destination (replaces rsync -a --delete)
        # Exit codes 0-7 are success for robocopy
        $null = robocopy $Source $Destination /MIR /NJH /NJS /NP /NFL /NDL 2>&1
        if ($LASTEXITCODE -gt 7) {
            Write-Err "robocopy failed with exit code ${LASTEXITCODE}: $Source -> $Destination"
            $script:Errors++
        }
    }
}

function New-Symlink {
    param(
        [string]$Target,
        [string]$LinkPath
    )
    if ($script:DryRunMode) {
        Write-VerboseLog "[dry-run] symlink $LinkPath -> $Target"
    }
    else {
        # Remove existing item at link path if present
        if (Test-Path $LinkPath) {
            Remove-Item -Path $LinkPath -Force -Recurse -ErrorAction SilentlyContinue
        }
        New-Item -ItemType SymbolicLink -Path $LinkPath -Target $Target -Force | Out-Null
    }
}

# ==============================================================================
# Per-file symlink install helpers
# ==============================================================================

function Install-Symlink {
    param(
        [string]$Source,
        [string]$Target
    )
    $name = Split-Path -Leaf $Target

    # Check if target is a symlink
    $item = Get-Item $Target -Force -ErrorAction SilentlyContinue
    if ($null -ne $item -and $item.LinkType -eq "SymbolicLink") {
        # Read existing symlink target (returns array on PS5.1)
        $existingTarget = $item.Target
        if ($existingTarget -is [array]) {
            $existingTarget = $existingTarget[0]
        }
        if ($existingTarget -eq $Source) {
            $script:Skipped++
            return
        }
        # Points elsewhere — update it
        Remove-SafeItem $Target
        New-Symlink -Target $Source -LinkPath $Target
        Write-Ok "$name (updated)"
        $script:Updated++
        return
    }

    # Check if target exists as regular file/dir
    if (Test-Path $Target) {
        if ($script:ForceMode) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $backup = "${Target}.backup_${timestamp}"
            Move-SafeItem -Source $Target -Destination $backup
            New-Symlink -Target $Source -LinkPath $Target
            Write-Ok "$name (backed up + replaced)"
            $script:Created++
            return
        }
        Write-Err "$name already exists as a regular file (use -Force to back up). Skipping."
        $script:Errors++
        return
    }

    # Nothing exists — create new symlink
    New-Symlink -Target $Source -LinkPath $Target
    $script:Created++
}

function Install-PerFileAgents {
    param(
        [string]$Plugin,
        [string]$TargetDir
    )
    $agentsDir = Join-Path $script:RingDir "$Plugin\agents"
    if (-not (Test-Path $agentsDir)) { return }
    foreach ($agent in Get-ChildItem -Path $agentsDir -Filter "*.md" -File -ErrorAction SilentlyContinue) {
        $targetPath = Join-Path $TargetDir "agents\$($agent.Name)"
        Install-Symlink -Source $agent.FullName -Target $targetPath
    }
}

function Install-PerFileCommands {
    param(
        [string]$Plugin,
        [string]$TargetDir
    )
    $commandsDir = Join-Path $script:RingDir "$Plugin\commands"
    if (-not (Test-Path $commandsDir)) { return }
    foreach ($cmd in Get-ChildItem -Path $commandsDir -Filter "*.md" -File -ErrorAction SilentlyContinue) {
        $targetPath = Join-Path $TargetDir "commands\$($cmd.Name)"
        Install-Symlink -Source $cmd.FullName -Target $targetPath
    }
}

function Install-PerFileSkills {
    param(
        [string]$Plugin,
        [string]$TargetDir
    )
    $skillsDir = Join-Path $script:RingDir "$Plugin\skills"
    if (-not (Test-Path $skillsDir)) { return }
    foreach ($skill in Get-ChildItem -Path $skillsDir -Directory -ErrorAction SilentlyContinue) {
        if ($skill.Name -eq "shared-patterns") { continue }
        $targetPath = Join-Path $TargetDir "skills\$($skill.Name)"
        Install-Symlink -Source $skill.FullName -Target $targetPath
    }
}

function Install-PerFileHooks {
    param(
        [string]$Plugin,
        [string]$TargetDir
    )
    $hooksDir = Join-Path $script:RingDir "$Plugin\hooks"
    if (-not (Test-Path $hooksDir)) { return }

    # 1) Symlink .sh hook scripts
    foreach ($hookScript in Get-ChildItem -Path $hooksDir -Filter "*.sh" -File -ErrorAction SilentlyContinue) {
        $targetPath = Join-Path $TargetDir "hooks\$($hookScript.Name)"
        Install-Symlink -Source $hookScript.FullName -Target $targetPath
    }

    # 2) Merge hooks.json into settings.json
    $hooksJson = Join-Path $hooksDir "hooks.json"
    if (-not (Test-Path $hooksJson)) { return }

    if ($script:DryRunMode) {
        Write-VerboseLog "[dry-run] merge $hooksJson into $TargetDir\settings.json"
        return
    }

    $settingsFile = Join-Path $TargetDir "settings.json"
    # Build the hooks target path with forward slashes for Claude Code
    $hooksTargetPath = (Join-Path $TargetDir "hooks") -replace '\\', '/'
    if (-not $hooksTargetPath.EndsWith('/')) { $hooksTargetPath += '/' }

    # Read and rewrite hooks.json: replace placeholder with actual path
    $rawContent = Get-Content $hooksJson -Raw
    $rewritten = $rawContent -replace '\$\{CLAUDE_PLUGIN_ROOT\}/hooks/', $hooksTargetPath

    try {
        $newHooks = $rewritten | ConvertFrom-Json
    }
    catch {
        Write-Err "Invalid hooks.json in $Plugin - skipping"
        $script:Errors++
        return
    }

    if (-not (Test-Path $settingsFile)) {
        # No existing settings.json — write the hooks JSON directly
        $newHooks | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsFile -Encoding UTF8
        Write-Ok "Created settings.json with hooks from $Plugin"
        return
    }

    # Merge into existing settings.json
    try {
        $existing = Get-Content $settingsFile -Raw | ConvertFrom-Json
    }
    catch {
        Write-Err "Invalid existing settings.json - cannot merge hooks from $Plugin"
        $script:Errors++
        return
    }

    # Ensure both have hooks objects
    if (-not $existing.PSObject.Properties['hooks']) {
        $existing | Add-Member -NotePropertyName 'hooks' -NotePropertyValue ([PSCustomObject]@{})
    }
    if (-not $newHooks.PSObject.Properties['hooks']) {
        return
    }

    # For each event key in new hooks, merge into existing
    foreach ($eventProp in $newHooks.hooks.PSObject.Properties) {
        $eventName = $eventProp.Name
        $newEntries = @($eventProp.Value)

        if ($existing.hooks.PSObject.Properties[$eventName]) {
            $existingEntries = @($existing.hooks.$eventName)
            # Deduplicate by comparing only matcher + hooks fields (matches bash unique_by)
            $existingSerialized = $existingEntries | ForEach-Object {
                $dedupeKey = [PSCustomObject]@{
                    matcher = $_.matcher
                    hooks = $_.hooks
                }
                $dedupeKey | ConvertTo-Json -Depth 10 -Compress
            }
            foreach ($entry in $newEntries) {
                $dedupeKey = [PSCustomObject]@{
                    matcher = $entry.matcher
                    hooks = $entry.hooks
                }
                $entrySerialized = $dedupeKey | ConvertTo-Json -Depth 10 -Compress
                if ($existingSerialized -notcontains $entrySerialized) {
                    $existingEntries += $entry
                }
            }
            $existing.hooks.$eventName = $existingEntries
        }
        else {
            $existing.hooks | Add-Member -NotePropertyName $eventName -NotePropertyValue $newEntries
        }
    }

    $existing | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsFile -Encoding UTF8
    Write-Ok "Merged hooks from $Plugin into settings.json"
}

function Prune-PerFileStale {
    param([string]$TargetDir)
    foreach ($sub in @("agents", "commands", "skills", "hooks")) {
        $subDir = Join-Path $TargetDir $sub
        if (-not (Test-Path $subDir)) { continue }
        foreach ($item in Get-ChildItem -Path $subDir -Force -ErrorAction SilentlyContinue) {
            if ($item.LinkType -ne "SymbolicLink") { continue }
            $linkTarget = $item.Target
            if ($linkTarget -is [array]) { $linkTarget = $linkTarget[0] }
            # Only prune symlinks that point into our Ring directory
            $ringDirNormalized = ($script:RingDir -replace '\\', '/').TrimEnd('/') + '/'
            $linkTargetNormalized = $linkTarget -replace '\\', '/'
            if (-not $linkTargetNormalized.StartsWith($ringDirNormalized)) { continue }
            # Check if the target still exists (dangling symlink)
            if (Test-Path $linkTarget) { continue }
            Remove-SafeItem $item.FullName
            Write-Ok "Pruned stale: $sub/$($item.Name)"
            $script:Pruned++
        }
    }
}

function Install-PerFile {
    param(
        [string]$TargetDir,
        [string]$Label
    )
    Write-Section "$Label  ($TargetDir)"

    # Create subdirectories
    foreach ($sub in @("agents", "commands", "skills", "hooks")) {
        $subDir = Join-Path $TargetDir $sub
        New-DirectoryIfNeeded $subDir
    }

    # Prune stale symlinks
    Prune-PerFileStale $TargetDir

    # Install per-file symlinks for each team/plugin
    foreach ($plugin in $script:Teams) {
        $pluginDir = Join-Path $script:RingDir $plugin
        if (-not (Test-Path $pluginDir)) { continue }
        Install-PerFileAgents   -Plugin $plugin -TargetDir $TargetDir
        Install-PerFileCommands -Plugin $plugin -TargetDir $TargetDir
        Install-PerFileSkills   -Plugin $plugin -TargetDir $TargetDir
        Install-PerFileHooks    -Plugin $plugin -TargetDir $TargetDir
    }
}

function Show-Summary {
    Write-Host ""
    Write-Host "  ========================================" -ForegroundColor White
    Write-Host "  " -NoNewline
    Write-Host "Created:" -ForegroundColor Green -NoNewline
    Write-Host "  $($script:Created) symlinks"
    if ($script:Updated -gt 0) {
        Write-Host "  " -NoNewline
        Write-Host "Updated:" -ForegroundColor Blue -NoNewline
        Write-Host "  $($script:Updated) (pointed elsewhere)"
    }
    if ($script:Pruned -gt 0) {
        Write-Host "  " -NoNewline
        Write-Host "Pruned:" -ForegroundColor Magenta -NoNewline
        Write-Host "   $($script:Pruned) (stale Ring links)"
    }
    Write-Host "  " -NoNewline
    Write-Host "Skipped:" -ForegroundColor Yellow -NoNewline
    Write-Host "  $($script:Skipped) (already correct)"
    if ($script:Errors -gt 0) {
        Write-Host "  " -NoNewline
        Write-Host "Errors:" -ForegroundColor Red -NoNewline
        Write-Host "   $($script:Errors)"
    }
    Write-Host "  ========================================" -ForegroundColor White
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host "Ring repo:" -ForegroundColor Cyan -NoNewline
    Write-Host "   $($script:RingDir)"
    Write-Host "  " -NoNewline
    Write-Host "Targets:" -ForegroundColor Cyan -NoNewline
    Write-Host "     $(Get-SelectedTargetsSummary)"
    Write-Host ""

    $total = $script:Created + $script:Updated + $script:Skipped
    if ($total -gt 0 -and $script:Errors -eq 0) {
        Write-Host "  " -NoNewline
        Write-Host "Ring is ready!" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Try these commands:"
        Write-Host "    " -NoNewline
        Write-Host "/ring:running-dev-cycle" -ForegroundColor White -NoNewline
        Write-Host "       - 10-gate development cycle"
        Write-Host "    " -NoNewline
        Write-Host "/ring:planning-small-features" -ForegroundColor White -NoNewline
        Write-Host " - lightweight pre-dev workflow"
        Write-Host "    " -NoNewline
        Write-Host "/ring:reviewing-code" -ForegroundColor White -NoNewline
        Write-Host "          - parallel code review (9 defaults + conditionals)"
        Write-Host "    " -NoNewline
        Write-Host "/ring:committing-changes" -ForegroundColor White -NoNewline
        Write-Host "      - smart atomic commits"
        Write-Host ""
    }
}

function Confirm-Interactive {
    if ($script:AssumeYes) { return }
    Write-Host ""
    Write-Host "  Proceed? " -NoNewline
    Write-Host "[Y/n] " -ForegroundColor White -NoNewline
    $ans = Read-Host
    Write-Host ""
    if ($ans -in @("n", "N", "no", "NO")) {
        Write-Info "Cancelled."
        exit 0
    }
}

# ==============================================================================
# Build helpers -- Opencode
# ==============================================================================

function Build-OpencodeAgents {
    param([string]$Team)
    $srcDir = Join-Path $script:RingDir "$Team\agents"
    if (-not (Test-Path $srcDir)) { return }
    $dstDir = Join-Path $script:OpencodeOut "agent\$Team"
    foreach ($f in Get-ChildItem -Path $srcDir -Filter "*.md" -File -ErrorAction SilentlyContinue) {
        $dst = Join-Path $dstDir $f.Name
        Copy-FileForce -Source $f.FullName -Destination $dst
        Write-VerboseLog "opencode agent: $Team/$($f.Name)"
    }
}

function Build-OpencodeSkills {
    param([string]$Team)
    $srcDir = Join-Path $script:RingDir "$Team\skills"
    if (-not (Test-Path $srcDir)) { return }
    foreach ($d in Get-ChildItem -Path $srcDir -Directory -ErrorAction SilentlyContinue) {
        if ($d.Name -eq "shared-patterns") {
            Build-SharedPatternsOpencode -Team $Team -SourceDir $d.FullName
            continue
        }
        $dst = Join-Path $script:OpencodeOut "skill\$Team\$($d.Name)"
        Copy-MirrorDirectory -Source $d.FullName -Destination $dst
        Write-VerboseLog "opencode skill: $Team/$($d.Name)"
    }
}

function Build-SharedPatternsOpencode {
    param(
        [string]$Team,
        [string]$SourceDir
    )
    $mdFiles = Get-ChildItem -Path $SourceDir -Filter "*.md" -File -ErrorAction SilentlyContinue
    if (-not $mdFiles -or @($mdFiles).Count -eq 0) {
        Write-VerboseLog "opencode shared-patterns empty: $Team (skip)"
        return
    }
    $dst = Join-Path $script:OpencodeOut "skill\$Team\shared-patterns"
    Copy-MirrorDirectory -Source $SourceDir -Destination $dst
    Write-VerboseLog "opencode shared-patterns: $Team"
}

function Build-OpencodeCommands {
    param([string]$Team)
    $srcDir = Join-Path $script:RingDir "$Team\commands"
    if (-not (Test-Path $srcDir)) { return }
    $dstDir = Join-Path $script:OpencodeOut "command\$Team"
    foreach ($f in Get-ChildItem -Path $srcDir -Filter "*.md" -File -ErrorAction SilentlyContinue) {
        $dst = Join-Path $dstDir $f.Name
        Copy-FileForce -Source $f.FullName -Destination $dst
        Write-VerboseLog "opencode command: $Team/$($f.Name)"
    }
}

function Build-OpencodeSkillCommands {
    param([string]$Team)
    $srcDir = Join-Path $script:RingDir "$Team\skills"
    if (-not (Test-Path $srcDir)) { return }
    $dstDir = Join-Path $script:OpencodeOut "command\$Team"
    foreach ($skillDir in Get-ChildItem -Path $srcDir -Directory -ErrorAction SilentlyContinue) {
        if ($skillDir.Name -eq "shared-patterns") { continue }
        $srcMd = Join-Path $skillDir.FullName "SKILL.md"
        if (-not (Test-Path $srcMd)) { continue }
        $dstMd = Join-Path $dstDir "$($skillDir.Name).md"
        # Real command at destination always wins — shims never overwrite
        if (Test-Path $dstMd) {
            Write-VerboseLog "opencode skill-cmd: $Team/$($skillDir.Name) (real command exists, skip shim)"
            continue
        }
        if ($script:DryRunMode) {
            Write-VerboseLog "[dry-run] opencode skill-cmd shim: $Team/$($skillDir.Name) -> $dstMd"
            continue
        }
        New-DirectoryIfNeeded $dstDir
        & python $script:PyHelper --emit-opencode-skill-shim --source $srcMd --dest $dstMd
        if ($LASTEXITCODE -ne 0) {
            Write-Err "python transform failed with exit code $LASTEXITCODE"
            $script:Errors++
            continue
        }
        Write-VerboseLog "opencode skill-cmd: $Team/$($skillDir.Name)"
    }
}

function Build-DocsMirrorOpencode {
    $src = Join-Path $script:RingDir "dev-team\docs"
    if (-not (Test-Path $src)) { return }
    $dst = Join-Path $script:OpencodeOut "skill\docs"
    Copy-MirrorDirectory -Source $src -Destination $dst
    Write-VerboseLog "opencode docs mirror"
}

function Build-CrossPluginMirrorOpencode {
    $src = Join-Path $script:RingDir "dev-team\skills\shared-patterns"
    if (-not (Test-Path $src)) { return }
    $dst = Join-Path $script:OpencodeOut "dev-team\skills\shared-patterns"
    Copy-MirrorDirectory -Source $src -Destination $dst
    Write-VerboseLog "opencode top-level cross-plugin mirror"
}

# ==============================================================================
# Build helpers -- Codex
# ==============================================================================

function Build-CodexSkill {
    param(
        [string]$Team,
        [string]$SkillDir
    )
    $name = Split-Path -Leaf $SkillDir
    if ($name -eq "shared-patterns") { return }
    $dstDir = Join-Path $script:CodexOut "$Team\ring-${Team}-${name}"
    $srcSkillMd = Join-Path $SkillDir "SKILL.md"

    if (-not (Test-Path $srcSkillMd)) {
        Write-Warn "skipping (no SKILL.md): $SkillDir"
        return
    }

    if ($script:DryRunMode) {
        Write-VerboseLog "[dry-run] codex skill: $Team/$name -> ring-${Team}-${name}"
        return
    }

    New-DirectoryIfNeeded $dstDir
    # Mirror skill dir excluding SKILL.md, then run python transform
    # robocopy /MIR would delete SKILL.md we're about to create, so use /XF to exclude source SKILL.md
    if (-not (Test-Path $dstDir)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }
    $null = robocopy $SkillDir $dstDir /MIR /XF "SKILL.md" /NJH /NJS /NP /NFL /NDL 2>&1

    $dstSkillMd = Join-Path $dstDir "SKILL.md"
    & python $script:PyHelper --source $srcSkillMd --dest $dstSkillMd --team $Team --skill-name $name --lookup $script:LookupJson
    if ($LASTEXITCODE -ne 0) {
        Write-Err "python transform failed with exit code $LASTEXITCODE"
        $script:Errors++
        return
    }

    Invoke-RewriteAccessoryPaths -Dir $dstDir -Team $Team
    Write-VerboseLog "codex skill: $Team/$name -> ring-${Team}-${name}"
}

function Build-SharedPatternsCodex {
    param([string]$Team)
    $src = Join-Path $script:RingDir "$Team\skills\shared-patterns"
    if (-not (Test-Path $src)) { return }
    $mdFiles = Get-ChildItem -Path $src -Filter "*.md" -File -ErrorAction SilentlyContinue
    if (-not $mdFiles -or @($mdFiles).Count -eq 0) {
        Write-VerboseLog "codex shared-patterns empty: $Team (skip)"
        return
    }
    if ($script:DryRunMode) {
        Write-VerboseLog "[dry-run] codex shared-patterns: $Team"
        return
    }
    $dst = Join-Path $script:CodexOut "$Team\shared-patterns"
    Copy-MirrorDirectory -Source $src -Destination $dst
    Invoke-RewriteAccessoryPaths -Dir $dst -Team $Team
    Write-VerboseLog "codex shared-patterns: $Team"
}

function Build-DocsMirrorCodex {
    $src = Join-Path $script:RingDir "dev-team\docs"
    if (-not (Test-Path $src)) { return }
    $dst = Join-Path $script:CodexOut "docs"
    Copy-MirrorDirectory -Source $src -Destination $dst
    Write-VerboseLog "codex docs mirror"
}

function Invoke-RewriteAccessoryPaths {
    param(
        [string]$Dir,
        [string]$Team
    )
    if (-not (Test-Path $Dir)) { return }
    $mdFiles = Get-ChildItem -Path $Dir -Filter "*.md" -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne "SKILL.md" }
    foreach ($f in $mdFiles) {
        & python $script:PyHelper --rewrite-paths --source $f.FullName --dest $f.FullName --team $Team --lookup $script:LookupJson
        if ($LASTEXITCODE -ne 0) {
            Write-Err "python transform failed with exit code $LASTEXITCODE"
            $script:Errors++
            continue
        }
    }
}

# ==============================================================================
# Build orchestration
# ==============================================================================

function Invoke-CleanBuild {
    Write-Section "Clean build outputs"

    if (Test-Path $script:OpencodeOut) {
        Remove-SafeItem $script:OpencodeOut
        Write-VerboseLog "removed $($script:OpencodeOut)"
    }

    # Codex: preserve .system/ (manually maintained Codex config)
    if (Test-Path $script:CodexOut) {
        foreach ($entry in Get-ChildItem -Path $script:CodexOut -Force -ErrorAction SilentlyContinue) {
            if ($entry.Name -eq ".system") {
                Write-VerboseLog "preserve $($entry.FullName)"
                continue
            }
            if ($entry.Name -eq ".codex-lookup.json") { continue }
            Remove-SafeItem $entry.FullName
            Write-VerboseLog "removed $($entry.FullName)"
        }
    }
    else {
        New-DirectoryIfNeeded $script:CodexOut
    }

    if (Test-Path $script:LookupJson) {
        Remove-SafeItem $script:LookupJson
    }

    Write-Ok "Build outputs cleaned."
}

function Test-NeedsBuild {
    return ($script:InstallOpencode -or $script:InstallCodex)
}

function Invoke-Build {
    Test-RequiredCommand "python" "Codex frontmatter transform"
    Write-Section "Build .ring-build\ (opencode + codex)"

    Invoke-CleanBuild

    New-DirectoryIfNeeded (Join-Path $script:OpencodeOut "agent")
    New-DirectoryIfNeeded (Join-Path $script:OpencodeOut "skill")
    New-DirectoryIfNeeded (Join-Path $script:OpencodeOut "command")
    New-DirectoryIfNeeded $script:CodexOut

    if ($script:DryRunMode) {
        Write-VerboseLog "[dry-run] build lookup -> $($script:LookupJson)"
    }
    else {
        & python $script:PyHelper --build-lookup $script:RingDir --lookup-out $script:LookupJson
        if ($LASTEXITCODE -ne 0) {
            Write-Err "python transform failed with exit code $LASTEXITCODE"
            exit 5
        }
        Write-VerboseLog "lookup written: $($script:LookupJson)"
    }

    foreach ($team in $script:Teams) {
        $teamDir = Join-Path $script:RingDir $team
        if (-not (Test-Path $teamDir)) {
            Write-Warn "team dir missing: $team"
            continue
        }

        Build-OpencodeAgents $team
        Build-OpencodeSkills $team
        Build-OpencodeCommands $team
        Build-OpencodeSkillCommands $team
        Build-SharedPatternsCodex $team

        $skillsDir = Join-Path $script:RingDir "$team\skills"
        if (Test-Path $skillsDir) {
            foreach ($d in Get-ChildItem -Path $skillsDir -Directory -ErrorAction SilentlyContinue) {
                Build-CodexSkill -Team $team -SkillDir $d.FullName
            }
        }
    }

    Build-DocsMirrorOpencode
    Build-DocsMirrorCodex
    Build-CrossPluginMirrorOpencode

    if (-not $script:DryRunMode) {
        $fileCount = (Get-ChildItem -Path $script:OpencodeOut, $script:CodexOut -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
        if ($fileCount -eq 0) {
            Write-Err "build produced zero output"
            exit 5
        }
    }

    Write-Ok "Build complete."
}

# ==============================================================================
# Top-level symlink install (Opencode / Codex)
# ==============================================================================

function Install-TopLevelSymlink {
    param(
        [string]$Source,
        [string]$Target
    )
    $name = Split-Path -Leaf $Target

    # Ensure parent directory exists
    $parentDir = Split-Path -Parent $Target
    New-DirectoryIfNeeded $parentDir

    # Delegate to Install-Symlink which handles collision detection
    Install-Symlink -Source $Source -Target $Target
}

function Install-Opencode {
    Write-Section "Opencode  ($($script:OpencodeDir))"

    # Clean up any dangling plugins symlink (historical artifact)
    $pluginsTgt = Join-Path $script:OpencodeDir "plugins"
    $pluginsItem = Get-Item $pluginsTgt -Force -ErrorAction SilentlyContinue
    if ($null -ne $pluginsItem -and $pluginsItem.LinkType -eq "SymbolicLink" -and -not (Test-Path $pluginsTgt)) {
        Remove-SafeItem $pluginsTgt
        Write-Ok "removed dangling plugins symlink"
    }

    Install-TopLevelSymlink -Source (Join-Path $script:OpencodeOut "agent")   -Target (Join-Path $script:OpencodeDir "agent")
    Install-TopLevelSymlink -Source (Join-Path $script:OpencodeOut "skill")   -Target (Join-Path $script:OpencodeDir "skill")
    Install-TopLevelSymlink -Source (Join-Path $script:OpencodeOut "command") -Target (Join-Path $script:OpencodeDir "command")
}

function Install-Codex {
    Write-Section "Codex  ($($script:CodexDir))"

    Install-TopLevelSymlink -Source $script:CodexOut -Target (Join-Path $script:CodexDir "skills")
}

# ==============================================================================
# Remove helpers
# ==============================================================================

function Remove-PerFileSymlinks {
    param(
        [string]$TargetDir,
        [string]$Label
    )
    Write-Section "Removing $Label  ($TargetDir)"

    if (-not (Test-Path $TargetDir)) { return }

    foreach ($sub in @("agents", "commands", "skills", "hooks")) {
        $subDir = Join-Path $TargetDir $sub
        if (-not (Test-Path $subDir)) { continue }
        foreach ($item in Get-ChildItem -Path $subDir -Force -ErrorAction SilentlyContinue) {
            if ($item.LinkType -ne "SymbolicLink") { continue }
            $target = if ($item.Target -is [array]) { $item.Target[0] } else { $item.Target }
            $ringDirNormalized = ($script:RingDir -replace '\\', '/').TrimEnd('/') + '/'
            $targetNormalized = $target -replace '\\', '/'
            if ($targetNormalized.StartsWith($ringDirNormalized)) {
                Remove-SafeItem $item.FullName
                Write-Ok "Removed: $sub/$($item.Name)"
                $script:Removed++
            }
        }
    }

    # Clean Ring hook entries from settings.json
    $settingsFile = Join-Path $TargetDir "settings.json"
    if (Test-Path $settingsFile) {
        $hooksTargetPath = (Join-Path $TargetDir "hooks") -replace '\\', '/'
        if (-not $hooksTargetPath.EndsWith('/')) { $hooksTargetPath += '/' }

        if ($script:DryRunMode) {
            Write-VerboseLog "[dry-run] strip Ring hooks from $settingsFile"
        }
        else {
            try {
                $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json
                if ($settings.PSObject.Properties['hooks']) {
                    foreach ($eventProp in $settings.hooks.PSObject.Properties) {
                        $eventName = $eventProp.Name
                        $entries = @($eventProp.Value)
                        $filtered = @()
                        foreach ($entry in $entries) {
                            $hasRingHook = $false
                            if ($entry.PSObject.Properties['hooks']) {
                                foreach ($hook in @($entry.hooks)) {
                                    if ($hook.PSObject.Properties['command'] -and $hook.command -like "*$hooksTargetPath*") {
                                        $hasRingHook = $true
                                        break
                                    }
                                }
                            }
                            if (-not $hasRingHook) {
                                $filtered += $entry
                            }
                        }
                        $settings.hooks.$eventName = $filtered
                    }
                    $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsFile -Encoding UTF8
                    Write-Ok "Cleaned Ring hooks from settings.json"
                }
            }
            catch {
                Write-Err "Could not clean hooks from settings.json: $_"
            }
        }
    }
}

function Remove-TopLevelSymlink {
    param(
        [string]$Target,
        [string]$Label
    )
    $item = Get-Item $Target -Force -ErrorAction SilentlyContinue
    if ($null -eq $item -or $item.LinkType -ne "SymbolicLink") { return }

    $linkTarget = if ($item.Target -is [array]) { $item.Target[0] } else { $item.Target }
    $linkTargetNormalized = $linkTarget -replace '\\', '/'
    $buildDirNormalized = ($script:BuildDir -replace '\\', '/').TrimEnd('/') + '/'
    $ringDirNormalized = ($script:RingDir -replace '\\', '/').TrimEnd('/') + '/'

    if ($linkTargetNormalized.StartsWith($buildDirNormalized) -or $linkTargetNormalized.StartsWith($ringDirNormalized)) {
        Remove-SafeItem $item.FullName
        Write-Ok "Removed: $Label"
        $script:Removed++
    }
}

function Invoke-Remove {
    if ($script:InstallClaude)  { Remove-PerFileSymlinks $script:ClaudeDir  "Claude Code" }
    if ($script:InstallFactory) { Remove-PerFileSymlinks $script:FactoryDir "Factory AI" }

    if ($script:InstallOpencode) {
        Write-Section "Removing Opencode  ($script:OpencodeDir)"
        Remove-TopLevelSymlink (Join-Path $script:OpencodeDir "agent")   "opencode/agent"
        Remove-TopLevelSymlink (Join-Path $script:OpencodeDir "skill")   "opencode/skill"
        Remove-TopLevelSymlink (Join-Path $script:OpencodeDir "command") "opencode/command"
    }
    if ($script:InstallCodex) {
        Write-Section "Removing Codex  ($script:CodexDir)"
        Remove-TopLevelSymlink (Join-Path $script:CodexDir "skills") "codex/skills"
    }

    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host "Done!" -ForegroundColor Green -NoNewline
    Write-Host " Removed $($script:Removed) symlinks."
    Write-Host ""
}

# ==============================================================================
# Doctor helpers
# ==============================================================================

function Test-PerFileInstall {
    param(
        [string]$TargetDir,
        [string]$Label
    )
    if (-not (Test-Path $TargetDir)) {
        Write-Skip "$Label not installed ($TargetDir absent)"
        return $true
    }

    $countOk = 0
    $countBad = 0

    foreach ($sub in @("agents", "commands", "skills", "hooks")) {
        $subDir = Join-Path $TargetDir $sub
        if (-not (Test-Path $subDir)) { continue }
        foreach ($item in Get-ChildItem -Path $subDir -Force -ErrorAction SilentlyContinue) {
            if ($item.LinkType -ne "SymbolicLink") { continue }
            $target = if ($item.Target -is [array]) { $item.Target[0] } else { $item.Target }
            $ringDirNormalized = ($script:RingDir -replace '\\', '/').TrimEnd('/') + '/'
            $targetNormalized = $target -replace '\\', '/'
            if (-not $targetNormalized.StartsWith($ringDirNormalized)) { continue }

            if (Test-Path $item.FullName) {
                $countOk++
            }
            else {
                Write-Err "DANGLING  $($item.FullName) -> $target"
                $countBad++
            }
        }
    }

    if ($countBad -gt 0) {
        Write-Err "$Label`: $countOk OK, $countBad broken"
        return $false
    }
    Write-Ok "$Label`: $countOk symlinks OK"
    return $true
}

function Test-TopLevelSymlink {
    param(
        [string]$Target,
        [string]$Expected
    )
    $item = Get-Item $Target -Force -ErrorAction SilentlyContinue
    if ($null -eq $item -or $item.LinkType -ne "SymbolicLink") {
        Write-Err "FAIL   $Target (not a symlink)"
        return $false
    }

    $linkTarget = if ($item.Target -is [array]) { $item.Target[0] } else { $item.Target }
    $linkTargetNormalized = $linkTarget -replace '\\', '/'
    $expectedNormalized = $Expected -replace '\\', '/'

    if ($linkTargetNormalized -ne $expectedNormalized) {
        Write-Err "FAIL   $Target (-> $linkTarget; expected $Expected)"
        return $false
    }

    if (-not (Test-Path $Target)) {
        Write-Err "FAIL   $Target (dangling -> $linkTarget)"
        return $false
    }

    Write-Ok "PASS   $Target"
    return $true
}

function Invoke-Doctor {
    Write-Section "Doctor -- verifying install state"
    $allPass = $true

    # Per-file targets
    if (-not (Test-PerFileInstall $script:ClaudeDir  "Claude Code"))  { $allPass = $false }
    if (-not (Test-PerFileInstall $script:FactoryDir "Factory AI"))   { $allPass = $false }

    # Top-level targets (opencode/codex) only checked if directory exists
    if (Test-Path $script:OpencodeDir) {
        if (-not (Test-TopLevelSymlink (Join-Path $script:OpencodeDir "agent")   (Join-Path $script:OpencodeOut "agent")))   { $allPass = $false }
        if (-not (Test-TopLevelSymlink (Join-Path $script:OpencodeDir "skill")   (Join-Path $script:OpencodeOut "skill")))   { $allPass = $false }
        if (-not (Test-TopLevelSymlink (Join-Path $script:OpencodeDir "command") (Join-Path $script:OpencodeOut "command"))) { $allPass = $false }
    }
    else {
        Write-Skip "Opencode not installed `($script:OpencodeDir absent`)"
    }

    if (Test-Path $script:CodexDir) {
        if (-not (Test-TopLevelSymlink (Join-Path $script:CodexDir "skills") $script:CodexOut)) { $allPass = $false }
    }
    else {
        Write-Skip "Codex not installed `($script:CodexDir absent`)"
    }

    # Build output sanity (only relevant if build directories exist)
    if (Test-Path $script:OpencodeOut) {
        $docsMirror = Join-Path $script:OpencodeOut "skill\docs\standards"
        if (Test-Path $docsMirror) {
            Write-Ok "PASS   opencode docs mirror present"
        }
        else {
            Write-Err "FAIL   opencode docs mirror missing"
            $allPass = $false
        }
        $crossPlugin = Join-Path $script:OpencodeOut "dev-team\skills\shared-patterns"
        if (Test-Path $crossPlugin) {
            Write-Ok "PASS   opencode cross-plugin mirror present"
        }
        else {
            Write-Err "FAIL   opencode cross-plugin mirror missing"
            $allPass = $false
        }
    }

    if (Test-Path $script:CodexOut) {
        $systemDir = Join-Path $script:CodexOut ".system"
        if (Test-Path $systemDir) {
            Write-Ok "PASS   codex .system/ preserved"
        }
        else {
            Write-Warn ".system/ missing in $($script:CodexOut) `(manual Codex config`)"
        }
        $codexDocs = Join-Path $script:CodexOut "docs\standards"
        if (Test-Path $codexDocs) {
            Write-Ok "PASS   codex docs mirror present"
        }
        else {
            Write-Err "FAIL   codex docs mirror missing"
            $allPass = $false
        }
    }

    Write-Host ""
    if ($allPass) {
        Write-Host "  " -NoNewline
        Write-Host "Doctor: all checks PASS" -ForegroundColor Green
    }
    else {
        Write-Host "  " -NoNewline
        Write-Host "Doctor: drift detected" -ForegroundColor Red -NoNewline
        Write-Host "  -- try " -NoNewline
        Write-Host ".\ring-install.ps1 all -All" -ForegroundColor White
    }
    Write-Host ""
}

# ==============================================================================
# Target selection helpers
# ==============================================================================

function Test-AnyTargetSelected {
    return ($script:InstallClaude -or $script:InstallFactory -or
            $script:InstallOpencode -or $script:InstallCodex)
}

function Select-InteractiveTargets {
    # Detect which tools are installed
    $cInstalled = Test-Path $script:ClaudeDir
    $fInstalled = Test-Path $script:FactoryDir
    $oInstalled = Test-Path $script:OpencodeDir
    $xInstalled = Test-Path $script:CodexDir

    # Print detection status
    Write-Host ""
    Write-Host "  Detected on this system:" -ForegroundColor White
    if ($cInstalled) {
        Write-Host "    " -NoNewline; Write-Host ([char]0x2713) -ForegroundColor Green -NoNewline
        Write-Host "  Claude Code      " -NoNewline; Write-Host $script:ClaudeDir -ForegroundColor DarkGray
    } else {
        Write-Host "    " -NoNewline; Write-Host ([char]0x00B7) -ForegroundColor DarkGray -NoNewline
        Write-Host "  Claude Code      " -NoNewline; Write-Host $script:ClaudeDir -ForegroundColor DarkGray
    }
    if ($fInstalled) {
        Write-Host "    " -NoNewline; Write-Host ([char]0x2713) -ForegroundColor Green -NoNewline
        Write-Host "  Factory AI       " -NoNewline; Write-Host $script:FactoryDir -ForegroundColor DarkGray
    } else {
        Write-Host "    " -NoNewline; Write-Host ([char]0x00B7) -ForegroundColor DarkGray -NoNewline
        Write-Host "  Factory AI       " -NoNewline; Write-Host $script:FactoryDir -ForegroundColor DarkGray
    }
    if ($oInstalled) {
        Write-Host "    " -NoNewline; Write-Host ([char]0x2713) -ForegroundColor Green -NoNewline
        Write-Host "  Opencode         " -NoNewline; Write-Host $script:OpencodeDir -ForegroundColor DarkGray
    } else {
        Write-Host "    " -NoNewline; Write-Host ([char]0x00B7) -ForegroundColor DarkGray -NoNewline
        Write-Host "  Opencode         " -NoNewline; Write-Host $script:OpencodeDir -ForegroundColor DarkGray
    }
    if ($xInstalled) {
        Write-Host "    " -NoNewline; Write-Host ([char]0x2713) -ForegroundColor Green -NoNewline
        Write-Host "  Codex            " -NoNewline; Write-Host $script:CodexDir -ForegroundColor DarkGray
    } else {
        Write-Host "    " -NoNewline; Write-Host ([char]0x00B7) -ForegroundColor DarkGray -NoNewline
        Write-Host "  Codex            " -NoNewline; Write-Host $script:CodexDir -ForegroundColor DarkGray
    }

    # Show numbered menu
    Write-Host ""
    Write-Host "  What do you want to install?" -ForegroundColor White
    Write-Host "    " -NoNewline; Write-Host "1" -ForegroundColor White -NoNewline; Write-Host ") Claude Code"
    Write-Host "    " -NoNewline; Write-Host "2" -ForegroundColor White -NoNewline; Write-Host ") Factory AI"
    Write-Host "    " -NoNewline; Write-Host "3" -ForegroundColor White -NoNewline; Write-Host ") Opencode    " -NoNewline
    Write-Host "(will build .ring-build\opencode\ first)" -ForegroundColor DarkGray
    Write-Host "    " -NoNewline; Write-Host "4" -ForegroundColor White -NoNewline; Write-Host ") Codex       " -NoNewline
    Write-Host "(will build .ring-build\codex\ first)" -ForegroundColor DarkGray
    Write-Host "    " -NoNewline; Write-Host "5" -ForegroundColor White -NoNewline; Write-Host ") All detected"
    Write-Host "    " -NoNewline; Write-Host "6" -ForegroundColor White -NoNewline; Write-Host ") All four"
    Write-Host "    " -NoNewline; Write-Host "q" -ForegroundColor White -NoNewline; Write-Host ") Cancel"
    Write-Host ""

    $choice = Read-Host "  Selection (number, comma-separated like 1,3, or q)"
    Write-Host ""

    # Handle cancel or empty input
    if ([string]::IsNullOrWhiteSpace($choice) -or $choice -eq "q" -or $choice -eq "Q") {
        Write-Info "Cancelled."
        exit 0
    }

    # Parse comma-separated selections
    $picks = $choice -split ','
    foreach ($pick in $picks) {
        $pick = $pick.Trim()
        switch ($pick) {
            "1" { $script:InstallClaude = $true }
            "2" { $script:InstallFactory = $true }
            "3" { $script:InstallOpencode = $true }
            "4" { $script:InstallCodex = $true }
            "5" {
                if ($cInstalled) { $script:InstallClaude = $true }
                if ($fInstalled) { $script:InstallFactory = $true }
                if ($oInstalled) { $script:InstallOpencode = $true }
                if ($xInstalled) { $script:InstallCodex = $true }
            }
            "6" {
                $script:InstallClaude = $true
                $script:InstallFactory = $true
                $script:InstallOpencode = $true
                $script:InstallCodex = $true
            }
            default {
                Write-Err "Invalid selection: '$pick'"
                exit 1
            }
        }
    }

    # Verify at least one target was selected (e.g., "5" with nothing detected)
    if (-not (Test-AnyTargetSelected)) {
        Write-Err "No targets selected."
        exit 1
    }
}

function Get-SelectedTargetsSummary {
    $parts = @()
    if ($script:InstallClaude) { $parts += "Claude Code" }
    if ($script:InstallFactory) { $parts += "Factory AI" }
    if ($script:InstallOpencode) { $parts += "Opencode" }
    if ($script:InstallCodex) { $parts += "Codex" }
    return ($parts -join ", ")
}

# ==============================================================================
# Main entry point
# ==============================================================================

# 1. Print banner
Show-Banner

# 2. Map params to script-scoped vars
$script:DryRunMode = $DryRun.IsPresent
$script:VerboseMode = $VerboseMode -or $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')
$script:ForceMode = $Force.IsPresent
$script:AssumeYes = $Yes.IsPresent

# Map "uninstall" -> "remove"
if ($Subcommand -eq "uninstall") {
    $Subcommand = "remove"
}

# 3. Handle -Help
if ($Help) {
    Show-Usage
    exit 0
}

# 4. Resolve Ring dir (symlink capability checked later, only for install/all)
Resolve-RingDir

# 5. Set target selection from flags
if ($All) {
    $script:InstallClaude = $true
    $script:InstallFactory = $true
    $script:InstallOpencode = $true
    $script:InstallCodex = $true
}
else {
    if ($Claude) { $script:InstallClaude = $true }
    if ($Factory) { $script:InstallFactory = $true }
    if ($Opencode) { $script:InstallOpencode = $true }
    if ($Codex) { $script:InstallCodex = $true }
}

# For install/remove/all without target flags, show interactive menu
if ($Subcommand -in @("install", "remove", "all")) {
    if (-not (Test-AnyTargetSelected)) {
        Select-InteractiveTargets
    }
}

# 6. Print plan
Write-Info "Ring repo:   $($script:RingDir)"
Write-Info "Subcommand:  $Subcommand"
if (Test-AnyTargetSelected) {
    Write-Info "Targets:     $(Get-SelectedTargetsSummary)"
}
if ($script:DryRunMode) { Write-Warn "DRY-RUN mode -- no changes will be made" }
if ($script:VerboseMode) { Write-Info "Verbose logging enabled" }
if ($script:ForceMode) { Write-Info "Force mode -- non-symlink collisions will be backed up" }

# 7. Switch on subcommand
switch ($Subcommand) {
    "install" {
        Confirm-Interactive
        if (-not $script:DryRunMode) {
            Test-SymlinkCapability
        }
        if ($script:InstallClaude)   { Install-PerFile $script:ClaudeDir   "Claude Code" }
        if ($script:InstallFactory)  { Install-PerFile $script:FactoryDir  "Factory AI" }
        # Auto-build if selected targets are missing their build outputs
        $needsAutoBuild = $false
        if ($script:InstallOpencode -and -not (Test-Path $script:OpencodeOut)) { $needsAutoBuild = $true }
        if ($script:InstallCodex -and -not (Test-Path $script:CodexOut)) { $needsAutoBuild = $true }
        if ($needsAutoBuild) {
            Write-Info "Build outputs missing -- running build first..."
            Invoke-Build
        }
        if ($script:InstallOpencode) { Install-Opencode }
        if ($script:InstallCodex)    { Install-Codex }
        Show-Summary
    }
    "remove" {
        Confirm-Interactive
        Invoke-Remove
    }
    "build" {
        Invoke-Build
    }
    "clean" {
        Invoke-CleanBuild
    }
    "doctor" {
        Invoke-Doctor
    }
    "all" {
        Confirm-Interactive
        if (-not $script:DryRunMode) {
            Test-SymlinkCapability
        }
        Invoke-CleanBuild
        Invoke-Build
        if ($script:InstallClaude)   { Install-PerFile $script:ClaudeDir   "Claude Code" }
        if ($script:InstallFactory)  { Install-PerFile $script:FactoryDir  "Factory AI" }
        if ($script:InstallOpencode) { Install-Opencode }
        if ($script:InstallCodex)    { Install-Codex }
        Show-Summary
    }
    default {
        Write-Err "Internal error: unknown subcommand '$Subcommand'"
        exit 1
    }
}
