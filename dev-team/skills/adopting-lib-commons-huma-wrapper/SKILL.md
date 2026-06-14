---
name: ring:adopting-lib-commons-huma-wrapper
description: "Adopting the lib-commons/v5 shared Huma (OAS 3.1) OpenAPI wrapper + RFC 9457 problem model (commons/net/http/{openapi,problem}) in a Lerian Go service: wire openapi.New/ServeSpec + problem.Install (central >=500 scrub) on BOTH runtime and spec-gen paths, the per-rail problem.MapError flex seam, and rename-only spec regen. Orchestrates a gated cycle dispatching ring:backend-go. Use for greenfield Huma or migrating a service off a local openapi/humaerr wrapper. Skip for non-Go or non-HTTP work."
---

# Adopt the lib-commons Huma OpenAPI Wrapper

## When to use
- A Go service needs code-first OpenAPI 3.1 over Fiber (Huma) with RFC 9457 `application/problem+json` errors
- User asks to "adopt the lib-commons OpenAPI/problem wrapper", "use the shared Huma wrapper", "standardize error responses on RFC 9457"
- A service already carries a **local copy** of the wrapper (`internal/shared/adapters/openapi`, `shared/openapi`, `shared/humaerr`, a hand-rolled `huma.NewError` override) and should move onto the shared `lib-commons/v5/commons/net/http/{openapi,problem}`
- A service is still on swaggo/swag (Swagger 2.0) and is migrating to Huma

## Skip when
- Service is not a Go project
- Task does not involve an HTTP API / OpenAPI spec
- The service genuinely needs a bespoke error envelope that is NOT RFC 9457 (rare; challenge it first)
- Documentation-only or non-code task

You orchestrate. Agents implement. NEVER use Edit/Write/Bash on Go source files — all code changes go through `Task(subagent_type="ring:backend-go")`. TDD mandatory for implementation gates (RED → GREEN → REFACTOR). The orchestrator owns git (commit/push/PR/release) and NEVER commits without the user's go-ahead.

## Architecture

The wrapper is **two packages** in `lib-commons/v5` (minimum **v5.6.0**):

| Alias | Import Path | Purpose |
|-------|-------------|---------|
| `openapi` | `github.com/LerianStudio/lib-commons/v5/commons/net/http/openapi` | `Config`, `New` (builds the `humafiber` API), `DeclareBearerAuth`, `ServeSpec` |
| `problem` | `github.com/LerianStudio/lib-commons/v5/commons/net/http/problem` | `Install` (global `huma.NewError` override), `MapError`, `Detail`, `BaseURI` |

**`openapi.New(app, group, cfg)`** constructs the Fiber-v2 Huma API via `humafiber.NewV2WithGroup` (the default `humafiber.New` targets Fiber v3 — wrong major), strips Transformers/OnAddOperation/CreateHooks, and **clears the auto-mounted `/openapi.json` + `/docs`** (auto-mount is a latent production exposure — the spec must be served explicitly and gated). `Config{Title, Version, Description, Servers}`.

**`openapi.ServeSpec(app, api, logger, prefix, title)`** mounts `{prefix}/openapi.json`, `{prefix}/openapi.yaml`, `{prefix}/docs` (Scalar UI). It normalizes `prefix` (leading slash, no trailing) and HTML-escapes the docs-page title and spec URL. **Gate this behind the service's `Swagger.Enabled`** flag — never serve unconditionally.

**`openapi.DeclareBearerAuth(api)`** registers the `BearerAuth` security scheme *component* (`components.securitySchemes`) so per-operation `Security` references resolve — it does NOT add a per-operation requirement (that stays the handler/registration's job). Wire it iff the API advertises bearer auth — runtime enforcement is separate (lib-auth middleware); omitting it only means the spec doesn't *document* the scheme.

**`problem.Install()`** is the crux. It is a `sync.Once` override of the process-global `huma.NewError`, so EVERY error Huma builds — domain errors via `MapError` and the framework's own validation/404/422 errors — becomes a `*problem.Detail`. Merge semantics:
- **status >= 500**: body scrubbed to the static `"internal error"`, NO `errs` folded. This is the central info-leak guard — even a careless `huma.Error500(rawErr.Error())` cannot leak an internal cause.
- **status < 500**: `msg` passes through and `errs` fold into `Errors[]` in order (skip nil, honor `huma.ErrorDetailer`) — native 422 field errors are preserved.

**`problem.MapError(err, codeOf, statusOf, fallbackCode)`** is the per-rail **flex seam** — the one place each service injects its own taxonomy:
- `codeOf func(error) (code, msg string, ok bool)` — extract a domain code; `ok=false` → unrecognized → sanitized 500 carrying `fallbackCode`.
- `statusOf func(code string) int` — map code → HTTP status.
- `fallbackCode` — code carried when the error is nil/unrecognized.
- A service WITH a code taxonomy passes real callbacks + a fallback (e.g. `"SPB-9000"`); a **bare** service passes an empty fallback and `code` is dropped (`omitempty`).

**`problem.Detail`** embeds `huma.ErrorModel` + an `omitempty` `Code`. Services that never set a code emit a bare RFC 9457 body; coded errors mapped through `MapError` carry the machine code in `Code` + a flat `Type` URI (`BaseURI + "/" + code`). `Type` is set **only** on the `MapError` coded path — framework-built errors (native 422/404 via `Install`) keep `Type` at `about:blank` with empty `Code`.

## Dependency facts (do not re-litigate)

- **huma version MUST match** what the pinned lib-commons build uses (`danielgtaylor/huma/v2 v2.38.0` at v5.6.0). A mismatch is module-graph skew that the security-scan/SBOM gate will flag.
- **`humafiber` drags `gofiber/fiber/v3` as an indirect dep** — this is EXPECTED, not a bug. `humafiber` is one package importing both Fiber majors; Go compiles the whole package, so importing it for the v2 funcs pulls v3 into the graph. Only the v2 path compiles into the binary. `govulncheck` stays quiet (v3 unreachable); Trivy/SBOM may flag *future* fiber/v3 CVEs — a waivable false positive, NOT a reason to avoid the wrapper.
- Test the API through the real `*fiber.App` via `app.Test`, not `humatest` (the humatest adapter diverges on `Unwrap`).

**Mandatory agent instruction (include in EVERY dispatch):**

> Use the canonical imports `github.com/LerianStudio/lib-commons/v5/commons/net/http/openapi` and `.../problem`. Do NOT reintroduce a local openapi/humaerr wrapper or a hand-rolled `huma.NewError` override — `problem.Install()` owns that globally.
> `problem.Install()` MUST be called before ANY Huma operation is registered, on BOTH the runtime API and any spec-gen API, or the runtime error bodies and the committed spec diverge.
> Match the huma version the pinned lib-commons uses (v2.38.0 @ v5.6.0). The indirect `fiber/v3` is expected — do not try to remove it.
> Serve the spec only via `openapi.ServeSpec`, gated on the Swagger-enabled flag. Never rely on Huma auto-mount.
> Preserve the service's existing per-rail code taxonomy verbatim — only rewire the wrapper call into `problem.MapError`.
> TDD: RED → GREEN → REFACTOR for every gate. Test via `app.Test`, not humatest.

## Gate Overview

| Gate | Name | Condition | Agent |
|------|------|-----------|-------|
| 0 | Stack Detection + Compliance Audit | Always | Orchestrator |
| 1 | Codebase Analysis (HTTP + error focus) | Always | ring:codebase-explorer |
| 1.5 | Implementation Preview | Always | ring:visualizing |
| 2 | lib-commons v5.6.0+ + huma version alignment | Always | ring:backend-go |
| 3 | `openapi.New` + `problem.Install` on BOTH paths | Always | ring:backend-go |
| 4 | Per-rail `problem.MapError` wiring | Skip only if zero domain-error mapping (bare framework errors only) | ring:backend-go |
| 5 | `ServeSpec` (gated) + `DeclareBearerAuth` | Always | ring:backend-go |
| 6 | Delete the local wrapper | Migration mode only (skip for greenfield) | ring:backend-go |
| 7 | Regenerate spec + prove rename-only | Always | ring:backend-go |
| 8 | Tests (build + unit `-race` + spec-drift gate) | Always | ring:backend-go |
| 9 | Code Review | Always | 9 defaults + triggered specialists |
| 10 | User Validation | Always | User |
| 11 | Release/pin discipline (cross-repo) | Only if the wrapper version is unreleased | Orchestrator + User |

Gates execute sequentially. Any surviving local wrapper or hand-rolled `huma.NewError` override = NON-COMPLIANT = gates cannot be skipped.

## Gate 0: Stack Detection + Compliance Audit

Orchestrator executes directly.

```bash
grep -n "lib-commons/v5" go.mod                                  # version (need >= v5.6.0)
grep -n "danielgtaylor/huma" go.mod                              # huma version (match the lib build)
grep -rn "humafiber\|huma.Register\|huma.Get\|huma.Post" internal/ cmd/   # existing Huma usage
grep -rln "huma.NewError" internal/ cmd/                         # hand-rolled overrides (must go)
grep -rn "shared/openapi\|shared/humaerr\|adapters/openapi" --include='*.go' .  # LOCAL wrapper (migration mode)
grep -rn "swaggo\|gofiber/swagger\|// @" --include='*.go' . docs/    # legacy swaggo (migrating from 2.0)
grep -rn "ServeSpec\|openapi.New\|problem.Install" internal/ cmd/  # already partially adopted?
grep -rn "Swagger.Enabled\|SWAGGER_ENABLED" internal/            # the serving gate flag
```

**Mode detection:**
- **Migration mode** — a local `openapi`/`humaerr` package or a hand-rolled `huma.NewError` override exists → Gate 6 runs.
- **Greenfield mode** — Huma not yet wired (or swaggo only) → Gate 6 skipped, Gate 3 builds fresh.

**Compliance audit** (if any Huma code detected):
- `problem.Install()` present on the runtime path AND the spec-gen path
- No surviving local wrapper / hand-rolled `huma.NewError` override
- Spec served only via `ServeSpec`, gated; no auto-mount
- huma version matches the lib-commons build

## Gate 2: Version + huma alignment

Ensure `go.mod` requires `lib-commons/v5 >= v5.6.0` and `danielgtaylor/huma/v2` at the version that lib-commons build uses. `go mod tidy`; expect `fiber/v3` to appear/stay indirect (expected). If validating against an **unreleased** wrapper version, use a local `replace => ../lib-commons` (see Gate 11) — never pin a pre-release for merge.

## Gate 3: `openapi.New` + `problem.Install` — BOTH paths

The single most common defect is wiring `problem.Install()` on only one path. Huma resolves the error response schema at **operation-registration time**, and `Install` swaps a process-global, so it must run **before** every `huma.Register/Get/Post` on:
1. the **runtime** API (bootstrap/routes), and
2. every **spec-gen** entrypoint (the `cmd/huma-spec`-style builder that writes the committed `openapi.yaml`).

If the two disagree on whether `Install` ran, the served error bodies and the committed spec diverge. `openapi.New` itself registers no operations (auto-mount cleared), so the correct order is: `api := openapi.New(...)` → `problem.Install()` → register operations.

## Gate 4: Per-rail `problem.MapError`

Replace the service's existing domain-error→HTTP translation with `problem.MapError`, **preserving its code taxonomy verbatim**. Wire `codeOf`/`statusOf`/`fallbackCode`:
- Coded rail: `codeOf` reads the service's domain-error code, `statusOf` is its code→status table, `fallbackCode` is the house "unknown" code.
- Bare rail: empty `fallbackCode`; `Code` is omitted from the body.
Verify the mapped status semantics are unchanged from before (this gate is a rewire, not a re-design).

## Gate 5: `ServeSpec` (gated) + `DeclareBearerAuth`

Mount the spec via `openapi.ServeSpec(app, api, logger, prefix, title)` behind the Swagger-enabled flag. If the API uses bearer auth and should advertise it, call `openapi.DeclareBearerAuth(api)` before registration. Confirm the served paths match the service's existing convention (no path drift).

## Gate 6: Delete the local wrapper (migration mode)

Remove the local `openapi`/`humaerr` packages and any hand-rolled `huma.NewError` override. Then:
- `grep -rn` for the old import paths/symbols → must be EMPTY in Go code.
- Relocate any cross-package parity/contract test out of the deleted dirs; retarget renamed schema component names.
- Fix stale doc-comments AND live docs (READMEs/architecture docs) that point at the removed packages — the diff-stat won't show these; grep for them.

## Gate 7: Regenerate spec + prove rename-only

Regenerate the committed OpenAPI spec(s). The diff should be **only** the error-schema rename (`ErrorModel`→`Detail`, or a local `ProblemDetail`→`Detail`) + the additive `code` property + `$ref` re-targets. **Do not trust the diff-stat** — an alphabetical component re-sort inflates insert/delete counts. Prove rename-only with an order-independent comparison:

```bash
diff <(git show HEAD:path/to/openapi.yaml | sed 's/ProblemDetail/Detail/g' | sort) <(sort path/to/openapi.yaml)
# EMPTY => pure rename (HEAD+rename equals worktree as a line multiset)
```

Confirm/refresh the committed-spec drift gate so a stale spec fails CI.

## Gate 8: Tests

Build + unit `-race` + the spec-drift gate. Error-policy assertions (the highest-value tests in the migration): a forced `>=500` asserts `detail == "internal error"` AND `Errors == nil` (no leaked cause); a `<500` validation error keeps its `Errors[]` field list. Note: `huma.ErrorModel.Type` is `omitempty` and is set only on the `MapError` coded path — assert `type` only on coded-domain responses, never on native 422/404 (where it stays `about:blank`/absent). Always assert `title`/`status`/`detail`/`code`.

## Gate 11: Release / pin discipline (cross-repo, only if the wrapper version is unreleased)

Relevant only when this adoption rides an **unreleased** lib-commons wrapper change (you modified the wrapper too). The shared `security-scan` gate **reds any PR pinned to a pre-release version**. So:
1. Validate the consumer against the beta via a local `replace => path/to/lib-commons` (the require can lag; replace overrides resolution).
2. Cut the lib-commons **stable** tag (develop→main release PR; semantic-release auto-tags) BEFORE pinning any consumer.
3. Drop the `replace`, bump `require` to the stable tag (a stale `require` masked by a replace will break the build when the replace is removed — bump them together), `go mod tidy && go mod verify`.
4. Only then open/merge the consumer PR — now the pre-release pin gate passes.
Intra-repo `replace` directives (module wiring within a multi-module repo) are fine and version-scoped; the gate targets pre-release *versions*, not the existence of a `replace`.

## Severity Reference

| Severity | Criteria |
|----------|----------|
| CRITICAL | `problem.Install()` missing on the runtime OR spec-gen path (runtime/spec divergence); a surviving hand-rolled `huma.NewError` override or local wrapper still in the binary; a `>=500` body leaking a raw cause (bypassing the central scrub) |
| HIGH | Per-rail `MapError` not wired (errors not RFC 9457); local wrapper not fully deleted (dangling refs / dead code); committed spec not regenerated (drift gate red); a consumer PR pinned to a pre-release lib-commons version (merge gate red) |
| MEDIUM | huma version skew vs the lib-commons build (graph/SBOM flag); `ServeSpec` not gated on the Swagger flag (prod spec exposure); treating the indirect `fiber/v3` as a bug to remove |
| LOW | `DeclareBearerAuth` omitted when the API uses bearer auth (spec doesn't advertise it); asserting on the absent `type` field; spec `Servers` left unset when the service should advertise one |

## Related

**Complementary:** ring:using-lib-commons (the broader non-observability lib-commons surface; this wrapper lives under its `commons/net/http`)
**Similar:** ring:migrating-to-lib-systemplane, ring:migrating-to-lib-observability
**Skills orchestrated:**
- ring:codebase-explorer
- ring:visualizing
- ring:backend-go
- ring:reviewing-code
