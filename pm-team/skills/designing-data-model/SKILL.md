---
name: ring:designing-data-model
description: "Designing the physical data model as a real stack-native schema (schema.sql with CREATE TABLE DDL, indexes, and constraints for Postgres/Go; schema.prisma for Prisma/TS; Postgres schema.sql as fallback) from the Gate 4 OpenAPI spec and TRD. Gate 5 of ring:planning-large-features; runs after ring:designing-api-contracts, before ring:pinning-dependency-versions. Use when the system stores persistent data. Skip for Small Track, no persistent data, or an unvalidated API contract."
---

# Data Modeling — Producing the Stack-Native Schema

## When to use

- OpenAPI spec passed Gate 4 validation (or Gate 4 SKIPPED for features with no API surface)
- System stores persistent data
- Large Track workflow (2+ day features)

## Skip when

- Small Track workflow → skip to ring:writing-plans
- No persistent data → skip to Dependency Map
- OpenAPI spec not validated (and Gate 4 not SKIPPED) → complete Gate 4 first

## Sequence

**Runs before:** ring:pinning-dependency-versions
**Runs after:** ring:designing-api-contracts

The deliverable is a REAL, stack-native schema file — DDL that becomes migrations, not markdown tables. The DDL **IS** the deliverable: `CREATE TABLE`, indexes, and constraints are required, not forbidden.

## Phase 0: Database Field Naming Strategy (MANDATORY)

See [shared-patterns/standards-discovery.md](../shared-patterns/standards-discovery.md) for the complete workflow.

### Step 1: Check for Gate 4 API standards
If `docs/pre-dev/{feature}/api-standards-ref.md` exists, auto-detect naming convention.

### Step 2: Ask user

**If api-standards-ref.md EXISTS:**
AskUserQuestion: "How should database fields be named?"
- "Convert to snake_case (Recommended)" — API: userId → DB: user_id
- "Keep same as API (camelCase)" — API: userId → DB: userId
- "Different standards — provide DB dictionary"
- "Define manually"

**If api-standards-ref.md DOES NOT EXIST:**
AskUserQuestion: "How should database fields be named?"
- "Use snake_case (Recommended)" — standard for PostgreSQL/MySQL
- "Use camelCase" — standard for MongoDB/document DBs
- "Load from standards document"
- "Define manually"

### Step 3: Generate `db-standards-ref.md`

**Option: Convert to snake_case** — apply automatic rules:
- userId → user_id, createdAt → created_at, isActive → is_active, phoneNumber → phone_number, userID → user_id

**Option: Keep same** — copy field names without modification.

**Option: Load from doc** — WebFetch or read, extract field definitions, save to `db-standards-ref.md`.

## Phase 1: Stack Detection (MANDATORY)

Determine the schema format from the TopologyConfig (research.md frontmatter) plus repo manifests:

| Evidence | Format | Output File |
|----------|--------|-------------|
| `language: golang` in TopologyConfig, `go.mod` present, Postgres in TRD/stack | PostgreSQL DDL | `docs/pre-dev/{feature}/schema.sql` |
| `prisma/` directory or `@prisma/client` in package.json | Prisma schema | `docs/pre-dev/{feature}/schema.prisma` |
| Other stack with a native schema format (e.g., Drizzle, SQLAlchemy) | That stack's native format | `docs/pre-dev/{feature}/schema.{ext}` |
| Undetectable / greenfield | PostgreSQL DDL (Lerian default) | `docs/pre-dev/{feature}/schema.sql` |

Postgres is the Lerian default. When in doubt, write `schema.sql`.

## Mandatory Workflow

| Phase | Activities |
|-------|------------|
| **2. Entity Identification** | From OpenAPI spec (Gate 4 schemas) and TRD (Gate 3): identify all persisted entities; determine aggregate boundaries; map ownership per service |
| **3. Schema Authoring** | Write the schema file: tables/models with typed columns, PK/FK constraints, NOT NULL, CHECK/enum constraints, indexes for known query patterns; apply naming from Phase 0 |
| **4. Validation** | Run the Gate 5 checklist; verify the file parses (e.g., `psql --dry-run`-style review or `npx prisma validate`) |

## Schema Requirements

The schema file MUST be migration-ready:

- Every table/model: explicit PK (`uuid` default at Lerian), `created_at`/`updated_at` timestamps (UTC, `timestamptz`)
- Foreign keys with explicit `ON DELETE` behavior — no implicit cascade decisions
- Lifecycle states as `CHECK` constraints or native enums (`ACTIVE`, `INACTIVE`, ...)
- Indexes for every query pattern implied by the OpenAPI list/filter operations
- Soft-delete (`deleted_at`) only where the TRD requires retention
- **Entity ownership** documented as comment headers per table/model: `-- owner: {service-name}` (or `/// owner:` in Prisma). Multi-service writes to one table are a design smell — flag them.

ER diagram, if useful, goes in a comment header at the top of the schema file or in the TRD — there is no separate `data-model.md` appendix.

### schema.sql sketch

```sql
-- owner: accounts-service
CREATE TABLE accounts (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name        varchar(255) NOT NULL,
    status      varchar(16) NOT NULL CHECK (status IN ('ACTIVE','INACTIVE','BLOCKED')),
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_accounts_status ON accounts (status);
```

## Gate 5 Validation Checklist

| Category | Requirements |
|----------|--------------|
| **Valid schema** | File parses in its native tooling; format matches detected stack; migration-ready (no pseudo-DDL) |
| **Entity Completeness** | Every persisted OpenAPI schema has a table/model; ownership comment per entity; lifecycle states constrained |
| **Schema Quality** | Precise column types; NOT NULL/CHECK/unique constraints explicit; naming consistent with db-standards-ref.md |
| **Relationships** | All FKs declared with explicit ON DELETE behavior; cardinality matches the TRD; join/lookup indexes present |
| **API Alignment** | Every column maps to an OpenAPI schema field per the naming strategy (or is documented as internal-only) |

**Gate Result:** ✅ PASS → Dependency Map | ⚠️ CONDITIONAL (fix naming/missing indexes) | ❌ FAIL (missing entities or non-parsing schema)

## Topology-Aware Output

| Structure | Files Generated |
|-----------|-----------------|
| single-repo | `docs/pre-dev/{feature}/schema.sql` (or `.prisma`) |
| monorepo | Root `docs/pre-dev/{feature}/schema.sql` (or `.prisma`) |
| multi-repo | `{backend.path}/docs/pre-dev/{feature}/schema.sql` (or `.prisma`) + frontend copy |

## Related

- ring:designing-api-contracts — produces the OpenAPI spec the schema is derived from
- ring:pinning-dependency-versions — consumes the schema to pin database products and versions
