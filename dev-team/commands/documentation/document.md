---
allowed-tools: Glob(*), Read(*), Edit(*), MultiEdit(*), Write(*), Grep(*), LS(*), Task(*)
description: Intelligent documentation management that analyzes changes and updates all relevant docs
argument-hint: [--mode=update|overview] [--focus=<docs>] [--git-scope=<scope>]
---

# /ring-dev-team:documentation:document

## Overview

I'll intelligently manage your project documentation by analyzing what actually happened and updating ALL relevant docs accordingly.

## Usage Patterns

### Git-focused documentation (recommended for active development)

```bash
/ring-dev-team:documentation:document --git-scope=all-changes --mode=update     # Document recent changes
/ring-dev-team:documentation:document --git-scope=branch --mode=update          # Document feature branch changes
/ring-dev-team:documentation:document --git-scope=staged --mode=overview        # Overview docs for staged changes
/ring-dev-team:documentation:document --git-scope=last-commit                   # Document last commit changes
```

### Traditional documentation modes

```bash
/ring-dev-team:documentation:document --mode=update --focus=API                 # Update API documentation
/ring-dev-team:documentation:document --mode=overview                           # Full documentation overview
/ring-dev-team:documentation:document --mode=update                             # Update all affected documentation
```

## Arguments

- `--mode`: Documentation mode - update|overview (defaults to overview)
- `--focus`: Specific documentation area to focus on
- `--git-scope`: Git scope for focusing documentation on specific changes - staged|unstaged|all-changes|branch|last-commit|commit-range=<range>

## Git-Scope Benefits

- **Targeted Updates**: Document only areas affected by recent changes
- **Change Attribution**: Connect documentation updates to specific code changes
- **Incremental Documentation**: Maintain documentation alongside development
- **Workflow Integration**: Document as part of feature development and code review

## Core Approach

1. **Analyze git changes** - Understand the specific scope of changes (when git-scope used)
2. **Read ALL documentation files** - README, CHANGELOG, docs/\*, guides, everything
3. **Identify what changed** - Features, architecture, bugs, performance, security, etc
4. **Update EVERYTHING affected** - Not just one file, but all relevant documentation
5. **Maintain consistency** - Ensure all docs tell the same story

I won't make assumptions - I'll look at what ACTUALLY changed and update accordingly.

## Initial Setup (Git-Scope Processing)

### Git Scope Analysis (when --git-scope used)

If `--git-scope` is specified:

```bash
# Source git utilities
if ! source .claude/utils/git-utilities.sh; then
    echo "Error: Could not load git utilities. Please ensure git-utilities.sh exists." >&2
    exit 1
fi

# Process git scope (this function handles validation, stats, and file listing)
target_files=$(process_git_scope "$git_scope")
```

## Documentation Modes

### Mode 1: Documentation Overview (Default)

When you run `/document` without context:

- **Glob** all markdown files (README, CHANGELOG, docs/\*)
- **Read** each documentation file
- **Analyze** documentation coverage
- **Present** organized summary

### Mode 2: Smart Update

When you run `/document update` or after implementations:

1. **Run `/analyze-codebase`** to analyze current codebase
2. **Compare** code reality vs documentation
3. **Identify** what needs updating:
   - New features not documented
   - Changed APIs or interfaces
   - Removed features still in docs
   - New configuration options
   - Updated dependencies
4. **Update systematically:**
   - README.md with new features/changes
   - CHANGELOG.md with version entries
   - API docs with new endpoints
   - Configuration docs with new options
   - Migration guides if breaking changes

### Mode 3: Session Documentation

When run after a long coding session:

- **Analyze conversation history**
- **List all changes made**
- **Group by feature/fix/enhancement**
- **Update appropriate docs**

### Mode 4: Context-Aware Updates

Based on what happened in session:

- **After new feature**: Update README features, add to CHANGELOG
- **After bug fixes**: Document in CHANGELOG, update troubleshooting
- **After refactoring**: Update architecture docs, migration guide
- **After security fixes**: Update security policy, CHANGELOG
- **After performance improvements**: Update benchmarks, CHANGELOG

## Output Format

### Documentation Overview Format

```
DOCUMENTATION OVERVIEW
├── README.md - [status: current/outdated]
├── CHANGELOG.md - [last updated: date]
├── CONTRIBUTING.md - [completeness: 85%]
├── docs/
│   ├── API.md - [status]
│   └── architecture.md - [status]
└── Total coverage: X%

KEY FINDINGS
- Missing: Setup instructions
- Outdated: API endpoints (3 new ones)
- Incomplete: Testing guide
```

### Smart Documentation Rules

1. **Preserve custom content** - Never overwrite manual additions
2. **Match existing style** - Follow current doc formatting
3. **Semantic sections** - Add to correct sections
4. **Version awareness** - Respect semver in CHANGELOG
5. **Link updates** - Fix broken internal links

### Documentation Preservation

**ALWAYS:**

- Read existing docs completely before any update
- Find the exact section that needs updating
- Update in-place, never duplicate
- Preserve custom content and formatting
- Only create new docs if absolutely essential (README missing, etc)

**Preserve sections:**

```markdown
<!-- CUSTOM:START -->

User's manual content preserved

<!-- CUSTOM:END -->
```

**Smart CHANGELOG:**

- Groups changes by type
- Suggests version bump (major/minor/patch)
- Links to relevant PRs/issues
- Maintains chronological order

## Integration with Commands

Works seamlessly with:

- `/analyze-codebase` - Get current architecture first
- `/scaffold` - Add new component docs
- `/security-scan` - Update security documentation

## Documentation Types I Can Manage

- **API Documentation** - Endpoints, parameters, responses
- **Database Schema** - Tables, relationships, migrations
- **Configuration** - Environment variables, settings
- **Deployment** - Setup, requirements, procedures
- **Troubleshooting** - Common issues and solutions
- **Performance** - Benchmarks, optimization guides
- **Security** - Policies, best practices, incident response

## Smart Features

- **Version Detection** - Auto-increment version numbers
- **Breaking Change Alert** - Warn when docs need migration guide
- **Cross-Reference** - Update links between docs
- **Example Generation** - Create usage examples from tests
- **Diagram Updates** - Update architecture diagrams (text-based)
- **Dependency Tracking** - Document external service requirements

## Team Collaboration Support

- **PR Documentation** - Generate docs for pull requests
- **Release Notes** - Create from CHANGELOG for releases
- **Onboarding Docs** - Generate from project analysis
- **Handoff Documentation** - Create when changing teams
- **Knowledge Transfer** - Document before leaving project

## Quality Assurance

- **Doc Coverage** - Report undocumented features
- **Freshness Check** - Flag stale documentation
- **Consistency** - Ensure uniform style across docs
- **Completeness** - Verify all sections present
- **Accuracy** - Compare docs vs actual implementation

## Important Constraints

I will NEVER:

- Delete existing documentation
- Overwrite custom sections
- Change documentation style drastically
- Add AI attribution markers
- Create unnecessary documentation

After analysis, I'll ask: "How should I proceed?"

- Update all outdated docs
- Focus on specific files
- Create missing documentation
- Generate migration guide
- Skip certain sections

## Additional Scenarios & Integrations

### When to Use /document

Simply run `/document` after any significant work:

- After `/analyze-codebase` - Ensure docs match code reality
- After `/scaffold` or new features - Document what was added
- After `/security-scan` or `/code-review` - Document findings and decisions
- After major refactoring - Update architecture, migration guides, everything

**I'll figure out what needs updating based on what actually happened, not rigid rules.**

### Smart Command Combinations

**After analyzing code:**

```bash
/ring-dev-team:analysis:analyze-codebase && /ring-dev-team:documentation:document
# Analyzes entire codebase, then updates docs to match reality
```

**After major refactoring:**

```bash
/ring-dev-team:quality:fix-imports && /ring-dev-team:quality:refactor && /ring-dev-team:documentation:document
# Fixes imports, formats code, updates architecture docs
```

**Before creating PR:**

```bash
/ring-dev-team:quality:code-review && /ring-dev-team:documentation:document
# Reviews code, then ensures docs reflect any issues found
```

### Simple Usage

Just run `/document` and I'll figure out what you need:

- Fresh project? I'll show what docs exist
- Just coded? I'll update the relevant docs
- Long session? I'll document everything
- Just fixed bugs? I'll update CHANGELOG

No need to remember arguments - I understand context!

This keeps your documentation as current as your code while supporting your entire development lifecycle.
