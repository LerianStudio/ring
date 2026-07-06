# Windows Installer (PowerShell) Implementation Plan

> **For implementers:** Use ring:executing-plans (rolling wave: dispatch each
> wave — a phase or one epic, your choice — as a workflow → review → user
> checkpoint → detail the next phase against the real code → repeat),
> or ring:running-dev-cycle for the full subagent-orchestrated workflow.
> This document is the living source of truth — task elaboration for later
> phases is written back into it during execution.

**Goal:** Port `ring-install.sh` to a PowerShell script (`ring-install.ps1`) that provides the same symlink-based dev installer experience on Windows, supporting Claude Code, Factory AI, Opencode, and Codex.

**Architecture:** A single `ring-install.ps1` script mirroring the bash installer's structure — subcommands (install/remove/build/clean/doctor/all), target flags (--claude/--factory/--opencode/--codex/--all), and behavior flags (--dry-run/--verbose/--force/--yes). Uses `New-Item -ItemType SymbolicLink` for symlinks (requires Developer Mode or admin), `robocopy /MIR` instead of `rsync`, and the existing `scripts/_codex_frontmatter.py` (invoked as `python` on Windows). Hooks.json merge uses a bundled PowerShell JSON merge function instead of `jq`.

**Tech Stack:** PowerShell 5.1+ (ships with Windows 10/11), Python 3 (for Codex/Opencode builds via `_codex_frontmatter.py`), robocopy (built into Windows)

## Phase Overview

| Phase | Milestone | Epics | Status |
|-------|-----------|-------|--------|
| 1 | Claude Code + Factory AI per-file symlink install/remove/doctor works on Windows | 1.1, 1.2, 1.3, 1.4 | Detailed |
| 2 | Opencode + Codex build pipeline and top-level symlink install works on Windows | 2.1, 2.2 | Epic-level |
| 3 | Interactive menu, summary display, and parity polish | 3.1, 3.2 | Epic-level |

---

## Phase 1: Per-file symlink installer (Claude Code + Factory AI)

### Epic 1.1: Script skeleton, arg parsing, and repo detection

**Goal:** `ring-install.ps1` parses all CLI flags and subcommands identically to the bash version and validates it's running inside a Ring repo
**Scope:** `ring-install.ps1` — top-level script structure
**Dependencies:** none
**Done when:** `.\ring-install.ps1 --help` prints usage; `.\ring-install.ps1 --claude --dry-run` resolves the repo, detects targets, and prints plan without error
**Status:** Pending

#### Task 1.1.1: Create ring-install.ps1 with param block, banner, and usage

- [ ] Done

**Context:** The bash installer (`ring-install.sh:1-178`) defines subcommands as positional args and target/behavior flags. PowerShell uses a `param()` block. The bash banner at `:122-128` uses ANSI escape codes which work in Windows Terminal and PowerShell 7+ but need `$Host.UI.SupportsVirtualTerminal` detection for legacy consoles.

**Implementation vision:** Create `ring-install.ps1` at repo root alongside `ring-install.sh`. Use a `param()` block with `[switch]` parameters for `$Claude`, `$Factory`, `$Opencode`, `$Codex`, `$All`, `$DryRun`, `$Verbose`, `$Force`, `$Yes`, `$Help`, plus `[string]$Subcommand = "install"` and `[string]$RepoPath`. Map subcommand validation to the same set: install, remove, uninstall→remove, build, clean, doctor, all. Use `$PSScriptRoot` as the default repo path (equivalent to `$SCRIPT_DIR`). Print the banner with ANSI if supported, plain text otherwise. The usage function mirrors `ring-install.sh:131-179` with `.ps1` syntax in examples.

**Files:**
- Create: `ring-install.ps1`

**Verification:** `powershell -File ring-install.ps1 -Help` prints usage and exits cleanly; `powershell -File ring-install.ps1 -Subcommand invalid` errors with a clear message.

**Done when:** Script accepts all flags, prints banner, prints usage on `-Help`.

---

#### Task 1.1.2: Repo detection and target directory resolution

- [ ] Done

**Context:** The bash installer (`ring-install.sh:182-225`) resolves the Ring directory by checking for `CLAUDE.md` and `default/agents/`, then sets `$BUILD_DIR`, `$OPENCODE_OUT`, etc. Windows paths use `$env:USERPROFILE` instead of `$HOME`. The `require_cmd` helper checks for `jq`, `python3`, `rsync` — on Windows these become checking for `python` (not `python3`) and `robocopy` (built-in), and `jq` is no longer needed (replaced by PowerShell JSON handling).

**Implementation vision:** Write a `Resolve-RingDir` function that validates `CLAUDE.md` and `default/agents` exist under the resolved path. Set script-scoped variables: `$RingDir`, `$BuildDir`, `$OpencodeOut`, `$CodexOut`, `$PyHelper`, `$LookupJson`. Target directories: `$ClaudeDir = "$env:USERPROFILE\.claude"`, `$FactoryDir = "$env:USERPROFILE\.factory"`, `$OpencodeDir = "$env:USERPROFILE\.config\opencode"`, `$CodexDir = "$env:USERPROFILE\.codex"`. Write a `Test-RequiredCommand` function that checks `Get-Command python -ErrorAction SilentlyContinue` (note: Windows uses `python` not `python3`). Detect tool presence via `Test-Path $ClaudeDir` (mirrors `detect_tool` at `:222-225`).

**Files:**
- Modify: `ring-install.ps1`

**Verification:** `powershell -File ring-install.ps1 -Claude -DryRun` prints "Ring repo: <path>" and "Targets: Claude Code" without errors; running from a non-Ring directory prints an error and exits with code 3.

**Done when:** Repo is validated, all path variables are set, required commands are checked.

---

#### Task 1.1.3: Logging helpers and dry-run-aware mutators

- [ ] Done

**Context:** The bash installer (`ring-install.sh:113-374`) defines colored logging functions and filesystem mutators (`do_mkdir_p`, `do_rm_one`, `do_ln_s`, etc.) that respect `$DRY_RUN`. On Windows, `New-Item -ItemType SymbolicLink` requires either Developer Mode enabled or admin elevation — this is a critical difference from Unix where symlinks are unprivileged.

**Implementation vision:** Write PowerShell equivalents: `Write-Info`, `Write-Ok`, `Write-Skip`, `Write-Warn`, `Write-Err`, `Write-Section`, `Write-Verbose` (use `Write-Host` with `-ForegroundColor`). For mutators: `New-DirectoryIfNeeded` (mkdir -p), `Remove-SafeItem` (rm -f), `New-Symlink` (ln -s, wrapping `New-Item -ItemType SymbolicLink -Force`), `Copy-MirrorDirectory` (rsync replacement using `robocopy /MIR /NJH /NJS /NP`). All mutators check `$script:DryRun` and log instead of acting. For `New-Symlink`, detect Developer Mode via registry key `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock\AllowDevelopmentWithoutDevLicense`. If Developer Mode is off and the process is not elevated, print a clear error explaining the two options: enable Developer Mode or run PowerShell as Administrator.

**Files:**
- Modify: `ring-install.ps1`

**Verification:** `powershell -File ring-install.ps1 -Claude -DryRun -Verbose` prints `[dry-run]` prefixed messages for each operation; without Developer Mode or admin, it errors with an actionable message.

**Done when:** All logging and mutator functions work, dry-run mode prints but doesn't touch the filesystem, symlink capability is validated at startup.

---

### Epic 1.2: Per-file symlink install for Claude Code and Factory AI

**Goal:** `ring-install.ps1 -Claude` creates per-file symlinks for agents, commands, skills, and hooks into `~/.claude/` identically to how the bash version does it
**Scope:** `ring-install.ps1` — install functions
**Dependencies:** Epic 1.1
**Done when:** Running `ring-install.ps1 -Claude` on Windows creates the same symlink structure as `ring-install.sh --claude` on Unix; `doctor` confirms all links are valid
**Status:** Pending

#### Task 1.2.1: Per-file symlink creation and collision handling

- [ ] Done

**Context:** The bash installer's `create_symlink` (`ring-install.sh:389-422`) handles three cases: symlink exists and points correctly (skip), symlink exists but points elsewhere (update), regular file exists (error or backup+replace with --force), nothing exists (create). The `link_perfile_*` functions at `:424-458` iterate agents/*.md, commands/*.md, skills/*/ directories, and hooks.

**Implementation vision:** Write `Install-Symlink` mirroring `create_symlink`: use `(Get-Item $target).Target` to read existing symlink targets (equivalent to `readlink`), `Test-Path $target -PathType Leaf` to check existence. Write `Install-PerFileAgents`, `Install-PerFileCommands`, `Install-PerFileSkills` that iterate source directories using `Get-ChildItem -Filter *.md` (agents/commands) or `Get-ChildItem -Directory` (skills, excluding `shared-patterns`). Write `Install-PerFile` that orchestrates all four plus stale-link pruning (`Prune-PerFileStale` — check if symlink target starts with `$RingDir` and doesn't exist, then remove).

**Files:**
- Modify: `ring-install.ps1`

**Verification:** `powershell -File ring-install.ps1 -Claude`; then verify `~/.claude/agents/` and `~/.claude/skills/` contain symlinks pointing into the ring repo. Run twice — second run should report all skipped.

**Done when:** Per-file symlinks for agents, commands, and skills are created, updated, or skipped correctly; stale links are pruned.

---

#### Task 1.2.2: Hooks symlink and settings.json merge without jq

- [ ] Done

**Context:** The bash installer's `link_perfile_hooks` (`ring-install.sh:461-521`) symlinks `.sh` scripts and merges `hooks.json` into `settings.json` using `jq`. The `jq` merge logic at `:504-511` combines hook event arrays. On Windows, PowerShell can natively parse and merge JSON with `ConvertFrom-Json` / `ConvertTo-Json`, eliminating the `jq` dependency.

**Implementation vision:** Write `Install-PerFileHooks` that: (1) symlinks `*.sh` hook scripts (they still work on Windows since Claude Code runs them via bash/Git Bash), (2) reads `hooks.json`, performs the `${CLAUDE_PLUGIN_ROOT}/hooks/` path replacement with the actual target hooks directory (using `-replace`), then merges into `settings.json` using PowerShell's `ConvertFrom-Json`. The merge logic: for each event key in the new hooks, append to the existing event's array, then deduplicate by matcher+hooks combination (equivalent to `unique_by` in the jq expression). Write merged result back with `ConvertTo-Json -Depth 10`.

**Files:**
- Modify: `ring-install.ps1`

**Verification:** After `ring-install.ps1 -Claude`, check that `~/.claude/settings.json` contains the merged hooks entries and `~/.claude/hooks/` contains symlinks to the `.sh` files.

**Done when:** Hooks merge produces identical `settings.json` content as the bash version.

---

### Epic 1.3: Remove and Doctor subcommands

**Goal:** `ring-install.ps1 remove -Claude` removes all Ring symlinks; `ring-install.ps1 doctor` verifies install integrity
**Scope:** `ring-install.ps1` — remove and doctor functions
**Dependencies:** Epic 1.2
**Done when:** `remove` cleans all Ring-owned symlinks and hook entries from settings.json; `doctor` reports PASS/FAIL for each target
**Status:** Pending

#### Task 1.3.1: Remove subcommand — symlink cleanup and settings.json hook stripping

- [ ] Done

**Context:** The bash `remove_perfile_symlinks` (`ring-install.sh:895-936`) iterates agents/commands/skills/hooks, removes symlinks pointing into `$RING_DIR`, then strips Ring hook entries from `settings.json` using `jq`. The `remove_toplevel_symlink` at `:938-947` handles opencode/codex (Phase 2 scope, but the function structure should be in place).

**Implementation vision:** Write `Remove-PerFileSymlinks` that mirrors the bash logic: iterate each sub-directory, check if the symlink target starts with `$RingDir`, remove it. Write `Remove-RingHooksFromSettings` using PowerShell JSON: load `settings.json`, filter out any hook entries whose command contains the hooks directory path, write back. Write `Remove-TopLevelSymlink` stub for Phase 2. Wire into `do_remove` equivalent based on selected targets.

**Files:**
- Modify: `ring-install.ps1`

**Verification:** Install with `-Claude`, then `ring-install.ps1 remove -Claude`; verify `~/.claude/agents/` has no Ring symlinks and `settings.json` has no Ring hook entries. Run `doctor` after remove — should show 0 symlinks.

**Done when:** All Ring-owned symlinks are removed, settings.json is cleaned, counter reports correctly.

---

#### Task 1.3.2: Doctor subcommand — install state verification

- [ ] Done

**Context:** The bash `do_doctor` (`ring-install.sh:971-1082`) checks per-file symlinks for dangling targets and top-level symlinks for correct destinations. It also validates build output sanity (docs mirror, cross-plugin mirror).

**Implementation vision:** Write `Test-PerFileInstall` and `Test-TopLevelSymlink` mirroring the bash `doctor_check_perfile` and `doctor_check_toplevel`. Iterate symlinks, verify each points into `$RingDir` and the target exists. Report OK count and broken count per target. For top-level targets (Phase 2), check symlink destination matches expected build output path. Print overall PASS or "drift detected" verdict at the end.

**Files:**
- Modify: `ring-install.ps1`

**Verification:** After a clean install with `-Claude`, `ring-install.ps1 doctor` prints "all checks PASS". Delete one source file, run doctor — it should report the dangling link.

**Done when:** Doctor detects healthy installs, dangling links, and missing build outputs.

---

### Epic 1.4: Confirmation prompt and summary display

**Goal:** Interactive confirmation before install/remove, and a summary table after install showing created/updated/skipped/error counts
**Scope:** `ring-install.ps1` — UI functions
**Dependencies:** Epic 1.2
**Done when:** Running without `-Yes` prompts for confirmation; after install, a summary with counts and "Ring is ready!" message is displayed
**Status:** Pending

#### Task 1.4.1: Confirmation prompt and install summary

- [ ] Done

**Context:** The bash `confirm_interactive` (`ring-install.sh:1134-1144`) prompts `[Y/n]` unless `--yes` is passed. The `print_summary` at `:1110-1132` shows a boxed summary with counters and suggested commands. The main entry point at `:1232-1277` orchestrates the flow.

**Implementation vision:** Write `Confirm-Interactive` using `Read-Host` (if `$Yes` is not set and stdin is a terminal). Write `Write-Summary` that prints the same boxed output with `Write-Host -ForegroundColor`. Wire the main entry point: banner → param validation → resolve repo → print plan → switch on subcommand (install → confirm → do_install → summary; remove → confirm → do_remove; build/clean/doctor/all). Track counters in `$script:Created`, `$script:Skipped`, `$script:Updated`, `$script:Errors`, `$script:Removed`, `$script:Pruned`.

**Files:**
- Modify: `ring-install.ps1`

**Verification:** `ring-install.ps1 -Claude` prompts for confirmation, installs, shows summary with counts. `ring-install.ps1 -Claude -Yes` skips the prompt.

**Done when:** End-to-end flow works for Claude Code install, remove, and doctor on Windows.

---

## Phase 2: Opencode + Codex build pipeline

### Epic 2.1: Build subcommand — generate .ring-build/ on Windows

**Goal:** `ring-install.ps1 build` generates `.ring-build/opencode/` and `.ring-build/codex/` using `robocopy` instead of `rsync` and `python` instead of `python3`
**Scope:** `ring-install.ps1` — build functions, `scripts/_codex_frontmatter.py` invocation
**Dependencies:** Phase 1
**Done when:** `ring-install.ps1 build` produces identical `.ring-build/` output as `ring-install.sh build` on Unix
**Status:** Pending

### Epic 2.2: Top-level symlink install for Opencode and Codex

**Goal:** `ring-install.ps1 -Opencode` and `-Codex` create top-level directory symlinks into `.ring-build/` and auto-trigger build when outputs are missing
**Scope:** `ring-install.ps1` — opencode/codex install, remove, doctor for top-level links
**Dependencies:** Epic 2.1
**Done when:** Full `ring-install.ps1 -All` installs all four targets; `doctor` validates everything; `remove` cleans everything
**Status:** Pending

---

## Phase 3: Interactive menu and parity polish

### Epic 3.1: Interactive target selection menu

**Goal:** Running `ring-install.ps1` without target flags shows an interactive numbered menu matching the bash version's UX
**Scope:** `ring-install.ps1` — interactive mode
**Dependencies:** Phase 2
**Done when:** `ring-install.ps1` with no flags shows detected tools with checkmarks, lets user pick by number/comma-separated, and proceeds with selection
**Status:** Pending

### Epic 3.2: Documentation and cross-platform parity verification

**Goal:** README documents the Windows installer; a manual comparison confirms parity with the bash version across all subcommands and targets
**Scope:** `README.md` update, manual verification matrix
**Dependencies:** Epic 3.1
**Done when:** README has a Windows section; all subcommand × target combinations produce equivalent results on both platforms
**Status:** Pending
