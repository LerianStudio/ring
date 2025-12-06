---
name: pre-dev-api-design
description: |
  Gate 4: API contracts document - defines component interfaces and data contracts
  before protocol/technology selection. Large Track only.

trigger: |
  - TRD passed Gate 3 validation
  - System has multiple components that need to integrate
  - Building APIs (internal or external)
  - Large Track workflow (2+ day features)

skip_when: |
  - Small Track workflow → skip to Task Breakdown
  - Single component system → skip to Data Model
  - TRD not validated → complete Gate 3 first

sequence:
  after: [pre-dev-trd-creation]
  before: [pre-dev-data-model]
---

# API/Contract Design - Defining Component Interfaces

## Foundational Principle

**Component contracts and interfaces must be defined before technology/protocol selection.**

Jumping to implementation without contract definition creates:
- Integration failures discovered during development
- Inconsistent data structures across components
- Teams blocked waiting for interface clarity
- Rework when assumptions about contracts differ
- No clear integration test boundaries

**The API Design answers**: WHAT data/operations components expose and consume?
**The API Design never answers**: HOW those are implemented (protocols, serialization, specific tech).

## When to Use This Skill

Use this skill when:
- TRD has passed Gate 3 validation
- System has multiple components that need to integrate
- Building APIs (internal or external)
- Microservices, modular monoliths, or distributed systems
- Need clear contracts for parallel development

## Mandatory Workflow

### Phase 1: Contract Analysis (Inputs Required)
1. **Approved TRD** (Gate 3 passed) - architecture patterns defined
2. **Approved Feature Map** (Gate 2 passed) - feature interactions mapped
3. **Approved PRD** (Gate 1 passed) - business requirements locked
4. **Identify integration points** from TRD component diagram
5. **Extract data flows** from Feature Map

### Phase 2: Contract Definition
For each component interface:
1. **Define operations** (what actions can be performed)
2. **Specify inputs** (what data is required)
3. **Specify outputs** (what data is returned)
4. **Define errors** (what failure cases exist)
5. **Document events** (what notifications are sent)
6. **Set constraints** (validation rules, rate limits)
7. **Version contracts** (how changes are managed)

### Phase 3: Gate 4 Validation
**MANDATORY CHECKPOINT** - Must pass before proceeding to Data Modeling:
- [ ] All TRD component interactions have contracts
- [ ] Operations are clearly named and described
- [ ] Inputs/outputs are fully specified
- [ ] Error scenarios are documented
- [ ] Events are defined with schemas
- [ ] Constraints are explicit (validation, limits)
- [ ] Versioning strategy is defined
- [ ] No protocol specifics (REST/gRPC/GraphQL)
- [ ] No technology implementations

## Explicit Rules

### ✅ DO Include in API Design
- Operation names and descriptions
- Input parameters (name, type, required/optional, constraints)
- Output structure (fields, types, nullable)
- Error codes and descriptions
- Event types and payloads
- Validation rules (format, ranges, patterns)
- Rate limits or quota policies
- Idempotency requirements
- Authentication/authorization needs (abstract)
- Contract versioning strategy

### ❌ NEVER Include in API Design
- HTTP verbs (GET/POST/PUT) or REST specifics
- gRPC/GraphQL/WebSocket protocol details
- URL paths or route definitions
- Serialization formats (JSON/Protobuf/Avro)
- Framework-specific code (middleware, decorators)
- Database queries or ORM code
- Infrastructure (load balancers, API gateways)
- Specific authentication libraries (JWT libraries, OAuth packages)

### Abstraction Rules
1. **Operation**: Say "CreateUser" not "POST /api/v1/users"
2. **Data Type**: Say "EmailAddress (validated)" not "string with regex"
3. **Error**: Say "UserAlreadyExists" not "HTTP 409 Conflict"
4. **Auth**: Say "Requires authenticated user" not "JWT Bearer token"
5. **Format**: Say "ISO8601 timestamp" not "time.RFC3339"

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "REST is obvious, just document endpoints" | Protocol choice goes in Dependency Map. Define contracts abstractly. |
| "We need HTTP codes for errors" | Error semantics matter; HTTP codes are protocol. Abstract the errors. |
| "Teams need to see JSON examples" | JSON is serialization. Define structure; format comes later. |
| "The contract IS the OpenAPI spec" | OpenAPI is protocol-specific. Design contracts first, generate specs later. |
| "gRPC/GraphQL affects the contract" | Protocols deliver contracts. Design protocol-agnostic contracts first. |
| "We already know it's REST" | Knowing doesn't mean documenting prematurely. Stay abstract. |
| "Framework validates inputs" | Validation logic is universal. Document rules; implementation comes later. |
| "This feels redundant with TRD" | TRD = components exist. API = how they talk. Different concerns. |
| "URL structure matters for APIs" | URLs are HTTP-specific. Focus on operations and data. |
| "But API Design means REST API" | API = interface. Could be REST, gRPC, events, or in-process. Stay abstract. |

## Red Flags - STOP

If you catch yourself writing any of these in API Design, **STOP**:

- HTTP methods (GET, POST, PUT, DELETE, PATCH)
- URL paths (/api/v1/users, /users/{id})
- Protocol names (REST, GraphQL, gRPC, WebSocket)
- Status codes (200, 404, 500)
- Serialization formats (JSON, XML, Protobuf)
- Authentication tokens (JWT, OAuth2 tokens, API keys)
- Framework code (Express routes, gRPC service definitions)
- Transport mechanisms (HTTP/2, TCP, UDP)

**When you catch yourself**: Replace protocol detail with abstract contract. "POST /users" → "CreateUser operation"

## Gate 4 Validation Checklist

Before proceeding to Data Modeling, verify:

**Contract Completeness**:
- [ ] All component-to-component interactions have contracts
- [ ] All external system integrations have contracts
- [ ] All event/message contracts are defined
- [ ] Client-facing APIs are fully specified

**Operation Clarity**:
- [ ] Each operation has clear purpose and description
- [ ] Operation names follow consistent naming convention
- [ ] Idempotency requirements are documented
- [ ] Batch operations are identified where relevant

**Data Specification**:
- [ ] All input parameters are typed and documented
- [ ] Required vs. optional is explicit
- [ ] Output structures are complete
- [ ] Null/empty cases are handled

**Error Handling**:
- [ ] All error scenarios are identified
- [ ] Error codes/types are defined
- [ ] Error messages provide actionable guidance
- [ ] Retry/recovery strategies are documented

**Event Contracts**:
- [ ] All events are named and described
- [ ] Event payloads are fully specified
- [ ] Event ordering/delivery semantics documented
- [ ] Event versioning strategy defined

**Constraints & Policies**:
- [ ] Validation rules are explicit (format, range, pattern)
- [ ] Rate limits or quotas are defined
- [ ] Timeouts and deadlines are specified
- [ ] Backward compatibility strategy exists

**Technology Agnostic**:
- [ ] No protocol-specific details (REST/gRPC/etc)
- [ ] No serialization format specifics
- [ ] No framework or library names
- [ ] Can implement in any protocol

**Gate Result**:
- ✅ **PASS**: All checkboxes checked → Proceed to Data Modeling
- ⚠️ **CONDITIONAL**: Remove protocol details → Re-validate
- ❌ **FAIL**: Incomplete contracts → Add missing specifications

## Contract Template

```markdown
# API/Contract Design: [Project/Feature Name]

## Overview
- **TRD Reference**: [Link to approved TRD]
- **Feature Map Reference**: [Link to approved Feature Map]
- **Last Updated**: [Date]
- **Status**: Draft / Under Review / Approved

## Contract Versioning Strategy
- **Approach**: [e.g., Semantic versioning, Date-based, etc.]
- **Backward Compatibility**: [Policy for breaking changes]
- **Deprecation Process**: [How old contracts are sunset]

## Component Contracts

### Component: [Component Name]
**Purpose**: [What this component does - from TRD]

**Integration Points** (from TRD):
- Inbound: [Components that call this one]
- Outbound: [Components this one calls]

---

#### Operation: [OperationName]

**Purpose**: [What this operation does]

**Inputs**:
| Parameter | Type | Required | Constraints | Description |
|-----------|------|----------|-------------|-------------|
| userId | Identifier | Yes | Non-empty, UUID format | Unique user identifier |
| email | EmailAddress | Yes | Valid email format | User's email address |
| displayName | String | No | 3-50 chars, alphanumeric | Public display name |
| preferences | PreferenceSet | No | - | User preferences object |

**Input Validation Rules**:
- `email` must match pattern: `[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}`
- `displayName` must not contain profanity (filter list: [reference])
- `preferences.theme` must be one of: ["light", "dark", "auto"]

**Outputs** (Success):
| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| userId | Identifier | No | Created user's unique ID |
| createdAt | Timestamp | No | ISO8601 timestamp of creation |
| status | UserStatus | No | Account status: "active" | "pending_verification" |

**Output Structure Example** (abstract):
```
UserCreatedResponse {
  userId: Identifier
  createdAt: Timestamp
  status: UserStatus
}
```

**Errors**:
| Error Code | Condition | Description | Retry? |
|------------|-----------|-------------|--------|
| InvalidEmail | Email format invalid | Provided email doesn't match format | No |
| EmailAlreadyExists | Email in use | Account with this email exists | No |
| RateLimitExceeded | Too many requests | Max 5 creates per hour per IP | Yes, after delay |
| ServiceUnavailable | Downstream failure | Dependency unavailable | Yes, with backoff |

**Idempotency**:
- Idempotent if called with same `email` within 5 minutes
- Returns existing user if already created

**Authorization**:
- Requires: Anonymous (public operation)
- Rate limited: 5 requests per hour per IP

**Related Operations**:
- Triggers Event: `UserCreated` (see Events section)
- May call: `SendVerificationEmail` (async)

---

#### Operation: [AnotherOperationName]
[Same structure as above]

---

## Event Contracts

### Event: UserCreated

**Purpose**: Notifies system that new user account was created

**When Emitted**: After successful user creation, before returning response

**Payload**:
| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| eventId | Identifier | No | Unique event identifier |
| timestamp | Timestamp | No | ISO8601 event timestamp |
| userId | Identifier | No | Created user's ID |
| email | EmailAddress | No | User's email (for notifications) |
| source | String | No | Registration source: "web" | "mobile" | "api" |

**Payload Structure Example** (abstract):
```
UserCreatedEvent {
  eventId: Identifier
  timestamp: Timestamp
  userId: Identifier
  email: EmailAddress
  source: String
}
```

**Consumers**:
- Email Service (sends welcome email)
- Analytics Service (tracks signups)
- Audit Log Service (records event)

**Delivery Semantics**:
- At-least-once delivery
- Consumers must handle duplicates (idempotency required)

**Ordering**:
- No guaranteed ordering with other events
- Events for same `userId` are ordered

**Retention**:
- Events retained for 30 days in event store

---

### Event: [AnotherEvent]
[Same structure as above]

---

## Cross-Component Integration Contracts

### Integration: User Service → Email Service

**Purpose**: Send transactional emails to users

**Operations Used**:
- `SendEmail` (async, fire-and-forget)
- `GetEmailStatus` (query email delivery status)

**Contract Reference**: See Email Service component contracts

**Data Flow**:
```
UserService --[UserCreated event]--> EventBroker --[subscribe]--> EmailService
EmailService --[SendEmail operation]--> EmailProvider
```

**Error Handling**:
- Email Service failures do NOT block User Service operations
- Retries handled by Email Service (3 attempts, exponential backoff)
- Dead-letter queue for permanent failures

---

### Integration: [Another Integration]
[Same structure as above]

---

## External System Contracts

### External System: Payment Gateway

**Purpose**: Process payments for user subscriptions

**Operations Exposed to Us**:
- `InitiatePayment`: Start payment transaction
- `CheckPaymentStatus`: Query transaction status
- `RefundPayment`: Reverse transaction

**Operations We Expose to Them**:
- `PaymentWebhook`: Receive payment status updates

**Contract Details**:

#### Operation: InitiatePayment (We call Them)

**Inputs**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| transactionId | Identifier | Yes | Our internal transaction ID |
| amount | MonetaryAmount | Yes | Amount in smallest currency unit (cents) |
| currency | CurrencyCode | Yes | ISO 4217 code (USD, EUR, etc.) |
| customerEmail | EmailAddress | Yes | Customer's email for receipt |

**Outputs**:
| Field | Type | Description |
|-------|------|-------------|
| paymentId | Identifier | Gateway's payment ID (store for status checks) |
| redirectUrl | URL | URL to redirect user for payment |
| expiresAt | Timestamp | Payment link expiration |

**Errors**:
| Error Code | Description |
|------------|-------------|
| InvalidAmount | Amount out of acceptable range |
| UnsupportedCurrency | Currency not supported |
| GatewayUnavailable | External service down |

---

#### Operation: PaymentWebhook (They call Us)

**Purpose**: Receive async payment status updates

**Inputs**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| paymentId | Identifier | Yes | Gateway's payment ID |
| status | PaymentStatus | Yes | "succeeded" | "failed" | "pending" |
| transactionId | Identifier | Yes | Our transaction ID (from InitiatePayment) |
| timestamp | Timestamp | Yes | Status update timestamp |
| signature | String | Yes | HMAC signature for verification |

**Outputs**:
| Field | Type | Description |
|-------|------|-------------|
| acknowledged | Boolean | Always true (confirms receipt) |

**Security**:
- Must verify HMAC signature before processing
- Signature algorithm: HMAC-SHA256
- Secret key: [stored in secrets management]

**Idempotency**:
- Must handle duplicate webhooks (same paymentId + status)
- Store processed webhook IDs for deduplication

---

## Data Type Definitions

### Custom Types

#### EmailAddress
- **Base Type**: String
- **Format**: Valid email format per RFC 5322
- **Constraints**: Max 254 characters, case-insensitive
- **Example**: "user@example.com"

#### Identifier
- **Base Type**: String
- **Format**: UUID v4
- **Constraints**: Non-empty, immutable
- **Example**: "550e8400-e29b-41d4-a716-446655440000"

#### Timestamp
- **Base Type**: String
- **Format**: ISO 8601 with timezone
- **Constraints**: UTC timezone, millisecond precision
- **Example**: "2025-10-23T16:45:00.123Z"

#### MonetaryAmount
- **Base Type**: Integer
- **Format**: Amount in smallest currency unit (cents, pence, etc.)
- **Constraints**: Non-negative, max value 9,223,372,036,854,775,807
- **Example**: 1999 (represents $19.99)

#### CurrencyCode
- **Base Type**: String
- **Format**: ISO 4217 three-letter code
- **Constraints**: Uppercase, exactly 3 characters
- **Example**: "USD", "EUR", "GBP"

#### UserStatus
- **Base Type**: Enum
- **Values**: "active", "suspended", "deleted", "pending_verification"
- **Description**: Current account status

---

## Naming Conventions

**Operations**:
- Use verb + noun format: `CreateUser`, `GetPayment`, `UpdateProfile`
- Be specific: `ArchiveUser` instead of `DeleteUser` if soft-delete

**Parameters**:
- Use camelCase: `userId`, `createdAt`, `displayName`
- Be descriptive: `subscriptionExpiresAt` not `expiry`
- Boolean parameters: prefix with `is`/`has`: `isActive`, `hasPermission`

**Events**:
- Use past tense: `UserCreated`, `PaymentProcessed`, `OrderShipped`
- Include entity: `OrderShipped` not just `Shipped`

**Errors**:
- Use noun + condition: `ResourceNotFound`, `InvalidInput`, `RateLimitExceeded`
- Be specific: `EmailAlreadyExists` not `DuplicateError`

---

## Rate Limiting & Quotas

### Per-Operation Limits

| Operation | Limit | Window | Scope |
|-----------|-------|--------|-------|
| CreateUser | 5 requests | 1 hour | Per IP address |
| GetUserProfile | 100 requests | 1 minute | Per user |
| UpdateProfile | 10 requests | 1 minute | Per user |
| SendPasswordReset | 3 requests | 1 hour | Per email |

### Quota Policies
- Free tier: 1,000 API calls per day
- Pro tier: 100,000 API calls per day
- Enterprise: Custom limits

### Exceeded Limit Behavior
- Return error: `RateLimitExceeded`
- Include retry info: `retryAfter` timestamp
- Do NOT process request

---

## Backward Compatibility Strategy

### Breaking Changes
**Definition**: Changes that require consumers to update
- Removing fields from outputs
- Adding required parameters to inputs
- Changing data types
- Renaming operations

**Process**:
1. Announce deprecation 90 days in advance
2. Support old + new contract in parallel
3. Monitor old contract usage
4. Remove old contract after 180 days

### Non-Breaking Changes
**Definition**: Changes consumers can ignore
- Adding optional parameters
- Adding new fields to outputs
- Adding new operations
- Adding new error codes

**Process**:
- Deploy immediately
- Document in changelog
- No consumer updates required

---

## Testing Contracts

### Contract Testing Strategy
- Use contract testing tools (language-agnostic)
- Provider tests verify contract implementation
- Consumer tests verify contract usage
- CI/CD validates contracts haven't broken

### Example Test Scenarios
**CreateUser Operation**:
- ✓ Valid input creates user successfully
- ✓ Duplicate email returns `EmailAlreadyExists`
- ✓ Invalid email returns `InvalidEmail`
- ✓ Missing required field returns `InvalidInput`
- ✓ Rate limit exceeded returns `RateLimitExceeded`
- ✓ Success emits `UserCreated` event

---

## Gate 4 Validation

**Validation Date**: [Date]
**Validated By**: [Person/team]

- [ ] All component contracts defined
- [ ] All operations have inputs/outputs
- [ ] Error scenarios documented
- [ ] Events fully specified
- [ ] External integrations covered
- [ ] No protocol specifics included
- [ ] Ready for Data Modeling (Gate 5)

**Approval**: ☐ Approved | ☐ Needs Revision | ☐ Rejected
**Next Step**: Proceed to Data Modeling (`pre-dev-data-model`)
```

## Common Violations and Fixes

### Violation 1: Protocol-Specific Details
❌ **Wrong**:
```markdown
#### Operation: CreateUser
**Endpoint**: POST /api/v1/users
**Status Codes**:
- 201 Created
- 409 Conflict (email exists)
- 400 Bad Request
```

✅ **Correct**:
```markdown
#### Operation: CreateUser
**Purpose**: Create new user account

**Inputs**: [userId, email, displayName]
**Outputs**: UserCreatedResponse
**Errors**:
- EmailAlreadyExists (email in use)
- InvalidInput (validation failure)
```

### Violation 2: Implementation in Contract
❌ **Wrong**:
```markdown
**Validation**:
```javascript
if (!/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/.test(email)) {
  throw new ValidationError("Invalid email");
}
```
```

✅ **Correct**:
```markdown
**Validation Rules**:
- `email` must match email format per RFC 5322
- Pattern: local@domain.tld
- Max length: 254 characters
```

### Violation 3: Technology-Specific Types
❌ **Wrong**:
```markdown
**Output**:
```json
{
  "userId": "uuid",
  "createdAt": "Date",
  "profile": "Map<String, Any>"
}
```
```

✅ **Correct**:
```markdown
**Outputs**:
| Field | Type | Description |
|-------|------|-------------|
| userId | Identifier | UUID format |
| createdAt | Timestamp | ISO8601 timestamp |
| profile | ProfileObject | User profile data |
```

## Confidence Scoring

Use this to adjust your interaction with the user:

```yaml
Confidence Factors:
  Contract Completeness: [0-30]
    - All operations documented: 30
    - Most operations covered: 20
    - Significant gaps: 10

  Interface Clarity: [0-25]
    - Clear, unambiguous contracts: 25
    - Some interpretation needed: 15
    - Vague or conflicting: 5

  Integration Complexity: [0-25]
    - Simple point-to-point: 25
    - Moderate dependencies: 15
    - Complex orchestration: 5

  Error Handling Coverage: [0-20]
    - All scenarios documented: 20
    - Common cases covered: 12
    - Minimal coverage: 5

Total: [0-100]

Action:
  80+: Generate complete contracts autonomously
  50-79: Present options for user selection
  <50: Ask clarifying questions about integration needs
```

## Output Location

**Always output to**: `docs/pre-dev/{feature-name}/api-design.md`

## After API Design Approval

1. ✅ Lock the contracts - interfaces are now reference for implementation
2. 🎯 Use contracts as input for Data Modeling (next phase: `pre-dev-data-model`)
3. 🚫 Never add protocol specifics to contracts retroactively
4. 📋 Keep contracts technology-agnostic until Dependency Map

## Quality Self-Check

Before declaring API Design complete, verify:
- [ ] All TRD integration points have contracts
- [ ] Operations are clearly named and described
- [ ] Inputs are fully specified (type, required, constraints)
- [ ] Outputs are complete (all fields documented)
- [ ] Error scenarios are comprehensive
- [ ] Events have full payload specifications
- [ ] Validation rules are explicit
- [ ] Rate limits are defined
- [ ] Idempotency is documented where relevant
- [ ] Zero protocol specifics (REST/gRPC/etc)
- [ ] Zero implementation code
- [ ] Contracts are testable
- [ ] Backward compatibility strategy exists
- [ ] Gate 4 validation checklist 100% complete

## The Bottom Line

**If you wrote API contracts with HTTP endpoints or gRPC services, remove them.**

Contracts are protocol-agnostic. Period. No REST. No GraphQL. No HTTP codes.

Protocol choices go in Dependency Map. That's a later phase. Wait for it.

Violating this separation means:
- You're locked into a protocol before evaluating alternatives
- Contracts can't be reused across different delivery mechanisms
- You can't objectively compare REST vs. gRPC vs. messaging
- Teams can't work in parallel with clear interface agreements

**Define the contract. Stay abstract. Choose protocol later.**
