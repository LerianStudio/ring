---
name: writing-api-docs
description: |
  Patterns and structure for writing API reference documentation including
  endpoint descriptions, request/response schemas, and error documentation.
metadata:
  related:
    similar:
    - ring:writing-functional-docs
    complementary:
    - ring:api-field-descriptions
    - ring:documentation-structure
  sequence:
    before:
    - ring:documentation-review
  skip_when: |
    - Writing conceptual guides → use ring:writing-functional-docs
    - Reviewing documentation → use ring:documentation-review
    - Writing code → use dev-team agents
  trigger: |
    - Documenting REST API endpoints
    - Writing request/response examples
    - Documenting error codes
    - Creating API field descriptions
---

# Writing API Reference Documentation

API reference documentation describes what each endpoint does, its parameters, request/response formats, and error conditions. It focuses on the "what" rather than the "why."

## API Reference Principles

- **RESTful and Predictable:** Standard HTTP methods, consistent URL patterns, document idempotency
- **Consistent Formats:** JSON requests/responses, clear typing, standard error format
- **Explicit Versioning:** Version in URL path, backward compatibility notes, deprecated fields marked

---

## Endpoint Documentation Structure

| Section | Content |
|---------|---------|
| **Title** | Endpoint name |
| **Description** | Brief description of what the endpoint does |
| **HTTP Method + Path** | `POST /v1/organizations/{orgId}/ledgers/{ledgerId}/accounts` |
| **Path Parameters** | Table: Parameter, Type, Required, Description |
| **Query Parameters** | Table: Parameter, Type, Default, Description |
| **Request Body** | JSON example + fields table |
| **Success Response** | Status code + JSON example + fields table |
| **Errors** | Table: Status Code, Error Code, Description |

---

## Field Description Patterns

| Type | Pattern |
|------|---------|
| Basic | `name: string — The name of the Account` |
| With constraints | `code: string — The asset code (max 10 chars, uppercase)` |
| With example | `email: string — Email address (e.g., "user@example.com")` |
| Deprecated | `chartOfAccountsGroupName: string — **[Deprecated]** Use \`route\` instead` |

---

## Data Types Reference

| Type | Description | Example |
|------|-------------|---------|
| `uuid` | UUID v4 identifier | `3172933b-50d2-4b17-96aa-9b378d6a6eac` |
| `string` | Text value | `"Customer Account"` |
| `integer` | Whole number | `42` |
| `boolean` | True/false | `true` |
| `timestamptz` | ISO 8601 (UTC) | `2024-01-15T10:30:00Z` |
| `jsonb` | JSON object | `{"key": "value"}` |
| `array` | List of values | `["item1", "item2"]` |
| `enum` | Predefined values | `currency`, `crypto` |

---

## Request/Response Examples

**Rules:**
- Show realistic, working examples (not "foo", "bar")
- Show all fields that would be returned
- Use actual UUIDs, timestamps, realistic data

---

## Error Documentation

**Standard error format:**
```json
{
  "code": "ACCOUNT_NOT_FOUND",
  "message": "The specified account does not exist",
  "details": { "accountId": "invalid-uuid" }
}
```

**Error table:**

| Status | Code | Description | Resolution |
|--------|------|-------------|------------|
| 400 | INVALID_REQUEST | Validation failed | Check request format |
| 401 | UNAUTHORIZED | Missing/invalid auth | Provide valid API key |
| 403 | FORBIDDEN | Insufficient permissions | Contact admin |
| 404 | NOT_FOUND | Resource doesn't exist | Verify resource ID |
| 409 | CONFLICT | Resource already exists | Use different identifier |
| 422 | UNPROCESSABLE_ENTITY | Business rule violation | Check constraints |
| 500 | INTERNAL_ERROR | Server error | Retry or contact support |

---

## HTTP Status Codes

**Success:** 200 (GET/PUT/PATCH), 201 (POST creates), 204 (DELETE)

**Client errors:** 400 (malformed), 401 (no auth), 403 (no permission), 404 (not found), 409 (conflict), 422 (invalid semantics)

**Server errors:** 500 (internal)

---

## Pagination Documentation

For paginated endpoints, document query parameters:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| limit | integer | 10 | Results per page (max 100) |
| page | integer | 1 | Page number |

Response includes: `items`, `page`, `limit`, `totalItems`, `totalPages`

---

## Versioning Notes

> **Note:** You're viewing documentation for the **current version** (v3).

For deprecated: `> **Deprecated:** This endpoint will be removed in v4. Use [/v3/accounts](link) instead.`

---

## Quality Checklist

- [ ] HTTP method and path correct
- [ ] All path parameters documented
- [ ] All query parameters documented
- [ ] All request body fields documented with types
- [ ] All response fields documented with types
- [ ] Required vs optional clear
- [ ] Realistic request/response examples included
- [ ] All error codes documented
- [ ] Deprecated fields marked
- [ ] Links to related endpoints included

---

## Standards Loading (MANDATORY)

Before writing any API documentation, MUST load relevant standards:

1. **Voice and Tone Guidelines** - Load `ring:voice-and-tone` skill
2. **Field Description Patterns** - Load `ring:api-field-descriptions` skill
3. **Documentation Structure** - Load `ring:documentation-structure` skill

**HARD GATE:** CANNOT proceed with API documentation without loading these standards.

---

## Blocker Criteria - STOP and Report

| Condition | Decision | Action |
|-----------|----------|--------|
| API endpoint not implemented | STOP | Report: "Cannot document non-existent endpoint" |
| API behavior undetermined | STOP | Report: "Need confirmed API behavior before documenting" |
| Response schema unknown | STOP | Report: "Need response schema to document fields" |
| Error codes undefined | STOP | Report: "Need error code list before completing" |
| Voice/tone guidelines unclear | STOP | Report: "Need style guide clarification" |

### Cannot Be Overridden

These requirements are NON-NEGOTIABLE:

- MUST document ALL fields (request and response)
- MUST include realistic examples (not "foo", "bar")
- MUST document ALL error codes
- MUST use present tense and active voice
- MUST use sentence case for headings
- CANNOT skip required vs optional indicators

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Missing core sections, incorrect API paths | No request/response examples, wrong HTTP method |
| **HIGH** | Missing field documentation, no error codes | Undocumented required fields, missing error table |
| **MEDIUM** | Voice/tone violations, structure issues | Passive voice, title case headings |
| **LOW** | Minor clarity improvements, formatting | Could add more context, spacing issues |

---

## Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Skip the examples, developers will figure it out" | "CANNOT skip examples. Realistic examples are REQUIRED for every endpoint. I'll add complete request/response examples." |
| "Just document the happy path, errors are rare" | "MUST document all error codes. Error handling is critical for developers. I'll include the complete error table." |
| "The code is the documentation" | "Code is NOT documentation. API reference MUST explain purpose, constraints, and behavior. I'll write proper field descriptions." |
| "We'll add docs later, ship the feature first" | "Documentation is part of the feature. CANNOT ship undocumented APIs. I'll complete the documentation now." |
| "Copy the schema, that's enough" | "Schema alone is insufficient. MUST add descriptions, examples, and context. I'll write complete documentation." |

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Field name is self-explanatory" | Self-explanatory to you ≠ self-explanatory to users | **MUST write explicit description** |
| "Simple API doesn't need extensive docs" | Simplicity doesn't reduce documentation need | **Document ALL fields completely** |
| "Error codes are standard HTTP" | Each error needs context and resolution guidance | **MUST document all errors with resolutions** |
| "Examples slow down documentation" | Examples are the most-read part of API docs | **MUST include realistic examples** |
| "Internal API, limited audience" | Internal users deserve quality docs too | **Apply same standards as public APIs** |
| "Schema is generated, no need to write" | Generated schemas lack context and guidance | **MUST add human-written descriptions** |

---

## When This Skill is Not Needed

Signs that API documentation already meets standards:

- ALL endpoints have HTTP method, path, and description
- ALL request fields documented with type, required status, constraints
- ALL response fields documented with type and description
- ALL error codes listed with descriptions and resolutions
- Realistic JSON examples for every request and response
- Links to related endpoints included
- Voice and tone guidelines followed consistently

**If all above are true:** Documentation is complete, no changes needed.
