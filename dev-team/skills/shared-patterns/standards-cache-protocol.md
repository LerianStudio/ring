---
name: shared-pattern:standards-cache-protocol
description: Protocol for reading cached standards from cycle state instead of WebFetching directly.
---

# Standards Cache Protocol

## Purpose

Eliminate redundant WebFetch calls during a dev-cycle by pre-caching all required
standards at cycle start (dev-cycle Step 1.5) and having sub-skills read from state.

## Protocol

### For Sub-Skills

When a sub-skill needs a standards document:

```yaml
STEP 1: Check state cache
  IF state.cached_standards[URL] exists:
    content = state.cached_standards[URL].content
    log: "Using cached standard: {URL} (fetched {fetched_at})"
    proceed with content
  ELSE:
    goto STEP 2

STEP 2: Fallback WebFetch (only if cache miss)
  log WARNING: "Standard {URL} not in cache; fetching inline"
  content = WebFetch(URL)
  proceed with content
```

### For Orchestrators (dev-cycle, dev-cycle-frontend)

At Step 1.5 of the cycle:
1. Detect project stack (Go / TypeScript / Frontend)
2. Build URL list (see dev-cycle Step 1.5 for current list)
3. WebFetch each URL once
4. Write to `state.cached_standards[URL] = {fetched_at, content}`
5. MANDATORY: Save state to file
6. Blocker if ANY URL fails to fetch

## Why

Before: ~15–25 WebFetch calls per cycle (one per sub-skill dispatch). Prompt cache TTL
of 5 min is regularly exceeded, causing repeated network fetches of identical content.

After: Exactly ONE WebFetch per unique URL per cycle. Same content, ~5x fewer network
operations.

## Safety

If the cache mechanism fails or is bypassed:
- Sub-skills fall back to direct WebFetch (with warning log).
- No correctness regression; only performance regression.
- Operators can monitor "Standard {URL} not in cache" warnings to detect misconfigurations.
