# File Size Enforcement (MANDATORY)

## Standard Reference

**Source:** `golang/domain.md` → File Organization (MANDATORY), `typescript.md` → File Organization (MANDATORY)

**Rule:** Max 1000 lines per file (soft limit). Files exceeding 1500 lines are hard-blocked.

**Cohesion judgment (applies before splitting):** File size is a proxy for cognitive load, not a rule in itself. Before splitting, ask: does this file represent a single cohesive concern (state machine, parser, schema definition, table-driven tests, tightly-coupled domain logic)? If splitting would require inventing artificial boundaries or creating import gymnastics between the parts, keep it together. Splits must reduce cognitive load, not just line count.

**Enforcement bands:**
- ≤ 1000 lines: no action
- 1001–1500 lines: examine with cohesion judgment. If coherent → keep. If fragmentable without artificial boundaries → split.
- > 1500 lines: HARD BLOCK unless explicit cohesion justification is documented in the PR description.

This is a **HARD GATE** — not a suggestion.

---

## Thresholds

| Lines | Action |
|-------|--------|
| ≤ 1000 | ✅ Compliant — no action |
| 1001-1500 | ⚠️ EXAMINE — apply cohesion judgment. Coherent → keep. Fragmentable without artificial boundaries → split. |
| > 1500 | ❌ HARD BLOCK — split required unless explicit cohesion justification is documented in the PR description |

**These thresholds apply to ALL source files** (`*.go`, `*.ts`, `*.tsx`) **including test files**. Auto-generated files (swagger, protobuf, mocks, `*.pb.go`, `*.gen.ts`, `*.generated.ts`, `*.d.ts`) are exempt.

**Gate 0 enforcement:** Any non-exempt file > 1500 lines after implementation = hard block (loop back to agent). Files in the 1001-1500 band require cohesion review — keep if coherent, split if fragmentable without artificial boundaries.

---

## When to Check

| Context | Check Point |
|---------|-------------|
| **ring:running-dev-cycle Gate 0** | After implementation agent completes — verify no file exceeds 1500 lines; 1001-1500 = cohesion review; >1500 = hard block. The Delivery Verification Exit Check (ring:implementing-tasks) MUST run file-size verification. |
| **ring:running-dev-cycle Gate 8** | Code reviewers MUST flag any file > 1000 lines as a MEDIUM+ issue (apply cohesion judgment); files > 1500 lines are CRITICAL. |
| **ring:planning-backend-refactor Step 4** | Agents MUST flag files > 1000 lines as ISSUE-XXX (HIGH; cohesion override allowed). Files > 1500 lines = CRITICAL. |
| **ring:implementing-tasks** | Agent MUST NOT create files > 1500 lines. Files in the 1001-1500 band require cohesion justification or proactive split. |

---

## Verification Commands

```bash
# Go projects — excludes tests, docs, mocks, protobuf, generated files
# Note: awk filters out the "total" row emitted by wc when multiple files are counted
# Threshold 1000 is the soft limit; apply cohesion judgment to 1001-1500 band; >1500 = hard block.
find . -name "*.go" \
  ! -name "*_test.go" \
  ! -path "*/docs/*" \
  ! -path "*/mocks*" \
  ! -path "*/generated/*" \
  ! -path "*/gen/*" \
  ! -name "*.pb.go" \
  ! -name "*.gen.go" \
  -exec wc -l {} + | awk '$1 > 1000 && $NF != "total" {print}' | sort -rn

# Go test files (checked separately — same 1000-line soft limit)
find . -name "*_test.go" \
  ! -path "*/mocks*" \
  -exec wc -l {} + | awk '$1 > 1000 && $NF != "total" {print}' | sort -rn

# TypeScript projects — excludes node_modules, dist, build, generated, declaration files, mocks
find . \( -name "*.ts" -o -name "*.tsx" \) \
  ! -path "*/node_modules/*" \
  ! -path "*/dist/*" \
  ! -path "*/build/*" \
  ! -path "*/out/*" \
  ! -path "*/.next/*" \
  ! -path "*/generated/*" \
  ! -path "*/__generated__/*" \
  ! -path "*/__mocks__/*" \
  ! -path "*/mocks/*" \
  ! -name "*.d.ts" \
  ! -name "*.gen.ts" \
  ! -name "*.generated.ts" \
  ! -name "*.mock.ts" \
  -exec wc -l {} + | awk '$1 > 1000 && $NF != "total" {print}' | sort -rn
```

---

## Split Strategy

When a file exceeds the threshold, split by **responsibility boundaries** (not arbitrary line counts):

### Go

| Pattern | Split Into |
|---------|-----------|
| CRUD + validation + business logic | `*_command.go`, `*_query.go`, `*_validator.go` |
| Provisioning + deprovisioning | `*_provision.go`, `*_deprovision.go` |
| Handler with settings + cache + CRUD | `*_handler.go`, `*_handler_settings.go`, `*_handler_cache.go` |
| Service with lifecycle + helpers | `*_lifecycle.go`, `*_helpers.go` |
| Large test file | Split test file to mirror source file split |

**Go rules:**
1. All split files stay in the **same package** — zero breaking changes
2. All methods remain on the **same receiver** (if applicable)
3. Test files split to match: `foo.go` → `foo_test.go`
4. Run `go build ./...` and `go test ./...` after each split to verify

### TypeScript

| Pattern | Split Into |
|---------|-----------|
| Service with CRUD + validation + helpers | `*.service.ts`, `*.validator.ts`, `*.helpers.ts` |
| Controller with routes + middleware + handlers | `*.controller.ts`, `*.middleware.ts` |
| Large module barrel | Split into sub-modules by domain concept |
| Large test file | Split test file to mirror source file split |

**TypeScript rules:**
1. Split files stay in the **same module/directory** — update barrel exports (`index.ts`) if needed
2. Split by logical responsibility (class methods can be extracted to separate service/helper files)
3. Test files split to match: `foo.service.ts` → `foo.service.spec.ts`
4. Run `tsc --noEmit && npm test` after each split to verify

---

## Agent Instructions

### For ring:implementing-tasks (Gate 0) — Go

Include in Go implementation agent prompts:

```
⛔ FILE SIZE ENFORCEMENT (MANDATORY):
- Soft limit 1000 lines, hard block 1500 lines (including test files)
- Before splitting, apply cohesion judgment: if the file is a single cohesive concern (state machine, parser, schema, table-driven tests, tightly-coupled domain logic) and splitting would force artificial boundaries or import gymnastics, KEEP IT TOGETHER
- Splits must reduce cognitive load, not just line count
- Split by responsibility boundaries (not arbitrary line counts)
- Each split file stays in the same package
- All methods remain on the same receiver
- Test files MUST be split to match source files
- After splitting, verify: go build ./... && go test ./...
- Files 1001-1500 lines = examine with cohesion judgment. Files > 1500 lines = HARD BLOCK unless cohesion justification is documented in the PR description.

Reference: golang/domain.md → File Organization (MANDATORY)
```

### For ring:implementing-tasks (Gate 0) — TypeScript

Include in TypeScript implementation agent prompts:

```
⛔ FILE SIZE ENFORCEMENT (MANDATORY):
- Soft limit 1000 lines, hard block 1500 lines (including test files)
- Before splitting, apply cohesion judgment: if the file is a single cohesive concern (state machine, parser, schema, table-driven tests, tightly-coupled domain logic) and splitting would force artificial boundaries or import gymnastics, KEEP IT TOGETHER
- Splits must reduce cognitive load, not just line count
- Split by logical responsibility (not arbitrary line counts)
- Update barrel exports (index.ts) if needed after splitting
- Test files MUST be split to match source files
- After splitting, verify: tsc --noEmit && npm test
- Files 1001-1500 lines = examine with cohesion judgment. Files > 1500 lines = HARD BLOCK unless cohesion justification is documented in the PR description.

Reference: typescript.md → File Organization (MANDATORY)
```

### For ring:planning-backend-refactor (Step 4 agents)

Include in ALL analysis agent prompts:

```
⛔ FILE SIZE ENFORCEMENT (MANDATORY):
- Any source file > 1000 lines (including test files) MUST be flagged as ISSUE-XXX
- Files 1001-1500 lines: severity HIGH (subject to cohesion override — document reasoning if kept)
- Files > 1500 lines: severity CRITICAL with explicit decomposition plan unless cohesion justification is documented
- Apply cohesion judgment: state machines, parsers, schemas, table-driven tests, tightly-coupled domain logic may remain whole if splitting creates artificial boundaries
- Include line count and proposed split (or cohesion rationale to keep) in the finding
- Each file = one ISSUE-XXX (not grouped)
```

---

## Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "It's all one struct, can't split" | Methods on the same struct can live in different files (same package) | **Split by method responsibility** |
| "File will be split later" | Later = never. Split NOW during implementation. | **Split before gate passes** |
| "It's only 1100 lines, just over the limit" | 1001-1500 band requires cohesion review, not automatic pass. Apply judgment: coherent → keep; fragmentable without artificial boundaries → split. | **Apply cohesion judgment, document outcome** |
| "Splitting adds complexity" | Large files ARE complexity. Small focused files reduce cognitive load. | **Split by responsibility** |
| "Tests will break" | Split test files to match. Same package = same access. | **Split tests alongside source** |
| "Auto-generated code is large" | Auto-generated files (swagger, protobuf, mocks) are exempt. | **Check if truly auto-generated** |
| "This is a temporary file" | Temporary becomes permanent. Standards apply to all files. | **Split or delete** |
| "Test files don't count" | Large test files are equally hard to maintain. Same threshold applies. | **Split test files to match source** |
