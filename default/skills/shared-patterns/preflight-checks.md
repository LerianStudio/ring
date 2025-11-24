# Universal Pre-flight Checks Pattern

Add this section to skills with prerequisites:

## Pre-flight Checks

**Before starting this skill, verify prerequisites:**

Run: `[skill-directory]/lib/preflight-checker.sh skills/[skill-name]/SKILL.md`

Or use `/ring:preflight [skill-name]`

**Prerequisites defined in frontmatter:**

```yaml
prerequisites:
  - name: "[prerequisite-name]"
    check: "[shell command that must succeed]"
    failure_message: "[helpful error message]"
    severity: "blocking|warning"
```

**Check types:**

1. **blocking** - Skill cannot proceed, must fail immediately
2. **warning** - Show warning but allow skill to continue

**Example prerequisites:**

```yaml
prerequisites:
  - name: "test_framework_installed"
    check: "npm list jest || npm list vitest || which pytest"
    failure_message: "No test framework found. Install jest, vitest, or pytest first."
    severity: "blocking"

  - name: "database_running"
    check: "pg_isready -h localhost"
    failure_message: "PostgreSQL is not running. Start with: brew services start postgresql"
    severity: "warning"

  - name: "git_clean_state"
    check: "git diff --quiet && git diff --cached --quiet"
    failure_message: "Working directory has uncommitted changes. Commit or stash first."
    severity: "blocking"
```

**Integration pattern:**

Add to skill SKILL.md after frontmatter, before main content:

```markdown
---
name: skill-name
description: skill description
prerequisites:
  - name: "prerequisite_name"
    check: "command to verify"
    failure_message: "What to do if check fails"
    severity: "blocking"
---

## Pre-flight Checks

Before starting, verify all prerequisites pass:

[Reference this pattern: shared-patterns/preflight-checks.md]
```

**Checker behavior:**

- Runs each check command in shell
- Success: exit code 0
- Failure: exit code non-zero
- **blocking** failures → abort skill immediately
- **warning** failures → show message, allow continuation
- All checks run before skill starts

**Common prerequisite categories:**

1. **Environment** - Required tools/frameworks installed
2. **State** - Git clean, database running, ports available
3. **Permissions** - File access, API credentials present
4. **Dependencies** - Other skills completed first
5. **Configuration** - Config files exist and valid
