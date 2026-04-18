# Migration Safety Checks (MANDATORY for Gate 0.5D)

**⛔ MIGRATION SAFETY (MANDATORY when SQL migration files are present):**

See [migration-safety.md](../../docs/standards/golang/migration-safety.md) for the complete standard including expand-contract pattern, multi-tenant considerations, and anti-rationalization table.

**Home:** These checks are executed by [`ring:dev-cycle` Step 12.0.5b](../dev-cycle/SKILL.md) — Gate 0.5D, a post-cycle conditional gate that runs once per cycle when SQL migration files are present in the diff against `origin/main`. Gate 0.5D is parallel to Gate 0.5G (multi-tenant dual-mode verification at Step 12.0.5); 0.5G checks Go code safety while 0.5D checks SQL schema evolution safety. Prior to the Prancy Bentley v1.56.0 refactor these checks lived in the now-deprecated `ring:dev-delivery-verification` skill; they were restored as a standalone gate to close that orphan.

## When This Applies

This check ONLY runs when the current branch contains new or modified SQL migration files compared to the base branch (main/develop). If no migration files are detected, this check is automatically skipped.

Detection:
```bash
git diff --name-only origin/main -- '**/migrations/*.sql' '**/*.sql' 2>/dev/null | grep -v "_test"
```

## What Gets Checked

### BLOCKING (returns to Gate 0)
| Pattern | Risk | Required Fix |
|---------|------|-------------|
| `ADD COLUMN ... NOT NULL` without `DEFAULT` | ACCESS EXCLUSIVE lock, table rewrite | Add as nullable → backfill → add constraint |
| `DROP COLUMN` | Breaks services still reading the column | Expand-contract: deprecate first |
| `DROP TABLE` | Data loss | Rename to `_deprecated_YYYYMMDD` first |
| `TRUNCATE TABLE` | Data loss | Never in production migrations |
| `CREATE INDEX` without `CONCURRENTLY` | SHARE lock blocks writes | Use `CREATE INDEX CONCURRENTLY` |
| `ALTER COLUMN TYPE` | Table rewrite | Add new column, migrate data, drop old |
| Missing DOWN migration (`.down.sql`) | Cannot rollback | Create matching DOWN file |
| Empty DOWN migration | Rollback will silently do nothing | Write actual rollback SQL |

### WARNING (flags but does not block)
| Pattern | Risk | Recommendation |
|---------|------|----------------|
| DDL without `IF NOT EXISTS`/`IF EXISTS` | Not idempotent for multi-tenant re-runs | Add conditional DDL |
| Large `UPDATE` without batching | Row locks on large tables | Batch in 1000-5000 row increments |

## Anti-Rationalization

| Excuse | Response |
|--------|----------|
| "The table is small" | Tables grow. Apply safe patterns regardless. |
| "We'll do a maintenance window" | Zero-downtime is the standard for SaaS. |
| "The DOWN migration is trivial" | Untested rollbacks fail when needed most. Write it. |
| "CONCURRENTLY is slower" | 2x slower without blocking writes > fast with blocking writes. |
| "Nobody reads this column" | You don't know that. Deprecate first, drop later. |
