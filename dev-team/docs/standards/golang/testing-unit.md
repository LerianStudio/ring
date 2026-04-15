# Go Standards - Unit Testing

> **Module:** testing-unit.md | **Sections:** 11 | **Parent:** [index.md](index.md)

This module covers unit testing patterns for Go projects. Unit tests verify code behavior in isolation with mocked dependencies.

> **Gate Reference:** This module is loaded by `ring:qa-analyst` at Gate 3 (Unit Testing).

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [Table-Driven Tests](#table-driven-tests-mandatory) | Structured test cases with subtests |
| 2 | [Test Naming Convention](#test-naming-convention-mandatory) | Function naming patterns |
| 3 | [Parallel Test Execution](#parallel-test-execution-mandatory) | t.Parallel() requirements |
| 4 | [Loop Variable Capture](#loop-variable-capture-mandatory) | Subtest closure safety |
| 5 | [Edge Case Coverage](#edge-case-coverage-mandatory) | Minimum edge cases per AC type |
| 6 | [Assertion Requirements](#assertion-requirements-mandatory) | Strong assertions for errors and responses |
| 7 | [Mock Generation](#mock-generation-mandatory) | GoMock patterns |
| 8 | [Environment Variables in Tests](#environment-variables-in-tests-mandatory) | t.Setenv patterns |
| 9 | [Shared Test Utilities](#shared-test-utilities-mandatory) | testutils import patterns |
| 10 | [Unit Test Scope & Boundaries](#unit-test-scope--boundaries-mandatory) | What belongs in unit tests vs integration tests |
| 11 | [Unit Test Quality Gate](#unit-test-quality-gate-mandatory) | Checklist before completion |

**Meta-sections:** [Anti-Rationalization Table](#anti-rationalization-table-unit-testing)

---

## Table-Driven Tests (MANDATORY)

**HARD GATE:** All unit tests MUST use table-driven test pattern. Single-case tests are FORBIDDEN except for complex setup scenarios.

### Why Table-Driven Is MANDATORY

| Benefit | Explanation |
|---------|-------------|
| **Consistent structure** | Every test follows same pattern |
| **Easy to add cases** | New scenario = new struct entry |
| **Clear failure messages** | `t.Run()` names identify failing case |
| **Reduced duplication** | Setup/teardown shared across cases |

### Required Pattern

```go
func TestCreateUser(t *testing.T) {
    tests := []struct {
        name    string
        input   CreateUserInput
        want    *User
        wantErr error
    }{
        {
            name:  "valid user",
            input: CreateUserInput{Name: "John", Email: "john@example.com"},
            want:  &User{Name: "John", Email: "john@example.com"},
        },
        {
            name:    "invalid email",
            input:   CreateUserInput{Name: "John", Email: "invalid"},
            wantErr: ErrInvalidEmail,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := CreateUser(tt.input)

            if tt.wantErr != nil {
                require.ErrorIs(t, err, tt.wantErr)
                return
            }

            require.NoError(t, err)
            assert.Equal(t, tt.want.Name, got.Name)
        })
    }
}
```

### FORBIDDEN Patterns

```go
// ❌ FORBIDDEN: Single assertion without table
func TestCreateUser_Valid(t *testing.T) {
    result, err := CreateUser(validInput())
    require.NoError(t, err)
    assert.NotNil(t, result)
}

// ❌ FORBIDDEN: Multiple similar tests without table
func TestCreateUser_EmptyName(t *testing.T) { ... }
func TestCreateUser_EmptyEmail(t *testing.T) { ... }
func TestCreateUser_InvalidEmail(t *testing.T) { ... }
// WRONG: Should be one table-driven test
```

---

## Test Naming Convention (MANDATORY)

**HARD GATE:** All test functions MUST follow the naming convention.

### Function Naming Pattern

```text
Test{Unit}_{Scenario}_{ExpectedResult}

Examples:
- TestOrderService_CreateOrder_WithValidItems_ReturnsOrder
- TestOrderService_CreateOrder_WithEmptyItems_ReturnsError
- TestMoney_Add_SameCurrency_ReturnsSum
```

### Subtest Naming (in table-driven tests)

| Type | Pattern | Example |
|------|---------|---------|
| Happy path | Descriptive scenario | `"valid user"` |
| Edge case | `{condition}` | `"empty email"` |
| Error case | `{condition}_returns_error` | `"invalid format returns error"` |
| Boundary | `{boundary}_value` | `"max length value"` |

### FORBIDDEN Patterns

| Pattern | Why Wrong | Correct |
|---------|-----------|---------|
| `TestGetByIDSuccess` | Redundant "Success" suffix | `TestGetByID` |
| `TestGetByIDNotFound` | Missing underscore separation | `TestGetByID_NotFound` |
| `Test1`, `Test2` | Non-descriptive | `TestCreateUser_ValidInput` |

---

## Parallel Test Execution (MANDATORY)

**HARD GATE:** Unit tests MUST use `t.Parallel()` at both function and subtest levels to maximize test execution speed.

### Why t.Parallel Is MANDATORY for Unit Tests

| Benefit | Explanation |
|---------|-------------|
| **Faster CI** | Tests run concurrently, reducing total time |
| **Isolation verification** | Parallel execution exposes shared state bugs |
| **Standard practice** | Expected in modern Go test suites |

### Required Pattern

```go
func TestCreateUser(t *testing.T) {
    t.Parallel()  // ✅ REQUIRED at function level

    tests := []struct {
        name  string
        input CreateUserInput
        want  *User
    }{
        {name: "valid user", input: validInput()},
        {name: "empty email", input: CreateUserInput{Name: "John"}},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()  // ✅ REQUIRED at subtest level
            // test code
        })
    }
}
```

### FORBIDDEN Pattern

```go
// ❌ FORBIDDEN: Missing t.Parallel()
func TestCreateUser(t *testing.T) {
    // No t.Parallel() - tests run sequentially, slower CI
    result, err := CreateUser(validInput())
    require.NoError(t, err)
}

// ❌ FORBIDDEN: Function-level only (subtests still sequential)
func TestCreateUser(t *testing.T) {
    t.Parallel()

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // Missing t.Parallel() here - subtests run sequentially
        })
    }
}
```

### Exception: Integration Tests

**Note:** `t.Parallel()` is FORBIDDEN in integration tests (see `testing-integration.md`). This rule applies ONLY to unit tests.

### Detection Command

```bash
# Find unit tests missing t.Parallel() (check manually - should have t.Parallel)
grep -rn "func Test" --include="*_test.go" ./internal | grep -v "_integration_test.go"
```

---

## Loop Variable Capture (MANDATORY)

**HARD GATE:** When using table-driven tests with `t.Run()`, loop variables MUST be captured before the subtest closure.

### Why Loop Variable Capture Is MANDATORY

In Go versions < 1.22, loop variables are reused across iterations. Without capture, all subtests may see the last value.

| Go Version | Behavior | Capture Required? |
|------------|----------|-------------------|
| Go < 1.22 | Loop variable reused | **YES - MANDATORY** |
| Go 1.22+ | Per-iteration variables | Recommended for compatibility |

### Required Pattern

```go
func TestCreateUser(t *testing.T) {
    t.Parallel()

    tests := []struct {
        name  string
        input CreateUserInput
    }{
        {name: "valid user", input: validInput()},
        {name: "empty email", input: emptyEmailInput()},
    }

    for _, tt := range tests {
        tt := tt  // ✅ REQUIRED: Capture loop variable
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()
            result, err := CreateUser(tt.input)  // Uses captured tt
            // ...
        })
    }
}

// With index
for i, tt := range tests {
    i := i    // ✅ Capture index if used in subtest
    tt := tt  // ✅ Capture test case
    t.Run(tt.name, func(t *testing.T) {
        t.Parallel()
        t.Logf("Running test case %d", i)
        // ...
    })
}
```

### FORBIDDEN Pattern

```go
// ❌ FORBIDDEN: Loop variable not captured
for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
        t.Parallel()
        // BUG: tt may have unexpected value (last iteration)
        result, err := CreateUser(tt.input)
    })
}
```

### Detection Command

```bash
# Find potential loop variable capture issues
grep -rn "for.*range.*tests" --include="*_test.go" -A 2 ./internal | grep -v "tt := tt"
```

---

## Edge Case Coverage (MANDATORY)

**HARD GATE:** Every acceptance criterion MUST have edge case tests beyond the happy path.

### Minimum Edge Cases by AC Type

| AC Type | Required Edge Cases | Minimum Count |
|---------|---------------------|---------------|
| Input validation | nil, empty string, boundary values, invalid format, special chars, max length | 3+ |
| CRUD operations | not found, duplicate key, concurrent modification, large payload | 3+ |
| Business logic | zero value, negative numbers, overflow, boundary conditions, invalid state | 3+ |
| Error handling | context timeout, connection refused, invalid response, retry exhausted | 2+ |
| Authentication | expired token, invalid signature, missing claims, revoked token | 2+ |

### Table-Driven Edge Cases Pattern

```go
func TestUserService_CreateUser(t *testing.T) {
    tests := []struct {
        name    string
        input   CreateUserInput
        wantErr error
    }{
        // Happy path
        {name: "valid user", input: validInput(), wantErr: nil},

        // Edge cases (MANDATORY - minimum 3)
        {name: "nil input", input: CreateUserInput{}, wantErr: ErrInvalidInput},
        {name: "empty email", input: CreateUserInput{Name: "John", Email: ""}, wantErr: ErrEmailRequired},
        {name: "invalid email format", input: CreateUserInput{Name: "John", Email: "invalid"}, wantErr: ErrInvalidEmail},
        {name: "email too long", input: CreateUserInput{Name: "John", Email: strings.Repeat("a", 256) + "@test.com"}, wantErr: ErrEmailTooLong},
        {name: "name with special chars", input: CreateUserInput{Name: "<script>", Email: "test@test.com"}, wantErr: ErrInvalidName},
    }
    // ... test execution
}
```

### FORBIDDEN Pattern

```go
// ❌ FORBIDDEN: Only happy path
func TestUserService_CreateUser(t *testing.T) {
    result, err := service.CreateUser(validInput())
    require.NoError(t, err)  // No edge cases = incomplete test
}
```

---

## Assertion Requirements (MANDATORY)

**HARD GATE:** All assertions MUST be strong and specific. Weak assertions that only check `err != nil` or `resp != nil` are FORBIDDEN.

### Error Assertion Requirements

**NEVER leave `errContains` or error assertions empty.** Every error test MUST verify specific error content.

```go
// ❌ FORBIDDEN: Weak error assertion
tests := []struct {
    name        string
    wantErr     bool
    errContains string
}{
    {
        name:        "duplicate key",
        wantErr:     true,
        errContains: "",  // WRONG: Empty - only checks err != nil
    },
}

// ✅ CORRECT: Strong error assertion
tests := []struct {
    name        string
    wantErr     bool
    errContains string
}{
    {
        name:        "duplicate key",
        wantErr:     true,
        errContains: "key value already exists",  // Verifies specific error
    },
}
```

### Error Type Assertions

Use `require.ErrorAs` or `require.ErrorIs` for typed errors:

```go
// ✅ CORRECT: Assert specific error type
var entityNotFoundErr pkg.EntityNotFoundError
require.ErrorAs(t, err, &entityNotFoundErr)

// ✅ CORRECT: Assert sentinel error
require.ErrorIs(t, err, ErrNotFound)
```

### Response Type Verification

**Always verify response types** for success cases, especially for empty/void responses:

```go
// ❌ FORBIDDEN: Weak response assertion
require.NoError(t, err)
require.NotNil(t, resp)  // WRONG: Only checks not nil

// ✅ CORRECT: Verify specific response type
require.NoError(t, err)
require.NotNil(t, resp)
assert.IsType(t, &balancepb.Empty{}, resp)  // For void responses

// ✅ CORRECT: Validate key fields for data responses
require.NoError(t, err)
require.NotNil(t, resp)
assert.NotEmpty(t, resp.ID)
assert.Equal(t, "@user1", resp.Alias)
assert.Equal(t, "USD", resp.AssetCode)
```

### Decimal Comparisons

**NEVER use `==` for decimal comparisons.** Use the `Equal()` method:

```go
// ❌ FORBIDDEN: Direct comparison
assert.True(t, balance.Available == expectedAmount)

// ✅ CORRECT: Use Equal() method
assert.True(t, balance.Available.Equal(decimal.NewFromInt(1000)))
```

### Assertion Library Usage

```go
import (
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

// require - fatal, test stops on failure (use for preconditions)
require.NoError(t, err, "setup should succeed")

// assert - non-fatal, test continues (use for actual assertions)
assert.Equal(t, expected, actual)
```

---

## Mock Generation (MANDATORY)

**HARD GATE:** GoMock is the MANDATORY mock framework for all Go projects.

### go:generate Pattern

```go
// GoMock is the MANDATORY mock framework for all Go projects
//go:generate mockgen -source=repository.go -destination=mocks/mock_repository.go -package=mocks

// For interface in external package:
//go:generate mockgen -destination=mocks/mock_service.go -package=mocks github.com/example/pkg Service
```

### Mock Directory Structure

```
internal/
├── domain/
│   └── repository.go           # Interface definition
├── service/
│   ├── user_service.go         # Implementation
│   └── user_service_test.go    # Tests using mocks
└── mocks/
    └── mock_repository.go      # Generated mocks
```

### Usage in Tests

```go
func TestUserService_Create(t *testing.T) {
    ctrl := gomock.NewController(t)
    defer ctrl.Finish()

    mockRepo := mocks.NewMockUserRepository(ctrl)
    mockRepo.EXPECT().
        Create(gomock.Any(), gomock.Any()).
        Return(&domain.User{ID: "123"}, nil)

    svc := NewUserService(mockRepo)
    result, err := svc.Create(context.Background(), input)

    require.NoError(t, err)
    assert.Equal(t, "123", result.ID)
}
```

### FORBIDDEN Patterns

```go
// ❌ FORBIDDEN: Hand-written mocks
type fakeRepository struct{}
func (f *fakeRepository) Create(ctx context.Context, user *User) error {
    return nil  // WRONG: Use GoMock instead
}

// ❌ FORBIDDEN: Testify mocks (use GoMock)
type MockRepository struct {
    mock.Mock
}
```

---

## Environment Variables in Tests (MANDATORY)

**HARD GATE:** Tests that modify environment variables MUST use `t.Setenv()` instead of `os.Setenv()`.

### Why t.Setenv Is MANDATORY

| Feature | `os.Setenv()` | `t.Setenv()` |
|---------|---------------|--------------|
| Auto-cleanup | No - leaks to other tests | Yes - restored after test |
| Test isolation | Breaks parallel tests | Safe for parallel tests |
| Subtest scoping | Affects all subtests | Scoped to current test/subtest |
| t.Parallel() compatible | Race conditions | Safe |

### Correct Pattern (REQUIRED)

```go
func TestConfig_LoadFromEnv(t *testing.T) {
    // ✅ CORRECT: t.Setenv auto-cleans after test
    t.Setenv("POSTGRES_HOST", "localhost")
    t.Setenv("POSTGRES_PORT", "5432")
    t.Setenv("POSTGRES_NAME", "test_db")

    cfg, err := LoadConfig()
    require.NoError(t, err)
    assert.Equal(t, "localhost", cfg.PrimaryHost)
}

func TestConfig_Parallel(t *testing.T) {
    t.Run("test1", func(t *testing.T) {
        t.Parallel()
        t.Setenv("API_KEY", "key1")  // ✅ Safe with t.Parallel()
        // ...
    })

    t.Run("test2", func(t *testing.T) {
        t.Parallel()
        t.Setenv("API_KEY", "key2")  // ✅ Isolated from test1
        // ...
    })
}
```

### FORBIDDEN Pattern

```go
// ❌ FORBIDDEN: os.Setenv in tests
func TestConfig_LoadFromEnv(t *testing.T) {
    os.Setenv("POSTGRES_HOST", "localhost")     // WRONG: leaks to other tests
    defer os.Unsetenv("POSTGRES_HOST")          // WRONG: manual cleanup is error-prone
    // ...
}
```

### Detection Command

```bash
# Find os.Setenv in test files (should return 0 matches)
grep -rn "os\.Setenv" --include="*_test.go" ./internal ./pkg ./cmd

# If matches found → Replace with t.Setenv
```

---

## Shared Test Utilities (MANDATORY)

**HARD GATE:** Use shared utilities from `tests/utils` instead of defining local helpers that duplicate functionality.

### Import Alias Consistency

When importing `tests/utils`, ALWAYS use the `testutils` alias:

```go
// ❌ FORBIDDEN: Import without alias, then using testutils.Xxx
import (
    "github.com/LerianStudio/midaz/v3/tests/utils"
)
// ... later: testutils.Ptr("value")  // COMPILE ERROR!

// ✅ CORRECT: Import with testutils alias
import (
    testutils "github.com/LerianStudio/midaz/v3/tests/utils"
)
// ... later: testutils.Ptr("value")  // Works correctly
```

### Available Shared Utilities

| Function | Purpose | Example |
|----------|---------|---------|
| `testutils.Ptr[T](v T) *T` | Create pointer to value | `testutils.Ptr("value")` |
| `testutils.UUID()` | Generate random UUID string | `id := testutils.UUID()` |
| `testutils.RandomString(n int)` | Generate random alphanumeric | `name := testutils.RandomString(10)` |

### FORBIDDEN: Local Duplicate Helpers

```go
// ❌ FORBIDDEN: Local Ptr helper duplicates testutils.Ptr
func Ptr[T any](v T) *T {
    return &v
}

func TestSomething(t *testing.T) {
    entity.Field = Ptr("value")  // WRONG: Use testutils.Ptr
}

// ✅ CORRECT: Use shared testutils.Ptr
import testutils "github.com/LerianStudio/midaz/v3/tests/utils"

func TestSomething(t *testing.T) {
    entity.Field = testutils.Ptr("value")
}
```

### Detection Command

```bash
# Find local Ptr helpers (should return 0 matches)
grep -rn "func Ptr\[" --include="*_test.go" ./internal ./pkg
```

---

## Unit Test Scope & Boundaries (MANDATORY)

**HARD GATE:** Unit tests verify code behavior **in isolation**. All external dependencies MUST be mocked. Connecting to real databases, message queues, or external services in unit tests is FORBIDDEN.

### What Belongs in Unit Tests

| Allowed | Tool | Example |
|---------|------|---------|
| Mock repository interfaces | GoMock | `mockRepo.EXPECT().Create(gomock.Any(), gomock.Any())` |
| Mock service interfaces | GoMock | `mockSvc.EXPECT().Process(gomock.Any())` |
| Mock HTTP clients | GoMock | `mockClient.EXPECT().Get(gomock.Any())` |
| In-memory data | Struct literals | `input := CreateRequest{Name: "test"}` |
| Environment variables | t.Setenv | `t.Setenv("POSTGRES_HOST", "localhost")` |

### What is FORBIDDEN in Unit Tests

| FORBIDDEN | Why | Use Instead |
|-----------|-----|-------------|
| testcontainers | Spins up real containers — belongs in Gate 6 (integration) | GoMock interfaces |
| Real PostgreSQL/MongoDB connections | Slow, flaky, not isolated | GoMock repository mocks |
| Real Redis connections | External dependency | GoMock cache interface mocks |
| Real RabbitMQ/Kafka | External dependency | GoMock publisher/consumer mocks |
| `docker-compose` in test setup | Infrastructure dependency | GoMock all external interfaces |
| HTTP calls to external APIs | Network dependency, flaky | GoMock HTTP client interface |

### Boundary Rule

```text
Unit Test (Gate 3):     Code → Mock Interface → Assertion
Integration Test (Gate 6): Code → testcontainers (real DB) → Assertion
Chaos Test (Gate 7):    Code → Toxiproxy (failure injection) → Assertion
```

**If your test file imports `testcontainers-go` → it is NOT a unit test. Move it to `*_integration_test.go`.**

### Anti-Rationalization: Scope Boundaries

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Testing with real DB is more realistic" | Realistic = integration test (Gate 6). Unit tests verify logic in isolation. | **Mock the repository interface with GoMock** |
| "GoMock is too verbose for DB tests" | Verbose mocks = explicit contracts. Implicit DB = hidden coupling. | **Use GoMock, complexity is the point** |
| "I need to verify SQL queries" | SQL verification belongs in integration tests with testcontainers. | **Unit test the service logic, integration test the queries** |
| "testcontainers is fast enough" | Speed is irrelevant. Unit tests MUST be isolated. No containers. | **Mock all external dependencies** |

---

## Unit Test Quality Gate (MANDATORY)

**Before marking unit tests complete:**

- [ ] All tests use table-driven pattern
- [ ] All test functions follow naming convention `Test{Unit}_{Scenario}`
- [ ] All tests use `t.Parallel()` at function and subtest levels
- [ ] All loop variables captured before subtest closure (`tt := tt`)
- [ ] All acceptance criteria have 3+ edge case tests
- [ ] All error assertions specify expected error content (no empty `errContains`)
- [ ] All response assertions verify type and key fields (not just `!= nil`)
- [ ] GoMock used for all mocks (no hand-written mocks)
- [ ] `t.Setenv()` used instead of `os.Setenv()`
- [ ] Shared utilities used (no local `Ptr` or duplicate helpers)
- [ ] All tests pass: `go test ./...`
- [ ] No flaky tests (run 3x consecutively)

---

## Output Format (Gate 3 - Unit Testing)

```markdown
## Unit Testing Summary

| Metric | Value |
|--------|-------|
| Acceptance criteria | X |
| Tests written | Y |
| Edge cases per AC | 3+ |
| Tests passed | Y |
| Tests failed | 0 |
| Coverage | Z% |

### Tests by Acceptance Criteria

| AC | Test File | Tests | Edge Cases | Status |
|----|-----------|-------|------------|--------|
| AC-1: User creation | user_service_test.go | 6 | 5 | PASS |
| AC-2: User validation | user_validation_test.go | 8 | 7 | PASS |

### Standards Compliance

| Standard | Status | Evidence |
|----------|--------|----------|
| Table-driven tests | PASS | All tests use table-driven pattern |
| t.Parallel() | PASS | All tests have t.Parallel() at function and subtest level |
| Loop variable capture | PASS | All subtests capture loop variables |
| Strong error assertions | PASS | All error tests specify expected content |
| Response type verification | PASS | All success tests verify type and fields |
| GoMock | PASS | mocks/ directory with generated mocks |
| t.Setenv | PASS | No os.Setenv in test files |
| Shared utilities | PASS | No local Ptr or duplicate helpers |
| Edge cases | PASS | Minimum 3 per AC |
```

---

## Anti-Rationalization Table (Unit Testing)

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "One test case is enough" | One case proves one scenario. Edge cases catch bugs. | **Add 3+ edge cases** |
| "Table-driven is verbose" | Verbosity enables maintainability. | **Use table-driven** |
| "Hand-written mocks are simpler" | Simpler now, tech debt later. Use standard tools. | **Use GoMock** |
| "os.Setenv works fine" | Works until parallel tests break. | **Use t.Setenv** |
| "Happy path covers it" | Happy path misses 90% of bugs. | **Test edge cases** |
| "Will add tests later" | Later = never. Tests first. | **Write tests now** |
| "t.Parallel() is optional" | Sequential tests = slow CI. Parallel tests expose shared state bugs. | **Add t.Parallel()** |
| "Loop variable capture is pedantic" | Without capture, all subtests see last value. Real bugs. | **Capture loop variables** |
| "Checking err != nil is enough" | Weak assertion. Different errors pass silently. | **Assert specific error content** |
| "resp != nil proves success" | Could be wrong type or empty data. | **Assert type and fields** |
| "Local Ptr helper is convenient" | Duplicate code. Use shared utilities. | **Use testutils.Ptr** |
| "Go 1.22 fixed loop variables" | Not all projects use Go 1.22+. Keep compatible. | **Capture loop variables** |

---
