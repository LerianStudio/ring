# Caching Analysis Checklist (MANDATORY)

**⛔ CACHING ANALYSIS (MANDATORY when Redis detected in stack):**

See [caching.md § Caching Strategy Patterns](../../docs/standards/golang/caching.md#caching-strategy-patterns-mandatory) for canonical patterns.

## Detection

1. **Stack check:** Does `go.mod` contain `redis` or `valkey`? Does `docker-compose` have a Redis service?
2. **If Redis detected → run caching analysis:**

## Strategy Identification

```bash
# Detect Redis adapter files
find internal/adapters/redis/ -name "*.go" ! -name "*_test.go" 2>/dev/null

# Detect Cache-Aside: Get before DB + Set after DB
grep -rn "\.Get(ctx" internal/adapters/redis/ --include="*.go" | grep -v "_test.go"
grep -rn "dbRepo\.\|\.Query\|\.QueryRow" internal/adapters/redis/ --include="*.go" | grep -v "_test.go"

# Detect Write-Through: Set + DB write in same method
grep -rn "\.Set(ctx" internal/adapters/ --include="*.go" | grep -v "_test.go"

# Detect Write-Behind: cache-only writes + background sync
grep -rn "IncrBy\|HIncrBy\|LPush" internal/adapters/redis/ --include="*.go" | grep -v "_test.go"
```

## Compliance Checks

```bash
# Check all Redis ops use tenant-aware keys (CRITICAL in multi-tenant)
grep -rn "\.Set(ctx\|\.Get(ctx\|\.Del(ctx\|\.SetNX(ctx" internal/adapters/redis/ --include="*.go" | grep -v "GetKeyContext\|_test.go"
# Expected: 0 matches

# Check TTL on all Set calls
grep -rn "\.Set(ctx" internal/adapters/redis/ --include="*.go" | grep -v "_test.go" | grep -v "ttl\|TTL\|Expir\|time\."
# Expected: 0 matches

# Check cache invalidation on mutations
for f in $(grep -rln "func.*Update\|func.*Delete" internal/adapters/redis/ --include="*.go" | grep -v "_test.go"); do
  has_del=$(grep -c "\.Del(ctx" "$f" 2>/dev/null)
  if [ "$has_del" -eq 0 ]; then
    echo "MISSING INVALIDATION: $f"
  fi
done
# Expected: 0 missing

# Check graceful degradation (DB fallback when Redis unavailable)
grep -rn "GetConnection(ctx)" internal/adapters/redis/ --include="*.go" | grep -v "_test.go"
# Then verify each has error handling that falls back to DB
```

- Each non-compliant item → ISSUE-XXX with severity based on compliance checklist in caching.md
- Missing tenant-aware keys → CRITICAL
- Missing TTL → HIGH
- Missing invalidation on mutation → HIGH
- Missing graceful degradation → HIGH
- Missing strategy documentation → MEDIUM
