# Standards Discovery Pattern

**Reusable workflow for loading organizational naming standards.**

This pattern is used in:
- Gate 4 (API Design) → `api-standards-ref.md` (API field naming)
- Gate 5 (Data Model) → `db-standards-ref.md` (Database field naming)

---

## When to Use

**MANDATORY at the START of any gate that defines field names or data structures.**

Use AskUserQuestion to check for standards BEFORE defining contracts or schemas.

---

## Question Structure

```javascript
AskUserQuestion({
  questions: [{
    question: "Do you have a {CONTEXT} naming standards document to reference?",
    header: "{CONTEXT} Standards",
    multiSelect: false,
    options: [
      {
        label: "No - Use industry best practices",
        description: "Generate {OUTPUT} using standard conventions"
      },
      {
        label: "Yes - URL to document",
        description: "Provide a URL to your standards document"
      },
      {
        label: "Yes - File path",
        description: "Provide a local file path (.md, .json, .yaml, .csv)"
      }
    ]
  }]
});
```

**Variables:**
- `{CONTEXT}`: "API field" or "database schema" or "data dictionary"
- `{OUTPUT}`: "contracts" or "schemas" or "models"

---

## Loading Standards

### If "Yes - URL" Selected:

```
1. Use WebFetch tool
2. Parse document content
3. Extract standards (see extraction table below)
```

### If "Yes - File path" Selected:

```
1. Use Read tool
2. Support formats: .md (tables), .json (structured), .yaml (structured), .csv (tabular)
3. Extract standards (see extraction table below)
```

---

## Extraction Table

**MUST extract these elements if present:**

| Element | What to Extract | Example |
|---------|----------------|---------|
| **Naming convention** | camelCase, snake_case, PascalCase | API: `userId`, DB: `user_id` |
| **Standard field names** | Common fields across system | `createdAt`, `updatedAt`, `isActive` |
| **Data type formats** | How to represent dates, IDs, amounts | ISO8601, UUID v4, Decimal(10,2) |
| **Validation patterns** | Regex, constraints, rules | Email RFC 5322, phone E.164 |
| **Error code naming** | Organizational error conventions | `EMAIL_ALREADY_EXISTS` vs `DuplicateEmail` |
| **Pagination fields** | Standard query/response pagination | `items`, `limit`, `next_cursor`, `prev_cursor` (cursor) or `items`, `page`, `limit` (page-based) |

---

## Output Template

**File:** `docs/pre-dev/{feature-name}/{context}-standards-ref.md`

Where `{context}` is:
- `api` for Gate 4 (API Design)
- `db` for Gate 5 (Data Model)

**Format:**

```markdown
# {Context} Standards Reference - {Feature Name}

Source: {URL or file path}
Extracted: {ISO 8601 timestamp}
Context: {API layer / Database layer / etc}

## Naming Convention

**Primary pattern:** {camelCase / snake_case / PascalCase}

**Rules:**
- IDs: `{pattern}` (example: `userId`)
- Timestamps: `{pattern}` (example: `createdAt`)
- Booleans: `{pattern}` (example: `isActive`)
- Collections: `{pattern}` (example: `userList`)

## Standard Fields

| Field | Type | Format | Validation | Example |
|-------|------|--------|------------|---------|
| {name} | {type} | {format} | {rules} | {example} |

**Example:**
| Field | Type | Format | Validation | Example |
|-------|------|--------|------------|---------|
| userId | string | UUID v4 | Required, unique | "550e8400-e29b-41d4-a716-446655440000" |
| email | string | RFC 5322 | Required, unique, max 254 | "user@example.com" |
| createdAt | string | ISO 8601 | Auto-generated, immutable | "2026-01-23T10:30:00Z" |

## Validation Patterns

| Pattern Type | Rule | Example |
|-------------|------|---------|
| Email | RFC 5322, max 254 chars | "user@example.com" |
| Phone | E.164 format | "+5511987654321" |
| Password | Min 8 chars, 1 upper, 1 number | "SecureP@ss1" |

## Error Code Naming

**Pattern:** `{RESOURCE}_{CONDITION}` (UPPER_SNAKE_CASE)

| Code | Usage | When to Use |
|------|-------|------------|
| EMAIL_ALREADY_EXISTS | Duplicate email | Registration, email update |
| INVALID_INPUT | Validation failure | Any input validation |
| UNAUTHORIZED | Auth failure | Missing/invalid credentials |

## Pagination Standards (if applicable)

### Cursor-Based (preferred for high-volume)
| Field | Type | Description | Default |
|-------|------|-------------|---------|
| items | array | Result set for the current page | - |
| limit | integer | Items per page (max 100) | 10 |
| next_cursor | string | Opaque cursor to fetch the next page | - |
| prev_cursor | string | Opaque cursor to fetch the previous page | - |

### Page-Based (for low-volume entities)
| Field | Type | Description | Default |
|-------|------|-------------|---------|
| items | array | Result set for the current page | - |
| page | integer | 1-indexed page number | 1 |
| limit | integer | Items per page (max 100) | 10 |

## Cross-Layer Mapping (optional)

**If this is database standards and API standards exist:**

| API Field (camelCase) | DB Column (snake_case) | Type Mapping |
|-----------------------|------------------------|--------------|
| userId | user_id | string → uuid |
| createdAt | created_at | ISO8601 → timestamptz |
| isActive | is_active | boolean → boolean |
```

---

## Handling Conflicts

**If standards conflict with existing codebase patterns:**

Use AskUserQuestion:

```javascript
AskUserQuestion({
  questions: [{
    question: "Standards document says `{standard_pattern}`, but codebase uses `{existing_pattern}`. Which should we follow?",
    header: "Standards Conflict",
    multiSelect: false,
    options: [
      {
        label: "Follow standards",
        description: "Use organizational standards, refactor existing code later"
      },
      {
        label: "Follow codebase",
        description: "Maintain consistency with existing implementation"
      },
      {
        label: "Hybrid approach",
        description: "Let me decide per-field"
      }
    ]
  }]
});
```

---

## If "No" Selected (Best Practices)

**Document the default choice in the standards-ref file:**

```markdown
# {Context} Standards Reference - {Feature Name}

Source: Industry best practices (no organizational standards provided)
Extracted: {ISO 8601 timestamp}

## Naming Convention

**Using standard convention for {language/framework}:**

- JavaScript/TypeScript APIs: camelCase (`userId`, `createdAt`)
- Python/Ruby APIs: snake_case (`user_id`, `created_at`)
- Database (PostgreSQL/MySQL): snake_case (`user_id`, `created_at`)
- Database (MongoDB): camelCase (`userId`, `createdAt`)

## Standard Fields

[Include common fields like userId, email, createdAt, updatedAt, isActive, etc.]
```

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "No need to ask about standards" | Organizations have standards. Assuming = inconsistency. | **ASK via AskUserQuestion** |
| "User will mention if important" | User doesn't know when to mention. You must ask proactively. | **ASK at Phase 0** |
| "I'll use common sense" | "Common sense" varies by developer. Explicit > implicit. | **ASK for standards or document best practices** |
| "Skip for small features" | Small features become big systems. Standards matter always. | **ASK regardless of feature size** |
| "Codebase pattern is good enough" | Existing code might predate standards. Check org standards. | **ASK, then handle conflict** |

---

## Automatic Convention Conversion

**When reusing field names across layers (API → Database), automatic conversion may be needed.**

### Conversion Rules: camelCase → snake_case

| Pattern | Input (camelCase) | Output (snake_case) | Rule Applied |
|---------|-------------------|---------------------|--------------|
| **Simple** | `userId` | `user_id` | Insert `_` before capitals, lowercase |
| **Multiple words** | `createdAt` | `created_at` | Insert `_` before capitals, lowercase |
| **Boolean prefix** | `isActive` | `is_active` | Preserve prefix pattern |
| **Consecutive capitals** | `userID` | `user_id` | Treat as acronym (collapse to one capital) |
| **Three+ capitals** | `APIKey` | `api_key` | Treat as acronym |
| **Mid-word capitals** | `phoneNumber` | `phone_number` | Split at capital |

### Conversion Rules: snake_case → camelCase

| Pattern | Input (snake_case) | Output (camelCase) | Rule Applied |
|---------|--------------------|--------------------|--------------|
| **Simple** | `user_id` | `userId` | Capitalize after `_`, remove `_` |
| **Multiple words** | `created_at` | `createdAt` | Capitalize after each `_` |
| **Boolean prefix** | `is_active` | `isActive` | Keep `is` lowercase |
| **Acronyms** | `api_key` | `apiKey` | First word lowercase, rest camelCase |

### Implementation Example (JavaScript/TypeScript)

```javascript
// camelCase → snake_case
function toSnakeCase(str) {
  return str
    .replace(/([A-Z]+)([A-Z][a-z])/g, '$1_$2')  // APIKey → API_Key
    .replace(/([a-z\d])([A-Z])/g, '$1_$2')      // userId → user_Id
    .toLowerCase();                              // user_Id → user_id
}

// Examples:
toSnakeCase('userId')       // → 'user_id'
toSnakeCase('createdAt')    // → 'created_at'
toSnakeCase('isActive')     // → 'is_active'
toSnakeCase('userID')       // → 'user_id'
toSnakeCase('APIKey')       // → 'api_key'
toSnakeCase('phoneNumber')  // → 'phone_number'
```

---

## Usage Examples

### Gate 4 (API Design):

```markdown
## Phase 0: API Standards Discovery

See [shared-patterns/standards-discovery.md](../shared-patterns/standards-discovery.md) for complete workflow.

**Context:** API field naming standards
**Output:** `docs/pre-dev/{feature}/api-standards-ref.md`
```

### Gate 5 (Data Model) - NEW APPROACH:

```markdown
## Phase 0: Database Field Naming Strategy

**Different from Gate 4:** Don't ask for separate DB dictionary. Instead, ask if user wants to REUSE API field names with conversion.

**Question:** "Gate 4 defined API field names. How should database fields be named?"
**Options:**
1. Convert to snake_case (Recommended for SQL) - Uses automatic conversion
2. Keep same as API (camelCase) - No conversion needed
3. Different standards - Load separate DB dictionary
4. Define manually - No standards

See [shared-patterns/standards-discovery.md](../shared-patterns/standards-discovery.md) for:
- Automatic conversion rules (camelCase ↔ snake_case)
- Mapping table generation
- Complete workflow
```
