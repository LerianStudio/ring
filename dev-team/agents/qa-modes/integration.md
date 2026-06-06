# QA Analyst — Integration Testing Mode

Extends `qa-analyst.v2.md`. Load this file when dispatched with `mode: integration`.

## When Integration Testing Applies

- Service-to-database integration (real PostgreSQL/MongoDB)
- Service-to-message-queue (real RabbitMQ)
- API endpoint testing with real HTTP handlers
- Cross-service interaction testing

## Infrastructure: Testcontainers

```go
import (
    "github.com/testcontainers/testcontainers-go"
    "github.com/testcontainers/testcontainers-go/modules/postgres"
)

func TestMain(m *testing.M) {
    ctx := context.Background()

    pgContainer, err := postgres.RunContainer(ctx,
        testcontainers.WithImage("postgres:16.3-alpine"),
        postgres.WithDatabase("testdb"),
        postgres.WithUsername("test"),
        postgres.WithPassword("test"),
        testcontainers.WithWaitStrategy(
            wait.ForLog("database system is ready to accept connections"),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }
    defer pgContainer.Terminate(ctx)

    connStr, _ := pgContainer.ConnectionString(ctx, "sslmode=disable")
    os.Setenv("DATABASE_URL", connStr)

    os.Exit(m.Run())
}
```

## Integration Test Structure

```go
func TestAccountRepository_Create(t *testing.T) {
    // Uses real DB from TestMain
    repo := NewPostgresAccountRepository(testDB)

    t.Run("creates account successfully", func(t *testing.T) {
        acc := &Account{Name: "Test Account", OrgID: "org-1"}
        err := repo.Create(ctx, acc)
        require.NoError(t, err)
        assert.NotEmpty(t, acc.ID)

        // Verify persisted
        found, err := repo.FindByID(ctx, acc.ID)
        require.NoError(t, err)
        assert.Equal(t, "Test Account", found.Name)
    })

    t.Run("duplicate name in same org returns conflict", func(t *testing.T) {
        acc := &Account{Name: "Duplicate", OrgID: "org-1"}
        require.NoError(t, repo.Create(ctx, acc))

        duplicate := &Account{Name: "Duplicate", OrgID: "org-1"}
        err := repo.Create(ctx, duplicate)
        require.Error(t, err)
        assert.Equal(t, "CONFLICT", extractCode(err))
    })
}
```

## Scenario Coverage

Integration tests MUST cover:
- **Happy path:** Full success flow end-to-end
- **Error paths:** Dependency failures, constraint violations
- **Boundary conditions:** Empty datasets, max records
- **Concurrency:** Parallel writes to same resource (if applicable)

## Running Integration Tests

```bash
# Build tag separates integration from unit tests
go test -tags=integration ./... -v -timeout=120s
```

## Output Format

```markdown
## VERDICT: [PASS | FAIL]

## Integration Testing Summary

| Metric | Value |
|--------|-------|
| Scenarios Tested | N |
| Infrastructure | PostgreSQL 16.3, RabbitMQ 3.13 (testcontainers) |
| Duration | Xs |

## Scenario Coverage

| Scenario | Type | Status |
|----------|------|--------|
| Account creation with real DB | Happy path | ✅ PASS |
| Duplicate name constraint | Error path | ✅ PASS |
| Concurrent writes | Concurrency | ✅ PASS |

## Quality Gate Results

| Check | Status |
|-------|--------|
| All scenarios pass | ✅ |
| No test isolation leaks | ✅ |
| Containers healthy | ✅ |

## Next Steps
[PASS: "Integration tests pass." | FAIL: list failed scenarios with root cause.]
```
