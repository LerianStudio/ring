---
name: pre-dev-data-model
description: |
  Gate 5: Data structures document - defines entities, relationships, and ownership
  before database technology selection. Large Track only.

trigger: |
  - API Design passed Gate 4 validation
  - System stores persistent data
  - Multiple entities with relationships
  - Large Track workflow (2+ day features)

skip_when: |
  - Small Track workflow → skip to Task Breakdown
  - No persistent data → skip to Dependency Map
  - API Design not validated → complete Gate 4 first

sequence:
  after: [pre-dev-api-design]
  before: [pre-dev-dependency-map]
---

# Data Modeling - Defining Data Structures

## Foundational Principle

**Data structures, relationships, and ownership must be defined before database technology selection.**

Jumping to database-specific schemas without modeling creates:
- Inconsistent data structures across services
- Unclear data ownership and authority
- Schema conflicts discovered during development
- Migration nightmares when requirements change

**The Data Model answers**: WHAT data exists, HOW entities relate, WHO owns what data?
**The Data Model never answers**: WHICH database technology or HOW to implement storage.

## Mandatory Workflow

| Phase | Activities |
|-------|------------|
| **1. Data Analysis** | Load approved API Design (Gate 4), TRD (Gate 3), Feature Map (Gate 2), PRD (Gate 1); extract entities from contracts; identify relationships |
| **2. Data Modeling** | Define entities, specify attributes, model relationships, assign ownership, define constraints, plan lifecycle, design access patterns, consider data quality |
| **3. Gate 5 Validation** | Verify all checkboxes before proceeding to Dependency Map |

## Explicit Rules

### ✅ DO Include
Entity definitions (conceptual data objects), attributes with types, constraints (required, unique, ranges), relationships (1:1, 1:N, M:N), data ownership (authoritative component), primary identifiers, lifecycle rules (soft delete, archival), access patterns, data quality rules, referential integrity

### ❌ NEVER Include
Database products (PostgreSQL, MongoDB, Redis), table/collection names, index definitions, SQL/query language, ORM frameworks (Prisma, TypeORM), storage engines, partitioning/sharding, replication/backup, database-specific types (JSONB, BIGSERIAL)

### Abstraction Rules

| Element | Abstract (✅) | Database-Specific (❌) |
|---------|--------------|----------------------|
| Entity | "User" | "users table" |
| Attribute | "emailAddress: String (email format)" | "email VARCHAR(255)" |
| Relationship | "User has many Orders" | "foreign key user_id" |
| Identifier | "Unique identifier" | "UUID primary key" |
| Constraint | "Must be unique" | "UNIQUE INDEX" |

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "We know it's PostgreSQL, just use PG types" | Database choice comes later. Model abstractly now. |
| "Table design is data modeling" | Tables are implementation. Entities are concepts. Stay conceptual. |
| "We need indexes for performance" | Indexes are optimization. Model data first, optimize later. |
| "ORMs require specific schemas" | ORMs adapt to models. Don't let tooling drive design. |
| "Foreign keys define relationships" | Relationships exist conceptually. FKs are implementation. |
| "SQL examples help clarity" | Abstract models are clearer. SQL is implementation detail. |
| "NoSQL doesn't need relationships" | All systems have data relationships. Model them regardless of DB type. |
| "This is just ERD" | ERD is visualization tool. Data model is broader (ownership, lifecycle, etc). |
| "We can skip this for simple CRUD" | Even CRUD needs clear entity design. Don't skip. |
| "Microservices mean no relationships" | Services interact via data. Model entities per service. |

## Red Flags - STOP

If you catch yourself writing any of these in Data Model, **STOP**:

- Database product names (Postgres, MySQL, Mongo, Redis)
- SQL keywords (CREATE TABLE, ALTER TABLE, SELECT, JOIN)
- Database-specific types (SERIAL, JSONB, VARCHAR, TEXT)
- Index commands (CREATE INDEX, UNIQUE INDEX)
- ORM code (Prisma schema, TypeORM decorators)
- Storage details (partitioning, sharding, replication)
- Query optimization (EXPLAIN plans, index hints)
- Backup/recovery strategies

**When you catch yourself**: Replace DB detail with abstract concept. "users table" → "User entity"

## Gate 5 Validation Checklist

| Category | Requirements |
|----------|--------------|
| **Entity Completeness** | All entities from PRD/Feature Map modeled; clear consistent names; defined purpose; boundaries align with TRD components |
| **Attribute Specification** | All types specified; required vs optional explicit; constraints documented; defaults where relevant; computed fields identified |
| **Relationship Modeling** | All relationships documented; cardinality specified (1:1, 1:N, M:N); optional vs required clear; referential integrity to be documented; circular deps resolved |
| **Data Ownership** | Each entity owned by exactly one component; read/write permissions documented; cross-component access via APIs only; no shared database anti-pattern |
| **Data Quality** | Validation rules specified; normalization level appropriate; denormalization justified; consistency strategy defined |
| **Lifecycle Management** | Creation rules; update patterns; deletion strategy (hard/soft); archival/retention policies; audit trail needs |
| **Access Patterns** | Primary patterns documented; query needs identified; write patterns documented; consistency requirements specified |
| **Technology Agnostic** | No database products; no SQL/NoSQL specifics; no table/index definitions; implementable in any DB |

**Gate Result:** ✅ PASS (all checked) → Dependency Map | ⚠️ CONDITIONAL (remove DB specifics) | ❌ FAIL (incomplete/poor ownership)

## Data Model Template Structure

Output to `docs/pre-dev/{feature-name}/data-model.md` with these sections:

| Section | Content |
|---------|---------|
| **Overview** | API Design/TRD/Feature Map references, status, last updated |
| **Data Ownership Map** | Table: Entity, Owning Component, Read Access, Write Access |

### Per-Entity Structure

| Field | Content |
|-------|---------|
| **Purpose** | What this entity represents |
| **Owned By** | Component from TRD |
| **Primary Identifier** | Unique identifier field and format |
| **Attributes** | Table: Attribute, Type, Required, Unique, Constraints, Description |
| **Nested Types** | Embedded types (e.g., OrderItem within Order, Address value object) |
| **Relationships** | Cardinality notation: Entity (1) ──< has many >── (*) OtherEntity |
| **Constraints** | Business rules, status transitions, referential integrity |
| **Lifecycle** | Creation (via which API), updates, deletion strategy, archival |
| **Access Patterns** | Lookup patterns by frequency (primary, secondary, rare) |
| **Data Quality** | Normalization rules, validation |

### Additional Sections

| Section | Content |
|---------|---------|
| **Relationship Diagram** | ASCII/text diagram showing entity relationships with cardinality legend |
| **Cross-Component Access** | Per scenario: data flow steps, rules (no direct DB access, API only) |
| **Consistency Strategy** | Strong consistency (immediate): auth, payments, inventory; Eventual (delay OK): analytics, search |
| **Validation Rules** | Per-entity and cross-entity validation |
| **Lifecycle Policies** | Retention periods table, soft delete strategy, audit trail requirements |
| **Privacy & Compliance** | PII fields table with handling, GDPR compliance, encryption needs (algorithm TBD) |
| **Access Pattern Analysis** | High/medium/low frequency patterns with req/sec estimates, optimization notes for later |
| **Data Quality Standards** | Normalization rules, validation approach, integrity enforcement |
| **Migration Strategy** | Schema evolution (additive, non-breaking, breaking), versioning approach |
| **Gate 5 Validation** | Date, validator, checklist, approval status |

## Common Violations

| Violation | Wrong | Correct |
|-----------|-------|---------|
| **Database Schema** | `CREATE TABLE users (id UUID PRIMARY KEY, email VARCHAR(255) UNIQUE)` | Entity User with attributes table: userId (Identifier, Unique), email (EmailAddress, Unique) |
| **ORM Code** | TypeScript with @Entity(), @PrimaryGeneratedColumn('uuid'), @Column decorators | Entity User with primary identifier, attributes list, constraints description |
| **Technology in Relationships** | "Foreign key user_id references users.id; Join table user_roles" | "User (1:N) Order; User (M:N) Role" with cardinality descriptions |

## Confidence Scoring

| Factor | Points | Criteria |
|--------|--------|----------|
| Entity Coverage | 0-30 | All entities: 30, Most: 20, Gaps: 10 |
| Relationship Clarity | 0-25 | All documented: 25, Most clear: 15, Ambiguous: 5 |
| Data Ownership | 0-25 | Clear boundaries: 25, Minor overlaps: 15, Unclear: 5 |
| Constraint Completeness | 0-20 | All rules: 20, Common cases: 12, Minimal: 5 |

**Action:** 80+ autonomous generation | 50-79 present options | <50 ask clarifying questions

## After Approval

1. ✅ Lock data model - entity structure is now reference
2. 🎯 Use model as input for Dependency Map (`pre-dev-dependency-map`)
3. 🚫 Never add database specifics retroactively
4. 📋 Keep technology-agnostic until Dependency Map

## The Bottom Line

**If you wrote SQL schemas or ORM code, delete it and model abstractly.**

Data modeling is conceptual. Period. No database products. No SQL. No ORMs.

Database technology goes in Dependency Map. That's the next phase. Wait for it.

**Model the data. Stay abstract. Choose database later.**
