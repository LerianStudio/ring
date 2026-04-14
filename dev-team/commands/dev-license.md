---
name: ring:dev-license
description: Apply or switch the license for the current repository
argument-hint: "[apache|elv2|proprietary] [options]"
---

Apply or switch the license for the current repository.

## Usage

```
/ring:dev-license [license-type] [options]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `license-type` | No* | One of: `apache`, `elv2`, `proprietary` |

*If omitted, the skill will detect the current license and ask which to apply.

## Options

| Option | Description | Example |
|--------|-------------|---------|
| `--dry-run` | Show what would change without modifying files | `--dry-run` |
| `--year YEAR` | Override copyright year (default: current year) | `--year 2025` |
| `--holder NAME` | Override copyright holder (default: Lerian Studio Ltd.) | `--holder "Lerian Studio Ltd."` |

## License Types

| Type | Full Name | SPDX | Use Case |
|------|-----------|------|----------|
| `apache` | Apache License 2.0 | `Apache-2.0` | Open source (e.g., Midaz core) |
| `elv2` | Elastic License v2 | `Elastic-2.0` | Source-available Lerian products |
| `proprietary` | Lerian Studio General License | `LicenseRef-Lerian-Proprietary` | Internal/closed repos |

## Examples

```bash
# Apply Apache 2.0 license
/ring:dev-license apache

# Switch to ELv2
/ring:dev-license elv2

# Apply proprietary license with specific year
/ring:dev-license proprietary --year 2024

# Check what would change without modifying
/ring:dev-license apache --dry-run

# Detect current license (interactive)
/ring:dev-license
```

## What It Does

1. **Detects** current license (LICENSE file, source headers, SPDX identifiers)
2. **Confirms** change with user (if switching from an existing license)
3. **Writes** the LICENSE file with the full license text
4. **Updates** all source file headers (.go, .ts, .js) to match
5. **Updates** SPDX identifiers in go.mod/package.json (if present)
6. **Updates** README.md license badge/section (if present)
7. **Validates** all files have consistent headers

## Related Commands

| Command | Description |
|---------|-------------|
| `/ring:dev-cycle` | Development cycle (includes license check at Gate 0) |
| `/ring:dev-refactor` | Codebase analysis (may detect license inconsistencies) |

---

## MANDATORY: Load Full Skill

**This command MUST load the skill for complete workflow execution.**

```
Use Skill tool: ring:dev-licensing
```

The skill contains the complete 4-gate workflow with:
- License detection and identification
- User confirmation gate
- Agent dispatch for header updates
- Validation with consistency checks
- Anti-rationalization tables
- Pressure resistance scenarios

## Execution Context

Pass the following context to the skill:

| Parameter | Value |
|-----------|-------|
| `license_type` | First argument: `apache`, `elv2`, or `proprietary` (if provided) |
| `dry_run` | `true` if `--dry-run` flag present |
| `copyright_year` | Value of `--year` option (default: current year) |
| `copyright_holder` | Value of `--holder` option (default: `Lerian Studio Ltd.`) |
