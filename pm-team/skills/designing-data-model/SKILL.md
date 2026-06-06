---
name: ring:designing-data-model
description: "Designing the data model (entities, fields, relationships, per-service ownership) from the Gate 4 API design and TRD, before database selection; no SQL, ORM, or migration syntax. Gate 5 of ring:planning-large-features; runs after ring:designing-api-contracts, before ring:pinning-dependency-versions. Use when the system stores persistent data. Skip for Small Track, no persistent data, or an unvalidated API design."
---

# Data Modeling — Defining Data Structures

## When to use

- API Design passed Gate 4 validation
- System stores persistent data
- Multiple entities with relationships
- Large Track workflow (2+ day features)

## Skip when

- Small Track workflow → skip to Task Breakdown
- No persistent data → skip to Dependency Map
- API Design not validated → complete Gate 4 first

## Sequence

**Runs before:** ring:pinning-dependency-versions
**Runs after:** ring:designing-api-contracts


Defines WHAT data exists, HOW entities relate, and WHO owns what data — before database technology selection.

## Phase 0: Database Field Naming Strategy (MANDATORY)

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

## Mandatory Workflow

| Phase | Activities |
|-------|------------|
| **1. Entity Identification** | From API Design (Gate 4) and TRD (Gate 3): identify all entities; determine aggregate boundaries; map ownership per service |
| **2. Schema Definition** | Per entity: define fields with types, constraints, indexes; apply naming strategy from Phase 0 |
| **3. Relationship Mapping** | Define relationships (one-to-one, one-to-many, many-to-many); document foreign keys; specify cascade behavior |
| **4. Gate 5 Validation** | All entities documented; relationships complete; ownership clear; field naming consistent; no tech-specific syntax |

## Entity Template

```markdown
### Entity: {EntityName}

**Ownership:** {service-name}
**Primary persistence:** Relational | Document | Key-value | Time-series

| Field | Type | Required | Constraints | Notes |
|-------|------|----------|-------------|-------|
| id | uuid | Yes | PK, unique | Auto-generated |
| name | string | Yes | max 255 chars | |
| status | enum | Yes | ACTIVE, INACTIVE, BLOCKED | |
| created_at | timestamp | Yes | UTC | |
| updated_at | timestamp | Yes | UTC | |

**Indexes:** [field combinations worth indexing for query patterns]

**Relationships:**
- has-many: {RelatedEntity} via {foreign_key}
- belongs-to: {ParentEntity} via {foreign_key}
```

## Data Rules

### Include
- Entity names and descriptions
- Field names (following naming strategy), types, constraints
- Relationships and cardinality
- Data ownership per entity
- Lifecycle states (ACTIVE, INACTIVE, etc.)
- Data retention rules

### Never Include
- Database-specific syntax (PostgreSQL, MongoDB)
- SQL DDL statements (`CREATE TABLE`)
- ORM annotations (`@Column`, `json:"field"`)
- Migration scripts
- Query patterns (belong in tasks)

## Topology-Aware Output

| Structure | Files Generated |
|-----------|-----------------|
| single-repo | `docs/pre-dev/{feature}/data-model.md` |
| monorepo | Root `docs/pre-dev/{feature}/data-model.md` |
| multi-repo | Both repos: `{backend.path}/docs/pre-dev/{feature}/data-model.md` + frontend copy |

## Gate 5 Validation Checklist

| Category | Requirements |
|----------|--------------|
| **Entity Completeness** | All API Design entities have data models; ownership clear; lifecycle states documented |
| **Schema Quality** | All required fields defined; types precise; constraints documented; naming consistent with db-standards-ref.md |
| **Relationships** | All entity relationships documented; cardinality correct; cascade rules specified |
| **No Implementation** | Zero SQL syntax; zero ORM annotations; zero database-specific types; zero migration scripts |

**Gate Result:** ✅ PASS → Dependency Map | ⚠️ CONDITIONAL (fix naming/missing entities) | ❌ FAIL (incomplete schema)
