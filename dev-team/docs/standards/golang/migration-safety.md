# Go Standards - Migration Safety

> **Module:** migration-safety.md | **Sections:** §1-§5 | **Parent:** [index.md](index.md)

This module covers database migration safety patterns to prevent production incidents caused by schema changes. All migrations MUST be backward-compatible and safe for zero-downtime deployments.

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [Principles](#principles) | Core migration safety principles |
| 2 | [Dangerous Operations](#dangerous-operations-detection) | Operations that require special handling |
| 3 | [Expand-Contract Pattern](#expand-contract-pattern-mandatory) | Safe schema evolution strategy |
| 4 | [ACKNOWLEDGE Convention](#acknowledge-convention) | Inline SQL comment for intentional breaking migrations |
| 5 | [Multi-Tenant Considerations](#multi-tenant-considerations) | Migration safety in multi-tenant context |
| 6 | [Verification Commands](#verification-commands) | Automated checks for Gate 0.5D |

**Meta-sections:**
- [Anti-Rationalization Table](#anti-rationalization-table) - Common excuses and required actions
- [Checklist](#checklist) - Pre-submission verification

---

## Principles

Database migrations in production fintech systems carry disproportionate risk. A bad migration can:
- Lock tables for minutes, blocking all transactions
- Cause data loss if a column is dropped prematurely
- Break other services that depend on the schema
- Multiply impact in multi-tenant mode (runs per tenant)

### Core Rules

1. **All migrations MUST be backward-compatible.** The previous version of the application must continue working after the migration runs. This enables zero-downtime rolling deployments.
2. **All migrations MUST be idempotent.** Running the same migration twice must produce the same result (critical for multi-tenant where it runs N times).
3. **All migrations MUST have a tested DOWN path.** Rollback is not optional.
4. **One feature = one migration file.** See [core.md § Database Migrations](core.md#database-migrations-mandatory).

---

## Dangerous Operations Detection

The following SQL operations are dangerous in production and require specific handling:

### ⛔ BLOCKING Operations (Gate 0.5D MUST reject)

| Operation | Risk | Safe Alternative |
|-----------|------|------------------|
| `ALTER TABLE ... ADD COLUMN ... NOT NULL` (without DEFAULT) | Rewrites entire table, acquires ACCESS EXCLUSIVE lock | Add as nullable first, backfill, then add constraint |
| `ALTER TABLE ... DROP COLUMN` | Breaks any service still reading that column | Use expand-contract: stop reading → deploy → drop in next release |
| `CREATE INDEX` (without CONCURRENTLY) | Acquires SHARE lock, blocks writes on large tables | `CREATE INDEX CONCURRENTLY` (PostgreSQL) |
| `ALTER TABLE ... ALTER COLUMN TYPE` | Rewrites entire table | Add new column, migrate data, drop old column |
| `LOCK TABLE` | Explicit lock blocks all concurrent access | Never use explicit locks in migrations |
| `DROP TABLE` | Data loss, breaks dependent services | Rename first (`_deprecated_YYYYMMDD`), drop in next release |
| `TRUNCATE TABLE` | Data loss | Never in production migrations |

### ⚠️ WARNING Operations (Gate 0.5D flags, does not block)

| Operation | Risk | Recommendation |
|-----------|------|----------------|
| `ALTER TABLE ... ADD COLUMN ... DEFAULT` | Safe in PostgreSQL 11+ (metadata-only), but verify version | Confirm target PostgreSQL version supports metadata-only ADD COLUMN |
| `ALTER TABLE ... RENAME COLUMN` | May break queries using old name | Prefer add-new + migrate + drop-old |
| `CREATE UNIQUE INDEX CONCURRENTLY` | Can fail and leave invalid index | Check for invalid indexes after migration |
| Large `UPDATE` in migration | May lock rows for extended time | Batch updates (1000-5000 rows per batch with commit) |

### Detection Patterns

```bash
# Detect dangerous operations in new migration files
# Run against files added in the current branch vs main

DANGEROUS_PATTERNS="NOT NULL(?!.*DEFAULT)|DROP COLUMN|DROP TABLE|TRUNCATE|LOCK TABLE|ALTER COLUMN TYPE"
WARNING_PATTERNS="RENAME COLUMN|CREATE UNIQUE INDEX(?!.*CONCURRENTLY)"
INDEX_PATTERN="CREATE INDEX(?!.*CONCURRENTLY)"

# Get new/modified migration files
migration_files=$(git diff --name-only origin/main -- '**/migrations/*.sql' '**/*.sql')

if [ -n "$migration_files" ]; then
  for f in $migration_files; do
    # BLOCKING checks
    if grep -Pn "$DANGEROUS_PATTERNS" "$f" 2>/dev/null; then
      echo "⛔ BLOCKING: Dangerous operation in $f"
    fi
    # Non-concurrent index
    if grep -Pn "$INDEX_PATTERN" "$f" 2>/dev/null | grep -v "CONCURRENTLY"; then
      echo "⛔ BLOCKING: CREATE INDEX without CONCURRENTLY in $f"
    fi
    # WARNING checks
    if grep -Pn "$WARNING_PATTERNS" "$f" 2>/dev/null; then
      echo "⚠️ WARNING: Review required for $f"
    fi
  done
fi
```

---

## Expand-Contract Pattern (MANDATORY)

All schema changes that modify existing columns or tables MUST follow the expand-contract pattern:

### Phase 1: Expand (Migration N)
- Add new column/table alongside old one
- New column is nullable (no NOT NULL constraint yet)
- Application writes to BOTH old and new
- Application reads from old (backward compatible)

### Phase 2: Migrate (Migration N+1, separate deploy)
- Backfill new column from old column data
- Application reads from new, writes to both
- Verify data consistency

### Phase 3: Contract (Migration N+2, separate deploy)
- Stop writing to old column
- Add NOT NULL constraint if needed (now safe — all rows populated)
- Drop old column in a FUTURE migration (not this one)

### Example: Renaming a Column

```sql
-- Migration 1 (PR #1): EXPAND — add new column, backfill
ALTER TABLE accounts ADD COLUMN account_name VARCHAR(255);
UPDATE accounts SET account_name = name WHERE account_name IS NULL;
-- Application now writes to BOTH name and account_name, reads from account_name

-- Migration 2 (PR #2, separate deploy): CONTRACT — drop old column
-- This PR is allowed to use DROP COLUMN because:
-- 1. The previous deploy confirmed no service reads 'name' anymore
-- 2. The PR description documents the expand-contract sequence
-- 3. Gate 0.5D will flag it — the agent must acknowledge it as intentional
ALTER TABLE accounts DROP COLUMN IF EXISTS name;
```

**Never combine expand and contract in the same migration or same PR.** Each phase must be a separate deployment to allow rollback.

**Note on Gate 0.5D interaction:** The contract phase (DROP COLUMN) will trigger a Gate 0.5D BLOCKING flag. This is by design — the agent must verify the expand phase was already deployed and documented in the PR. The check forces explicit acknowledgment, not blind automation.

---

## ACKNOWLEDGE Convention

Gate 0.5D (Migration Safety) defaults to BLOCKING for dangerous operations such as contract-phase `DROP COLUMN` (executed after the expand phase has already been deployed) and `ALTER TYPE` on tables exceeding 100k rows. These are legitimate operations in the correct expand-contract sequence, but they are indistinguishable from accidental destructive changes without author intent. The `ACKNOWLEDGE` comment is how a migration author explicitly opts into accepting that risk.

### Syntax

Place an inline SQL comment on the line immediately above the dangerous operation:

```sql
-- ACKNOWLEDGE: <rationale>
```

- The comment MUST be on the line directly preceding the dangerous statement (no blank lines between).
- `<rationale>` MUST be a human-readable explanation. An empty rationale (`-- ACKNOWLEDGE:` with nothing after) is treated as missing.
- Multi-line rationales are permitted using consecutive `-- ACKNOWLEDGE:` / `--` comment lines.

### When to use it

The `ACKNOWLEDGE` convention applies only to Gate 0.5D BLOCKING findings that have a legitimate safe usage:

| Finding | When ACKNOWLEDGE is Appropriate |
|---------|---------------------------------|
| `DROP COLUMN` | Contract phase of expand-contract, after the expand phase was deployed in a prior PR and consumers have migrated. |
| `ALTER COLUMN TYPE` on tables > 100k rows | Type change is necessary, expand-contract is not possible, and a maintenance window or streaming migration is planned. |

Other BLOCKING findings (e.g., `CREATE INDEX` without `CONCURRENTLY`, `TRUNCATE TABLE`, `DROP TABLE`, `NOT NULL` without `DEFAULT`) have safe alternatives and CANNOT be acknowledged away — they must be rewritten.

### Example

```sql
-- ACKNOWLEDGE: contract phase of expand-contract. Expand phase (add new_column)
-- deployed in PR #1234 on 2026-03-01; consumers migrated by 2026-04-01.
ALTER TABLE users DROP COLUMN old_column;
```

### Orchestrator behavior at Gate 0.5D

At Gate 0.5D (`ring:dev-cycle` Step 12.0.5b), each BLOCKING finding is checked for an associated `-- ACKNOWLEDGE:` comment on the line immediately above:

1. **Finding has an ACKNOWLEDGE comment with non-empty rationale** → reclassified from `BLOCKING` to `ACKNOWLEDGE` severity. The cycle pauses at a user checkpoint that displays the finding and the rationale, and requires explicit user approval to proceed.
2. **Finding has no ACKNOWLEDGE comment** (or the rationale is empty) → remains `BLOCKING`. The cycle HARD BLOCKS. There is no silent opt-out.

### Fail-safe default

No comment = BLOCKING. This is non-negotiable. The absence of a comment is never interpreted as implicit approval. Authors who intend a breaking migration MUST state their intent in the migration file itself, not in commit messages, PR descriptions, or chat — because only the file travels with the migration into every downstream tool that inspects it.

---

## Multi-Tenant Considerations

In multi-tenant mode, migrations run once per tenant database (or per tenant schema). This amplifies risk:

| Single-Tenant Risk | Multi-Tenant Risk |
|--------------------|--------------------|
| Table lock for 30s | Table lock for 30s × N tenants |
| Failed migration → rollback 1 DB | Failed migration → partial state across N DBs |
| Index creation blocks writes | Index creation blocks writes for ALL tenants sequentially |

### Multi-Tenant Migration Rules

1. **Migrations MUST be idempotent.** If migration fails on tenant 5 of 20, re-running must skip tenants 1-4 safely.
2. **Use IF NOT EXISTS / IF EXISTS.** All DDL must be conditional.
3. **Timeout per tenant.** Set statement timeout to prevent one tenant's large table from blocking all others.
4. **Log per-tenant progress.** The migration runner must log which tenant is being migrated for debugging partial failures.

```sql
-- ✅ Idempotent migration (safe for re-run)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_transactions_tenant_date
  ON transactions (tenant_id, created_at);

-- ❌ Non-idempotent (fails on re-run)
CREATE INDEX CONCURRENTLY idx_transactions_tenant_date
  ON transactions (tenant_id, created_at);
```

---

## Verification Commands

These commands are used by Gate 0.5D (Migration Safety) at `ring:dev-cycle` Step 12.0.5b (post-cycle, conditional on SQL migration files present in the cycle diff against `origin/main`).

### Step 1: Detect migration files

```bash
migration_files=$(git diff --name-only origin/main -- '**/migrations/*.sql' '**/*.sql' 2>/dev/null)
if [ -z "$migration_files" ]; then
  echo "NO_MIGRATIONS — skip migration safety checks"
  exit 0
fi
echo "Found migration files: $migration_files"
```

### Step 2: Check for blocking operations

```bash
blocking=0
for f in $migration_files; do
  # NOT NULL without DEFAULT
  if grep -Pin "NOT\s+NULL" "$f" | grep -Piv "DEFAULT|CONSTRAINT|CHECK|WHERE|AND|OR"; then
    echo "⛔ $f: ADD COLUMN NOT NULL without DEFAULT"
    blocking=1
  fi
  # DROP COLUMN
  if grep -Pin "DROP\s+COLUMN" "$f"; then
    echo "⛔ $f: DROP COLUMN (use expand-contract pattern)"
    blocking=1
  fi
  # DROP TABLE (not IF EXISTS rename pattern)
  if grep -Pin "DROP\s+TABLE" "$f" | grep -Piv "IF EXISTS.*deprecated"; then
    echo "⛔ $f: DROP TABLE"
    blocking=1
  fi
  # TRUNCATE
  if grep -Pin "TRUNCATE" "$f"; then
    echo "⛔ $f: TRUNCATE TABLE"
    blocking=1
  fi
  # CREATE INDEX without CONCURRENTLY
  if grep -Pin "CREATE\s+(UNIQUE\s+)?INDEX\b" "$f" | grep -Piv "CONCURRENTLY"; then
    echo "⛔ $f: CREATE INDEX without CONCURRENTLY"
    blocking=1
  fi
  # ALTER COLUMN TYPE
  if grep -Pin "ALTER\s+COLUMN.*TYPE" "$f"; then
    echo "⛔ $f: ALTER COLUMN TYPE (rewrite risk)"
    blocking=1
  fi
done

if [ "$blocking" -eq 1 ]; then
  echo "MIGRATION_SAFETY: ⛔ BLOCKED — fix dangerous operations above"
  exit 1
fi
```

### Step 3: Check for DOWN migration

```bash
for f in $migration_files; do
  dir=$(dirname "$f")
  base=$(basename "$f")
  # golang-migrate convention: NNNN_name.up.sql must have NNNN_name.down.sql
  if echo "$base" | grep -q "\.up\.sql$"; then
    down_file="${base/.up.sql/.down.sql}"
    if [ ! -f "$dir/$down_file" ]; then
      echo "⛔ $f: Missing DOWN migration ($down_file)"
      blocking=1
    elif [ ! -s "$dir/$down_file" ]; then
      echo "⛔ $f: DOWN migration is empty ($down_file)"
      blocking=1
    fi
  fi
done
```

### Step 4: Check idempotency (for multi-tenant)

```bash
for f in $migration_files; do
  # Check DDL statements use IF NOT EXISTS / IF EXISTS
  if grep -Pin "CREATE\s+(TABLE|INDEX)" "$f" | grep -Piv "IF NOT EXISTS|CONCURRENTLY"; then
    echo "⚠️ $f: DDL without IF NOT EXISTS (not idempotent for multi-tenant re-runs)"
  fi
  if grep -Pin "DROP\s+(TABLE|INDEX|COLUMN)" "$f" | grep -Piv "IF EXISTS"; then
    echo "⚠️ $f: DROP without IF EXISTS (not idempotent)"
  fi
done
```

---

## Anti-Rationalization Table

| Excuse | Why It's Wrong | Required Action |
|--------|---------------|-----------------|
| "The table is small" | Tables grow. What's small today may be huge in 6 months. | **Apply safe patterns regardless of current size** |
| "We can just do a maintenance window" | Zero-downtime is the standard. Maintenance windows are not acceptable for SaaS. | **Use expand-contract pattern** |
| "The DOWN migration is trivial, we don't need to test it" | Untested rollbacks fail when you need them most. | **Write and verify DOWN migration** |
| "CONCURRENTLY is slower" | A 2x slower index creation that doesn't block writes is always better than a fast one that does. | **Always use CONCURRENTLY** |
| "Nobody else reads this column" | You don't know that. Other services may query it directly or via views. | **Follow expand-contract: deprecate first, drop later** |
| "We'll fix it in the next migration" | Broken state between migrations can cascade. | **Fix in this migration or don't merge** |
| "Multi-tenant just runs it N times, same risk" | N × risk ≠ same risk. Partial failure across tenants is a nightmare to debug. | **Ensure idempotency with IF NOT EXISTS/IF EXISTS** |

---

## Checklist

Before submitting a migration, verify:

- [ ] No `ALTER TABLE ... ADD COLUMN ... NOT NULL` without `DEFAULT`
- [ ] No `DROP COLUMN` without prior deprecation period
- [ ] No `CREATE INDEX` without `CONCURRENTLY`
- [ ] No `ALTER COLUMN TYPE` (use add-new-column pattern instead)
- [ ] No `TRUNCATE TABLE` or `DROP TABLE` without safety check
- [ ] DOWN migration exists and is non-empty
- [ ] All DDL uses `IF NOT EXISTS` / `IF EXISTS` (idempotent for multi-tenant)
- [ ] Large data migrations use batched updates (not single UPDATE)
- [ ] Expand-contract pattern followed for column modifications
- [ ] Migration tested locally with `migrate up` then `migrate down`
