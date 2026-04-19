# Caching Strategy Standard & CQRS Pattern Implementation Plan

> **NOTE:** This plan was authored when lib-commons v2/v4 was current. Code examples reflect the version at plan-time. Current standard is lib-commons/v5 v5.0.2.

> **For Agents:** REQUIRED SUB-SKILL: Use ring:execute-plan to implement this plan task-by-task.

**Goal:** Add two new Go engineering standards to the Ring project: a new `caching.md` module (Module 20) and a new CQRS section in the existing `architecture.md`.

**Architecture:** The Ring project is a markdown-based standards library. Standards live in `dev-team/docs/standards/golang/` as modular markdown files. Every standards change MUST follow the FOUR-FILE UPDATE RULE from CLAUDE.md: (1) the standards file itself, (2) its internal TOC, (3) the coverage table in `dev-team/skills/shared-patterns/standards-coverage-table.md`, and (4) verification that the agent file references the coverage table. Additionally, the `index.md` file tracks all modules and MUST be updated when adding a new module.

**Tech Stack:** Markdown, Go code examples (lib-commons v2/v4, Fiber, Redis/Valkey, PostgreSQL)

**Global Prerequisites:**
- Environment: macOS or Linux, Git 2.x+
- Tools: Any text editor, Git CLI
- Access: Write access to `LerianStudio/ring` repository
- State: Branch from `main`, clean working tree

**Verification before starting:**
```bash
# Run ALL these commands and verify output:
git --version          # Expected: git version 2.x+
git status             # Expected: clean working tree on main (or feature branch)
ls dev-team/docs/standards/golang/index.md  # Expected: file exists
ls dev-team/docs/standards/golang/architecture.md  # Expected: file exists
ls dev-team/skills/shared-patterns/standards-coverage-table.md  # Expected: file exists
ls dev-team/agents/backend-engineer-golang.md  # Expected: file exists
```

---

## Part A: Create `caching.md` (New Module 20)

### Task 1: Create the `caching.md` file with Section 1 (Caching Strategy Patterns)

**Files:**
- Create: `dev-team/docs/standards/golang/caching.md`

**Prerequisites:**
- Directory exists: `dev-team/docs/standards/golang/`

**Step 1: Create the file with the full content**

Create `dev-team/docs/standards/golang/caching.md` with the following complete content:

```markdown
# Go Standards - Caching

> **Module:** caching.md | **Sections:** 2 | **Parent:** [index.md](index.md)

This module covers caching strategy patterns and compliance detection for Redis/Valkey-based caching using lib-commons.

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [Caching Strategy Patterns (MANDATORY)](#caching-strategy-patterns-mandatory) | Cache-Aside, Write-Through, Write-Behind strategies with lib-commons Redis |
| 2 | [Cache Compliance Detection](#cache-compliance-detection) | Detection commands for dev-refactor caching analysis |

**Meta-sections:**
- [Anti-Rationalization Table](#anti-rationalization-table) - Common excuses and required actions
- [Checklist](#checklist) - Pre-submission verification

---

## Caching Strategy Patterns (MANDATORY)

**MUST implement caching using lib-commons Redis patterns.** All cache keys MUST use `valkey.GetKeyContext(ctx, key)` for multi-tenant awareness. All Redis connections MUST use `r.conn.GetConnection(ctx)` for tenant-scoped connection resolution. **HARD GATE**

### Why Caching Standards Are Mandatory

| Problem | Consequence | Solution |
|---------|-------------|----------|
| No caching strategy | Every request hits DB, latency spikes under load | Define explicit strategy per data type |
| Hardcoded keys without tenant prefix | Cross-tenant data leakage in multi-tenant mode | `valkey.GetKeyContext(ctx, key)` for every key |
| No TTL on cache entries | Stale data served indefinitely, memory exhaustion | Explicit TTL on every `Set` call |
| No invalidation on mutations | Users see outdated data after updates | Invalidate/delete cache on every write operation |
| Cache stampede on cold start | Thundering herd overwhelms DB | singleflight or mutex-based stampede prevention |

### Strategy Decision Framework

| Strategy | Consistency | Latency | Throughput | Best For |
|----------|-------------|---------|------------|----------|
| **Cache-Aside** | Eventual (TTL-bounded) | Low on hit, high on miss | Medium | Read-heavy data, tolerance for stale reads |
| **Write-Through** | Strong (always consistent) | Higher on writes | Medium | Data that MUST be consistent, audit logs |
| **Write-Behind** | Eventual (async sync) | Lowest on writes | Highest | High-throughput writes, analytics, counters |

**Decision Guide:**

| Scenario | Recommended Strategy | Reason |
|----------|---------------------|--------|
| User profile lookups | Cache-Aside | Read-heavy, tolerance for brief staleness |
| Account balance display | Cache-Aside with short TTL | Frequently read, needs near-real-time |
| Transaction processing | Write-Through | MUST be consistent, financial data |
| Configuration/settings | Cache-Aside with long TTL | Rarely changes, read on every request |
| Audit event logging | Write-Behind | High volume, eventual persistence acceptable |
| Rate limit counters | Write-Behind | High throughput, loss of a few counts acceptable |
| Session data | Cache-Aside | Read-heavy, natural TTL expiration |

### Strategy 1: Cache-Aside (Lazy Loading)

The application reads from cache first. On miss, it reads from the database and populates the cache. The cache is never written to directly by the database.

```
Request → Check cache (rds.Get)
    ├─ HIT → Return cached value
    └─ MISS → Query DB → Write to cache (rds.Set with TTL) → Return value
```

**Complete Implementation:**

```go
// internal/adapters/redis/cache_repository.go
package redis

import (
    "context"
    "encoding/json"
    "errors"
    "time"

    libCommons "github.com/LerianStudio/lib-commons/v2/commons"
    libOpentelemetry "github.com/LerianStudio/lib-commons/v2/commons/opentelemetry"
    valkey "github.com/LerianStudio/lib-commons/v4/commons/tenant-manager/valkey"
    goredis "github.com/redis/go-redis/v9"
)

// CacheRepository handles cache operations using lib-commons Redis patterns.
type CacheRepository struct {
    conn RedisConnection // lib-commons Redis connection
}

// NewCacheRepository creates a new CacheRepository.
func NewCacheRepository(conn RedisConnection) *CacheRepository {
    return &CacheRepository{conn: conn}
}

// GetOrLoad implements Cache-Aside pattern.
// Checks cache first, on miss calls loader function, caches result with TTL.
// All keys are tenant-aware via valkey.GetKeyContext.
func (r *CacheRepository) GetOrLoad(
    ctx context.Context,
    key string,
    ttl time.Duration,
    loader func(ctx context.Context) (interface{}, error),
) ([]byte, error) {
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "cache.get_or_load")
    defer span.End()

    // Step 1: Tenant-aware key prefixing
    prefixedKey := valkey.GetKeyContext(ctx, key)

    // Step 2: Get Redis connection (tenant-scoped in multi-tenant mode)
    rds, err := r.conn.GetConnection(ctx)
    if err != nil {
        libOpentelemetry.HandleSpanError(&span, "Failed to get Redis connection", err)
        logger.Errorf("Failed to get Redis connection: %v", err)
        // Fallback to loader on Redis failure (degrade gracefully)
        return r.loadAndMarshal(ctx, loader)
    }

    // Step 3: Try cache first
    cached, err := rds.Get(ctx, prefixedKey).Bytes()
    if err == nil {
        logger.Infof("Cache HIT for key: %s", key)
        return cached, nil
    }

    if !errors.Is(err, goredis.Nil) {
        libOpentelemetry.HandleSpanError(&span, "Redis Get error", err)
        logger.Errorf("Redis Get error for key %s: %v", key, err)
        // Fallback to loader on Redis error
        return r.loadAndMarshal(ctx, loader)
    }

    // Step 4: Cache MISS - load from source
    logger.Infof("Cache MISS for key: %s, loading from source", key)

    data, err := loader(ctx)
    if err != nil {
        return nil, err
    }

    // Step 5: Marshal and cache the result
    bytes, err := json.Marshal(data)
    if err != nil {
        logger.Errorf("Failed to marshal cache value for key %s: %v", key, err)
        return nil, err
    }

    // Step 6: Write to cache with TTL (non-blocking error - log but don't fail)
    if setErr := rds.Set(ctx, prefixedKey, bytes, ttl).Err(); setErr != nil {
        logger.Errorf("Failed to set cache for key %s: %v", key, setErr)
        // Don't fail the request - cache write failure is non-critical
    }

    return bytes, nil
}

// loadAndMarshal calls the loader and marshals the result.
func (r *CacheRepository) loadAndMarshal(
    ctx context.Context,
    loader func(ctx context.Context) (interface{}, error),
) ([]byte, error) {
    data, err := loader(ctx)
    if err != nil {
        return nil, err
    }

    bytes, err := json.Marshal(data)
    if err != nil {
        return nil, err
    }

    return bytes, nil
}

// Invalidate removes a cache entry. MUST be called on every mutation (Update/Delete).
func (r *CacheRepository) Invalidate(ctx context.Context, key string) error {
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "cache.invalidate")
    defer span.End()

    prefixedKey := valkey.GetKeyContext(ctx, key)

    rds, err := r.conn.GetConnection(ctx)
    if err != nil {
        libOpentelemetry.HandleSpanError(&span, "Failed to get Redis connection for invalidation", err)
        logger.Errorf("Failed to get Redis connection for invalidation: %v", err)
        return err
    }

    if err := rds.Del(ctx, prefixedKey).Err(); err != nil {
        libOpentelemetry.HandleSpanError(&span, "Failed to invalidate cache", err)
        logger.Errorf("Failed to invalidate cache key %s: %v", key, err)
        return err
    }

    logger.Infof("Cache invalidated for key: %s", key)

    return nil
}
```

**Usage in Service Layer (Cache-Aside):**

```go
// internal/services/query/get_account.go
func (uc *UseCase) GetAccount(ctx context.Context, id uuid.UUID) (*domain.Account, error) {
    cacheKey := fmt.Sprintf("account:%s", id.String())

    bytes, err := uc.CacheRepo.GetOrLoad(ctx, cacheKey, 5*time.Minute, func(ctx context.Context) (interface{}, error) {
        return uc.AccountRepo.FindByID(ctx, id)
    })
    if err != nil {
        return nil, err
    }

    var account domain.Account
    if err := json.Unmarshal(bytes, &account); err != nil {
        return nil, err
    }

    return &account, nil
}

// internal/services/command/update_account.go
func (uc *UseCase) UpdateAccount(ctx context.Context, id uuid.UUID, input UpdateAccountInput) (*domain.Account, error) {
    // ... validation and DB update ...

    account, err := uc.AccountRepo.Update(ctx, id, input)
    if err != nil {
        return nil, err
    }

    // MANDATORY: Invalidate cache on mutation
    cacheKey := fmt.Sprintf("account:%s", id.String())
    if err := uc.CacheRepo.Invalidate(ctx, cacheKey); err != nil {
        // Log but don't fail the mutation - cache will expire via TTL
        logger.Errorf("Failed to invalidate cache after update: %v", err)
    }

    return account, nil
}
```

### Strategy 2: Write-Through

The handler writes to both cache and database in the same operation. The cache is always consistent with the database because every write updates both.

```
Write Request → Write to DB → Write to cache (rds.Set with TTL) → Return
Read Request  → Check cache (rds.Get) → Return (always consistent)
```

**Complete Implementation:**

```go
// internal/services/command/create_transaction.go

// CreateTransaction implements Write-Through caching.
// Both DB and cache are written in the same operation.
func (uc *UseCase) CreateTransaction(ctx context.Context, input CreateTransactionInput) (*domain.Transaction, error) {
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "command.create_transaction")
    defer span.End()

    // Step 1: Validate and create in database
    transaction, err := uc.TransactionRepo.Create(ctx, input)
    if err != nil {
        return nil, err
    }

    // Step 2: Write to cache immediately (Write-Through)
    cacheKey := fmt.Sprintf("transaction:%s", transaction.ID.String())
    prefixedKey := valkey.GetKeyContext(ctx, cacheKey)

    rds, err := uc.RedisConn.GetConnection(ctx)
    if err != nil {
        // Log error but return success - DB write succeeded
        logger.Errorf("Write-Through cache failed (Redis connection): %v", err)
        return transaction, nil
    }

    bytes, err := json.Marshal(transaction)
    if err != nil {
        logger.Errorf("Write-Through cache failed (marshal): %v", err)
        return transaction, nil
    }

    if err := rds.Set(ctx, prefixedKey, bytes, 10*time.Minute).Err(); err != nil {
        logger.Errorf("Write-Through cache failed (Set): %v", err)
        // Return success - DB write is the source of truth
    }

    return transaction, nil
}
```

### Strategy 3: Write-Behind (Write-Back)

The handler writes to cache only. A background worker asynchronously syncs cached data to the database. This provides the highest write throughput but carries risk of data loss if the cache fails before sync.

```
Write Request → Write to cache only (rds.Set) → Return immediately
Background Worker → Read from cache → Write to DB → Delete from cache
```

**Complete Implementation:**

```go
// internal/adapters/redis/write_behind_buffer.go

// WriteBehindBuffer stores writes in Redis for async DB persistence.
// WARNING: Data in the buffer is at risk until synced to DB.
type WriteBehindBuffer struct {
    conn      RedisConnection
    queueKey  string
    batchSize int
}

// NewWriteBehindBuffer creates a new write-behind buffer.
func NewWriteBehindBuffer(conn RedisConnection, queueKey string, batchSize int) *WriteBehindBuffer {
    return &WriteBehindBuffer{
        conn:      conn,
        queueKey:  queueKey,
        batchSize: batchSize,
    }
}

// Push adds an item to the write-behind queue.
func (b *WriteBehindBuffer) Push(ctx context.Context, value interface{}) error {
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "cache.write_behind_push")
    defer span.End()

    prefixedKey := valkey.GetKeyContext(ctx, b.queueKey)

    rds, err := b.conn.GetConnection(ctx)
    if err != nil {
        libOpentelemetry.HandleSpanError(&span, "Failed to get Redis connection", err)
        return err
    }

    bytes, err := json.Marshal(value)
    if err != nil {
        return err
    }

    if err := rds.RPush(ctx, prefixedKey, bytes).Err(); err != nil {
        libOpentelemetry.HandleSpanError(&span, "Failed to push to write-behind queue", err)
        logger.Errorf("Write-behind push failed for queue %s: %v", b.queueKey, err)
        return err
    }

    return nil
}

// Flush reads a batch from the queue for DB persistence.
// Called by the background worker.
func (b *WriteBehindBuffer) Flush(ctx context.Context) ([][]byte, error) {
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "cache.write_behind_flush")
    defer span.End()

    prefixedKey := valkey.GetKeyContext(ctx, b.queueKey)

    rds, err := b.conn.GetConnection(ctx)
    if err != nil {
        return nil, err
    }

    // Atomically pop a batch from the queue
    var items [][]byte

    for i := 0; i < b.batchSize; i++ {
        result, err := rds.LPop(ctx, prefixedKey).Bytes()
        if err != nil {
            if errors.Is(err, goredis.Nil) {
                break // Queue empty
            }

            logger.Errorf("Write-behind flush error: %v", err)

            break
        }

        items = append(items, result)
    }

    return items, nil
}
```

**WARNING: Write-Behind carries data loss risk.** If Redis crashes before the background worker syncs to the database, buffered writes are lost. Only use for data where eventual loss is acceptable (analytics, counters, non-financial events).

### TTL Best Practices

| Data Type | Recommended TTL | Rationale |
|-----------|----------------|-----------|
| User session | 30 minutes | Matches session timeout |
| Configuration/settings | 1 hour | Rarely changes, long TTL safe |
| Account balance | 30 seconds - 2 minutes | Needs near-real-time accuracy |
| Transaction details | 5-10 minutes | Immutable after creation |
| Rate limit counters | Window size (e.g., 60s) | Matches rate limit window |
| Search results | 5-15 minutes | Tolerance for staleness |
| Idempotency keys | 5 minutes (default) | See [idempotency.md](idempotency.md) |

**TTL Rules:**

| Rule | Enforcement |
|------|-------------|
| Every `rds.Set` MUST have an explicit TTL | **HARD GATE** - no `0` or negative TTL in production |
| TTL MUST come from configuration, not hardcoded | Config struct or constants, not magic numbers |
| Financial data TTL MUST be short (< 5 min) | Stale financial data causes incorrect decisions |
| Immutable data can have longer TTL | Transaction records don't change after creation |

### Eviction Policy

**MUST configure Redis `maxmemory-policy` for production:**

| Policy | Use When |
|--------|----------|
| `allkeys-lru` | General caching - evict least recently used keys first |
| `volatile-lru` | Only evict keys with TTL set (keeps persistent keys) |
| `noeviction` | FORBIDDEN for caching - causes write errors when full |

### Cache Stampede Prevention (MANDATORY)

When a popular cache key expires, many concurrent requests may simultaneously attempt to load from the database, overwhelming it. This is called a "cache stampede" or "thundering herd."

**Option 1: singleflight (RECOMMENDED)**

```go
import "golang.org/x/sync/singleflight"

// Package-level singleflight group
var sfGroup singleflight.Group

// GetOrLoadWithSingleflight prevents cache stampede.
// Only one goroutine loads from source; others wait for the result.
func (r *CacheRepository) GetOrLoadWithSingleflight(
    ctx context.Context,
    key string,
    ttl time.Duration,
    loader func(ctx context.Context) (interface{}, error),
) ([]byte, error) {
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "cache.get_or_load_sf")
    defer span.End()

    prefixedKey := valkey.GetKeyContext(ctx, key)

    // Try cache first
    rds, err := r.conn.GetConnection(ctx)
    if err == nil {
        cached, err := rds.Get(ctx, prefixedKey).Bytes()
        if err == nil {
            return cached, nil
        }
    }

    // Cache miss - use singleflight to deduplicate concurrent loads
    result, err, shared := sfGroup.Do(key, func() (interface{}, error) {
        logger.Infof("singleflight: loading key %s from source", key)

        data, err := loader(ctx)
        if err != nil {
            return nil, err
        }

        bytes, err := json.Marshal(data)
        if err != nil {
            return nil, err
        }

        // Populate cache for future requests
        if rds != nil {
            if setErr := rds.Set(ctx, prefixedKey, bytes, ttl).Err(); setErr != nil {
                logger.Errorf("singleflight: cache set failed for key %s: %v", key, setErr)
            }
        }

        return bytes, nil
    })

    if err != nil {
        return nil, err
    }

    if shared {
        logger.Infof("singleflight: shared result for key %s", key)
    }

    return result.([]byte), nil
}
```

**Option 2: Mutex-based (for distributed systems)**

```go
// DistributedLockLoad uses Redis SetNX as a distributed lock to prevent stampede.
func (r *CacheRepository) DistributedLockLoad(
    ctx context.Context,
    key string,
    ttl time.Duration,
    loader func(ctx context.Context) (interface{}, error),
) ([]byte, error) {
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "cache.distributed_lock_load")
    defer span.End()

    prefixedKey := valkey.GetKeyContext(ctx, key)
    lockKey := valkey.GetKeyContext(ctx, "lock:"+key)

    rds, err := r.conn.GetConnection(ctx)
    if err != nil {
        return r.loadAndMarshal(ctx, loader)
    }

    // Try cache first
    cached, err := rds.Get(ctx, prefixedKey).Bytes()
    if err == nil {
        return cached, nil
    }

    // Try to acquire distributed lock
    locked, err := rds.SetNX(ctx, lockKey, "1", 10*time.Second).Result()
    if err != nil || !locked {
        // Another process is loading - wait and retry cache
        time.Sleep(100 * time.Millisecond)

        cached, err := rds.Get(ctx, prefixedKey).Bytes()
        if err == nil {
            return cached, nil
        }

        // Fallback to direct load if still missing
        return r.loadAndMarshal(ctx, loader)
    }

    // Lock acquired - load and cache
    defer rds.Del(ctx, lockKey)

    data, err := loader(ctx)
    if err != nil {
        return nil, err
    }

    bytes, err := json.Marshal(data)
    if err != nil {
        return nil, err
    }

    if setErr := rds.Set(ctx, prefixedKey, bytes, ttl).Err(); setErr != nil {
        logger.Errorf("Failed to cache after lock load for key %s: %v", key, setErr)
    }

    return bytes, nil
}
```

### Cache Invalidation on Mutations (MANDATORY)

**HARD GATE:** Every mutation (Create, Update, Delete) that affects cached data MUST invalidate the corresponding cache entries. Stale cache after mutation is a data consistency bug.

```go
// ✅ CORRECT: Invalidate after mutation
func (uc *UseCase) UpdateAccount(ctx context.Context, id uuid.UUID, input UpdateInput) (*domain.Account, error) {
    account, err := uc.AccountRepo.Update(ctx, id, input)
    if err != nil {
        return nil, err
    }

    // MANDATORY: Invalidate cache
    cacheKey := fmt.Sprintf("account:%s", id.String())
    _ = uc.CacheRepo.Invalidate(ctx, cacheKey)

    return account, nil
}

// ✅ CORRECT: Invalidate on delete
func (uc *UseCase) DeleteAccount(ctx context.Context, id uuid.UUID) error {
    if err := uc.AccountRepo.Delete(ctx, id); err != nil {
        return err
    }

    // MANDATORY: Invalidate cache
    cacheKey := fmt.Sprintf("account:%s", id.String())
    _ = uc.CacheRepo.Invalidate(ctx, cacheKey)

    return nil
}
```

```go
// ❌ FORBIDDEN: Mutation without cache invalidation
func (uc *UseCase) UpdateAccount(ctx context.Context, id uuid.UUID, input UpdateInput) (*domain.Account, error) {
    return uc.AccountRepo.Update(ctx, id, input)
    // WRONG: cache still has old data until TTL expires
}
```

**Invalidation Rules:**

| Mutation Type | Cache Action | Scope |
|---------------|-------------|-------|
| Create | Invalidate list caches (if any) | Collection keys |
| Update | Invalidate entity cache + list caches | Entity key + collection keys |
| Delete | Invalidate entity cache + list caches | Entity key + collection keys |

### Detection Commands (Caching Strategy)

```bash
# Find Redis Get/Set patterns (identify caching usage)
grep -rn "\.Get(ctx\|\.Set(ctx" internal/adapters/redis/ --include="*.go" | grep -v "_test.go"

# Find cache key construction
grep -rn "GetKeyContext\|cacheKey\|cache:" internal/ --include="*.go" | grep -v "_test.go"

# Find mutations WITHOUT cache invalidation (potential gap)
grep -rn "\.Update(\|\.Delete(\|\.Create(" internal/services/command/ --include="*.go" | grep -v "_test.go"
# Then cross-reference: each mutation file should also have Invalidate() call

# Find TTL usage (verify no zero/negative TTL)
grep -rn "time\.Duration\|time\.Minute\|time\.Second\|time\.Hour" internal/adapters/redis/ --include="*.go" | grep -v "_test.go"

# Find singleflight usage (stampede prevention)
grep -rn "singleflight" internal/ --include="*.go"
```

---

## Cache Compliance Detection

This section provides detection commands for `ring:dev-refactor` to analyze which caching strategy a codebase uses and identify compliance gaps.

### Strategy Detection

```bash
# ---- Cache-Aside Detection ----
# Pattern: rds.Get BEFORE db.Query + rds.Set AFTER
# Look for: Get from Redis, then DB query, then Set to Redis in same method
grep -rn "\.Get(ctx" internal/adapters/redis/ --include="*.go" | grep -v "_test.go"
grep -rn "\.Set(ctx" internal/adapters/redis/ --include="*.go" | grep -v "_test.go"
# If both exist in same repository file AND service layer calls cache before DB → Cache-Aside

# ---- Write-Through Detection ----
# Pattern: DB write AND cache write in same method
# Look for: Repository.Create/Update followed by rds.Set in same command handler
grep -rn "\.Create(\|\.Update(" internal/services/command/ --include="*.go" -A 10 | grep "\.Set(\|CacheRepo\|cache"
# If mutation + cache set in same handler → Write-Through

# ---- Write-Behind Detection ----
# Pattern: Cache write WITHOUT DB write + background worker
# Look for: RPush/LPush to queue + separate worker that reads queue and writes DB
grep -rn "RPush\|LPush\|write.behind\|WriteBehind" internal/ --include="*.go" | grep -v "_test.go"
# If queue-based buffering exists → Write-Behind

# ---- No Strategy Detected ----
# If none of the above patterns match:
grep -rn "redis\|valkey\|cache" internal/ --include="*.go" | grep -v "_test.go" | head -20
# If Redis usage exists but no clear pattern → Flag as gap: "No explicit caching strategy"
# If no Redis usage at all → N/A: "Service does not use caching"
```

### Compliance Checks Per Strategy

**All strategies MUST pass these checks:**

```bash
# 1. Tenant-aware keys (MANDATORY for all cached data)
grep -rn "GetKeyContext" internal/adapters/redis/ --include="*.go" | grep -v "_test.go"
# Expected: Every Redis operation uses valkey.GetKeyContext
# FAIL if: Direct key usage without GetKeyContext

# 2. TTL present on all Set operations (MANDATORY)
grep -rn "\.Set(ctx" internal/ --include="*.go" | grep -v "_test.go"
# Expected: Every Set call has explicit TTL parameter (not 0)
# FAIL if: Set without TTL or TTL = 0

# 3. Cache invalidation on mutations (MANDATORY)
grep -rn "Invalidate\|\.Del(ctx" internal/services/command/ --include="*.go" | grep -v "_test.go"
# Cross-reference with mutation methods:
grep -rn "func.*Create\|func.*Update\|func.*Delete" internal/services/command/ --include="*.go" | grep -v "_test.go"
# Expected: Every mutation handler has corresponding cache invalidation
# FAIL if: Mutation without invalidation

# 4. Stampede prevention (MANDATORY for high-traffic keys)
grep -rn "singleflight\|SetNX.*lock" internal/ --include="*.go" | grep -v "_test.go"
# Expected: singleflight or distributed lock for popular cache keys
# WARNING if: No stampede prevention found

# 5. Graceful degradation on Redis failure (MANDATORY)
grep -rn "GetConnection" internal/adapters/redis/ --include="*.go" -A 5 | grep -v "_test.go"
# Expected: Error handling that falls back to DB on Redis failure
# FAIL if: Redis failure causes request failure for read operations
```

### Compliance Summary Table Format

When analyzing a codebase, output this table:

```markdown
## Caching Compliance

| Check | Status | Evidence |
|-------|--------|----------|
| Strategy identified | ✅/❌ | Cache-Aside / Write-Through / Write-Behind / None |
| Tenant-aware keys | ✅/❌ | `valkey.GetKeyContext` in all Redis operations |
| Explicit TTL on all Sets | ✅/❌ | file:line or "missing in X files" |
| Mutation invalidation | ✅/❌ | Invalidate calls in command handlers |
| Stampede prevention | ✅/⚠️/❌ | singleflight or distributed lock |
| Redis failure graceful degradation | ✅/❌ | Fallback to DB on connection error |
```

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Caching is premature optimization" | Without caching, every request hits DB. Under load, DB becomes bottleneck. | **Define caching strategy for all read-heavy data** |
| "TTL handles invalidation" | TTL-only means stale data for the entire TTL window after mutation. | **MUST invalidate on every mutation + TTL as safety net** |
| "Redis is always available" | Redis can fail. Network partitions happen. | **Implement graceful degradation (fallback to DB)** |
| "Small service doesn't need caching" | Small now = large later. Caching patterns are cheaper to add early. | **At minimum, define strategy in architecture docs** |
| "We'll add stampede prevention later" | Stampede happens on the first popular key expiration. Day 1 risk. | **Add singleflight from the start** |
| "Hardcoded keys are fine" | Breaks multi-tenant isolation. Cross-tenant data leakage. | **MUST use `valkey.GetKeyContext` for every key** |
| "Cache invalidation is too complex" | Stale data is a data consistency bug, not an optimization issue. | **Invalidate on every mutation. No exceptions.** |
| "Write-Behind is always better for performance" | Write-Behind risks data loss on Redis failure. Not suitable for financial data. | **Use Write-Through for financial/critical data** |

---

## Checklist

- [ ] Caching strategy explicitly chosen and documented (Cache-Aside, Write-Through, or Write-Behind)
- [ ] All cache keys use `valkey.GetKeyContext(ctx, key)` for tenant awareness
- [ ] All Redis connections use `r.conn.GetConnection(ctx)` for tenant-scoped resolution
- [ ] Every `rds.Set` has explicit TTL (no zero, no negative, from config not hardcoded)
- [ ] Every mutation (Create, Update, Delete) invalidates corresponding cache entries
- [ ] Cache stampede prevention implemented (singleflight or distributed lock) for popular keys
- [ ] Graceful degradation on Redis failure (read operations fall back to DB)
- [ ] Write-Behind only used for non-critical data (not financial transactions)
- [ ] Cache key naming convention is consistent (e.g., `entity:id` pattern)
- [ ] TTL values come from configuration, not hardcoded magic numbers
- [ ] Redis `maxmemory-policy` configured for production (not `noeviction`)

---
```

**Step 2: Verify the file was created correctly**

Run: `wc -l dev-team/docs/standards/golang/caching.md`

**Expected output:**
```
A line count > 400 (the file is comprehensive)
```

Run: `head -5 dev-team/docs/standards/golang/caching.md`

**Expected output:**
```
# Go Standards - Caching

> **Module:** caching.md | **Sections:** 2 | **Parent:** [index.md](index.md)

This module covers caching strategy patterns and compliance detection for Redis/Valkey-based caching using lib-commons.
```

**If Task Fails:**

1. **File not created:**
   - Check: `ls dev-team/docs/standards/golang/` (directory exists?)
   - Fix: Create directory if missing
   - Rollback: `git checkout -- .`

2. **Content malformed:**
   - Check: Open file and verify markdown renders correctly
   - Fix: Re-create file with corrected content
   - Rollback: `git checkout -- dev-team/docs/standards/golang/caching.md`

---

### Task 2: Update `index.md` to add Module 20 (caching.md)

**Files:**
- Modify: `dev-team/docs/standards/golang/index.md`

**Prerequisites:**
- Task 1 completed (caching.md exists)

**Step 1: Update the Module Index table**

In `dev-team/docs/standards/golang/index.md`, find the Module Index table (around line 48). Add module 20 after module 19 (migration-safety.md, line 68):

Find this line:
```markdown
| 19 | [migration-safety.md](migration-safety.md) | 5 | ~350 | Migration Safety (Gate 0.5D): Dangerous ops detection, expand-contract, multi-tenant idempotency |
```

Add after it:
```markdown
| 20 | [caching.md](caching.md) | 2 | ~500 | Caching Strategy Patterns, Cache Compliance Detection |
```

**Step 2: Update the Total line**

Find:
```markdown
**Total:** 19 modules with testing split into 6 specialized files
```

Replace with:
```markdown
**Total:** 20 modules with testing split into 6 specialized files
```

**Step 3: Update the Table of Contents row for Module Index**

Find:
```markdown
| 2 | [Module Index](#module-index) | All 18 modules with section counts and descriptions |
```

Replace with:
```markdown
| 2 | [Module Index](#module-index) | All 20 modules with section counts and descriptions |
```

**Step 4: Add Section Index for Caching**

In the Section Index (Full) section, add after the Migration Safety block (after line ~268):

```markdown
### Caching (caching.md)

| # | Section | Anchor |
|---|---------|--------|
| 1 | Caching Strategy Patterns (MANDATORY) | [#caching-strategy-patterns-mandatory](caching.md#caching-strategy-patterns-mandatory) |
| 2 | Cache Compliance Detection | [#cache-compliance-detection](caching.md#cache-compliance-detection) |
```

**Step 5: Update the Dependency Graph**

In the Dependency Graph (around line 255), add caching.md as a new node after multi-tenant.md:

Find:
```
    └── multi-tenant.md (depends on bootstrap.md, security.md)
        └── Tenant Manager, JWT extraction, Context injection
```

Add after it:
```
    └── caching.md (depends on multi-tenant.md, bootstrap.md)
        └── Cache-Aside, Write-Through, Write-Behind, Stampede Prevention
```

**Step 6: Add WebFetch URL**

In the WebFetch URLs table, add after migration-safety.md:

```markdown
| caching.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/caching.md` |
```

**Step 7: Add to Quick Reference table**

In the Quick Reference table, add a new row:

```markdown
| **Caching** | caching.md (+ multi-tenant.md for tenant-aware keys) |
```

**Step 8: Verify the update**

Run: `grep -n "caching" dev-team/docs/standards/golang/index.md`

**Expected output:** Multiple matches showing caching.md in Module Index, Section Index, Dependency Graph, WebFetch URLs, and Quick Reference.

**If Task Fails:**

1. **Line numbers don't match:**
   - Read the file first to find correct insertion points
   - The content structure is what matters, not exact line numbers

2. **Formatting broken:**
   - Verify table alignment in a markdown renderer
   - Rollback: `git checkout -- dev-team/docs/standards/golang/index.md`

---

### Task 3: Update `standards-coverage-table.md` to add caching sections

**Files:**
- Modify: `dev-team/skills/shared-patterns/standards-coverage-table.md`

**Prerequisites:**
- Task 1 completed (caching.md exists)

**Step 1: Add caching sections to the ring:backend-engineer-golang section index**

In `dev-team/skills/shared-patterns/standards-coverage-table.md`, find the last row of the `ring:backend-engineer-golang` section index. Currently line 311:

```markdown
| 54 | Settings Revalidation | multi-tenant.md | N/A (pgManager internal) | **pgManager handles internally via `WithConnectionsCheckInterval`.** No separate watcher needed. Pass option when creating PostgreSQL manager. Detects maxOpenConns/maxIdleConns/statementTimeout changes |
```

Add after it:

```markdown
| 55 | Caching Strategy Patterns | caching.md | `#caching-strategy-patterns-mandatory` | **MANDATORY:** Cache-Aside, Write-Through, Write-Behind strategies. `valkey.GetKeyContext` for tenant-aware keys, `r.conn.GetConnection(ctx)` for tenant-scoped Redis, TTL on every Set, invalidation on mutations, singleflight stampede prevention |
| 56 | Cache Compliance Detection | caching.md | `#cache-compliance-detection` | Strategy detection commands, compliance checks per strategy, grep patterns for dev-refactor analysis |
```

**Step 2: Update the Module Loading Guide table**

Find the Module Loading Guide table (around line 313). Add a new row:

```markdown
| Caching | caching.md + multi-tenant.md |
```

**Step 3: Verify the update**

Run: `grep -n "caching\|Caching" dev-team/skills/shared-patterns/standards-coverage-table.md`

**Expected output:** Matches showing the two new rows (55, 56) and the Module Loading Guide entry.

Run: `grep -c "^|" dev-team/skills/shared-patterns/standards-coverage-table.md`

**Expected output:** The count should have increased by 3 (two section rows + one loading guide row).

**If Task Fails:**

1. **Row numbering conflict:**
   - Verify the last row number before insertion
   - Ensure sequential numbering (55, 56)
   - Rollback: `git checkout -- dev-team/skills/shared-patterns/standards-coverage-table.md`

---

### Task 4: Verify `backend-engineer-golang.md` references coverage table (not inline)

**Files:**
- Verify (read-only): `dev-team/agents/backend-engineer-golang.md`

**Prerequisites:**
- Tasks 1-3 completed

**Step 1: Verify the agent references the coverage table**

Run: `grep -n "standards-coverage-table" dev-team/agents/backend-engineer-golang.md`

**Expected output:**
```
266:MUST: Be bound to all sections in [standards-coverage-table.md](../skills/shared-patterns/standards-coverage-table.md).
272:| **Coverage table is authoritative** | See standards-coverage-table.md for the authoritative list of sections to check |
```

This confirms the agent references the coverage table (not inline categories). **No modification needed** if this output appears.

**Step 2: Verify the agent does NOT have inline comparison categories**

Run: `grep -n "Comparison Categories" dev-team/agents/backend-engineer-golang.md`

**Expected output:** No matches (empty output). If matches are found, the agent has FORBIDDEN inline categories that MUST be removed.

**If Task Fails:**

1. **Agent has inline categories:**
   - Remove the inline categories section
   - Replace with reference to coverage table
   - This is a CRITICAL issue per CLAUDE.md rules

2. **Agent doesn't reference coverage table:**
   - Add the reference per the pattern in the agent file
   - This should not happen based on current file state

---

### Task 5: Commit Part A (caching.md and all related updates)

**Files:**
- All files from Tasks 1-4

**Prerequisites:**
- Tasks 1-4 completed and verified

**Step 1: Stage the files**

```bash
git add dev-team/docs/standards/golang/caching.md
git add dev-team/docs/standards/golang/index.md
git add dev-team/skills/shared-patterns/standards-coverage-table.md
```

**Step 2: Commit with GPG signing**

```bash
git commit -S -m "feat(standards): add caching strategy standard (module 20)" --trailer "Generated-by: Claude" --trailer "AI-Model: claude-opus-4-6"
```

**Expected output:**
```
[branch-name abc1234] feat(standards): add caching strategy standard (module 20)
 3 files changed, XXX insertions(+), X deletions(-)
 create mode 100644 dev-team/docs/standards/golang/caching.md
```

**Step 3: Verify commit**

Run: `git log --oneline -1`

**Expected output:** Shows the commit message starting with `feat(standards): add caching strategy standard`

Run: `git diff --stat HEAD~1`

**Expected output:** Shows 3 files changed: caching.md (created), index.md (modified), standards-coverage-table.md (modified)

**If Task Fails:**

1. **GPG signing fails:**
   - Check: `gpg --list-keys` (GPG key exists?)
   - Fix: Configure GPG key or ask user for signing setup
   - Retry commit with correct key

2. **Pre-commit hook fails:**
   - Read hook output to identify issue
   - Fix the issue
   - Create a NEW commit (do NOT amend)

---

### Task 6: Run Code Review (Part A)

1. **Dispatch all 8 reviewers in parallel:**
   - REQUIRED SUB-SKILL: Use ring:codereview
   - All reviewers run simultaneously (ring:code-reviewer, ring:business-logic-reviewer, ring:security-reviewer, ring:test-reviewer, ring:nil-safety-reviewer, ring:consequences-reviewer, ring:dead-code-reviewer, ring:performance-reviewer)
   - Wait for all to complete

2. **Handle findings by severity (MANDATORY):**

**Critical/High/Medium Issues:**
- Fix immediately (do NOT add TODO comments for these severities)
- Re-run all 8 reviewers in parallel after fixes
- Repeat until zero Critical/High/Medium issues remain

**Low Issues:**
- Add `TODO(review):` comments in code at the relevant location
- Format: `TODO(review): [Issue description] (reported by [reviewer] on [date], severity: Low)`
- This tracks tech debt for future resolution

**Cosmetic/Nitpick Issues:**
- Add `FIXME(nitpick):` comments in code at the relevant location
- Format: `FIXME(nitpick): [Issue description] (reported by [reviewer] on [date], severity: Cosmetic)`
- Low-priority improvements tracked inline

3. **Proceed only when:**
   - Zero Critical/High/Medium issues remain
   - All Low issues have TODO(review): comments added
   - All Cosmetic issues have FIXME(nitpick): comments added

---

## Part B: Add CQRS Section to `architecture.md`

### Task 7: Add CQRS Pattern section to `architecture.md`

**Files:**
- Modify: `dev-team/docs/standards/golang/architecture.md`

**Prerequisites:**
- Part A committed (Task 5)

**Step 1: Add the CQRS section**

In `dev-team/docs/standards/golang/architecture.md`, add the following section at the end of the file, before the final closing (after the Performance Patterns section, which ends around line 882):

```markdown

## CQRS Pattern (CONDITIONAL)

**CONDITIONAL:** Only applies when the service has separate read and write models, or when the `/internal/services/` directory contains both `command/` and `query/` subdirectories.

### Detection: When CQRS Applies

| Signal | Meaning |
|--------|---------|
| `internal/services/command/` directory exists | Write operations are separated |
| `internal/services/query/` directory exists | Read operations are separated |
| Different structs for write vs read | Separate models indicate CQRS |
| Read/write ratio > 10:1 | Read-optimized views benefit from CQRS |
| Financial audit + dashboards | Audit trail (write) vs analytics (read) |

**Detection Commands:**

```bash
# Check if service uses CQRS structure
ls -la internal/services/command/ 2>/dev/null && echo "CQRS: command directory found"
ls -la internal/services/query/ 2>/dev/null && echo "CQRS: query directory found"

# Find separate read/write models
grep -rn "type.*Command\|type.*Query\|type.*WriteModel\|type.*ReadModel" internal/ --include="*.go" | grep -v "_test.go"

# Find handler separation
grep -rn "func.*Create\|func.*Update\|func.*Delete" internal/services/command/ --include="*.go" | head -10
grep -rn "func.*Get\|func.*List\|func.*Find\|func.*Search" internal/services/query/ --include="*.go" | head -10
```

### When to Use CQRS

| Scenario | CQRS Recommended? | Reason |
|----------|-------------------|--------|
| Read/write ratio > 10:1 | Yes | Read path can be optimized independently |
| Different read models needed | Yes | Dashboards need denormalized views, writes need normalized |
| Financial audit + analytics | Yes | Audit trail (immutable writes) + analytics dashboards (read views) |
| Event sourcing architecture | Yes | Natural fit - events are writes, projections are reads |
| Complex business validation on writes | Yes | Command handlers focus on validation without read concerns |

### When NOT to Use CQRS

| Scenario | CQRS Recommended? | Reason |
|----------|-------------------|--------|
| Simple CRUD operations | No | Over-engineering for straightforward data access |
| Small service with few endpoints | No | Complexity overhead outweighs benefits |
| 1:1 read/write ratio | No | No read path optimization needed |
| Single data model serves both | No | No benefit from separating models |
| Prototyping / MVP | No | CQRS adds structural complexity too early |

### Pattern Definition

#### Command Handlers (Write Side)

Command handlers process mutations. They validate input, enforce business rules, persist state changes, and return minimal confirmation.

```go
// internal/services/command/create_account.go
package command

import (
    "context"

    libCommons "github.com/LerianStudio/lib-commons/v2/commons"
)

// CreateAccountCommand represents the input for creating an account.
// Commands carry only the data needed for the write operation.
type CreateAccountCommand struct {
    Name           string
    OrganizationID uuid.UUID
    LedgerID       uuid.UUID
    Type           string
    Metadata       map[string]string
}

// CreateAccount processes the create account command.
// Command handlers: validate, persist, return minimal response.
func (uc *UseCase) CreateAccount(ctx context.Context, cmd CreateAccountCommand) (*domain.Account, error) {
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "command.create_account")
    defer span.End()

    // Step 1: Validate using Always-Valid Domain Model
    account, err := domain.NewAccount(cmd.Name, cmd.OrganizationID, cmd.LedgerID, cmd.Type)
    if err != nil {
        return nil, err
    }

    // Step 2: Persist (command side writes to normalized tables)
    created, err := uc.AccountRepo.Create(ctx, account)
    if err != nil {
        return nil, err
    }

    logger.Infof("Account created: %s", created.ID)

    // Step 3: Return minimal response (ID + status, not full entity)
    return created, nil
}
```

#### Query Handlers (Read Side)

Query handlers process read operations. They retrieve data, optionally from denormalized views or caches, and return rich response models.

```go
// internal/services/query/get_account.go
package query

import (
    "context"

    libCommons "github.com/LerianStudio/lib-commons/v2/commons"
)

// AccountView represents the read-optimized model.
// Query models can be denormalized, enriched, or aggregated.
type AccountView struct {
    ID             uuid.UUID
    Name           string
    Type           string
    Balance        decimal.Decimal
    TransactionCount int64
    LastActivity   time.Time
    // Denormalized: includes data from multiple tables
    OrganizationName string
    LedgerName       string
}

// GetAccountByID retrieves an account with enriched data.
// Query handlers: read, denormalize, return rich response.
func (uc *UseCase) GetAccountByID(ctx context.Context, id uuid.UUID) (*AccountView, error) {
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "query.get_account_by_id")
    defer span.End()

    // Query side can use JOINs, views, or caches for optimized reads
    view, err := uc.AccountViewRepo.FindByID(ctx, id)
    if err != nil {
        return nil, err
    }

    return view, nil
}

// ListAccounts retrieves a paginated list of accounts.
func (uc *UseCase) ListAccounts(ctx context.Context, filter AccountFilter) (*AccountListResponse, error) {
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "query.list_accounts")
    defer span.End()

    // Query side can use read replicas, materialized views, or cache
    return uc.AccountViewRepo.List(ctx, filter)
}
```

### Directory Structure (CQRS)

```text
/internal
  /services
    /command                    # Write operations
      create_account.go         # CreateAccountCommand → domain.Account
      update_account.go         # UpdateAccountCommand → domain.Account
      delete_account.go         # DeleteAccountCommand → error
      usecase.go                # UseCase struct with write-side dependencies
    /query                      # Read operations
      get_account.go            # GetAccountByID → AccountView
      list_accounts.go          # ListAccounts → AccountListResponse
      usecase.go                # UseCase struct with read-side dependencies
```

**Key Rules:**

| Rule | Enforcement |
|------|-------------|
| Commands MUST NOT return full query models | Commands return minimal data (ID, status) |
| Queries MUST NOT modify state | Queries are read-only, no side effects |
| Command and query UseCases have separate dependencies | Command depends on write repos, query depends on read repos/views |
| Command handlers use Always-Valid Domain Model | See [domain-modeling.md](domain-modeling.md#always-valid-domain-model-mandatory) |
| Query handlers can use denormalized views | Optimized for read performance |

### Integration with Ring Patterns

| Ring Pattern | Command Side (Write) | Query Side (Read) |
|-------------|---------------------|-------------------|
| **Always-Valid Domain Model** | MUST use `domain.NewEntity()` constructors for validation | Not required - views are read-only |
| **ToEntity/FromEntity** | MUST use for DB ↔ domain mapping | Can use simplified mappers for views |
| **Cache-Aside** (from [caching.md](caching.md)) | MUST invalidate cache on mutations | Can use cached views for reads |
| **Idempotency** (from [idempotency.md](idempotency.md)) | MUST implement for create commands | Not applicable (reads are idempotent) |
| **Error Codes** | Use command-specific error codes | Use query-specific error codes |
| **Span Naming** | `command.{operation}` | `query.{operation}` |

### Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Simple CRUD doesn't need CQRS" | If directory structure already has command/query, CQRS is already the pattern. Follow it. | **Follow the existing CQRS structure** |
| "Commands can return rich data" | Mixing read concerns into commands couples the two sides. | **Commands return minimal data. Use query for rich reads.** |
| "Queries can update cache" | Cache updates are side effects. Only commands should cause state changes. | **Cache invalidation belongs in command handlers** |
| "One UseCase struct is simpler" | Shared UseCase couples read/write dependencies and makes testing harder. | **Separate UseCase per side** |
| "CQRS means event sourcing" | CQRS and event sourcing are independent patterns. CQRS is simpler. | **CQRS is just command/query separation** |
| "We need CQRS for every service" | CQRS is CONDITIONAL. Only when read/write separation provides value. | **Check detection signals before applying** |

### Detection Commands (CQRS Compliance)

```bash
# Verify command handlers don't return query models
grep -rn "func.*Command.*UseCase\|func.*Create\|func.*Update\|func.*Delete" internal/services/command/ --include="*.go" | grep -v "_test.go"
# Review return types: should be minimal (entity, ID, error) not views

# Verify query handlers don't modify state
grep -rn "func.*Query.*UseCase\|func.*Get\|func.*List\|func.*Find" internal/services/query/ --include="*.go" | grep -v "_test.go"
# Review: should NOT contain Create/Update/Delete/Save calls

# Verify separate UseCase structs
grep -rn "type UseCase struct" internal/services/command/usecase.go internal/services/query/usecase.go
# Expected: Two separate UseCase structs with different dependencies

# Verify span naming convention
grep -rn "tracer.Start" internal/services/command/ --include="*.go" | grep -v "_test.go"
# Expected: "command.{operation}" naming
grep -rn "tracer.Start" internal/services/query/ --include="*.go" | grep -v "_test.go"
# Expected: "query.{operation}" naming
```
```

**Step 2: Update the Table of Contents in architecture.md**

Find the TOC table at the top of `architecture.md` (around line 11):

```markdown
| 7 | [Performance Patterns](#performance-patterns-mandatory) | SELECT * avoidance, sync.Pool, memory optimization |
```

Add after it:

```markdown
| 8 | [CQRS Pattern (CONDITIONAL)](#cqrs-pattern-conditional) | Command/Query separation, when to use, integration with Ring patterns |
```

**Step 3: Update the module header section count**

Find at the top of the file (line 3):

```markdown
> **Module:** architecture.md | **Sections:** §23-29 | **Parent:** [index.md](index.md)
```

This section count is based on global section numbering from the index. The exact range will need to be updated. However, the key metric is the TOC row count. After adding CQRS, the TOC should have 8 rows.

**Step 4: Verify the update**

Run: `grep -n "CQRS" dev-team/docs/standards/golang/architecture.md`

**Expected output:** Multiple matches showing CQRS in the TOC and in the new section.

Run: `grep -c "^## " dev-team/docs/standards/golang/architecture.md`

**Expected output:** `8` (7 original sections + 1 new CQRS section)

**If Task Fails:**

1. **Section numbering conflict:**
   - Verify current section count before insertion
   - Ensure TOC is correctly numbered
   - Rollback: `git checkout -- dev-team/docs/standards/golang/architecture.md`

---

### Task 8: Update `index.md` for architecture.md section count change

**Files:**
- Modify: `dev-team/docs/standards/golang/index.md`

**Prerequisites:**
- Task 7 completed

**Step 1: Update the Module Index section count for architecture.md**

In `dev-team/docs/standards/golang/index.md`, find the architecture.md row in the Module Index table:

```markdown
| 7 | [architecture.md](architecture.md) | 7 | ~500 | Architecture, Directory, Concurrency, Goroutine Recovery, Goroutine Leak Detection (goleak), N+1 Detection, Performance |
```

Replace with:

```markdown
| 7 | [architecture.md](architecture.md) | 8 | ~750 | Architecture, Directory, Concurrency, Goroutine Recovery, Goroutine Leak Detection (goleak), N+1 Detection, Performance, CQRS Pattern |
```

**Step 2: Update the Section Index for architecture.md**

In the Section Index (Full) section, find the Architecture section index. After the last row:

```markdown
| 7 | Performance Patterns (MANDATORY) | [#performance-patterns-mandatory](architecture.md#performance-patterns-mandatory) |
```

Add:

```markdown
| 8 | CQRS Pattern (CONDITIONAL) | [#cqrs-pattern-conditional](architecture.md#cqrs-pattern-conditional) |
```

**Step 3: Verify**

Run: `grep -n "CQRS" dev-team/docs/standards/golang/index.md`

**Expected output:** Matches in Module Index and Section Index.

**If Task Fails:**

1. **Line numbers don't match:**
   - Read the file to find correct positions
   - Rollback: `git checkout -- dev-team/docs/standards/golang/index.md`

---

### Task 9: Update `standards-coverage-table.md` to add CQRS section

**Files:**
- Modify: `dev-team/skills/shared-patterns/standards-coverage-table.md`

**Prerequisites:**
- Task 7 completed

**Step 1: Add CQRS to the ring:backend-engineer-golang section index**

Find the last architecture.md row in the coverage table. After the caching rows added in Task 3, these are now rows 55-56. But CQRS is in architecture.md, so it should be positioned after the existing architecture rows (rows 38-44).

Find the Performance Patterns row:

```markdown
| 44 | Performance Patterns | architecture.md | `#performance-patterns-mandatory` | **SELECT * avoidance (MANDATORY)**, sync.Pool, memory allocation, detection commands |
```

The current numbering has rows 38-44 for architecture.md, then 45-46 for messaging.md, etc. Adding a new row after 44 requires renumbering all subsequent rows.

**IMPORTANT:** To maintain sequential numbering, insert the CQRS row after row 44 and renumber all subsequent rows (+1):

After row 44, add:

```markdown
| 45 | CQRS Pattern | architecture.md | `#cqrs-pattern-conditional` | **CONDITIONAL:** Command/Query separation. Command handlers (validate, persist, minimal return). Query handlers (read, denormalize, rich response). Detection commands for CQRS compliance |
```

Then renumber existing rows 45-56 to 46-57:
- Row 45 (RabbitMQ Worker Pattern) becomes 46
- Row 46 (RabbitMQ Reconnection Strategy) becomes 47
- Row 47 (Always-Valid Domain Model) becomes 48
- Row 48 (Idempotency Patterns) becomes 49
- Row 49 (Multi-Tenant Patterns) becomes 50
- Row 50 (Route-Level Auth-Before-Tenant Ordering) becomes 51
- Row 51 (Rate Limiting) becomes 52
- Row 52 (CORS Configuration) becomes 53
- Row 53 (Service Authentication) becomes 54
- Row 54 (Settings Revalidation) becomes 55
- Row 55 (Caching Strategy Patterns) becomes 56
- Row 56 (Cache Compliance Detection) becomes 57

**Step 2: Verify sequential numbering**

Run: `grep -n "^| [0-9]" dev-team/skills/shared-patterns/standards-coverage-table.md | head -60`

**Expected output:** Sequential numbering from 1 to 57 for the golang section, with no gaps.

**If Task Fails:**

1. **Renumbering error:**
   - Count all rows manually
   - Verify sequential order
   - Rollback: `git checkout -- dev-team/skills/shared-patterns/standards-coverage-table.md`

---

### Task 10: Commit Part B (CQRS section and all related updates)

**Files:**
- All files from Tasks 7-9

**Prerequisites:**
- Tasks 7-9 completed and verified

**Step 1: Stage the files**

```bash
git add dev-team/docs/standards/golang/architecture.md
git add dev-team/docs/standards/golang/index.md
git add dev-team/skills/shared-patterns/standards-coverage-table.md
```

**Step 2: Commit with GPG signing**

```bash
git commit -S -m "feat(standards): add CQRS pattern section to architecture.md" --trailer "Generated-by: Claude" --trailer "AI-Model: claude-opus-4-6"
```

**Expected output:**
```
[branch-name def5678] feat(standards): add CQRS pattern section to architecture.md
 3 files changed, XXX insertions(+), X deletions(-)
```

**Step 3: Verify commit**

Run: `git log --oneline -2`

**Expected output:** Shows both commits (Part A and Part B).

Run: `git diff --stat HEAD~1`

**Expected output:** Shows 3 files changed: architecture.md, index.md, standards-coverage-table.md.

**If Task Fails:**

1. **GPG signing fails:**
   - Same resolution as Task 5

2. **Pre-commit hook fails:**
   - Fix issue and create NEW commit

---

### Task 11: Run Code Review (Part B)

1. **Dispatch all 8 reviewers in parallel:**
   - REQUIRED SUB-SKILL: Use ring:codereview
   - All reviewers run simultaneously (ring:code-reviewer, ring:business-logic-reviewer, ring:security-reviewer, ring:test-reviewer, ring:nil-safety-reviewer, ring:consequences-reviewer, ring:dead-code-reviewer, ring:performance-reviewer)
   - Wait for all to complete

2. **Handle findings by severity (MANDATORY):**

**Critical/High/Medium Issues:**
- Fix immediately (do NOT add TODO comments for these severities)
- Re-run all 8 reviewers in parallel after fixes
- Repeat until zero Critical/High/Medium issues remain

**Low Issues:**
- Add `TODO(review):` comments in code at the relevant location
- Format: `TODO(review): [Issue description] (reported by [reviewer] on [date], severity: Low)`

**Cosmetic/Nitpick Issues:**
- Add `FIXME(nitpick):` comments in code at the relevant location
- Format: `FIXME(nitpick): [Issue description] (reported by [reviewer] on [date], severity: Cosmetic)`

3. **Proceed only when:**
   - Zero Critical/High/Medium issues remain
   - All Low issues have TODO(review): comments added
   - All Cosmetic issues have FIXME(nitpick): comments added

---

## Part C: dev-refactor Integration (Caching Analysis Shared Pattern)

### Task 12: Create `caching-analysis.md` shared pattern

**Files:**
- Create: `dev-team/skills/shared-patterns/caching-analysis.md`

**Prerequisites:**
- Part A committed (caching.md exists with compliance detection section)

**Step 1: Create the file with full content**

Create `dev-team/skills/shared-patterns/caching-analysis.md` with the following content:

```markdown
# Caching Analysis Checklist (MANDATORY)

**MULTI-TENANT CACHING ANALYSIS (MANDATORY):**

See [caching.md](../../docs/standards/golang/caching.md) for canonical caching patterns and [caching.md - Cache Compliance Detection](../../docs/standards/golang/caching.md#cache-compliance-detection) for detection commands.

**Existence != Compliance.** Code that has "some Redis usage" but does not follow Ring caching standards is NON-COMPLIANT and MUST be flagged as a gap.

## Compliance Audit

1. WebFetch caching.md: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/caching.md
2. **Detection:** Check if any caching code exists
   ```bash
   # Detect Redis/cache usage
   grep -rn "redis\|valkey\|cache\|GetConnection\|GetKeyContext" internal/ --include="*.go" | grep -v "_test.go" | head -20
   ```
3. **If caching code exists -> run compliance audit:**
   - Strategy identification: Cache-Aside, Write-Through, or Write-Behind (see detection commands in caching.md)
   - Tenant-aware keys: MUST use `valkey.GetKeyContext(ctx, key)` for every Redis key operation
   - Redis connection: MUST use `r.conn.GetConnection(ctx)` for tenant-scoped connections
   - TTL: MUST have explicit TTL on every `rds.Set` call (no zero, no negative)
   - Mutation invalidation: MUST invalidate cache on every Create/Update/Delete
   - Stampede prevention: MUST have singleflight or distributed lock for popular keys
   - Graceful degradation: MUST fall back to DB on Redis failure for read operations
   - Each non-compliant item -> ISSUE-XXX with severity based on impact
4. **If caching code is MISSING entirely:**
   - Check if service has read-heavy endpoints
   ```bash
   grep -rn "func.*Get\|func.*List\|func.*Find" internal/services/query/ --include="*.go" | grep -v "_test.go" | wc -l
   ```
   - If > 5 read endpoints with no caching -> ISSUE-XXX (MEDIUM): "Service has read-heavy endpoints without caching strategy. Consider adding Cache-Aside pattern."
   - If service is write-heavy or simple CRUD -> N/A: "Service does not require caching"
5. **If non-compliant** -> ISSUE-XXX per component: "Caching [component] is non-compliant. See caching.md for canonical pattern."

## Strategy-Specific Checks

### Cache-Aside Compliance

```bash
# Verify cache-before-DB pattern in query handlers
grep -rn "Get(ctx\|GetOrLoad" internal/services/query/ --include="*.go" | grep -v "_test.go"
# Expected: Cache lookup before DB query

# Verify invalidation in command handlers
grep -rn "Invalidate\|Del(ctx" internal/services/command/ --include="*.go" | grep -v "_test.go"
# Expected: Invalidation call in every mutation handler
```
- ISSUE if cache read not before DB -> HIGH: "Cache-Aside pattern requires cache check before DB query"
- ISSUE if no invalidation in mutations -> HIGH: "Mutations MUST invalidate cache. Stale data is a consistency bug."

### Write-Through Compliance

```bash
# Verify DB write AND cache write in same handler
grep -rn "\.Create(\|\.Update(" internal/services/command/ --include="*.go" -A 10 | grep "Set(ctx\|cache"
# Expected: Both DB and cache write in same method
```
- ISSUE if cache write missing after DB write -> HIGH: "Write-Through requires cache update on every DB write"

### Write-Behind Compliance

```bash
# Verify queue-based buffering exists
grep -rn "RPush\|LPush\|write.behind\|WriteBehind" internal/ --include="*.go" | grep -v "_test.go"
# Expected: Queue operations for deferred persistence

# Verify background worker exists
grep -rn "Flush\|sync.worker\|background.*write" internal/ --include="*.go" | grep -v "_test.go"
# Expected: Worker that reads queue and persists to DB
```
- ISSUE if Write-Behind used for financial data -> CRITICAL: "Write-Behind MUST NOT be used for financial data. Use Write-Through instead."
- ISSUE if no background worker -> HIGH: "Write-Behind requires background worker for DB persistence"

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Redis usage exists, so caching is implemented" | Existence != compliance. Strategy must be explicit. | **Verify explicit strategy per caching.md** |
| "Keys don't need tenant prefix" | Cross-tenant data leakage is a CRITICAL security issue. | **Verify `valkey.GetKeyContext` on every key** |
| "TTL handles invalidation" | Stale data for TTL window after mutation is a consistency bug. | **Verify invalidation on every mutation** |
| "Small cache, stampede won't happen" | Stampede happens on first popular key expiration. | **Verify singleflight or lock exists** |
| "Only checking what seems relevant" | You don't decide relevance. The checklist does. | **Run all checks regardless** |
```

**Step 2: Verify the file was created**

Run: `ls -la dev-team/skills/shared-patterns/caching-analysis.md`

**Expected output:** File exists with reasonable size.

**If Task Fails:**

1. **Directory doesn't exist:**
   - Check: `ls dev-team/skills/shared-patterns/`
   - Fix: Directory should exist (it has other files)
   - Rollback: `git checkout -- .`

---

### Task 13: Commit Part C (caching-analysis.md shared pattern)

**Files:**
- `dev-team/skills/shared-patterns/caching-analysis.md`

**Prerequisites:**
- Task 12 completed

**Step 1: Stage and commit**

```bash
git add dev-team/skills/shared-patterns/caching-analysis.md
git commit -S -m "feat(standards): add caching analysis shared pattern for dev-refactor" --trailer "Generated-by: Claude" --trailer "AI-Model: claude-opus-4-6"
```

**Expected output:**
```
[branch-name ghi9012] feat(standards): add caching analysis shared pattern for dev-refactor
 1 file changed, XXX insertions(+)
 create mode 100644 dev-team/skills/shared-patterns/caching-analysis.md
```

**Step 2: Verify**

Run: `git log --oneline -3`

**Expected output:** Shows all three commits (Part A, Part B, Part C).

**If Task Fails:**

1. **GPG signing fails:**
   - Same resolution as Task 5

---

### Task 14: Final Verification

**Files:**
- Read-only verification of all changes

**Prerequisites:**
- Tasks 5, 10, 13 completed (all three commits)

**Step 1: Verify FOUR-FILE UPDATE RULE compliance for caching.md**

| File | Check | Command |
|------|-------|---------|
| caching.md | File exists with TOC | `head -20 dev-team/docs/standards/golang/caching.md` |
| index.md | Module 20 listed | `grep "caching" dev-team/docs/standards/golang/index.md` |
| standards-coverage-table.md | Sections 56-57 | `grep "Caching" dev-team/skills/shared-patterns/standards-coverage-table.md` |
| backend-engineer-golang.md | References coverage table | `grep "standards-coverage-table" dev-team/agents/backend-engineer-golang.md` |

**Step 2: Verify FOUR-FILE UPDATE RULE compliance for CQRS section**

| File | Check | Command |
|------|-------|---------|
| architecture.md | CQRS section exists, TOC updated | `grep "CQRS" dev-team/docs/standards/golang/architecture.md` |
| architecture.md TOC | Row 8 added | `grep -A 1 "Performance Patterns" dev-team/docs/standards/golang/architecture.md \| head -3` |
| standards-coverage-table.md | CQRS row added | `grep "CQRS" dev-team/skills/shared-patterns/standards-coverage-table.md` |
| backend-engineer-golang.md | References coverage table | Already verified in Step 1 |

**Step 3: Verify section counts match**

Run: `grep -c "^## " dev-team/docs/standards/golang/caching.md`

**Expected output:** `2` (Caching Strategy Patterns + Cache Compliance Detection; meta-sections like Anti-Rationalization Table and Checklist are counted but they are subsections)

Run: `grep -c "^## " dev-team/docs/standards/golang/architecture.md`

**Expected output:** `8` (7 original + 1 CQRS)

**Step 4: Verify all commits are present**

Run: `git log --oneline -3`

**Expected output:**
```
[hash3] feat(standards): add caching analysis shared pattern for dev-refactor
[hash2] feat(standards): add CQRS pattern section to architecture.md
[hash1] feat(standards): add caching strategy standard (module 20)
```

**Step 5: Run full diff to verify scope**

Run: `git diff --stat HEAD~3`

**Expected output:**
```
 dev-team/docs/standards/golang/architecture.md                | XXX +
 dev-team/docs/standards/golang/caching.md                     | XXX +
 dev-team/docs/standards/golang/index.md                       | XXX +
 dev-team/skills/shared-patterns/caching-analysis.md           | XXX +
 dev-team/skills/shared-patterns/standards-coverage-table.md   | XXX +
 5 files changed
```

**If any verification fails:**

1. Identify which file is missing or incorrect
2. Fix the specific file
3. Create a NEW commit with the fix (do NOT amend previous commits)
4. Re-run the verification

---

### Task 15: Run Final Code Review

1. **Dispatch all 8 reviewers in parallel:**
   - REQUIRED SUB-SKILL: Use ring:codereview
   - All reviewers run simultaneously (ring:code-reviewer, ring:business-logic-reviewer, ring:security-reviewer, ring:test-reviewer, ring:nil-safety-reviewer, ring:consequences-reviewer, ring:dead-code-reviewer, ring:performance-reviewer)
   - Scope: All changes from HEAD~3 to HEAD

2. **Handle findings by severity (MANDATORY):**
   - Critical/High/Medium: Fix immediately, re-run all reviewers
   - Low: Add TODO(review): comments
   - Cosmetic: Add FIXME(nitpick): comments

3. **Proceed only when zero Critical/High/Medium issues remain.**

---

## Summary of All Files Changed

| File | Action | Part |
|------|--------|------|
| `dev-team/docs/standards/golang/caching.md` | Create (new module 20) | A |
| `dev-team/docs/standards/golang/index.md` | Modify (add module 20, update counts) | A + B |
| `dev-team/skills/shared-patterns/standards-coverage-table.md` | Modify (add sections 45, 56-57, renumber) | A + B |
| `dev-team/docs/standards/golang/architecture.md` | Modify (add CQRS section + TOC row) | B |
| `dev-team/skills/shared-patterns/caching-analysis.md` | Create (new shared pattern) | C |

## Summary of Commits

| # | Commit Message | Files |
|---|---------------|-------|
| 1 | `feat(standards): add caching strategy standard (module 20)` | caching.md, index.md, standards-coverage-table.md |
| 2 | `feat(standards): add CQRS pattern section to architecture.md` | architecture.md, index.md, standards-coverage-table.md |
| 3 | `feat(standards): add caching analysis shared pattern for dev-refactor` | caching-analysis.md |
