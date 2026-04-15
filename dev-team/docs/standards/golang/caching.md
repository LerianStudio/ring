# Go Standards - Caching Strategy

> **Module:** caching.md | **Sections:** §51-52 | **Parent:** [index.md](index.md)

This module covers caching strategy patterns using lib-commons Redis integration.

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [Caching Strategy Patterns (MANDATORY)](#caching-strategy-patterns-mandatory) | Cache-Aside, Write-Through, Write-Behind with lib-commons Redis |
| 2 | [Cache Compliance Detection](#cache-compliance-detection) | Detection commands for dev-refactor strategy identification |

---

## Caching Strategy Patterns (MANDATORY)

Services that use Redis for caching MUST follow one of the three canonical strategies below. Each strategy has specific compliance requirements.

### Strategy Decision Framework

| Criteria | Cache-Aside | Write-Through | Write-Behind |
|----------|-------------|---------------|-------------|
| **Consistency** | Eventual (TTL-based) | Strong (dual write) | Eventual (async sync) |
| **Write latency** | Normal (no cache write on write path) | Higher (2x write) | Lowest (cache only) |
| **Read latency** | Slow on miss, fast on hit | Always fast | Always fast |
| **Data loss risk** | None (cache is disposable) | None (DB always written) | Yes (cache crash before sync) |
| **Use when** | Read-heavy, stale data tolerable for TTL | Read-heavy, consistency required | Write-heavy, eventual consistency ok |
| **Lerian examples** | Config lookups, metadata, report templates | Account balances, tenant settings | Metrics counters, audit log buffering |

### Cache-Aside (Lazy Loading)

The application manages the cache manually. On read: check cache first, on miss read from DB and populate cache. On write: write to DB, then invalidate cache.

```go
// internal/adapters/redis/entity.redis.go

type EntityCacheRepository struct {
    conn    *libRedis.RedisConnection
    dbRepo  ports.EntityRepository  // fallback to DB
    ttl     time.Duration
}

// Read path: cache first, DB on miss, populate cache
func (r *EntityCacheRepository) FindByID(ctx context.Context, id uuid.UUID) (*entity.Entity, error) {
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "cache.entity.find_by_id")
    defer span.End()

    rds, err := r.conn.GetConnection(ctx)
    if err != nil {
        // Cache unavailable — fallback to DB (graceful degradation)
        logger.Warnf("Redis unavailable, falling back to DB: %v", err)
        return r.dbRepo.FindByID(ctx, id)
    }

    // Tenant-aware key prefixing
    key := valkey.GetKeyContext(ctx, fmt.Sprintf("entity:%s", id.String()))

    // Try cache
    cached, err := rds.Get(ctx, key).Result()
    if err == nil {
        var e entity.Entity
        if json.Unmarshal([]byte(cached), &e) == nil {
            return &e, nil
        }
    }

    // Cache miss — read from DB
    e, err := r.dbRepo.FindByID(ctx, id)
    if err != nil {
        return nil, err
    }

    // Populate cache (best-effort, don't fail the request)
    data, _ := json.Marshal(e)
    _ = rds.Set(ctx, key, data, r.ttl).Err()

    return e, nil
}

// Write path: write to DB, then INVALIDATE cache (not update)
func (r *EntityCacheRepository) Update(ctx context.Context, e *entity.Entity) error {
    if err := r.dbRepo.Update(ctx, e); err != nil {
        return err
    }

    // Invalidate — next read will repopulate from DB
    rds, err := r.conn.GetConnection(ctx)
    if err != nil {
        return nil // DB write succeeded, cache invalidation is best-effort
    }

    key := valkey.GetKeyContext(ctx, fmt.Sprintf("entity:%s", e.ID.String()))
    _ = rds.Del(ctx, key).Err()

    return nil
}
```

**Compliance requirements for Cache-Aside:**
- MUST have TTL on every `Set` call (never cache forever)
- MUST invalidate cache on `Update` and `Delete` (not just on `Create`)
- MUST fall back to DB when Redis is unavailable (graceful degradation)
- MUST use `valkey.GetKeyContext(ctx, key)` for all keys (multi-tenant aware)
- SHOULD implement stampede prevention for hot keys (see below)

### Write-Through

The application writes to both cache and database in the same operation. Cache is always consistent with DB.

```go
// internal/adapters/redis/balance.redis.go

type BalanceCacheRepository struct {
    conn    *libRedis.RedisConnection
    dbRepo  ports.BalanceRepository
    ttl     time.Duration
}

// Write path: write to DB AND cache in same operation
func (r *BalanceCacheRepository) UpdateBalance(ctx context.Context, b *entity.Balance) error {
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "cache.balance.update")
    defer span.End()

    // Write to DB first (source of truth)
    if err := r.dbRepo.UpdateBalance(ctx, b); err != nil {
        return err
    }

    // Write to cache (keep in sync)
    rds, err := r.conn.GetConnection(ctx)
    if err != nil {
        logger.Warnf("Redis unavailable after DB write, cache stale: %v", err)
        return nil // DB write succeeded, cache staleness is acceptable
    }

    key := valkey.GetKeyContext(ctx, fmt.Sprintf("balance:%s", b.ID.String()))
    data, _ := json.Marshal(b)

    if err := rds.Set(ctx, key, data, r.ttl).Err(); err != nil {
        logger.Warnf("Cache write failed after DB write: %v", err)
    }

    return nil
}

// Read path: always from cache (cache is always fresh)
func (r *BalanceCacheRepository) GetBalance(ctx context.Context, id uuid.UUID) (*entity.Balance, error) {
    rds, err := r.conn.GetConnection(ctx)
    if err != nil {
        return r.dbRepo.GetBalance(ctx, id) // fallback
    }

    key := valkey.GetKeyContext(ctx, fmt.Sprintf("balance:%s", id.String()))

    cached, err := rds.Get(ctx, key).Result()
    if err == nil {
        var b entity.Balance
        if json.Unmarshal([]byte(cached), &b) == nil {
            return &b, nil
        }
    }

    // Cache miss (shouldn't happen often in write-through)
    return r.dbRepo.GetBalance(ctx, id)
}
```

**Compliance requirements for Write-Through:**
- MUST write to DB before cache (DB is source of truth)
- MUST NOT fail the request if cache write fails after DB write succeeds
- MUST use TTL even though cache is kept in sync (defense against stale data on cache recovery)
- MUST use `valkey.GetKeyContext(ctx, key)` for all keys

### Write-Behind (Write-Back)

The application writes to cache only. A background worker syncs to DB asynchronously. Highest write throughput but risk of data loss.

```go
// internal/adapters/redis/counter.redis.go

type CounterCacheRepository struct {
    conn    *libRedis.RedisConnection
    ttl     time.Duration
}

// Write path: cache only — background worker syncs to DB
func (r *CounterCacheRepository) Increment(ctx context.Context, counterID string, delta int64) error {
    rds, err := r.conn.GetConnection(ctx)
    if err != nil {
        return fmt.Errorf("redis unavailable for write-behind counter: %w", err)
    }

    key := valkey.GetKeyContext(ctx, fmt.Sprintf("counter:%s", counterID))

    // Atomic increment in Redis — no DB call
    if err := rds.IncrBy(ctx, key, delta).Err(); err != nil {
        return fmt.Errorf("counter increment failed: %w", err)
    }

    // Ensure key has TTL (defense against orphaned keys)
    rds.Expire(ctx, key, r.ttl)

    return nil
}
```

**Compliance requirements for Write-Behind:**
- MUST have a background sync worker that flushes to DB
- MUST have retry logic in the sync worker (at-least-once delivery)
- MUST have alerting if sync queue grows beyond threshold
- MUST document the data loss window (time between cache write and DB sync)
- MUST use `valkey.GetKeyContext(ctx, key)` for all keys
- SHOULD use atomic Redis operations (INCR, HSET) to avoid read-modify-write races

### Stampede Prevention

When a hot key expires, many concurrent requests hit the DB simultaneously. Prevent this with singleflight:

```go
import "golang.org/x/sync/singleflight"

type CachedRepository struct {
    conn    *libRedis.RedisConnection
    dbRepo  ports.EntityRepository
    ttl     time.Duration
    sf      singleflight.Group
}

func (r *CachedRepository) FindByID(ctx context.Context, id uuid.UUID) (*entity.Entity, error) {
    rds, err := r.conn.GetConnection(ctx)
    if err != nil {
        return r.dbRepo.FindByID(ctx, id)
    }

    key := valkey.GetKeyContext(ctx, fmt.Sprintf("entity:%s", id.String()))

    cached, err := rds.Get(ctx, key).Result()
    if err == nil {
        var e entity.Entity
        if json.Unmarshal([]byte(cached), &e) == nil {
            return &e, nil
        }
    }

    // Singleflight: only one goroutine hits DB, others wait for result
    result, err, _ := r.sf.Do(key, func() (interface{}, error) {
        e, err := r.dbRepo.FindByID(ctx, id)
        if err != nil {
            return nil, err
        }

        data, _ := json.Marshal(e)
        _ = rds.Set(ctx, key, data, r.ttl).Err()

        return e, nil
    })

    if err != nil {
        return nil, err
    }

    return result.(*entity.Entity), nil
}
```

**When stampede prevention is MANDATORY:**
- Keys with TTL < 60s that serve > 100 req/s
- Keys that trigger expensive DB queries (JOINs, aggregations)
- Keys shared across multiple endpoints

### TTL Best Practices

| Data Type | Recommended TTL | Rationale |
|-----------|----------------|-----------|
| User session data | 30min - 2h | Balance between UX and freshness |
| Configuration/settings | 5min - 15min | Rarely changes, fast invalidation on update |
| Entity lookups | 1min - 5min | Frequently accessed, tolerable stale window |
| Report templates | 1h - 24h | Rarely changes |
| Counters/metrics | 5min - 30min | Aggregated periodically |
| Rate limiting | 1s - 60s | Must be precise |

### Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "No TTL needed, we invalidate on write" | Cache recovery after crash leaves stale data forever without TTL. | **MUST set TTL on every Set call** |
| "Update cache on write instead of invalidate" | Double-write without transaction risks inconsistency (DB succeeds, cache fails with stale old value). Invalidate is safer. | **Invalidate on mutation for Cache-Aside** |
| "Redis never goes down" | Every dependency fails eventually. Without graceful degradation, Redis outage = service outage. | **MUST fall back to DB when Redis unavailable** |
| "Raw Redis keys are fine" | Without `valkey.GetKeyContext`, multi-tenant mode leaks data across tenants. | **MUST use valkey.GetKeyContext for every key** |
| "Stampede won't happen to us" | Any TTL expiry under load causes stampede. It's math, not probability. | **Implement singleflight for hot keys** |
| "Write-Behind is too risky" | It depends on the use case. Counters and metrics are perfect for Write-Behind. Balance and transactions are not. | **Choose strategy based on data criticality** |

---

## Cache Compliance Detection

### Strategy Detection Commands (for dev-refactor)

```bash
# Detect Cache-Aside pattern: Get before DB query + Set after
grep -rn "\.Get(ctx" internal/adapters/redis/ --include="*.go" | grep -v "_test.go"
# Then check if same file has DB fallback:
grep -rn "dbRepo\.\|\.Query\|\.QueryRow" internal/adapters/redis/ --include="*.go" | grep -v "_test.go"
# If both present → Cache-Aside detected

# Detect Write-Through pattern: DB write + cache Set in same method
grep -rn "\.Set(ctx" internal/adapters/redis/ --include="*.go" | grep -v "_test.go"
# Check if same method also writes to DB (look for dbRepo calls in same function)

# Detect Write-Behind pattern: cache write without DB write in same method
# Plus background worker/cron that syncs
grep -rn "IncrBy\|HSet\|LPush" internal/adapters/redis/ --include="*.go" | grep -v "_test.go"
grep -rn "sync.*worker\|flush.*db\|sync.*database" internal/ --include="*.go" | grep -v "_test.go"

# Detect missing tenant-aware keys (NON-COMPLIANT)
grep -rn "\.Set(ctx\|\.Get(ctx\|\.Del(ctx" internal/adapters/redis/ --include="*.go" | grep -v "GetKeyContext\|_test.go"
# Expected: 0 matches. All Redis operations must use valkey.GetKeyContext.

# Detect missing TTL (NON-COMPLIANT)
grep -rn "\.Set(ctx" internal/adapters/redis/ --include="*.go" | grep -v "_test.go" | grep -v "ttl\|TTL\|Expir"
# Expected: 0 matches. Every Set must have a TTL.

# Detect missing cache invalidation on mutations
grep -rn "func.*Update\|func.*Delete" internal/adapters/redis/ --include="*.go" | grep -v "_test.go"
# Then verify each has a corresponding Del call
```

### Compliance Checklist (for production-readiness-audit)

| Check | What it validates | Failure = |
|-------|------------------|-----------|
| Strategy identified | Service uses one of the 3 canonical strategies | WARNING if no clear strategy |
| Tenant-aware keys | All Redis ops use `valkey.GetKeyContext` | CRITICAL (data leakage in MT) |
| TTL on all Set | Every `Set` call includes TTL | HIGH (stale data forever) |
| Invalidation on mutation | `Update`/`Delete` methods invalidate cache | HIGH (stale reads) |
| Graceful degradation | Redis unavailable → service still works via DB | HIGH (single point of failure) |
| Stampede prevention | Hot keys use singleflight or mutex | MEDIUM (DB overload risk) |
| Write-Behind has sync worker | Background worker flushes to DB | CRITICAL (data loss) |
| Write-Behind has retry | Sync worker retries on failure | HIGH (data loss on transient errors) |

### Checklist

- [ ] Caching strategy is one of: Cache-Aside, Write-Through, Write-Behind
- [ ] All Redis keys use `valkey.GetKeyContext(ctx, key)` for multi-tenant support
- [ ] All `Set` calls include TTL (never cache indefinitely)
- [ ] Cache invalidation on `Update` and `Delete` mutations
- [ ] Graceful degradation: DB fallback when Redis unavailable
- [ ] Stampede prevention via `singleflight` for hot keys
- [ ] Write-Behind: background sync worker exists with retry logic
- [ ] Strategy documented in `docs/PROJECT_RULES.md` or equivalent
