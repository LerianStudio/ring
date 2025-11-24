---
name: pre-dev-data-model
description: Use after API/Contract Design to define data structures and relationships, before selecting databases, when you need clear data ownership and schemas
---

# Data Modeling - Defining Data Structures

## Foundational Principle

**Data structures, relationships, and ownership must be defined before database technology selection.**

Jumping to database-specific schemas without modeling creates:
- Inconsistent data structures across services
- Unclear data ownership and authority
- Schema conflicts discovered during development
- Migration nightmares when requirements change
- Performance issues from poor data design

**The Data Model answers**: WHAT data exists, HOW entities relate, WHO owns what data?
**The Data Model never answers**: WHICH database technology or HOW to implement storage.

## When to Use This Skill

Use this skill when:
- API Design has passed Gate 4 validation
- TRD has passed Gate 3 validation
- System stores persistent data
- Multiple entities with relationships
- Need clear data ownership boundaries
- Building data-intensive applications

## Mandatory Workflow

### Phase 1: Data Analysis (Inputs Required)
1. **Approved API Design** (Gate 4 passed) - contracts define data flows
2. **Approved TRD** (Gate 3 passed) - architecture components identified
3. **Approved Feature Map** (Gate 2 passed) - domains defined
4. **Approved PRD** (Gate 1 passed) - business requirements locked
5. **Extract entities** from PRD, Feature Map, and API contracts
6. **Identify relationships** between entities

### Phase 2: Data Modeling
1. **Define entities** (what data objects exist)
2. **Specify attributes** (what properties each entity has)
3. **Model relationships** (how entities connect)
4. **Assign ownership** (which component owns which data)
5. **Define constraints** (uniqueness, required fields, ranges)
6. **Plan data lifecycle** (creation, updates, deletion, archival)
7. **Design access patterns** (how data will be queried)
8. **Consider data quality** (validation, normalization)

### Phase 3: Gate 5 Validation
**MANDATORY CHECKPOINT** - Must pass before proceeding to Dependency Map:
- [ ] All entities are identified and defined
- [ ] Entity attributes are complete with types and constraints
- [ ] Relationships between entities are modeled
- [ ] Data ownership is explicitly assigned to components
- [ ] Primary identifiers are defined
- [ ] Unique constraints are specified
- [ ] Required vs. optional fields are clear
- [ ] Data lifecycle is documented
- [ ] Access patterns are identified
- [ ] No database-specific details (tables, indexes, SQL)
- [ ] No ORM or storage technology specifics

## Explicit Rules

### ✅ DO Include in Data Model
- Entity definitions (conceptual data objects)
- Attributes with types (string, number, boolean, date, etc.)
- Constraints (required, unique, ranges, patterns)
- Relationships (one-to-one, one-to-many, many-to-many)
- Data ownership (which component is authoritative)
- Primary identifiers (how entities are uniquely identified)
- Lifecycle rules (soft delete, archival, retention)
- Access patterns (how data will be queried)
- Data quality rules (validation, normalization)
- Referential integrity requirements

### ❌ NEVER Include in Data Model
- Database product names (PostgreSQL, MongoDB, Redis)
- Table names or collection names
- Index definitions
- SQL or query language specifics
- ORM frameworks (Prisma, TypeORM, SQLAlchemy)
- Storage engine specifics (InnoDB, MyISAM)
- Partitioning or sharding strategies (implementation detail)
- Replication or backup strategies
- Database-specific data types (JSONB, UUID, BIGSERIAL)

### Abstraction Rules
1. **Entity**: Say "User" not "users table"
2. **Attribute**: Say "emailAddress: String (email format)" not "email VARCHAR(255)"
3. **Relationship**: Say "User has many Orders" not "foreign key user_id"
4. **Identifier**: Say "Unique identifier" not "UUID primary key"
5. **Constraint**: Say "Must be unique" not "UNIQUE INDEX"

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

Before proceeding to Dependency Map, verify:

**Entity Completeness**:
- [ ] All entities from PRD/Feature Map are modeled
- [ ] Entity names are clear and consistent
- [ ] Each entity has defined purpose
- [ ] Entity boundaries align with component ownership (from TRD)

**Attribute Specification**:
- [ ] All attributes have types specified
- [ ] Required vs. optional is explicit
- [ ] Constraints are documented (unique, range, format)
- [ ] Default values are specified where relevant
- [ ] Computed/derived fields are identified

**Relationship Modeling**:
- [ ] All relationships between entities are documented
- [ ] Cardinality is specified (one-to-one, one-to-many, many-to-many)
- [ ] Optional vs. required relationships are clear
- [ ] Referential integrity needs are documented
- [ ] Circular dependencies are identified and resolved

**Data Ownership**:
- [ ] Each entity is owned by exactly one component
- [ ] Read/write permissions are documented
- [ ] Cross-component data access is via APIs (from Gate 4)
- [ ] No shared database anti-pattern

**Data Quality**:
- [ ] Validation rules are specified
- [ ] Normalization level is appropriate
- [ ] Denormalization decisions are justified
- [ ] Data consistency strategy is defined (eventual vs. strong)

**Lifecycle Management**:
- [ ] Creation rules are documented
- [ ] Update patterns are defined
- [ ] Deletion strategy is specified (hard vs. soft delete)
- [ ] Archival and retention policies exist
- [ ] Audit trail needs are identified

**Access Patterns**:
- [ ] Primary access patterns are documented
- [ ] Query needs are identified (lookups, searches, aggregations)
- [ ] Write patterns are documented (create, update, delete frequencies)
- [ ] Consistency requirements are specified

**Technology Agnostic**:
- [ ] No database product names
- [ ] No SQL or NoSQL specifics
- [ ] No table/collection/index definitions
- [ ] Can implement in any database technology

**Gate Result**:
- ✅ **PASS**: All checkboxes checked → Proceed to Dependency Map
- ⚠️ **CONDITIONAL**: Remove DB specifics or add missing entities → Re-validate
- ❌ **FAIL**: Incomplete model or poor ownership → Rework

## Data Model Template

```markdown
# Data Model: [Project/Feature Name]

## Overview
- **API Design Reference**: [Link to Gate 4 API contracts]
- **TRD Reference**: [Link to Gate 3 TRD]
- **Feature Map Reference**: [Link to Gate 2 Feature Map]
- **Last Updated**: [Date]
- **Status**: Draft / Under Review / Approved

## Data Ownership Map

| Entity | Owning Component (from TRD) | Read Access | Write Access |
|--------|------------------------------|-------------|--------------|
| User | User Service | All components | User Service only |
| Order | Order Service | User, Payment, Fulfillment | Order Service only |
| Payment | Payment Service | Order, Billing | Payment Service only |
| Product | Catalog Service | All components | Catalog Service only |

**Principle**: Each entity has exactly ONE authoritative owner. Cross-component access via APIs only.

---

## Entity Definitions

### Entity: User

**Purpose**: Represents a system user account

**Owned By**: User Service (from TRD)

**Primary Identifier**: userId (Unique identifier, immutable)

**Attributes**:
| Attribute | Type | Required | Unique | Constraints | Description |
|-----------|------|----------|--------|-------------|-------------|
| userId | Identifier | Yes | Yes | Immutable, UUID format | Unique user identifier |
| email | EmailAddress | Yes | Yes | Valid email format, max 254 chars | Primary email |
| displayName | String | No | No | 3-50 chars, alphanumeric + spaces | Public name |
| passwordHash | String | Yes | No | Hashed value only, never store plain text | Authentication credential |
| accountStatus | UserStatus | Yes | No | One of: active, suspended, deleted, pending | Current status |
| emailVerified | Boolean | Yes | No | Default: false | Email verification status |
| createdAt | Timestamp | Yes | No | Immutable, ISO8601 | Account creation time |
| updatedAt | Timestamp | Yes | No | Auto-updated on changes | Last modification time |
| lastLoginAt | Timestamp | No | No | ISO8601 | Most recent login time |

**Constraints**:
- `email` must be unique across all users
- `displayName` is optional but recommended (prompt user during registration)
- `passwordHash` must never be returned in API responses
- `accountStatus` transitions: pending → active, active → suspended → active, active → deleted (final)

**Lifecycle**:
- **Creation**: Via `CreateUser` API operation (Gate 4 contract)
- **Updates**: Via `UpdateUserProfile`, `ChangePassword`, `UpdateStatus` operations
- **Deletion**: Soft delete (set `accountStatus = deleted`, retain data for 90 days)
- **Archival**: Hard delete after 90 days of soft delete

**Access Patterns**:
- Lookup by `userId` (primary pattern, most frequent)
- Lookup by `email` (login flow, unique constraint)
- List users by `accountStatus` (admin operations)
- Search by `displayName` (user search feature)

**Data Quality**:
- `email` is normalized to lowercase before storage
- `displayName` is trimmed of leading/trailing whitespace
- `passwordHash` uses industry-standard hashing (algorithm TBD in Dependency Map)

---

### Entity: Order

**Purpose**: Represents a customer order

**Owned By**: Order Service (from TRD)

**Primary Identifier**: orderId (Unique identifier, immutable)

**Attributes**:
| Attribute | Type | Required | Unique | Constraints | Description |
|-----------|------|----------|--------|-------------|-------------|
| orderId | Identifier | Yes | Yes | Immutable, UUID format | Unique order identifier |
| userId | Identifier | Yes | No | Must reference existing User | Customer who placed order |
| orderStatus | OrderStatus | Yes | No | One of: pending, confirmed, shipped, delivered, cancelled | Current status |
| totalAmount | MonetaryAmount | Yes | No | Non-negative, in smallest currency unit | Total order value |
| currency | CurrencyCode | Yes | No | ISO 4217 code | Currency for totalAmount |
| shippingAddress | Address | Yes | No | Valid address structure | Delivery destination |
| orderItems | List<OrderItem> | Yes | No | Min 1 item, max 100 items | Products in order |
| createdAt | Timestamp | Yes | No | Immutable, ISO8601 | Order creation time |
| updatedAt | Timestamp | Yes | No | Auto-updated on changes | Last modification time |

**Nested Types**:

#### OrderItem (embedded within Order)
| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| productId | Identifier | Yes | References Product entity |
| quantity | Integer | Yes | Min 1, max 999 |
| unitPrice | MonetaryAmount | Yes | Price per item at time of order |
| subtotal | MonetaryAmount | Yes | quantity × unitPrice |

#### Address (value object)
| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| street1 | String | Yes | Primary street address |
| street2 | String | No | Secondary address (apt, suite) |
| city | String | Yes | City name |
| state | String | Yes | State/province code |
| postalCode | String | Yes | Postal/ZIP code |
| country | String | Yes | ISO 3166-1 alpha-2 code |

**Relationships**:
- **User** (one-to-many): One User can have many Orders
- **Product** (via OrderItem): Order references Products (read-only, owned by Catalog Service)

**Constraints**:
- `totalAmount` must equal sum of all `orderItems[].subtotal` + shipping + tax
- `orderStatus` transitions: pending → confirmed → shipped → delivered
- `orderStatus` can go to cancelled from pending or confirmed only
- `orderItems` must contain at least 1 item
- All `productId` references must be valid at order creation time (validate via API)

**Lifecycle**:
- **Creation**: Via `CreateOrder` API operation
- **Updates**: Via `UpdateOrderStatus`, `CancelOrder` operations
- **Deletion**: Soft delete after 7 years (regulatory compliance)
- **Archival**: Orders never hard deleted (permanent record)

**Access Patterns**:
- Lookup by `orderId` (most frequent)
- List by `userId` (user order history)
- List by `orderStatus` (fulfillment workflows)
- Query by `createdAt` range (reporting, analytics)

**Data Quality**:
- `orderItems[].unitPrice` is snapshot at order time (price changes don't affect existing orders)
- `totalAmount` is computed and validated on creation
- `shippingAddress` is validated against address API before order creation

---

### Entity: [Another Entity]
[Same structure as above]

---

## Relationship Diagram

```
User (1) ──< has many >── (*) Order
                              │
                              │ contains
                              ↓
                            OrderItem (embedded)
                              │
                              │ references
                              ↓
                            Product (1)
                              │
                              │ belongs to
                              ↓
                            Category (1)

Payment (*) ──< processes >── (1) Order
```

**Legend**:
- `(1)`: One
- `(*)`: Many
- `──<`: One-to-many relationship
- `──`: One-to-one relationship
- Embedded: Data stored within parent entity

---

## Cross-Component Data Access

### User Service → Order Service

**Scenario**: User wants to view their order history

**Data Flow**:
1. User Service authenticates user (owns User entity)
2. User Service calls Order Service API: `GetOrdersByUserId(userId)`
3. Order Service returns order data (owns Order entity)
4. User Service enriches with user display name if needed

**Rules**:
- User Service does NOT access Order Service's data store directly
- All access via APIs (from Gate 4 contracts)
- Order Service is authoritative for Order data

---

### Order Service → Catalog Service

**Scenario**: Order creation needs product info

**Data Flow**:
1. Order Service receives `CreateOrder` request
2. Order Service calls Catalog Service API: `GetProduct(productId)`
3. Catalog Service returns product data (price, availability)
4. Order Service creates order with snapshot of product data

**Rules**:
- Order stores `productId` reference and price snapshot
- Catalog Service is authoritative for current Product data
- Order's product snapshot is immutable (historical record)

---

### [Another Cross-Component Access]
[Same structure]

---

## Data Consistency Strategy

### Strong Consistency (Immediate)
- User authentication (must be immediately consistent)
- Payment transactions (cannot tolerate eventual consistency)
- Inventory deductions (prevent overselling)

### Eventual Consistency (Acceptable Delay)
- User profile updates reflecting in analytics (delay OK)
- Order history in user dashboard (few seconds lag acceptable)
- Search indexes (brief staleness tolerable)

### Consistency Implementation**:
- Strong: Synchronous API calls with transactional guarantees
- Eventual: Async events with idempotent handlers

---

## Data Validation Rules

### User Entity Validation
- `email`: Must match RFC 5322 format
- `displayName`: No profanity (filter list: [reference])
- `passwordHash`: Must meet complexity requirements (min 12 chars, mixed case, numbers, symbols)

### Order Entity Validation
- `totalAmount`: Must match sum of items + fees
- `orderItems`: Each `productId` must exist in Catalog Service at order time
- `shippingAddress`: Must pass address validation API

### Cross-Entity Validation
- User must have `accountStatus = active` to create orders
- Products must have `availability > 0` to be added to orders

---

## Data Lifecycle Policies

### Retention Periods
| Entity | Active Period | Archive After | Delete After |
|--------|---------------|---------------|--------------|
| User | Until deleted | 90 days (soft delete) | 90 days after soft delete |
| Order | Permanent | N/A | Never (regulatory) |
| Payment | 7 years | 7 years | 10 years (compliance) |
| AuditLog | 1 year | 1 year | 5 years |

### Soft Delete Strategy
- **User**: Set `accountStatus = deleted`, retain data for GDPR compliance window
- **Order**: Never deleted (permanent financial record)
- **Payment**: Anonymize after 7 years (retain transaction, remove PII)

### Audit Trail Requirements
- **User**: Log all status changes, login attempts
- **Order**: Log all status transitions, modifications
- **Payment**: Log all transaction attempts, results

---

## Data Privacy & Compliance

### Personally Identifiable Information (PII)
| Entity | PII Fields | Handling |
|--------|-----------|----------|
| User | email, displayName | Encrypted at rest, GDPR right to deletion |
| Order | shippingAddress | Encrypted at rest, retention per policy |
| Payment | card details | Never stored (use tokenization) |

### GDPR Compliance
- Users can request data export (via `ExportUserData` API)
- Users can request deletion (soft delete with 90-day grace period)
- Consent tracking for marketing communications

### Data Encryption
- Sensitive fields encrypted at rest (algorithm TBD in Dependency Map)
- Encryption keys managed externally (key management TBD in Dependency Map)

---

## Access Pattern Analysis

### High-Frequency Patterns (Optimize for these)
1. **User lookup by ID**: `GetUser(userId)` - 1000 req/sec
2. **Order lookup by ID**: `GetOrder(orderId)` - 500 req/sec
3. **User's orders**: `GetOrdersByUserId(userId)` - 200 req/sec

### Medium-Frequency Patterns
4. **User lookup by email**: `GetUserByEmail(email)` - 50 req/sec (login)
5. **Orders by status**: `GetOrdersByStatus(status)` - 30 req/sec (fulfillment)

### Low-Frequency Patterns
6. **User search**: `SearchUsers(query)` - 5 req/sec (admin)
7. **Order reports**: `GetOrdersByDateRange(start, end)` - 1 req/hour (reporting)

**Optimization Notes** (for later, not now):
- High-frequency patterns need fast lookups (indexes, caching)
- Medium-frequency patterns need balanced design
- Low-frequency patterns can tolerate slower queries

---

## Data Quality Standards

### Normalization
- **User email**: Stored in lowercase, normalized form
- **Addresses**: Standardized format via address validation service
- **Phone numbers**: Stored in E.164 format

### Validation
- All inputs validated before storage
- Validation rules documented per attribute
- Failed validation returns clear error messages

### Data Integrity
- Referential integrity enforced (userId in Order must exist)
- Constraints enforced at model level (not just database)
- Data consistency checks in automated tests

---

## Migration & Evolution Strategy

### Schema Evolution
- **Additive changes**: Add optional fields (backward compatible)
- **Non-breaking**: Default values for new required fields
- **Breaking changes**: Versioned approach (v1 → v2 with migration)

### Data Migration
- Plan for zero-downtime migrations
- Backward and forward compatibility during migration
- Rollback strategy for failed migrations

### Versioning
- Entities can evolve over time
- Migration scripts documented (but not written here - that's implementation)
- Compatibility maintained during transitions

---

## Gate 5 Validation

**Validation Date**: [Date]
**Validated By**: [Person/team]

- [ ] All entities defined with complete attributes
- [ ] Relationships documented and valid
- [ ] Data ownership assigned to components
- [ ] Constraints and validation rules specified
- [ ] Lifecycle policies documented
- [ ] Access patterns identified
- [ ] No database-specific details included
- [ ] Ready for Dependency Map (Gate 6)

**Approval**: ☐ Approved | ☐ Needs Revision | ☐ Rejected
**Next Step**: Proceed to Dependency Map (`pre-dev-dependency-map`)
```

## Common Violations and Fixes

### Violation 1: Database-Specific Schema
❌ **Wrong**:
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

✅ **Correct**:
```markdown
### Entity: User
**Attributes**:
| Attribute | Type | Required | Unique | Description |
|-----------|------|----------|--------|-------------|
| userId | Identifier | Yes | Yes | Unique user identifier |
| email | EmailAddress | Yes | Yes | Primary email address |
| createdAt | Timestamp | Yes | No | Account creation time |
```

### Violation 2: ORM-Specific Code
❌ **Wrong**:
```typescript
@Entity()
class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;
}
```

✅ **Correct**:
```markdown
### Entity: User
**Primary Identifier**: userId (Unique identifier)
**Attributes**: userId, email, ...
**Constraints**: email must be unique
```

### Violation 3: Technology in Relationships
❌ **Wrong**:
```markdown
**Relationships**:
- Foreign key `user_id` references `users.id`
- Join table `user_roles` for many-to-many
```

✅ **Correct**:
```markdown
**Relationships**:
- User (one-to-many) Order: One user can have many orders
- User (many-to-many) Role: Users can have multiple roles, roles can be assigned to multiple users
```

## Confidence Scoring

Use this to adjust your interaction with the user:

```yaml
Confidence Factors:
  Entity Coverage: [0-30]
    - All entities modeled: 30
    - Most entities covered: 20
    - Significant gaps: 10

  Relationship Clarity: [0-25]
    - All relationships documented: 25
    - Most relationships clear: 15
    - Ambiguous connections: 5

  Data Ownership: [0-25]
    - Clear ownership boundaries: 25
    - Mostly clear with minor overlaps: 15
    - Unclear or contested: 5

  Constraint Completeness: [0-20]
    - All validation rules specified: 20
    - Common cases covered: 12
    - Minimal specification: 5

Total: [0-100]

Action:
  80+: Generate complete data model autonomously
  50-79: Present options for normalization/relationships
  <50: Ask clarifying questions about entity boundaries
```

## Output Location

**Always output to**: `docs/pre-development/data-model/data-model-[feature-name].md`

## After Data Model Approval

1. ✅ Lock the data model - entity structure is now reference
2. 🎯 Use data model as input for Dependency Map (next phase: `pre-dev-dependency-map`)
3. 🚫 Never add database specifics to data model retroactively
4. 📋 Keep data model technology-agnostic until Dependency Map

## Quality Self-Check

Before declaring Data Model complete, verify:
- [ ] All entities are defined with complete attributes
- [ ] Attribute types and constraints are specified
- [ ] Relationships are modeled with correct cardinality
- [ ] Data ownership is explicitly assigned
- [ ] Primary identifiers are defined
- [ ] Lifecycle policies are documented
- [ ] Access patterns are identified
- [ ] Validation rules are comprehensive
- [ ] Privacy/compliance needs are addressed
- [ ] Consistency strategy is defined
- [ ] Zero database-specific details (tables, SQL, indexes)
- [ ] Zero ORM or framework specifics
- [ ] Gate 5 validation checklist 100% complete

## The Bottom Line

**If you wrote SQL schemas or ORM code, delete it and model abstractly.**

Data modeling is conceptual. Period. No database products. No SQL. No ORMs.

Database technology goes in Dependency Map. That's the next phase. Wait for it.

Violating this separation means:
- You're locked into a database before evaluating alternatives
- Data model can't be reused across different database types
- You can't objectively compare relational vs. document vs. key-value
- Poor separation of concerns (conceptual vs. physical)

**Model the data. Stay abstract. Choose database later.**
