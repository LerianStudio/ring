# Go Standards - API Patterns

> **Module:** api-patterns.md | **Sections:** §17-21 | **Parent:** [index.md](index.md)

This module covers API naming conventions, pagination patterns, HTTP status codes, OpenAPI documentation, and handler initialization patterns.

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [JSON Naming Convention (camelCase)](#json-naming-convention-camelcase-mandatory) | API response field naming |
| 2 | [Pagination Patterns](#pagination-patterns) | Offset & cursor pagination strategies |
| 3 | [HTTP Status Code Consistency](#http-status-code-consistency-mandatory) | 201 for creation, 200 for update |
| 4 | [OpenAPI Documentation (Swaggo)](#openapi-documentation-swaggo-mandatory) | Swagger annotations as source of truth |
| 5 | [Handler Constructor Pattern](#handler-constructor-pattern-mandatory) | Dependency injection via constructor |
| 6 | [Input Validation](#input-validation-mandatory) | Request validation at API boundary |

---

## JSON Naming Convention (camelCase) (MANDATORY)

**HARD GATE:** all JSON fields in API requests and responses MUST use `camelCase`. No exceptions.

### Rule

| Layer                          | Format     | Example                                    |
| ------------------------------ | ---------- | ------------------------------------------ |
| **JSON response fields**       | camelCase  | `userId`, `createdAt`, `accountBalance`    |
| **Pagination response fields** | snake_case | `next_cursor`, `prev_cursor` (exception — matches Core one `Pagination` struct json tags) |
| **Query parameters**           | snake_case | `sort_order`, `start_date`, `end_date`     |
| **Go structs**                 | PascalCase | `UserID`, `CreatedAt`, `AccountBalance`    |
| **Database columns**           | snake_case | `user_id`, `created_at`, `account_balance` |

### Implementation Pattern

```go
// ✅ CORRECT: camelCase in JSON tags
type UserResponse struct {
    ID            string    `json:"id"`
    FirstName     string    `json:"firstName"`
    LastName      string    `json:"lastName"`
    EmailAddress  string    `json:"emailAddress"`
    PhoneNumber   string    `json:"phoneNumber,omitempty"`
    AccountType   string    `json:"accountType"`
    IsActive      bool      `json:"isActive"`
    CreatedAt     time.Time `json:"createdAt"`
    UpdatedAt     time.Time `json:"updatedAt"`
}

// ❌ FORBIDDEN: snake_case in JSON tags
type UserResponse struct {
    ID           string    `json:"id"`
    FirstName    string    `json:"first_name"`     // WRONG
    LastName     string    `json:"last_name"`      // WRONG
    EmailAddress string    `json:"email_address"`  // WRONG
    CreatedAt    time.Time `json:"created_at"`     // WRONG
}
```

### Query Parameters vs Body Fields

**HARD GATE:** Query parameters and body fields use different conventions.

| Location                  | Convention   | Examples                                         |
| ------------------------- | ------------ | ------------------------------------------------ |
| **Query parameters**      | `snake_case` | `?limit=10&sort_order=asc&start_date=2024-01-01` |
| **Request/Response body** | `camelCase`  | `{"firstName": "John", "createdAt": "..."}`      |

> **Source:** This pattern matches the Core one API standard (verified via Apidog).

#### Query Parameters (all snake_case)

```go
// ✅ CORRECT: All query params use snake_case
type ListParams struct {
    // Pagination: cursor for high-volume, page for admin entities
    Cursor    string `query:"cursor"`
    Page      int    `query:"page"`
    Limit     int    `query:"limit"`
    SortOrder string `query:"sort_order"`

    // Filters
    StartDate string `query:"start_date"`
    EndDate   string `query:"end_date"`
    Status    string `query:"status"`
}
```

```text
✅ CORRECT (offset-based, all query params snake_case):
GET /v1/organizations?limit=10&page=1&sort_order=asc&start_date=2024-01-01&end_date=2024-12-31

✅ CORRECT (cursor-based, all query params snake_case):
GET /v1/transactions?limit=10&sort_order=asc&start_date=2024-01-01&end_date=2024-12-31
GET /v1/transactions?cursor=eyJpZCI6IjEyMzQ1...&limit=10&sort_order=asc

❌ WRONG (camelCase in query params):
GET /v1/transactions?cursor=xyz&limit=10&sortOrder=asc&startDate=2024-01-01
```

#### Response Body - Pagination Fields (camelCase)

```go
// ✅ CORRECT: Pagination cursor fields use snake_case (exception — matches Core one Pagination struct json tags)
type PaginatedResponse struct {
    Items      []interface{} `json:"items"`
    Limit      int           `json:"limit"`
    NextCursor string        `json:"next_cursor,omitempty"`
    PrevCursor string        `json:"prev_cursor,omitempty"`
}
```

#### Response Body - Data Fields (camelCase)

```go
// ✅ CORRECT: Data fields in body use camelCase
type UserResponse struct {
    ID                   string `json:"id"`
    FirstName            string `json:"firstName"`
    LastName             string `json:"lastName"`
    ParentOrganizationId string `json:"parentOrganizationId"`
    CreatedAt            string `json:"createdAt"`
    UpdatedAt            string `json:"updatedAt"`
}
```

#### Complete List Response Example

```go
// ✅ CORRECT: Data fields camelCase; pagination cursors snake_case (exception — matches Core one code)
type UserListResponse struct {
    // Data fields - camelCase
    Items []struct {
        ID        string `json:"id"`
        FirstName string `json:"firstName"`      // camelCase
        LastName  string `json:"lastName"`       // camelCase
        CreatedAt string `json:"createdAt"`      // camelCase
    } `json:"items"`

    // Pagination cursor fields - snake_case (exception: matches Core one Pagination struct json tags)
    Limit      int    `json:"limit"`
    NextCursor string `json:"next_cursor,omitempty"`
    PrevCursor string `json:"prev_cursor,omitempty"`
}
```

### Common Field Names Reference

**Body Fields (camelCase):**

| Concept    | ✅ Correct (camelCase)                   | ❌ Wrong (snake_case)             |
| ---------- | ---------------------------------------- | --------------------------------- |
| Identifier | `id`, `userId`, `accountId`              | `user_id`, `account_id`           |
| Timestamps | `createdAt`, `updatedAt`, `deletedAt`    | `created_at`, `updated_at`        |
| Status     | `isActive`, `isDeleted`, `isVerified`    | `is_active`, `is_deleted`         |
| Amounts    | `totalAmount`, `accountBalance`          | `total_amount`, `account_balance` |
| Metadata   | `parentId`, `organizationId`, `ledgerId` | `parent_id`, `organization_id`    |
| Names      | `legalName`, `doingBusinessAs`           | `legal_name`, `doing_business_as` |

**Query Parameters (snake_case):**

| Concept          | ✅ Correct (snake_case)  | ❌ Wrong (camelCase)   |
| ---------------- | ------------------------ | ---------------------- |
| Sorting          | `sort_order`, `sort_by`  | `sortOrder`, `sortBy`  |
| Date filters     | `start_date`, `end_date` | `startDate`, `endDate` |
| All query params | `snake_case`             | `camelCase`            |

**Response Fields — Note on Pagination Cursor Exception:**

| Concept                   | ✅ Correct                                              | ❌ Wrong                                            |
| ------------------------- | ------------------------------------------------------- | --------------------------------------------------- |
| Pagination cursors        | `next_cursor`, `prev_cursor` (snake_case — matches Core one `Pagination` struct) | `nextCursor`, `prevCursor`, `hasMore` |
| All other response fields | `camelCase`                                             | `snake_case`                                        |

### Detection Commands

```bash
# Find snake_case in JSON response tags for non-pagination fields (should return 0 matches)
grep -rn 'json:"[a-z]*_[a-z]*' --include="*.go" ./internal | grep -v 'next_cursor\|prev_cursor'

# Check for common violations in body fields (these should NEVER be snake_case)
grep -rn 'json:"created_at\|json:"updated_at\|json:"deleted_at' --include="*.go" ./internal
grep -rn 'json:"first_name\|json:"last_name\|json:"legal_name' --include="*.go" ./internal

# Verify query params ARE snake_case (check query tags)
grep -rn 'query:"[a-zA-Z]*[A-Z]' --include="*.go" ./internal  # Should return 0 (no camelCase in query tags)

# Verify pagination cursor fields ARE snake_case (matches Core one Pagination struct)
grep -rn 'json:"next_cursor\|json:"prev_cursor' --include="*.go" ./internal

# Verify no legacy camelCase cursor fields remain
grep -rn 'json:"nextCursor\|json:"prevCursor\|json:"hasMore\|json:"has_more' --include="*.go" ./internal  # Should return 0
```

### Anti-Rationalization Table

| Rationalization                         | Why it's wrong                                                                  | Required Action                      |
| --------------------------------------- | ------------------------------------------------------------------------------- | ------------------------------------ |
| "Database uses snake_case"              | DB ≠ API body. Each layer has its convention.                                   | **Use camelCase in JSON body tags**  |
| "It's more readable"                    | Consistency > personal preference.                                              | **Follow the standard**              |
| "Existing API uses snake_case in body"  | New code must comply. Migrate old APIs.                                         | **Use camelCase for body fields**    |
| "OpenAPI spec shows snake_case"         | Fix the struct tag, regenerate spec.                                            | **Fix source, run generate-docs**    |
| "Query params should match body fields" | No. Query params = snake_case, body = camelCase. Different rules.               | **Follow location-based convention** |
| "startDate is cleaner than start_date"  | Core one standard uses snake_case for query params. Follow the standard.           | **Use snake_case for query params**  |
| "Why two different conventions?"        | URLs use snake_case, JSON uses camelCase — with one exception: pagination cursor fields (`next_cursor`, `prev_cursor`) are snake_case in responses because that's what the Core one `Pagination` struct uses. | **Accept the dual convention and the cursor exception** |

---

## Pagination Patterns

Core one uses **two pagination strategies** depending on the entity type. Both are valid and supported by the shared infrastructure in lib-commons.

### When to Use Each Strategy

| Use Cursor When | Use Offset When |
|-----------------|-----------------|
| High-volume data (transactions, operations, balances) | Low-volume admin entities (organizations, ledgers, accounts) |
| Real-time data with frequent inserts | Stable datasets with rare inserts |
| Performance at scale matters | Simplicity is preferred |
| Client doesn't need page numbers | Client needs numbered pages |

| Strategy | Core one Entities | Return Type |
|----------|---------------|-------------|
| **Offset** | Organizations, Ledgers, Assets, Portfolios, Accounts, Products, Segments | `([]*Entity, error)` |
| **Cursor** (preferred for high-volume) | Transactions, Operations, Balances, Audit logs, Events | `([]*Entity, CursorPagination, error)` |

| Issue with Offset                                             | Cursor Solution                             |
| ------------------------------------------------------------- | ------------------------------------------- |
| `OFFSET 10000` scans 10k rows before returning                | `WHERE id > cursor` uses index directly     |
| Data can skip/duplicate if records inserted during navigation | Consistent results regardless of insertions |
| Performance degrades linearly with offset value               | Constant performance regardless of position |

Both strategies share these common query parameters:

| Parameter    | Type     | Default      | Description                                  |
| ------------ | -------- | ------------ | -------------------------------------------- |
| `cursor`     | string   | (none)       | Base64-encoded cursor from previous response |
| `limit`      | int      | 10           | Items per page (max: 100)                    |
| `sort_order` | string   | "asc"        | Sort direction: "asc" or "desc"              |
| `start_date` | datetime | (calculated) | Filter start date                            |
| `end_date`   | datetime | now          | Filter end date                              |

**Strategy-specific parameters:**

| Parameter | Strategy | Type | Description |
|-----------|----------|------|-------------|
| `page` | Offset | int | Page number (1-based) |
| `cursor` | Cursor | string | Base64-encoded cursor from previous response |

### Shared Infrastructure

**Query Parameter Parsing** (from `pkg/net/http/httputils.go`):

```go
// QueryHeader — unified query parsing with both Page and Cursor fields
type QueryHeader struct {
    Limit     int
    Page      int       // Used by offset strategy
    Cursor    string    // Used by cursor strategy
    SortOrder string
    StartDate time.Time
    EndDate   time.Time
}

// ValidateParameters — parses query params, enforces MAX_PAGINATION_LIMIT
func ValidateParameters(queries map[string]string) (*QueryHeader, error)
```

**Pagination Response** (from `lib-commons/commons/postgres/pagination.go`):

```go
// Pagination — unified response envelope
// NOTE: cursor fields use snake_case json tags — this matches the actual Core one Pagination struct
type Pagination struct {
    Items      any    `json:"items"`
    Limit      int    `json:"limit"`
    Page       int    `json:"page,omitempty"`        // Offset mode
    NextCursor string `json:"next_cursor,omitempty"` // Cursor mode
    PrevCursor string `json:"prev_cursor,omitempty"` // Cursor mode
}

// SetItems — sets the items collection
func (p *Pagination) SetItems(items any)

// SetCursor — sets next/prev cursors (cursor mode only)
func (p *Pagination) SetCursor(next, prev string)
```

The `omitempty` tags ensure only strategy-relevant fields appear in responses.

### Strategy 1: Offset-Based Pagination

Used for onboarding entities (organizations, ledgers, accounts, etc.) where datasets are small and page numbers are useful.

**Handler Pattern:**

```go
func (h *Handler) GetAllOrganizations(c *fiber.Ctx) error {
    ctx := c.UserContext()
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "handler.get_all_organizations")
    defer span.End()

    headerParams, err := libHTTP.ValidateParameters(c.Queries())
    if err != nil {
        libOpentelemetry.HandleSpanBusinessErrorEvent(&span, "Invalid parameters", err)
        return libHTTP.WithError(c, err)
    }

    // Build pagination request (offset-based — Page is set)
    pagination := libPostgres.Pagination{
        Limit:     headerParams.Limit,
        Page:      headerParams.Page,      // <-- Page field enables offset mode
        SortOrder: headerParams.SortOrder,
        StartDate: headerParams.StartDate,
        EndDate:   headerParams.EndDate,
    }

    items, err := h.Query.GetAllOrganizations(ctx, *headerParams)
    if err != nil {
        libOpentelemetry.HandleSpanBusinessErrorEvent(&span, "Query failed", err)
        return libHTTP.WithError(c, err)
    }

    pagination.SetItems(items)

    return libHTTP.OK(c, pagination)
}
```

**Repository Pattern:**

```go
func (r *Repository) FindAll(ctx context.Context, filter libHTTP.QueryHeader) ([]*Entity, error) {
    ctx, span := tracer.Start(ctx, "postgres.find_all_organizations")
    defer span.End()

    findAll := squirrel.Select(columns...).
        From(r.tableName).
        Where(squirrel.Eq{"deleted_at": nil}).
        Where(squirrel.GtOrEq{"created_at": filter.StartDate}).
        Where(squirrel.LtOrEq{"created_at": filter.EndDate}).
        OrderBy("id " + strings.ToUpper(filter.SortOrder)).
        Limit(libCommons.SafeIntToUint64(filter.Limit)).
        Offset(libCommons.SafeIntToUint64((filter.Page - 1) * filter.Limit)).
        PlaceholderFormat(squirrel.Dollar)

    rows, err := findAll.RunWith(db).QueryContext(ctx)
    // ... scan rows into items ...

    return items, nil
}
```

**Key formula:** `OFFSET = (Page - 1) * Limit`

**Response JSON:**

```json
{
  "items": [...],
  "page": 2,
  "limit": 10
}
```

### Strategy 2: Cursor-Based Pagination (Preferred for High-Volume)

Used for transaction entities (transactions, operations, balances) where performance at scale and consistency during inserts matter.

**Cursor Struct and Encoding** (from `lib-commons/commons/net/http/cursor.go`):

| Parameter    | Type     | Default      | Description                                  |
| ------------ | -------- | ------------ | -------------------------------------------- |
| `cursor`     | string   | (none)       | Base64-encoded cursor from previous response |
| `limit`      | int      | 10           | Items per page (max: 100)                    |
| `sort_order` | string   | "asc"        | Sort direction: "asc" or "desc"              |
| `start_date` | datetime | (calculated) | Filter start date                            |
| `end_date`   | datetime | now          | Filter end date                              |

// ApplyCursorPagination — adds WHERE + ORDER BY + LIMIT to squirrel query
func ApplyCursorPagination(query squirrel.SelectBuilder, cursor Cursor, sortOrder string, limit int) (squirrel.SelectBuilder, string)

// PaginateRecords — trims to limit, reverses if backward navigation
func PaginateRecords[T any](isFirstPage, hasPagination, pointsNext bool, items []T, limit int, orderUsed string) []T

// CalculateCursor — generates next/prev cursor strings
func CalculateCursor(isFirstPage, hasPagination, pointsNext bool, firstID, lastID string) (CursorPagination, error)
```

**N+1 fetch pattern:** query `limit + 1` rows to detect whether a next page exists.

**Handler Pattern:**

```go
func (h *Handler) GetAllTransactions(c *fiber.Ctx) error {
    ctx := c.UserContext()
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "handler.get_all_transactions")
    defer span.End()

    headerParams, err := libHTTP.ValidateParameters(c.Queries())
    if err != nil {
        libOpentelemetry.HandleSpanBusinessErrorEvent(&span, "Invalid parameters", err)
        return libHTTP.WithError(c, err)
    }

    // Build pagination request (cursor-based — no Page field)
    pagination := libPostgres.Pagination{
        Limit:     headerParams.Limit,
        SortOrder: headerParams.SortOrder,
        StartDate: headerParams.StartDate,
        EndDate:   headerParams.EndDate,
    }

    // Query returns items + cursor (3 return values)
    items, cursor, err := h.Query.GetAllTransactions(ctx, orgID, ledgerID, *headerParams)
    if err != nil {
        libOpentelemetry.HandleSpanBusinessErrorEvent(&span, "Query failed", err)
        return libHTTP.WithError(c, err)
    }

    pagination.SetItems(items)
    pagination.SetCursor(cursor.Next, cursor.Prev)

    return libHTTP.OK(c, pagination)
}
```

**Repository Pattern:**

```go
func (r *Repository) FindAll(ctx context.Context, filter libHTTP.QueryHeader) ([]*Entity, libHTTP.CursorPagination, error) {
    ctx, span := tracer.Start(ctx, "postgres.find_all_transactions")
    defer span.End()

    // Decode cursor if provided
    var decodedCursor libHTTP.Cursor
    isFirstPage := true

    if filter.Cursor != "" {
        isFirstPage = false
        decodedCursor, _ = libHTTP.DecodeCursor(filter.Cursor)
    }

    // Build query with cursor pagination
    query := squirrel.Select(columns...).From(r.tableName)
    query, orderUsed := libHTTP.ApplyCursorPagination(
        query,
        decodedCursor,
        strings.ToUpper(filter.SortOrder),
        filter.Limit,
    )

    rows, err := query.RunWith(db).QueryContext(ctx)
    // ... scan rows into items ...

    // Check if there are more items (N+1 pattern)
    hasPagination := len(items) > filter.Limit

    // Trim to limit, handle backward navigation
    items = libHTTP.PaginateRecords(
        isFirstPage,
        hasPagination,
        decodedCursor.PointsNext || isFirstPage,
        items,
        filter.Limit,
        orderUsed,
    )

    // Calculate cursors for response
    var firstID, lastID string
    if len(items) > 0 {
        firstID = items[0].ID
        lastID = items[len(items)-1].ID
    }

    cursor, _ := libHTTP.CalculateCursor(
        isFirstPage,
        hasPagination,
        decodedCursor.PointsNext || isFirstPage,
        firstID,
        lastID,
    )

    return items, cursor, nil
}
```

**Response JSON:**

```json
{
  "items": [...],
  "limit": 10,
  "next_cursor": "eyJpZCI6Ii4uLiIsInBvaW50c19uZXh0Ijp0cnVlfQ==",
  "prev_cursor": "eyJpZCI6Ii4uLiIsInBvaW50c19uZXh0IjpmYWxzZX0="
}
```

**Backward pagination:** client sends `prev_cursor` value as the `cursor` query param. The `PointsNext: false` flag causes `ApplyCursorPagination` to reverse the query direction, and `PaginateRecords` reverses the result set back to the expected order.

### Shared Utilities from lib-commons

| Utility | Package | Purpose |
|---------|---------|---------|
| `Pagination` struct | `lib-commons/commons/postgres` | Unified response envelope with `page` (omitempty) + `next_cursor`/`prev_cursor` (omitempty, snake_case) |
| `QueryHeader` struct | `pkg/net/http` | Unified query parsing with both `Page` and `Cursor` fields |
| `ValidateParameters` | `pkg/net/http` | Parses query params, enforces `MAX_PAGINATION_LIMIT` |
| `Cursor` struct | `lib-commons/commons/net/http` | Cursor encoding (ID + direction) |
| `DecodeCursor` | `lib-commons/commons/net/http` | Parse cursor from request |
| `ApplyCursorPagination` | `lib-commons/commons/net/http` | Add cursor WHERE/ORDER BY/LIMIT to squirrel query |
| `PaginateRecords` | `lib-commons/commons/net/http` | Trim results to limit, handle backward direction |
| `CalculateCursor` | `lib-commons/commons/net/http` | Generate next/prev cursor strings |
| `SafeIntToUint64` | `lib-commons/commons` | Safe int→uint64 conversion for OFFSET/LIMIT |

### Environment Variables

| Variable                          | Default | Description                       |
| --------------------------------- | ------- | --------------------------------- |
| `MAX_PAGINATION_LIMIT`            | 100     | Maximum allowed limit per request |
| `MAX_PAGINATION_MONTH_DATE_RANGE` | 1       | Default date range in months      |

---

## OpenAPI Documentation (Swaggo) (MANDATORY)

**HARD GATE:** All API documentation MUST be generated from code annotations using swaggo. Editing generated files directly is FORBIDDEN.

### Source of Truth

| Source                                               | Editable | Purpose                       |
| ---------------------------------------------------- | -------- | ----------------------------- |
| **Handler annotations** (`@Summary`, `@Param`, etc.) | ✅ YES   | Define endpoint documentation |
| **main.go annotations** (`@title`, `@version`, etc.) | ✅ YES   | Define API metadata           |
| `api/swagger.json`                                   | ❌ NO    | **GENERATED** - Do not edit   |
| `api/swagger.yaml`                                   | ❌ NO    | **GENERATED** - Do not edit   |
| `api/docs.go`                                        | ❌ NO    | **GENERATED** - Do not edit   |

### Required Tool

| Tool          | Installation                                        | Purpose                                 |
| ------------- | --------------------------------------------------- | --------------------------------------- |
| `swaggo/swag` | `go install github.com/swaggo/swag/cmd/swag@latest` | Generate OpenAPI specs from annotations |

### FORBIDDEN: Editing Generated Files

```yaml
# ❌ FORBIDDEN: Directly editing api/swagger.yaml
paths:
  /v1/users:
    get:
      summary: "Get all users" # DON'T edit here!
```

```go
// ✅ CORRECT: Edit the annotation in the handler
// @Summary      Get all users
// @Description  Retrieve a paginated list of all users
// @Tags         Users
// @Router       /v1/users [get]
func (h *Handler) GetAllUsers(c *fiber.Ctx) error {
```

**Why this matters:**

- Generated files are overwritten on each `swag init`
- Manual edits are lost and cause confusion
- Annotations are version-controlled with the code
- Single source of truth prevents drift

### API Metadata (main.go)

Add these annotations above your `main()` function:

```go
// @title           Service Name API
// @version         v1.0.0
// @description     Brief description of this service API.

// @termsOfService  http://swagger.io/terms/
// @contact.name    Discord community
// @contact.url     https://discord.gg/DnhqKwkGv3

// @license.name    Apache 2.0
// @license.url     http://www.apache.org/licenses/LICENSE-2.0.html

// @host            localhost:3000
// @BasePath        /

func main() {
    // ...
}
```

### Handler Annotations (Complete Reference)

Every handler function MUST have swaggo annotations:

```go
// CreateUser creates a new user
// @Summary      Create a new user
// @Description  Create a new user with the provided information
// @Tags         Users
// @Accept       json
// @Produce      json
// @Param        Authorization  header    string                 true  "Authorization Bearer Token"
// @Param        X-Request-Id   header    string                 false "Request ID for tracing"
// @Param        user           body      mmodel.CreateUserInput true  "User creation payload"
// @Success      201            {object}  mmodel.User            "Successfully created user"
// @Failure      400            {object}  mmodel.Error           "Invalid input, validation errors"
// @Failure      401            {object}  mmodel.Error           "Unauthorized access"
// @Failure      403            {object}  mmodel.Error           "Forbidden access"
// @Failure      409            {object}  mmodel.Error           "Conflict: User already exists"
// @Failure      500            {object}  mmodel.Error           "Internal server error"
// @Router       /v1/users [post]
func (h *Handler) CreateUser(c *fiber.Ctx) error {
    // implementation
}
```

### Annotation Reference Table

| Annotation     | Required           | Description                       | Example                                          |
| -------------- | ------------------ | --------------------------------- | ------------------------------------------------ |
| `@Summary`     | ✅                 | Short description (shown in list) | `@Summary Create a new user`                     |
| `@Description` | ✅                 | Detailed description              | `@Description Create a new user with validation` |
| `@Tags`        | ✅                 | Group endpoints by resource       | `@Tags Users`                                    |
| `@Accept`      | For POST/PUT/PATCH | Request content type              | `@Accept json`                                   |
| `@Produce`     | ✅                 | Response content type             | `@Produce json`                                  |
| `@Param`       | Per parameter      | Define each parameter             | See below                                        |
| `@Success`     | ✅                 | Success response                  | `@Success 200 {object} User`                     |
| `@Failure`     | ✅                 | Error responses (all expected)    | `@Failure 400 {object} Error`                    |
| `@Router`      | ✅                 | Endpoint path and method          | `@Router /v1/users [get]`                        |

### @Param Syntax

```text
@Param  name  location  type  required  "description"

Locations: path, query, header, body, formData
Types: string, int, bool, object (for body)
Required: true, false
```

**Examples:**

```go
// Path parameter
// @Param  id  path  string  true  "User ID (UUID format)"

// Query parameter
// @Param  page   query  int     false  "Page number (default: 1)"
// @Param  limit  query  int     false  "Items per page (default: 10, max: 100)"

// Header parameter
// @Param  Authorization  header  string  true   "Authorization Bearer Token"
// @Param  X-Request-Id   header  string  false  "Request ID for tracing"

// Body parameter
// @Param  user  body  mmodel.CreateUserInput  true  "User creation payload"
```

### Required Failure Responses

Every endpoint MUST document these failure responses:

| Status | When                                          | Annotation                                            |
| ------ | --------------------------------------------- | ----------------------------------------------------- |
| 400    | Invalid input/validation                      | `@Failure 400 {object} mmodel.Error "Invalid input"`  |
| 401    | Missing/invalid auth                          | `@Failure 401 {object} mmodel.Error "Unauthorized"`   |
| 403    | Insufficient permissions                      | `@Failure 403 {object} mmodel.Error "Forbidden"`      |
| 404    | Resource not found (for GET/PUT/DELETE by ID) | `@Failure 404 {object} mmodel.Error "Not found"`      |
| 409    | Conflict (for POST creating duplicates)       | `@Failure 409 {object} mmodel.Error "Conflict"`       |
| 500    | Internal error                                | `@Failure 500 {object} mmodel.Error "Internal error"` |

### Generation Command

**See [devops.md - Documentation Commands](../devops.md#documentation-commands-mandatory)** for the complete Makefile implementation.

**Quick reference:**

| Command              | Purpose                           |
| -------------------- | --------------------------------- |
| `make generate-docs` | Generate Swagger from annotations |
| `make dev-setup`     | Install swag and other tools      |

**swag init parameters:**

| Flag                 | Purpose                                |
| -------------------- | -------------------------------------- |
| `-g cmd/app/main.go` | Entry point with API metadata          |
| `-o api`             | Output directory                       |
| `--parseDependency`  | Parse external dependencies for models |
| `--parseInternal`    | Parse internal packages                |

### Generated Files Structure

```text
/api
  docs.go         # Go code for embedding (GENERATED)
  swagger.json    # OpenAPI spec in JSON (GENERATED)
  swagger.yaml    # OpenAPI spec in YAML (GENERATED)
```

### Workflow for OpenAPI Changes

```text
1. Receive CodeRabbit issue about OpenAPI spec
2. Identify which handler needs the change
3. Edit the ANNOTATION in the handler Go file
4. Run: make generate-docs
5. Commit BOTH: handler change + regenerated api/ files
6. Verify the spec change in swagger.yaml
```

### Anti-Patterns (FORBIDDEN)

```go
// ❌ FORBIDDEN: Handler without annotations
func (h *Handler) GetUser(c *fiber.Ctx) error {
    // No swaggo annotations = undocumented endpoint
}

// ❌ FORBIDDEN: Missing required failure responses
// @Success 200 {object} User
// @Router  /v1/users/{id} [get]
// Missing: @Failure 400, 401, 403, 404, 500

// ❌ FORBIDDEN: Vague descriptions
// @Summary Get user
// @Description Get user
// Should be: @Description Retrieve a user by their unique identifier (UUID)
```

### Detection Commands

```bash
# Find handlers without @Router annotation (undocumented)
grep -rn "func.*Handler.*fiber.Ctx" --include="*.go" ./internal/adapters/http | \
  while read line; do
    file=$(echo "$line" | cut -d: -f1)
    linenum=$(echo "$line" | cut -d: -f2)
    if ! head -n "$linenum" "$file" | tail -20 | grep -q "@Router"; then
      echo "Missing @Router: $line"
    fi
  done

# Verify api/ files are in sync (should show no diff after generate-docs)
make generate-docs && git diff --exit-code api/
```

### Anti-Rationalization Table

| Rationalization                        | Why it's wrong                                   | Required Action                         |
| -------------------------------------- | ------------------------------------------------ | --------------------------------------- |
| "Editing YAML is faster"               | Edits are lost on next generation. Causes drift. | **Edit annotations, run generate-docs** |
| "The annotation is verbose"            | Verbosity ensures complete documentation.        | **Write complete annotations**          |
| "I'll add annotations later"           | Later = never. Undocumented APIs are incomplete. | **Add annotations with the handler**    |
| "Only public APIs need docs"           | All APIs need docs for internal developers too.  | **Document all endpoints**              |
| "CodeRabbit can fix the YAML directly" | YAML is generated. Fix the source (annotations). | **Edit handler annotations**            |

### Detection Commands

```bash
# Identify which strategy an endpoint uses
# Offset mode: handler sets Page field, repo returns ([]*Entity, error)
grep -rn "Page:.*headerParams.Page" internal/adapters/http --include="*.go"

# Cursor mode: handler calls SetCursor, repo returns CursorPagination
grep -rn "SetCursor" internal/adapters/http --include="*.go"

# Verify MAX_PAGINATION_LIMIT is enforced (ValidateParameters usage)
grep -rn "ValidateParameters" internal/adapters/http --include="*.go"

# Find endpoints missing pagination validation
grep -rn "func.*Handler.*GetAll\|func.*Handler.*List" internal/adapters/http --include="*.go" | \
  while read line; do
    file=$(echo "$line" | cut -d: -f1)
    if ! grep -q "ValidateParameters" "$file"; then
      echo "MISSING ValidateParameters: $file"
    fi
  done
```

### FORBIDDEN Patterns

| Pattern | Why It's Wrong |
|---------|---------------|
| Mixing both strategies in the same endpoint | Each endpoint MUST use one strategy consistently |
| Missing `MAX_PAGINATION_LIMIT` enforcement | MUST use `ValidateParameters` which enforces the limit |
| Offset on high-volume tables (>100K rows) without justification | Use cursor for transaction-class entities |
| Returning `page` and `next_cursor` in the same response | `omitempty` tags handle this — don't override |
| Hardcoding limit values instead of using `ValidateParameters` | Centralized validation prevents inconsistencies |

### Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "All endpoints should use cursor" | Core one uses offset for onboarding entities — both are valid | **Match strategy to entity type** |
| "Offset is always bad" | Offset is fine for low-volume admin entities | **Use offset for organizations, ledgers, accounts** |
| "Cursor is overkill for small tables" | Transaction tables grow fast — cursor prevents future problems | **Use cursor for transactions, operations, balances** |
| "I'll add pagination later" | Unpaginated list endpoints are a production risk | **Add pagination from the start** |
| "ValidateParameters is optional" | Skipping it bypasses limit enforcement | **MUST use ValidateParameters** |
| "Page numbers are better UX" | For high-volume data, cursor is more reliable | **Choose strategy based on entity type, not preference** |

---

## HTTP Status Code Consistency (MANDATORY)

Swagger annotations with inconsistent response codes (using 200 OK for resource creation instead of 201 Created) break API contracts and client expectations.

**⛔ HARD GATE:** HTTP status codes MUST match the operation semantics. Using incorrect status codes breaks API contracts and client expectations.

### Status Code Rules

| Operation       | HTTP Method | ✅ Correct Status          | ❌ Wrong Status | Description                            |
| --------------- | ----------- | -------------------------- | --------------- | -------------------------------------- |
| Create resource | POST        | `201 Created`              | 200 OK          | New resource created                   |
| Update resource | PUT/PATCH   | `200 OK`                   | 201 Created     | Existing resource modified             |
| Delete resource | DELETE      | `204 No Content`           | 200 OK          | Resource removed                       |
| Get resource    | GET         | `200 OK`                   | -               | Resource retrieved                     |
| List resources  | GET         | `200 OK`                   | -               | Collection retrieved                   |
| Action endpoint | POST        | `200 OK` or `202 Accepted` | 201 Created     | Action performed (no resource created) |

### Correct Swagger Annotations

```go
// ✅ CORRECT: 201 Created for POST that creates a resource
// @Summary      Create a new user
// @Success      201            {object}  mmodel.User  "Successfully created user"
// @Router       /v1/users [post]
func (h *Handler) CreateUser(c *fiber.Ctx) error {
    // ... create user ...
    return libHTTP.Created(c, user)  // Returns 201
}

// ✅ CORRECT: 200 OK for PUT that updates a resource
// @Summary      Update user
// @Success      200            {object}  mmodel.User  "Successfully updated user"
// @Router       /v1/users/{id} [put]
func (h *Handler) UpdateUser(c *fiber.Ctx) error {
    // ... update user ...
    return libHTTP.OK(c, user)  // Returns 200
}

// ✅ CORRECT: 204 No Content for DELETE
// @Summary      Delete user
// @Success      204            "Successfully deleted user"
// @Router       /v1/users/{id} [delete]
func (h *Handler) DeleteUser(c *fiber.Ctx) error {
    // ... delete user ...
    return libHTTP.NoContent(c)  // Returns 204
}
```

### FORBIDDEN Patterns

```go
// ❌ FORBIDDEN: 200 OK for resource creation
// @Summary      Create a new user
// @Success      200            {object}  mmodel.User  "Successfully created user"  // WRONG: Should be 201
// @Router       /v1/users [post]

// ❌ FORBIDDEN: 201 Created for update
// @Summary      Update user
// @Success      201            {object}  mmodel.User  "Successfully updated user"  // WRONG: Should be 200
// @Router       /v1/users/{id} [put]

// ❌ FORBIDDEN: Mismatched annotation and implementation
// @Success      201            {object}  mmodel.User
// @Router       /v1/users [post]
func (h *Handler) CreateUser(c *fiber.Ctx) error {
    return libHTTP.OK(c, user)  // WRONG: Returns 200, annotation says 201
}
```

### lib-commons Response Methods

| Method                      | Status Code | Use For                                    |
| --------------------------- | ----------- | ------------------------------------------ |
| `libHTTP.Created(c, data)`  | 201         | POST creating a new resource               |
| `libHTTP.OK(c, data)`       | 200         | GET, PUT, PATCH, action POSTs              |
| `libHTTP.NoContent(c)`      | 204         | DELETE, successful operations without body |
| `libHTTP.Accepted(c, data)` | 202         | Async operations (will be processed later) |

### Detection Commands (MANDATORY)

```bash
# MANDATORY: Run before every PR with API changes
# Find 200 OK used for POST creation endpoints
grep -B 10 "@Router.*\[post\]" internal/adapters/http/in/*.go | grep "@Success.*200"

# Find 201 Created used for PUT/PATCH endpoints (use -E for alternation)
grep -E -B 10 "@Router.*\[(put|patch)\]" internal/adapters/http/in/*.go | grep "@Success.*201"

# Expected: Both commands return 0 matches
# If matches found: Fix annotation to use correct status code
```

### Anti-Rationalization Table

| Rationalization           | Why It's WRONG                                                       | Required Action                        |
| ------------------------- | -------------------------------------------------------------------- | -------------------------------------- |
| "200 OK is simpler"       | Clients expect 201 for creation. Breaking convention breaks clients. | **Use 201 for POST creation**          |
| "Both mean success"       | Different semantics: 201 = created, 200 = retrieved/updated.         | **Use correct code for operation**     |
| "Frontend ignores status" | Frontend SHOULD check status. API MUST be correct.                   | **Use correct status code**            |
| "OpenAPI just documents"  | OpenAPI is a contract. Wrong docs = broken contract.                 | **Match annotation to implementation** |
| "We've always used 200"   | Legacy is not justification. Fix during maintenance.                 | **Correct when modifying endpoint**    |

---

## OpenAPI Documentation (Swaggo) (MANDATORY)

**HARD GATE:** All API documentation MUST be generated from code annotations using swaggo. Editing generated files directly is FORBIDDEN.

### Source of Truth

| Source                                               | Editable | Purpose                       |
| ---------------------------------------------------- | -------- | ----------------------------- |
| **Handler annotations** (`@Summary`, `@Param`, etc.) | ✅ YES   | Define endpoint documentation |
| **main.go annotations** (`@title`, `@version`, etc.) | ✅ YES   | Define API metadata           |
| `api/swagger.json`                                   | ❌ NO    | **GENERATED** - Do not edit   |
| `api/swagger.yaml`                                   | ❌ NO    | **GENERATED** - Do not edit   |
| `api/docs.go`                                        | ❌ NO    | **GENERATED** - Do not edit   |

### Required Tool

| Tool          | Installation                                        | Purpose                                 |
| ------------- | --------------------------------------------------- | --------------------------------------- |
| `swaggo/swag` | `go install github.com/swaggo/swag/cmd/swag@latest` | Generate OpenAPI specs from annotations |

### FORBIDDEN: Editing Generated Files

```yaml
# ❌ FORBIDDEN: Directly editing api/swagger.yaml
paths:
  /v1/users:
    get:
      summary: "Get all users" # DON'T edit here!
```

```go
// ✅ CORRECT: Edit the annotation in the handler
// @Summary      Get all users
// @Description  Retrieve a paginated list of all users
// @Tags         Users
// @Router       /v1/users [get]
func (h *Handler) GetAllUsers(c *fiber.Ctx) error {
```

**Why this matters:**

- Generated files are overwritten on each `swag init`
- Manual edits are lost and cause confusion
- Annotations are version-controlled with the code
- Single source of truth prevents drift

### API Metadata (main.go)

Add these annotations above your `main()` function:

```go
// @title           Service Name API
// @version         v1.0.0
// @description     Brief description of this service API.

// @termsOfService  http://swagger.io/terms/
// @contact.name    Discord community
// @contact.url     https://discord.gg/DnhqKwkGv3

// @license.name    Apache 2.0
// @license.url     http://www.apache.org/licenses/LICENSE-2.0.html

// @host            localhost:3000
// @BasePath        /

func main() {
    // ...
}
```

### Handler Annotations (Complete Reference)

MUST: every handler function has swaggo annotations:

```go
// CreateUser creates a new user
// @Summary      Create a new user
// @Description  Create a new user with the provided information
// @Tags         Users
// @Accept       json
// @Produce      json
// @Param        Authorization  header    string                 true  "Authorization Bearer Token"
// @Param        X-Request-Id   header    string                 false "Request ID for tracing"
// @Param        user           body      mmodel.CreateUserInput true  "User creation payload"
// @Success      201            {object}  mmodel.User            "Successfully created user"
// @Failure      400            {object}  mmodel.Error           "Invalid input, validation errors"
// @Failure      401            {object}  mmodel.Error           "Unauthorized access"
// @Failure      403            {object}  mmodel.Error           "Forbidden access"
// @Failure      409            {object}  mmodel.Error           "Conflict: User already exists"
// @Failure      500            {object}  mmodel.Error           "Internal server error"
// @Router       /v1/users [post]
func (h *Handler) CreateUser(c *fiber.Ctx) error {
    // implementation
}
```

### Annotation Reference Table

| Annotation     | Required           | Description                       | Example                                          |
| -------------- | ------------------ | --------------------------------- | ------------------------------------------------ |
| `@Summary`     | ✅                 | Short description (shown in list) | `@Summary Create a new user`                     |
| `@Description` | ✅                 | Detailed description              | `@Description Create a new user with validation` |
| `@Tags`        | ✅                 | Group endpoints by resource       | `@Tags Users`                                    |
| `@Accept`      | For POST/PUT/PATCH | Request content type              | `@Accept json`                                   |
| `@Produce`     | ✅                 | Response content type             | `@Produce json`                                  |
| `@Param`       | Per parameter      | Define each parameter             | See below                                        |
| `@Success`     | ✅                 | Success response                  | `@Success 200 {object} User`                     |
| `@Failure`     | ✅                 | Error responses (all expected)    | `@Failure 400 {object} Error`                    |
| `@Router`      | ✅                 | Endpoint path and method          | `@Router /v1/users [get]`                        |

### @Param Syntax

```text
@Param  name  location  type  required  "description"

Locations: path, query, header, body, formData
Types: string, int, bool, object (for body)
Required: true, false
```

**Examples:**

```go
// Path parameter
// @Param  id  path  string  true  "User ID (UUID format)"

// Query parameter (pagination - cursor or page depending on entity type)
// @Param  cursor  query  string  false  "Base64-encoded cursor from previous response (cursor mode)"
// @Param  page    query  int     false  "Page number, 1-based (offset mode)"
// @Param  limit   query  int     false  "Items per page (default: 10, max: 100)"

// Header parameter
// @Param  Authorization  header  string  true   "Authorization Bearer Token"
// @Param  X-Request-Id   header  string  false  "Request ID for tracing"

// Body parameter
// @Param  user  body  mmodel.CreateUserInput  true  "User creation payload"
```

### Required Failure Responses

MUST document these failure responses for every endpoint:

| Status | When                                          | Annotation                                            |
| ------ | --------------------------------------------- | ----------------------------------------------------- |
| 400    | Invalid input/validation                      | `@Failure 400 {object} mmodel.Error "Invalid input"`  |
| 401    | Missing/invalid auth                          | `@Failure 401 {object} mmodel.Error "Unauthorized"`   |
| 403    | Insufficient permissions                      | `@Failure 403 {object} mmodel.Error "Forbidden"`      |
| 404    | Resource not found (for GET/PUT/DELETE by ID) | `@Failure 404 {object} mmodel.Error "Not found"`      |
| 409    | Conflict (for POST creating duplicates)       | `@Failure 409 {object} mmodel.Error "Conflict"`       |
| 500    | Internal error                                | `@Failure 500 {object} mmodel.Error "Internal error"` |

### Generation Command

**See [devops.md - Documentation Commands](../devops.md#documentation-commands-mandatory)** for the complete Makefile implementation.

**Quick reference:**

| Command              | Purpose                           |
| -------------------- | --------------------------------- |
| `make generate-docs` | Generate Swagger from annotations |
| `make dev-setup`     | Install swag and other tools      |

**swag init parameters:**

| Flag                 | Purpose                                |
| -------------------- | -------------------------------------- |
| `-g cmd/app/main.go` | Entry point with API metadata          |
| `-o api`             | Output directory                       |
| `--parseDependency`  | Parse external dependencies for models |
| `--parseInternal`    | Parse internal packages                |

### Generated Files Structure

```text
/api
  docs.go         # Go code for embedding (GENERATED)
  swagger.json    # OpenAPI spec in JSON (GENERATED)
  swagger.yaml    # OpenAPI spec in YAML (GENERATED)
```

### Workflow for OpenAPI Changes

```text
1. Receive CodeRabbit issue about OpenAPI spec
2. Identify which handler needs the change
3. Edit the ANNOTATION in the handler Go file
4. Run: make generate-docs
5. Commit BOTH: handler change + regenerated api/ files
6. Verify the spec change in swagger.yaml
```

### Anti-Patterns (FORBIDDEN)

```go
// ❌ FORBIDDEN: Handler without annotations
func (h *Handler) GetUser(c *fiber.Ctx) error {
    // No swaggo annotations = undocumented endpoint
}

// ❌ FORBIDDEN: Missing required failure responses
// @Success 200 {object} User
// @Router  /v1/users/{id} [get]
// Missing: @Failure 400, 401, 403, 404, 500

// ❌ FORBIDDEN: Vague descriptions
// @Summary Get user
// @Description Get user
// Should be: @Description Retrieve a user by their unique identifier (UUID)
```

### Detection Commands

```bash
# Find handlers without @Router annotation (undocumented)
grep -rn "func.*Handler.*fiber.Ctx" --include="*.go" ./internal/adapters/http | \
  while read line; do
    file=$(echo "$line" | cut -d: -f1)
    linenum=$(echo "$line" | cut -d: -f2)
    if ! head -n "$linenum" "$file" | tail -20 | grep -q "@Router"; then
      echo "Missing @Router: $line"
    fi
  done

# Verify api/ files are in sync (should show no diff after generate-docs)
make generate-docs && git diff --exit-code api/
```

### Anti-Rationalization Table

| Rationalization                        | Why it's wrong                                   | Required Action                         |
| -------------------------------------- | ------------------------------------------------ | --------------------------------------- |
| "Editing YAML is faster"               | Edits are lost on next generation. Causes drift. | **Edit annotations, run generate-docs** |
| "The annotation is verbose"            | Verbosity ensures complete documentation.        | **Write complete annotations**          |
| "I'll add annotations later"           | Later = never. Undocumented APIs are incomplete. | **Add annotations with the handler**    |
| "Only public APIs need docs"           | All APIs need docs for internal developers too.  | **Document all endpoints**              |
| "CodeRabbit can fix the YAML directly" | YAML is generated. Fix the source (annotations). | **Edit handler annotations**            |

---

## Handler Constructor Pattern (MANDATORY)

Handlers with implicit dependencies make testing difficult and hide coupling. Direct struct initialization bypasses validation.

**⛔ HARD GATE:** All HTTP handlers MUST use constructor functions for initialization. Direct struct initialization is FORBIDDEN.

### Why Constructor Pattern Is MANDATORY

| Problem               | Without Constructor      | With Constructor            |
| --------------------- | ------------------------ | --------------------------- |
| Dependency visibility | Hidden in struct         | Explicit in signature       |
| Nil checks            | Scattered in methods     | Single place in constructor |
| Testing               | Mock injection difficult | Clean dependency injection  |
| Compilation safety    | Runtime nil panics       | Compile-time errors         |

### Handler Constructor Pattern

```go
// internal/adapters/http/in/user_handler.go

// Handler struct holds dependencies (private fields)
type UserHandler struct {
    command *command.UseCase
    query   *query.UseCase
    logger  libLog.Logger
}

// NewUserHandler creates a handler with validated dependencies
// MANDATORY: Constructor validates all dependencies; returns error instead of panicking
func NewUserHandler(cmd *command.UseCase, qry *query.UseCase, logger libLog.Logger) (*UserHandler, error) {
    if cmd == nil {
        return nil, fmt.Errorf("command use case is required")
    }
    if qry == nil {
        return nil, fmt.Errorf("query use case is required")
    }
    if logger == nil {
        return nil, fmt.Errorf("logger is required")
    }

    return &UserHandler{
        command: cmd,
        query:   qry,
        logger:  logger,
    }, nil
}

// Handler methods use injected dependencies
func (h *UserHandler) CreateUser(c *fiber.Ctx) error {
    // h.command, h.query, h.logger are guaranteed non-nil
    // ...
}
```

### Bootstrap Integration (REQUIRED)

```go
// internal/bootstrap/config.go

func InitServers() (*Service, error) {
    // ... initialize dependencies ...

    // CORRECT: Use constructor and handle error
    userHandler, err := httpin.NewUserHandler(commandUseCase, queryUseCase, logger)
    if err != nil {
        return nil, fmt.Errorf("create user handler: %w", err)
    }

    // Pass handler to router
    httpApp := httpin.NewRouter(logger, telemetry, userHandler)

    // ...
    return &Service{httpApp: httpApp}, nil
}
```

### FORBIDDEN Patterns

```go
// ❌ FORBIDDEN: Direct struct initialization
userHandler := &httpin.UserHandler{
    Command: commandUseCase,  // No validation
    Query:   queryUseCase,
    Logger:  logger,
}

// ❌ FORBIDDEN: Public fields allowing direct access
type UserHandler struct {
    Command *command.UseCase  // WRONG: Public field
    Query   *query.UseCase    // WRONG: Public field
}

// ❌ FORBIDDEN: Constructor without validation
func NewUserHandler(cmd *command.UseCase) *UserHandler {
    return &UserHandler{command: cmd}  // WRONG: No nil check
}

// ❌ FORBIDDEN: Lazy initialization in handler methods
func (h *UserHandler) CreateUser(c *fiber.Ctx) error {
    if h.command == nil {  // WRONG: Should fail at startup, not request time
        return errors.New("not initialized")
    }
}
```

### Detection Commands (MANDATORY)

```bash
# MANDATORY: Run before every PR that adds/modifies handlers
# Find handlers without constructor functions
for f in internal/adapters/http/in/*_handler.go; do
  handler=$(basename "$f" .go | sed 's/_handler//')
  if ! grep -q "func New.*Handler" "$f" 2>/dev/null; then
    echo "MISSING CONSTRUCTOR: $f"
  fi
done

# Find direct struct initialization of handlers (potential violation)
grep -rn "&.*Handler{" internal/bootstrap --include="*.go" | grep -v "New.*Handler"

# Find handlers with public fields (violation)
grep -rn "type.*Handler struct" internal/adapters/http/in --include="*.go" -A 10 | \
  grep -E "^\s+[A-Z][a-zA-Z]*\s+\*?[a-zA-Z]+"

# Expected: All handlers have New* constructor, no direct initialization, no public fields
# If any violation found: STOP. Fix before proceeding.
```

### Anti-Rationalization Table

| Rationalization                      | Why It's WRONG                                     | Required Action                      |
| ------------------------------------ | -------------------------------------------------- | ------------------------------------ |
| "Direct initialization is simpler"   | Simplicity now = nil panics later.                 | **Use constructor**                  |
| "I'll add validation later"          | Later = production incident. Fail fast at startup. | **Add validation in constructor**    |
| "Tests can set fields directly"      | Tests should use same constructor as production.   | **Use constructor in tests too**     |
| "Handler is small, doesn't need it"  | Consistency matters more than size.                | **Use constructor for all handlers** |
| "Public fields are easier to access" | Easier access = easier to corrupt.                 | **Use private fields + constructor** |

---

## Input Validation (MANDATORY)

**⛔ HARD GATE:** All user input MUST be validated at the API boundary before processing. Trusting user input is FORBIDDEN.

### Defense in Depth Principle

Validate at EVERY layer where data enters the system:

```text
┌─────────────────────────────────────────────────────────────────┐
│ HTTP Request                                                     │
│   ↓                                                              │
│ [Layer 1: Handler] - Struct binding + validation tags            │
│   ↓                                                              │
│ [Layer 2: Use Case] - Business rule validation                   │
│   ↓                                                              │
│ [Layer 3: Domain] - Domain invariant validation                  │
│   ↓                                                              │
│ [Layer 4: Repository] - Database constraints                     │
└─────────────────────────────────────────────────────────────────┘
```

### Required Validation at Handler Layer

**MANDATORY: Use go-playground/validator v10 with struct tags.**

```go
import (
    "github.com/go-playground/validator/v10"
)

// ✅ CORRECT: Input struct with validation tags
type CreateUserInput struct {
    Email     string `json:"email" validate:"required,email,max=255"`
    FirstName string `json:"firstName" validate:"required,min=1,max=100"`
    LastName  string `json:"lastName" validate:"required,min=1,max=100"`
    Age       int    `json:"age" validate:"omitempty,gte=0,lte=150"`
    Role      string `json:"role" validate:"required,oneof=admin user guest"`
    Phone     string `json:"phone" validate:"omitempty,e164"`
}

// Handler validates input before processing
func (h *Handler) CreateUser(c *fiber.Ctx) error {
    ctx := c.UserContext()

    var input CreateUserInput
    if err := c.BodyParser(&input); err != nil {
        return libHTTP.WithError(c, ErrInvalidJSON)
    }

    // ✅ CORRECT: Validate before processing
    if err := h.validator.Struct(input); err != nil {
        return libHTTP.WithError(c, translateValidationError(err))
    }

    // Now input is validated, proceed with business logic
    result, err := h.command.CreateUser(ctx, input)
    // ...
}
```

### Common Validation Tags Reference

| Tag        | Description                               | Example                            |
| ---------- | ----------------------------------------- | ---------------------------------- |
| `required` | Field must be present and non-zero        | `validate:"required"`              |
| `email`    | Valid email format                        | `validate:"email"`                 |
| `uuid`     | Valid UUID format                         | `validate:"uuid"`                  |
| `min`      | Minimum length (string) or value (number) | `validate:"min=1"`                 |
| `max`      | Maximum length (string) or value (number) | `validate:"max=255"`               |
| `gte`      | Greater than or equal                     | `validate:"gte=0"`                 |
| `lte`      | Less than or equal                        | `validate:"lte=100"`               |
| `oneof`    | Value must be one of listed               | `validate:"oneof=active inactive"` |
| `e164`     | International phone format                | `validate:"e164"`                  |
| `url`      | Valid URL format                          | `validate:"url"`                   |
| `iso8601`  | Valid ISO8601 date                        | `validate:"iso8601"`               |

### Validation Error Translation

```go
// ✅ CORRECT: Translate validation errors to user-friendly messages
func translateValidationError(err error) error {
    var validationErrors validator.ValidationErrors
    if errors.As(err, &validationErrors) {
        var errMessages []string
        for _, e := range validationErrors {
            errMessages = append(errMessages, formatFieldError(e))
        }
        return NewValidationError(errMessages)
    }
    return ErrInvalidInput
}

func formatFieldError(e validator.FieldError) string {
    switch e.Tag() {
    case "required":
        return fmt.Sprintf("field '%s' is required", e.Field())
    case "email":
        return fmt.Sprintf("field '%s' must be a valid email", e.Field())
    case "min":
        return fmt.Sprintf("field '%s' must be at least %s characters", e.Field(), e.Param())
    case "max":
        return fmt.Sprintf("field '%s' must be at most %s characters", e.Field(), e.Param())
    case "oneof":
        return fmt.Sprintf("field '%s' must be one of: %s", e.Field(), e.Param())
    default:
        return fmt.Sprintf("field '%s' failed validation: %s", e.Field(), e.Tag())
    }
}
```

### UUID and Path Parameter Validation

```go
// ✅ CORRECT: Validate path parameters
func (h *Handler) GetUser(c *fiber.Ctx) error {
    userID := c.Params("id")

    // Validate UUID format
    if _, err := uuid.Parse(userID); err != nil {
        return libHTTP.WithError(c, ErrInvalidUserID)
    }

    // Proceed with validated ID
    user, err := h.query.GetUser(ctx, userID)
    // ...
}
```

### Query Parameter Validation

```go
// ✅ CORRECT: Validate query parameters with defaults
func (h *Handler) ListUsers(c *fiber.Ctx) error {
    // Use lib-commons validation
    params, err := libHTTP.ValidateParameters(c.Queries())
    if err != nil {
        return libHTTP.WithError(c, err)
    }

    // params.Limit, params.Cursor, params.SortOrder are validated and have defaults
    // ...
}
```

### Numeric Query Parameter Errors (MANDATORY)

**⛔ HARD GATE:** Numeric query parameters MUST be explicitly validated. Silent conversion failures (swallowed errors) cause unexpected behavior.

```go
// ❌ FORBIDDEN: Silent conversion failure (error swallowed)
func (h *Handler) GetItems(c *fiber.Ctx) error {
    limit := c.QueryInt("limit", 10)  // If "limit=abc", silently returns 10
    // WRONG: Invalid input is silently accepted
}

// ✅ CORRECT: Explicit validation with error response
func (h *Handler) GetItems(c *fiber.Ctx) error {
    limitStr := c.Query("limit", "10")
    limit, err := strconv.Atoi(limitStr)
    if err != nil {
        return libHTTP.WithError(c, ErrInvalidLimit)  // Return 400 Bad Request
    }
    if limit < 1 || limit > 100 {
        return libHTTP.WithError(c, ErrLimitOutOfRange)
    }
    // ...
}

// ✅ PREFERRED: Use lib-commons ValidateParameters
func (h *Handler) GetItems(c *fiber.Ctx) error {
    params, err := libHTTP.ValidateParameters(c.Queries())
    if err != nil {
        return libHTTP.WithError(c, err)  // Handles all validation
    }
    // params.Limit is guaranteed valid
}
```

**Detection Command:**

```bash
# Find silent numeric conversion (QueryInt, QueryFloat without error check)
grep -rn "QueryInt\|QueryFloat" internal/adapters/http --include="*.go" | \
  grep -v "ValidateParameters"
# Expected: 0 matches (use ValidateParameters instead)
```

### FORBIDDEN Patterns

```go
// ❌ FORBIDDEN: Trusting input without validation
func (h *Handler) CreateUser(c *fiber.Ctx) error {
    var input CreateUserInput
    c.BodyParser(&input)
    // WRONG: Using input directly without validation
    h.command.CreateUser(ctx, input)
}

// ❌ FORBIDDEN: Validating only some fields
type CreateUserInput struct {
    Email string `json:"email" validate:"required,email"`
    Name  string `json:"name"`  // WRONG: No validation on required field
}

// ❌ FORBIDDEN: Catching validation errors but not returning them
if err := h.validator.Struct(input); err != nil {
    log.Error(err)
    // WRONG: Continuing despite validation failure
}

// ❌ FORBIDDEN: Manual validation when tags would suffice
if input.Email == "" {
    return ErrEmailRequired  // WRONG: Use validate:"required" tag
}
if len(input.Name) > 100 {
    return ErrNameTooLong  // WRONG: Use validate:"max=100" tag
}
```

### Detection Commands (MANDATORY)

```bash
# MANDATORY: Run before every PR with API changes

# Find input structs without validation tags
grep -rn "type.*Input struct" internal/adapters/http --include="*.go" -A 10 | \
  grep -v "validate:" | grep "json:"

# Find handlers that use BodyParser without validation
grep -rn "BodyParser" internal/adapters/http --include="*.go" -A 5 | \
  grep -v "validator\|Validate\|validate"

# Find path parameter usage without UUID validation
grep -rn 'Params("id")' internal/adapters/http --include="*.go" -A 3 | \
  grep -v "uuid.Parse\|ValidateUUID"

# Expected: 0 matches for unvalidated inputs
# If matches found: Add validation before processing
```

### Anti-Rationalization Table

| Rationalization                      | Why It's WRONG                                              | Required Action         |
| ------------------------------------ | ----------------------------------------------------------- | ----------------------- |
| "Frontend validates input"           | Frontend can be bypassed. Server is last defense.           | **Validate on server**  |
| "Input comes from trusted service"   | Services can be compromised. Trust nothing.                 | **Validate all input**  |
| "Validation is expensive"            | Invalid data processing is more expensive. Fail fast.       | **Validate early**      |
| "Database will reject invalid data"  | Database errors are cryptic. Validate for clear messages.   | **Validate before DB**  |
| "Small internal API doesn't need it" | Internal APIs become external. Build right from start.      | **Validate all APIs**   |
| "Manual validation is clearer"       | Tags are declarative and consistent. Manual is error-prone. | **Use validation tags** |

---
