---
name: shared-pattern:standards-cache-protocol
description: Protocol for reading cached standards from cycle state instead of WebFetching directly. Includes the canonical `<standards>` dispatch block format and the cache-first resolution protocol that reviewer agents follow at runtime.
---

# Standards Cache Protocol

## Purpose

Eliminate redundant WebFetch calls during a dev-cycle by pre-caching all required
standards at cycle start (dev-cycle Step 1.5) and having sub-skills and reviewer
agents read from state instead of fetching inline on every dispatch.

This document is the single source of truth for:

1. How orchestrators build the `<standards>` block at dispatch time.
2. How reviewer agents resolve that block (cache hit / cache miss / standalone fallback).

## Canonical `<standards>` Block Format

Orchestrators (dev-cycle, codereview SKILL) MUST use this exact block shape when
injecting cached standards into a reviewer's dispatch prompt:

```
<standards>
  <standard url="https://raw.githubusercontent.com/LerianStudio/ring/main/.../file.md">
    <content>{{ state.cached_standards["<same url>"].content OR empty }}</content>
  </standard>
  <!-- ...one <standard> per URL in the reviewer's slice... -->
</standards>
```

Rules:

- `url` attribute is ALWAYS populated (the canonical URL on `main`).
- `<content>` is populated when `state.cached_standards[url]` exists (cache hit).
- `<content>` is empty when the orchestrator has no cached entry (cache-miss signal).

## Orchestrator Resolution (at dispatch time)

```yaml
for each url in standards_slice:
  if state.cached_standards[url] exists:
    emit <standard url="..."><content>{{cached content}}</content></standard>
  else:
    emit <standard url="..."><content></content></standard>  # cache-miss signal
```

## Reviewer/Sub-Skill Resolution (at runtime)

Reviewer agents and sub-skills MUST follow this three-tier protocol, in order:

1. **Cache hit.** If the dispatch prompt contains a `<standards>` block and a
   `<standard>`'s `<content>` is populated, use that content as the authoritative
   rules source. No WebFetch needed.
2. **Cache miss fallback.** If a `<standard>`'s `<content>` is empty, WebFetch
   that `<standard>`'s `url` yourself and use the fetched content. Log a
   "Standard {url} not in cache; fetching inline" warning so operators can detect
   orchestrator misconfigurations. Do not skip the standard.
3. **Standalone fallback.** If the dispatch prompt contains no `<standards>`
   block at all (standalone/legacy invocation, no dev-cycle context), WebFetch
   the reviewer's hardcoded fallback URL list (defined in the reviewer agent
   itself) and proceed.

Pseudocode form (equivalent):

```yaml
STEP 1: Check cache
  IF <standards> block is present AND <standard>.<content> is populated:
    use content directly (cache hit)
    proceed

STEP 2: Cache-miss fallback
  IF <standards> block is present AND <standard>.<content> is empty:
    log WARNING: "Standard {url} not in cache; fetching inline"
    content = WebFetch(standard.url)
    proceed

STEP 3: Standalone fallback
  IF no <standards> block in dispatch prompt:
    FOR EACH url in reviewer's hardcoded fallback list:
      content = WebFetch(url)
    proceed
```

## Rolling Standards Policy

All URLs point to the `main` branch. WebFetch always returns current rules;
there is no pinned version. This is intentional — installed plugins pick up
standards updates without a plugin release.

## For Orchestrators (dev-cycle, dev-cycle-frontend)

At Step 1.5 of the cycle:

1. Detect project stack (Go / TypeScript / Frontend).
2. Build the URL list (see dev-cycle Step 1.5 for the current list).
3. WebFetch each URL once.
4. Write to `state.cached_standards[URL] = {fetched_at, content}`.
5. MANDATORY: Save state to file.
6. Blocker if ANY URL fails to fetch.

At dispatch time (Step 3 of codereview, and elsewhere): build the `<standards>`
block per the canonical format above, one `<standard>` entry per URL in the
reviewer's slice.

## Why

Before: ~15–25 WebFetch calls per cycle (one per sub-skill/reviewer dispatch).
Prompt cache TTL of 5 min is regularly exceeded, causing repeated network fetches
of identical content.

After: Exactly ONE WebFetch per unique URL per cycle. Same content, ~5x fewer
network operations.

## Safety

If the cache mechanism fails or is bypassed:

- Sub-skills and reviewers fall back to direct WebFetch (with warning log).
- No correctness regression; only performance regression.
- Operators can monitor "Standard {URL} not in cache" warnings to detect
  misconfigurations.

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "The cache might be stale — safer to WebFetch directly" | The cache is populated once at dev-cycle Step 1.5 specifically so every sub-skill and reviewer sees identical standards content within a cycle. Re-fetching creates drift between reviewers running in parallel and produces inconsistent verdicts. | **MUST read from `state.cached_standards[url]` when a `<standards>` block is present in the dispatch prompt. MUST NOT re-WebFetch on cache hit.** |
| "Empty `<content>` probably means the orchestrator failed — I'll just skip" | Empty `<content>` is the documented cache-miss signal. Skipping standards loading silently omits compliance checks the orchestrator expected to run. | **MUST WebFetch the URL on empty `<content>` and emit a WARNING to surface the cache miss. MUST NOT skip the standard.** |
| "No `<standards>` block in my prompt — I'll abort" | Absence of the block means standalone invocation (not dispatched from dev-cycle). Standalone invocation is a supported mode; the reviewer MUST still load standards via direct WebFetch using its own fallback URL list. | **MUST fall back to WebFetch of hardcoded URLs when no `<standards>` block is present. MUST NOT fail the review.** |
| "The cached content looks old — I'll fetch a fresh copy" | The cache is an intra-cycle consistency guarantee, not a freshness guarantee. Freshness is the orchestrator's concern at Step 1.5. A reviewer that second-guesses cache freshness breaks the guarantee for its peers. | **MUST trust cached content within a cycle. Report staleness concerns to the orchestrator via the Standards Compliance section of the review output, not by re-fetching.** |
| "Silent fallback is fine — no one reads warnings" | Silent fallbacks hide misconfigured orchestrators and let cache-population bugs fester across cycles. The WARN log is how operators detect cache-population regressions. | **MUST emit a clearly-prefixed WARNING log on every cache miss (e.g., `[cache-miss] WebFetching <url>`).** |
