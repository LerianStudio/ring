# Review Slicing Strategy

**Version:** 2.0.0
**Applies to:** ring:requesting-code-review, ring:codereview command, ring:review-slicer agent

---

## Why We Slice

Large PRs that touch multiple themes (API handlers + infrastructure + migrations + domain logic) force every reviewer to parse the full diff. This causes **context pollution**: each reviewer wastes context window on irrelevant files and produces shallower analysis on the files that actually matter to their domain.

**The problem scales non-linearly.** A 10-file PR in one theme is reviewed deeply. A 40-file PR across 4 themes means each reviewer gets 1/4 of useful signal buried in 3/4 noise. Review quality degrades faster than PR size grows.

Slicing solves this by giving each reviewer a focused, thematic subset of the diff. Same total coverage, dramatically better depth per file.

**Note:** The adaptive slicer v2 evaluates whether context pollution is actually present, rather than assuming it from file count alone.

---

## When We Slice

The `ring:review-slicer` agent uses **three-phase adaptive reasoning** instead of rigid threshold tables:

### Phase 1: Volume Assessment (Hard Guardrails)

| Condition | Decision | Rationale |
|-----------|----------|-----------|
| < 5 files | **Never slice** | Unconditional. Full-diff review is optimal. Slicing overhead has zero benefit at this volume. |
| 40+ files | **Always slice** | Unconditional. No PR of this size benefits from full-diff review regardless of cohesion. |
| 5-39 files | **Proceed to Phase 2** | Volume alone is insufficient to decide. Cohesion analysis required. |

### Phase 2: Cohesion Analysis (5-39 files)

For changesets in the adaptive range, the slicer evaluates **semantic cohesion** across six dimensions:

| Dimension | What It Measures | High Cohesion Signal |
|-----------|-----------------|---------------------|
| Package groupings | How many distinct packages/modules are touched | Files concentrated in 1-2 packages |
| Import relationships | Whether changed files import each other | Dense import graph among changed files |
| Naming patterns | Shared prefixes, suffixes, domain terms | Files share naming conventions (e.g., `order_*.go`) |
| Directory proximity | How close files are in the directory tree | Files clustered in adjacent directories |
| Functional relationships | Whether files collaborate on the same feature | Handler + service + repository for one entity |
| Diff concentration | Whether changes are spread thin or focused | Most hunks modify related logic |

### Phase 3: Cost-Benefit Judgment

The slicer makes a final decision based on whether slicing would **improve or degrade** review quality for the specific changeset:

- **High cohesion** → Don't slice. Splitting a cohesive changeset fractures context that reviewers need together.
- **Low cohesion** → Slice. Multiple unrelated themes benefit from focused review passes.
- **Mixed cohesion** → Slice, grouping cohesive files together into slices.

**Key insight:** File count is a volume signal, not a quality signal. Cohesion determines whether slicing helps. A 25-file PR touching one feature across handler/service/repo/test layers is best reviewed whole. A 12-file PR touching auth, billing, and migrations benefits from slicing.

---

## Enhanced Inputs

The adaptive slicer v2 receives enriched inputs that enable cohesion-based reasoning beyond simple file lists:

| Input | Format | Purpose |
|-------|--------|---------|
| `package_map` | `{ "pkg/order": ["order.go", "order_test.go"], ... }` | Files grouped by Go package or TS module. Reveals package-level concentration. |
| `import_hints` | `{ "handler.go": ["service.go", "model.go"], ... }` | Adjacency list showing which changed files import each other. Reveals functional coupling. |
| `change_summary` | `{ "handler.go": ["func CreateOrder", "func UpdateOrder"], ... }` | Per-file hunk headers for semantic context. Reveals what each file actually changes. |

These inputs allow the slicer to assess cohesion structurally rather than relying on directory heuristics or file count alone. When `import_hints` show dense cross-references among changed files, that is a strong signal to keep them together. When `package_map` reveals 5+ unrelated packages with no shared imports, that is a strong signal to slice.

---

## Why All 7 Reviewers on All Slices

**Key design decision: every reviewer runs on every slice. No "relevant reviewer" routing.**

The temptation is to route only "relevant" reviewers per slice — send `ring:security-reviewer` to the API slice but skip it for infrastructure. This is wrong for three reasons:

### 1. The Best Findings Are the Unexpected Ones

A security reviewer scanning a migration file might catch a privilege escalation path nobody else would flag. A nil-safety reviewer looking at infrastructure config might spot a missing null check in a template variable. Routing by "relevance" optimizes for the expected and kills the unexpected.

### 2. Cross-Cutting Concerns Are Invisible to Routing

Authorization logic might live in middleware (API slice) but depend on database roles defined in migrations (migration slice). A consequences reviewer needs to see both independently to catch the ripple effect. Routing that reviewer to only one slice would miss the cross-cutting dependency.

### 3. Cost Difference Is Negligible

7 reviewers on 1 full diff = 7 calls, each processing N files of context.
7 reviewers on 3 slices = 21 calls, each processing ~N/3 files of context.

Total tokens processed is roughly equivalent. The per-call cost is lower (smaller context = faster inference, fewer irrelevant tokens). The marginal increase in API calls is offset by better quality per call.

---

## How Slicing Works

### Grouping Strategy

Files are grouped by **semantic theme**, not blindly by directory:

| Theme | Description | Example Patterns |
|-------|-------------|-----------------|
| `api-handlers` | HTTP/gRPC handlers, middleware, routing | `*/api/*`, `*/handler*`, `*/route*`, `*/middleware*` |
| `domain-models` | Entities, value objects, business rules | `*/domain/*`, `*/model*`, `*/entity*`, `*/service/*` |
| `infrastructure` | Helm charts, K8s manifests, CI/CD | `charts/*`, `k8s/*`, `.github/*`, `Dockerfile*` |
| `migrations` | Database schema changes | `*/migration*`, `*/schema*`, `*.sql` |
| `tests` | Standalone test infrastructure | `testutil/*`, `test/*` (not co-located tests) |
| `config` | Application configuration, bootstrap | `cmd/*/main.go`, `*.toml`, `*.env*` |
| `documentation` | Non-code documentation | `*.md`, `docs/*` |

### Co-Location Rule (NON-NEGOTIABLE)

**Test files MUST be co-located with the production code they test.** If `handler.go` is in the `api-handlers` slice, then `handler_test.go` goes in that same slice. The test-reviewer MUST see code + tests together to assess coverage.

### Constraints

- A file appears in exactly **one** slice (no duplication)
- Target **2-5 slices** (merge smallest if > 5)
- Every slice has at least 1 file
- Ambiguous files go to the closest match by directory proximity

---

## How Deduplication Works

When 7 reviewers run on N slices, the same issue might surface multiple times. The consolidation step deduplicates before presenting results:

### Exact Match Dedup

**Same reviewer + same file:line** across different invocations (e.g., re-run) = keep one instance.

### Fuzzy Match Dedup

**Different reviewers or different slices + same file:line + description similarity > 80%** = keep the more detailed finding. Note which reviewers flagged it (higher confidence signal).

### Cross-Cutting Detection

**Same issue found across multiple slices** = flag as **"cross-cutting concern"**. This is a high-value signal: it often indicates an architectural issue (e.g., a broken interface contract affecting both API and domain slices). Cross-cutting issues are surfaced prominently in the consolidated report.

### Dedup Preserves Signal

Dedup removes noise, not signal. Two different reviewers catching the same issue from different angles is stronger evidence, not redundancy. The consolidated report notes "found by N reviewers" to convey confidence.

---

## Cost Analysis

| Scenario | API Calls | Context per Call | Total Tokens | Review Quality |
|----------|-----------|-----------------|--------------|---------------|
| **No slicing** (40-file PR) | 7 | ~40 files each | 7 x FULL | Shallow (noise dilutes signal) |
| **3 slices** (40-file PR) | 21 | ~13 files each | 21 x (FULL/3) ~ 7 x FULL | Deep (focused context per slice) |
| **5 slices** (40-file PR) | 35 | ~8 files each | 35 x (FULL/5) ~ 7 x FULL | Deepest (most focused) |

**Key insight:** Total tokens processed is approximately constant. We're redistributing the same work into focused chunks, not adding work.

**Slicer overhead (v2):** The adaptive slicer uses a **Sonnet-class model** for reasoning capability (upgraded from Flash/Haiku). Latency target is **< 15 seconds** (up from < 5s in v1). This is justified because the slicer runs **once per review**, and its decision shapes **7 x N downstream reviewer calls**. A better slice/no-slice decision at 15s saves far more than 10s of slicer time when it prevents unnecessary sliced dispatches or avoids context pollution in full-diff mode. Token cost per slicer call is slightly higher, but potentially fewer unnecessary sliced dispatches save downstream tokens when full-diff is actually optimal.

---

## Integration Points

### With Mithril Pre-Analysis

The slicer runs **after** Mithril completes. Mithril context files are filtered per slice: each reviewer receives only the Mithril analysis sections that mention files in their slice. This keeps pre-analysis context focused too.

### With Reviewer Dispatch

When slicing is active:
- `implementation_files` passed to each reviewer = the slice's file list, not the full list
- Git diff is scoped: `git diff [base_sha] [head_sha] -- [slice files...]`
- All 7 reviewers still dispatch in parallel per slice

### With Consolidation

The consolidation step (Step 4 of the review skill) merges all slice results before presenting to the user. The output format is unchanged — the user sees a unified review report, not per-slice fragments. The only visible difference is a note:

> "Review was sliced into N thematic groups for deeper analysis."

---

## Transparency to Users

**The user never manages slices.** Slicing is an internal optimization:

- Small PRs: No slicing, no mention of slicing. Zero overhead.
- Large PRs: Slicing happens automatically. Report notes "sliced into N groups."
- The consolidated report is identical in structure to a non-sliced review.
- Per-slice details are available in `review_state.slices` for debugging but not surfaced by default.

---

## Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Route only relevant reviewers per slice" | Unexpected findings > efficiency. All 7, all slices. | **Dispatch all 7 on every slice** |
| "Skip slicing, reviewers can handle large diffs" | Context pollution degrades quality non-linearly | **Apply adaptive slicer. Respect hard guardrails and cohesion analysis.** |
| "Slice into 8 themes for maximum focus" | > 5 slices = overhead exceeds benefit | **Merge to stay within 2-5** |
| "Separate tests into their own slice" | Reviewers need code + tests together | **Co-locate tests with production code** |
| "Dedup removes too many findings" | Dedup removes duplicates, not unique findings | **Dedup by file:line + similarity only** |
| "Cohesion analysis takes too long, just count files" | Volume-only decisions are the old model. Cohesion analysis is mandatory for the 5-39 file range. | **MUST run cohesion analysis for adaptive range. Hard guardrails handle extremes.** |
| "Import hints aren't available, skip cohesion" | Missing inputs degrade analysis but do not eliminate it. | **Fall back to conservative mode: favor no-slice for medium counts, slice for high counts. MUST note degraded analysis in reasoning.** |
