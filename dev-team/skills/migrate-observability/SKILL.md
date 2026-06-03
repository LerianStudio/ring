---
name: ring:migrate-observability
description: |
  Migrates a Lerian Go application's direct observability imports from
  lib-commons (deprecated shims OR already-removed APIs) to lib-observability.
  Operates in three compatible modes against the same known mapping table:
    - pre-removal reference mode: when a removal commit is known, inspect the
      parent/previous lib-commons ref to recover the source-side Deprecated
      notices and exact migration scope.
    - deprecated-shim mode: effective lib-commons still ships the shims with
      `// Deprecated:` notices.
    - removed-api/break-fix mode: lib-commons has already removed the observability
      packages/symbols (sources absent, `go list` or `go build` fails on the
      removed imports). The skill still migrates known source imports/symbols
      by static source analysis of the application repo.
      It also applies the companion dependency moves required by the same
      lib-commons removal train: stable lib-streaming/lib-systemplane bumps and
      direct systemplane imports moved out of lib-commons.
  Targets are gated on the lib-observability target API, not on the presence of
  source-side Deprecated notices. Adds lib-observability to go.mod and validates
  the build. Scope is strictly observability: deprecated/removed observability
  packages, commons/net/http observability middleware/span symbols, root commons
  observability context helpers, commons/opentelemetry, and direct
  commons/systemplane imports. Does NOT touch infrastructure clients or general
  commons helpers.
---

# Migrate lib-commons Observability APIs to lib-observability

## When to use
- Application imports one or more lib-commons observability packages/symbols listed in the mapping table below
- Team decision to eliminate deprecation warnings from lib-commons shims
- lib-commons deprecation notices appear in IDE or go vet output
- Application no longer builds because lib-commons has removed observability APIs and source imports still reference them

## Skip when
- Application already imports lib-observability for all observability concerns
- Application has no imports of the lib-commons observability packages/symbols listed below
- Application is lib-commons itself

**Do NOT skip when:**
- "The app only imports log/ from lib-commons" → still migrate; log is an observability target
- "The app uses streaming/kafka" → streaming is out of scope; only observability packages and HTTP/gRPC observability middleware migrate
- "The app uses commons/opentelemetry for tracing bootstrap" → migrate when `lib-observability/tracing` exposes the target API (helper-only files first, bootstrap when type boundaries allow)
- "`go list` or `go build` fails because lib-commons removed the observability APIs" → still migrate; this skill performs static source rewrites against the known mapping table even when the source packages no longer exist

## Sequence
**Runs before:** (none)
**Runs after:** (none)

## Related
**Complementary:** ring:using-ring, ring:dev-cycle, ring:codereview, ring:lint, ring:using-lib-commons

---

## Overview

This skill replaces imports/usages of lib-commons observability APIs
with their canonical lib-observability equivalents.

**Stable target baseline for this migration:**
- `github.com/LerianStudio/lib-commons/v5` >= `v5.2.0`
- `github.com/LerianStudio/lib-observability` >= `v1.0.0`
- `github.com/LerianStudio/lib-auth/v2` >= `v2.8.0` when present
- `github.com/LerianStudio/lib-license-go/v2` >= `v2.3.5` when present
- `github.com/LerianStudio/lib-streaming` >= `v1.3.1` when present
- `github.com/LerianStudio/lib-systemplane` >= `v1.0.0` when systemplane is used

`lib-commons/v5.2.0` is the first stable lib-commons release where the
deprecated observability shims are removed. `lib-observability/v1.0.0` is the
first stable lib-observability release. `lib-auth/v2.8.0` and
`lib-license-go/v2.3.5` are the first stable companion releases known to be
compatible with the removed lib-commons observability APIs. `lib-streaming/v1.3.1`
is the first stable streaming release in this validation set that no longer
imports removed lib-commons observability packages. `lib-systemplane/v1.0.0`
is the stable package destination for direct `commons/systemplane` imports
removed from lib-commons. Do not use beta tags for new migrations unless the
target application is intentionally pinned to a beta train.

**Known lib-commons observability removal refs:**
- Removal commit: `fe1db9e60ac9e959de4288208b6cf65f7bbfe439`
  (`refactor: remove deprecated commons observability shims`)
- First stable removal release: `v5.2.0`
- Pre-removal reference: `fe1db9e60ac9e959de4288208b6cf65f7bbfe439^`
  (currently `a33b160ac165cff8b4ddf5c69d8dbb80a10868f6`)

Use the pre-removal reference as the default source-evidence ref when the
effective lib-commons dependency has already removed the deprecated shims and
the user did not provide `lib_commons_pre_removal_ref`. That ref still contains
the `Deprecated:` notices while using lib-observability types internally.

**Targeting strategy:** migrate known observability APIs when the target API
exists in the effective lib-observability version. Source-side `Deprecated:`
notices are preferred evidence. Read them from the effective lib-commons version
when available; if a removal commit/ref is known, read them from the immediate
pre-removal lib-commons ref. If neither source is available because lib-commons
has already removed the package/symbol, the application may not compile, and the
skill must still migrate by static source analysis.

If a target API is missing from lib-observability, do not migrate that API.
Report the missing target and leave the lib-commons usage unchanged unless it is
already broken by removal; in that case report it as a manual migration blocker.

In removed-api mode, package-level imports such as `commons/log` can still
cross non-observability lib-commons boundaries (for example
`mongo.Config.Logger`, `postgres.Config.Logger`, `WithCORSLogger`,
`circuitbreaker.NewManager`, auth middleware, outbox/tenant-manager clients,
streaming builders, or any remaining lib-commons API typed as
`commons/log.Logger`). Do not invent adapters in the skill.
Migrate safe source files, run build validation, and if a file fails only
because a migrated value crosses a remaining lib-commons typed boundary, revert
that file/family to lib-commons and report it as a manual blocker.

Also check transitive dependencies after bumping lib-commons to a removal
release. If `go build` fails from `$GOMODCACHE` with errors such as
`no required module provides package github.com/LerianStudio/lib-commons/v5/commons/log`,
`commons/zap`, or `commons/opentelemetry`, the target repo was
migrated as far as local source allows, but one of its dependencies still
depends on removed lib-commons observability packages. First try the known
stable companion bumps when the modules are present:

```bash
GONOSUMDB="github.com/LerianStudio/*" \
GOPRIVATE="github.com/LerianStudio/*" \
  go get github.com/LerianStudio/lib-auth/v2@v2.8.0 \
         github.com/LerianStudio/lib-license-go/v2@v2.3.5 \
         github.com/LerianStudio/lib-streaming@v1.3.1 \
         github.com/LerianStudio/lib-systemplane@v1.0.0
go mod tidy
```

If the dependency is outside that stable set (for example `lib-auth/v3`,
`systemplane` packages removed from lib-commons, or a `lib-streaming` version
older than `v1.3.1`), first apply the known companion bumps and direct
systemplane import move. Then report only the remaining module/package as a
manual blocker; do not try to patch module cache files or vendor ad-hoc
replacements into the application.

Known repo-specific dependency drift:
- `matcher` may depend on `github.com/LerianStudio/lib-auth/v3` as a
  pseudo-version even though there is no stable lib-auth v3 release in this
  migration train. If that pseudo-version still imports removed lib-commons
  observability packages, do not rewrite it automatically. Report it as a
  dependency blocker and ask the executor whether they want to move matcher back
  to `github.com/LerianStudio/lib-auth/v2@v2.8.0` for this migration.

Packages that are NOT deprecated in lib-commons (e.g. non-observability
`commons/net/http` helpers, `commons/streaming`) are explicitly out of scope.

**What changes:** import paths and deprecated symbol qualifiers in `.go` files + `go.mod` dependency.
**What stays the same:** all non-deprecated lib-commons packages, including infrastructure
clients (`commons/postgres`, `commons/streaming`, etc.).

---

## CRITICAL: Role Clarification

| Who | Responsibility |
|-----|----------------|
| **This Skill** | Discover imports, plan replacements, validate, report |
| **Agent** | Apply file edits, run go mod, fix compilation errors |

---

## Import Mapping Reference

The lib-commons observability packages and their lib-observability replacements.
Match the source import with the module major already used by the repo
(`/v2`, `/v4`, `/v5`, etc.); do not require a lib-commons major-version bump
before migrating observability imports.

| lib-commons import | lib-observability replacement | Package name change? |
|---|---|---|
| `lib-commons[/vN]/commons/log` | `lib-observability/log` | No — qualifier stays `log` |
| `lib-commons[/vN]/commons/zap` | `lib-observability/zap` | No — qualifier stays `zap` |
| `lib-commons[/vN]/commons/runtime` | `lib-observability/runtime` | No — qualifier stays `runtime` |
| `lib-commons[/vN]/commons/assert` | `lib-observability/assert` | No — qualifier stays `assert` |
| `lib-commons[/vN]/commons/opentelemetry` | `lib-observability/tracing` | Yes if the old import was unaliased: `opentelemetry.X` → `tracing.X`. Preserve explicit aliases. |
| `lib-commons[/vN]/commons/opentelemetry/metrics` | `lib-observability/metrics` | No — qualifier stays `metrics` |
| `lib-commons[/vN]/commons/opentelemetry/constants` | `lib-observability/constants` | No — qualifier stays `constants` |
| `lib-commons[/vN]/commons/opentelemetry/redaction` | `lib-observability/redaction` | No — qualifier stays `redaction` |

> The metrics/constants/redaction/log/zap/runtime/assert replacements share the same package qualifier — import path changes only,
> no call-site renames needed in the file body.
> For root `commons/opentelemetry`, preserve explicit aliases such as
> `libOpentelemetry` or `libCommonsOtel`. If the import is unaliased, rewrite
> the package qualifier from `opentelemetry` to `tracing`.

### Deprecated root commons/opentelemetry package

`commons/opentelemetry` is an API-aware package migration. Run it when the
effective `lib-observability/tracing` package exposes the matching bootstrap,
span, redaction, and propagation APIs. A source-side `Deprecated:` notice is
accepted as deprecated-shim mode evidence; source package absence or compile
failure is accepted as removed-api mode evidence.

| Deprecated symbol family | lib-observability replacement |
|---|---|
| `TelemetryConfig`, `Telemetry`, `NewTelemetry`, `ApplyGlobals`, `Tracer`, `Meter`, `ShutdownTelemetry*` | `tracing` equivalents |
| `RedactionRule`, `Redactor`, `NewDefaultRedactor`, `NewAlwaysMaskRedactor`, `NewRedactor`, `ObfuscateStruct` | `tracing` equivalents |
| `AttrBagSpanProcessor`, `RedactingAttrBagSpanProcessor` | `tracing` equivalents |
| `HandleSpanBusinessErrorEvent`, `HandleSpanEvent`, `HandleSpanError` | `tracing` equivalents |
| `SetSpanAttributesFromValue`, `BuildAttributesFromValue`, `SetSpanAttributeForParam` | `tracing` equivalents |
| `InjectTraceContext`, `ExtractTraceContext`, `InjectHTTPContext`, `ExtractHTTPContext`, `InjectGRPCContext`, `ExtractGRPCContext` | `tracing` equivalents |
| `InjectQueueTraceContext`, `ExtractQueueTraceContext`, `PrepareQueueHeaders`, `InjectTraceHeadersIntoQueue`, `ExtractTraceContextFromQueueHeaders` | `tracing` equivalents |
| `GetTraceIDFromContext`, `GetTraceStateFromContext` | `tracing` equivalents |

Migration rule:
- Preserve explicit aliases. Example:
  `libOpentelemetry "github.com/LerianStudio/lib-commons/v5/commons/opentelemetry"`
  becomes `libOpentelemetry "github.com/LerianStudio/lib-observability/tracing"`
  and call sites remain `libOpentelemetry.X`.
- If the old import was unaliased, replace the import path and rewrite
  `opentelemetry.X` call sites to `tracing.X`.
- Qualifier rewrites must apply only to Go selector expressions in the file
  body. Never rewrite module import paths such as `go.opentelemetry.io/...`,
  comments, or string literals to `go.tracing.io/...`.
- Helper-only files may migrate independently. These include calls such as
  `HandleSpanError`, `HandleSpanBusinessErrorEvent`,
  `SetSpanAttributesFromValue`, `InjectHTTPContext`, and queue/header
  propagation helpers. They operate on OpenTelemetry public interfaces and do
  not require the application's bootstrap `Telemetry` type to move.
- Bootstrap files that use `Telemetry`, `TelemetryConfig`, `NewTelemetry`,
  `ApplyGlobals`, `Tracer`, `Meter`, or `ShutdownTelemetry*` must be
  migrated only if the resulting `*tracing.Telemetry` does not cross a
  remaining lib-commons API boundary. Typical blockers:
  `commons/server.NewServerManager(..., *commons/opentelemetry.Telemetry, ...)`
  and `commons/net/http.NewTelemetryMiddleware(*commons/opentelemetry.Telemetry)`
  when that middleware call is not also migrated to `lib-observability/middleware`.
- If bootstrap migration would create a type mismatch, leave that file on
  `commons/opentelemetry`, migrate the helper-only files, and report the
  remaining bootstrap import as intentionally blocked.
- If any referenced symbol is absent from `lib-observability/tracing`, do not
  migrate that file. Report the missing symbol and leave the lib-commons import
  unchanged.
- If migration produces a type mismatch against a remaining lib-commons API
  boundary, revert that file's bootstrap/type-bearing migration and report the
  boundary as manual.

### Deprecated symbols inside commons/net/http

`commons/net/http` is a mixed package. Most helpers stay in lib-commons. Only
the known observability middleware/span symbols listed below may migrate, and
only when present in `lib-observability/middleware`. Source-side
`Deprecated:` notices are not required in removed-api mode.

| Deprecated symbol | lib-observability replacement |
|---|---|
| `RequestInfo` | `middleware.RequestInfo` |
| `ResponseMetricsWrapper` | `middleware.ResponseMetricsWrapper` |
| `NewRequestInfo` | `middleware.NewRequestInfo` |
| `LogMiddlewareOption` | `middleware.LogMiddlewareOption` |
| `WithCustomLogger` | `middleware.WithCustomLogger` |
| `WithObfuscationDisabled` | `middleware.WithObfuscationDisabled` |
| `WithHTTPLogging` | `middleware.WithHTTPLogging` |
| `WithGrpcLogging` | `middleware.WithGrpcLogging` |
| `RequestInfo.CLFString` | `middleware.RequestInfo.CLFString` |
| `RequestInfo.String` | `middleware.RequestInfo.String` |
| `RequestInfo.FinishRequestInfo` | `middleware.RequestInfo.FinishRequestInfo` |
| `DefaultMetricsCollectionInterval` | `middleware.DefaultMetricsCollectionInterval` |
| `TelemetryMiddleware` | `middleware.TelemetryMiddleware` |
| `NewTelemetryMiddleware` | `middleware.NewTelemetryMiddleware` |
| `TelemetryMiddleware.WithTelemetry` | `middleware.TelemetryMiddleware.WithTelemetry` |
| `TelemetryMiddleware.EndTracingSpans` | `middleware.TelemetryMiddleware.EndTracingSpans` |
| `TelemetryMiddleware.WithTelemetryInterceptor` | `middleware.TelemetryMiddleware.WithTelemetryInterceptor` |
| `TelemetryMiddleware.EndTracingSpansInterceptor` | `middleware.TelemetryMiddleware.EndTracingSpansInterceptor` |
| `StopMetricsCollector` | `middleware.StopMetricsCollector` |
| `SetHandlerSpanAttributes` | `middleware.SetHandlerSpanAttributes` |
| `SetTenantSpanAttribute` | `middleware.SetTenantSpanAttribute` |
| `SetExceptionSpanAttributes` | `middleware.SetExceptionSpanAttributes` |
| `SetDisputeSpanAttributes` | `middleware.SetDisputeSpanAttributes` |

Migration rule:
- If a file imports `lib-commons/v5/commons/net/http` and uses only deprecated
  observability middleware symbols from that import, replace the import path with
  `github.com/LerianStudio/lib-observability/middleware` and preserve/adjust the
  alias so call sites compile.
- If a file imports `lib-commons/v5/commons/net/http` and also uses non-observability
  HTTP helpers (`Respond`, pagination, validation, CORS,
  rate-limit/idempotency subpackages, etc.), keep the lib-commons import and add
  a second import for `github.com/LerianStudio/lib-observability/middleware`.
  Rewrite only deprecated observability middleware symbol qualifiers to the middleware alias.
- Do not migrate response helpers, validation helpers, pagination helpers,
  CORS/basic-auth helpers, ownership helpers, `AuthGuard`,
  `ClientIPMiddleware`, `FaultInjection`, `WithCORSLogger`, or any
  `commons/net/http` subpackage.

### Deprecated symbols inside commons root

The root commons package is also mixed. App configuration, environment, OS,
security, and general helpers stay in lib-commons. Only the known observability
context helpers listed below may migrate, and only when present in root
lib-observability. Source-side `Deprecated:` notices are not required in
removed-api mode.

| Deprecated symbol | lib-observability replacement |
|---|---|
| `NewLoggerFromContext` | `observability.NewLoggerFromContext` |
| `ContextWithLogger` | `observability.ContextWithLogger` |
| `ContextWithTracer` | `observability.ContextWithTracer` |
| `ContextWithMetricFactory` | `observability.ContextWithMetricFactory` |
| `ContextWithHeaderID` | `observability.ContextWithHeaderID` |
| `TrackingComponents` | `observability.TrackingComponents` |
| `NewTrackingFromContext` | `observability.NewTrackingFromContext` |
| `ContextWithSpanAttributes` | `observability.ContextWithSpanAttributes` |
| `AttributesFromContext` | `observability.AttributesFromContext` |
| `ReplaceAttributes` | `observability.ReplaceAttributes` |

Migration rule:
- If a file imports root `lib-commons/v5/commons` and uses only deprecated
  observability context helpers from that import, replace the import path with
  `github.com/LerianStudio/lib-observability` and preserve or adjust the alias.
  If the old import had an explicit alias, preserve that alias exactly. Example:
  `libObservability "github.com/LerianStudio/lib-commons/v5/commons"` becomes
  `libObservability "github.com/LerianStudio/lib-observability"`; do not drop
  the alias while leaving `libObservability.X` call sites behind.
- If a file imports root commons and also uses non-observability helpers
  (`AppConfig`, env helpers, security rules, pointer/string/time helpers, etc.),
  keep the lib-commons import and add a second import for
  `github.com/LerianStudio/lib-observability`. Rewrite only deprecated
  observability context helper qualifiers to the lib-observability alias.

### Do NOT migrate (not deprecated — stays lib-commons)

| Import | Reason |
|---|---|
| `lib-commons/v5/commons/net/http` non-observability helpers | HTTP helpers — NOT deprecated. Only logging and telemetry middleware symbols migrate. |
| `lib-commons/v5/commons/streaming` | Kafka/CloudEvents producer — NOT deprecated; uses lib-observability internally |
| `lib-commons/v5/commons/postgres`, `mongo`, `redis`, `rabbitmq` | Infrastructure clients — NOT deprecated |
| `lib-commons/v5/commons/multitenancy` | Multi-tenant dispatch — NOT deprecated |
| `lib-commons/v5/commons/systemplane` | Removed from lib-commons v5.2.0 — migrate direct imports to `lib-systemplane` |
| `lib-commons/v5/commons` non-observability helpers | Root package helpers such as AppConfig, environment, OS, security, pointers, string/time utilities — NOT deprecated. Only observability context helpers migrate. |

## Step 1: Validate Input

<verify_before_proceed>
- repo_path exists and contains a go.mod file
- go.mod declares module path (to identify lib-commons import prefix)
- effective lib-observability version satisfies the per-migration target gates below
- optional lib_commons_pre_removal_ref is resolved when provided
</verify_before_proceed>

```text
1. Verify repo_path/go.mod exists
2. Extract module name from go.mod
3. Confirm lib-commons is or was a dependency: grep "lib-commons" go.mod
   if not found → report "No lib-commons dependency found. Nothing to migrate." and exit PASS

4. Quick check — lib-observability already present?
   grep "lib-observability" go.mod
   if found → note for UX messaging; do NOT exit here.
   lib-observability presence alone does not mean migration is complete —
   deprecated lib-commons imports may still exist. Continue to Step 2 discovery.
   If Step 2 finds zero deprecated imports, report "Migration already complete.
   No deprecated lib-commons observability imports found." and exit PASS.
5. Source evidence — resolve pre-removal lib-commons ref:

   If the user provides `lib_commons_pre_removal_ref` (commit, tag, branch, or
   `<removal_commit>^`), inspect lib-commons at that ref for source-side
   `Deprecated:` notices.

   If the user does not provide a ref and the effective lib-commons dependency
   is missing the deprecated observability source files, default to:
     `fe1db9e60ac9e959de4288208b6cf65f7bbfe439^`

   This is the preferred source map after the removal PR lands because the
   effective app dependency may already be missing the source files.

   Example:
     LIB_COMMONS_PRE_REMOVAL_REF="${lib_commons_pre_removal_ref:-fe1db9e60ac9e959de4288208b6cf65f7bbfe439^}"
     LIB_COMMONS_PRE_REMOVAL_DIR=$(mktemp -d)
     git clone --depth 1 https://github.com/LerianStudio/lib-commons "$LIB_COMMONS_PRE_REMOVAL_DIR"
     git -C "$LIB_COMMONS_PRE_REMOVAL_DIR" fetch origin "$LIB_COMMONS_PRE_REMOVAL_REF"
     git -C "$LIB_COMMONS_PRE_REMOVAL_DIR" checkout FETCH_HEAD

   Use this ref only to decide scope/evidence. Do not add it to the target repo.
   If the default removal commit is not reachable yet from the remote used by
   the agent, fall back to removed-api mode and report that the pre-removal
   source-evidence ref could not be fetched.

6. HARD GATE — Verify effective lib-observability target APIs:

   Resolve the effective lib-commons module directory for the module major used
   by the repo (honours replace directives, workspaces, and custom GOMODCACHE):

   LIB_COMMONS_MODULE=$(go list -m -f '{{.Path}}' all | grep -E '^github.com/LerianStudio/lib-commons(/v[0-9]+)?$' | tail -1)
   LIB_COMMONS_DIR=$(go list -m -f '{{.Dir}}' "$LIB_COMMONS_MODULE" 2>/dev/null || true)
   LIB_OBSERVABILITY_DIR=$(go list -m -f '{{.Dir}}' github.com/LerianStudio/lib-observability 2>/dev/null || true)
   if [ -z "$LIB_OBSERVABILITY_DIR" ]; then
     GONOSUMDB="github.com/LerianStudio/lib-observability" \
     GOPRIVATE="github.com/LerianStudio/lib-observability" \
       go get github.com/LerianStudio/lib-observability@v1.0.0
     LIB_OBSERVABILITY_DIR=$(go list -m -f '{{.Dir}}' github.com/LerianStudio/lib-observability)
   fi
   DOC_PATH="${LIB_COMMONS_DIR}/commons/log/doc.go"
   CONTEXT_PATH="${LIB_COMMONS_DIR}/commons/context.go"
   LOGGING_PATH="${LIB_COMMONS_DIR}/commons/net/http/withLogging_middleware.go"
   TELEMETRY_PATH="${LIB_COMMONS_DIR}/commons/net/http/withTelemetry.go"
   SPAN_HELPERS_PATH="${LIB_COMMONS_DIR}/commons/net/http/context_span.go"
   OBS_ROOT_PATH="${LIB_OBSERVABILITY_DIR}/observability.go"
   OBS_MIDDLEWARE_PATH="${LIB_OBSERVABILITY_DIR}/middleware/logging.go"
   OBS_TELEMETRY_PATH="${LIB_OBSERVABILITY_DIR}/middleware/telemetry.go"
   OBS_SPAN_HELPERS_PATH="${LIB_OBSERVABILITY_DIR}/middleware/context_span.go"
   OTEL_DOC_PATH="${LIB_COMMONS_DIR}/commons/opentelemetry/doc.go"
   OBS_TRACING_PATH="${LIB_OBSERVABILITY_DIR}/tracing/otel.go"

   SOURCE_LOG_DOC_PATH="${DOC_PATH}"
   SOURCE_CONTEXT_PATH="${CONTEXT_PATH}"
   SOURCE_LOGGING_PATH="${LOGGING_PATH}"
   SOURCE_TELEMETRY_PATH="${TELEMETRY_PATH}"
   SOURCE_SPAN_HELPERS_PATH="${SPAN_HELPERS_PATH}"
   SOURCE_OTEL_DOC_PATH="${OTEL_DOC_PATH}"
   if [ -n "${LIB_COMMONS_PRE_REMOVAL_DIR}" ]; then
     SOURCE_LOG_DOC_PATH="${LIB_COMMONS_PRE_REMOVAL_DIR}/commons/log/doc.go"
     SOURCE_CONTEXT_PATH="${LIB_COMMONS_PRE_REMOVAL_DIR}/commons/context.go"
     SOURCE_LOGGING_PATH="${LIB_COMMONS_PRE_REMOVAL_DIR}/commons/net/http/withLogging_middleware.go"
     SOURCE_TELEMETRY_PATH="${LIB_COMMONS_PRE_REMOVAL_DIR}/commons/net/http/withTelemetry.go"
     SOURCE_SPAN_HELPERS_PATH="${LIB_COMMONS_PRE_REMOVAL_DIR}/commons/net/http/context_span.go"
     SOURCE_OTEL_DOC_PATH="${LIB_COMMONS_PRE_REMOVAL_DIR}/commons/opentelemetry/doc.go"
   fi

   Determine source mode:
     if [ -n "$LIB_COMMONS_PRE_REMOVAL_DIR" ]; then
       echo "NOTE: using pre-removal reference mode. Source migration evidence
       comes from the lib-commons ref immediately before observability removals."
     fi
     if [ ! -f "$DOC_PATH" ]; then
       echo "NOTE: unable to locate lib-commons log docs. Treating source as
       removed-api/break-fix mode for known observability targets; migration is
       gated by lib-observability target APIs and source usage in the app."
     fi

   Check if doc.go contains "Deprecated" when present. Prefer
   "$SOURCE_LOG_DOC_PATH":
     grep -c "Deprecated" "$SOURCE_LOG_DOC_PATH"

   If result is 0 → continue. This means old source mode, missing pre-removal
   evidence, or removed-api mode; source deprecation is not a hard gate. Migrate
   only known observability targets whose lib-observability API exists, then
   rely on build/test validation to catch remaining type-boundary blockers.

   Check if HTTP/gRPC logging middleware deprecations are available in the
   preferred source evidence ref when present:
     if [ -f "$SOURCE_LOGGING_PATH" ]; then grep -c "Deprecated" "$SOURCE_LOGGING_PATH"; fi

   Check if the target lib-observability middleware API exists:
     if [ -f "$OBS_MIDDLEWARE_PATH" ]; then grep -E "func WithHTTPLogging|func WithGrpcLogging|type RequestInfo|type LogMiddlewareOption" "$OBS_MIDDLEWARE_PATH"; fi

   Check if HTTP/gRPC telemetry middleware deprecations are available in the
   preferred source evidence ref when present:
     if [ -f "$SOURCE_TELEMETRY_PATH" ]; then grep -c "Deprecated" "$SOURCE_TELEMETRY_PATH"; fi

   Check if the target lib-observability telemetry middleware API exists:
     if [ -f "$OBS_TELEMETRY_PATH" ]; then grep -E "func NewTelemetryMiddleware|func \\(tm \\*TelemetryMiddleware\\) WithTelemetry|func \\(tm \\*TelemetryMiddleware\\) WithTelemetryInterceptor|type TelemetryMiddleware" "$OBS_TELEMETRY_PATH"; fi

   Check if root commons observability context helper deprecations are available
   in the preferred source evidence ref when present:
     if [ -f "$SOURCE_CONTEXT_PATH" ]; then grep -E "Deprecated: use (NewTrackingFromContext|ContextWithLogger|ContextWithTracer|ContextWithMetricFactory|ContextWithHeaderID|ContextWithSpanAttributes|AttributesFromContext|ReplaceAttributes)" "$SOURCE_CONTEXT_PATH"; fi

   Check if the target root lib-observability context helper API exists:
     if [ -f "$OBS_ROOT_PATH" ]; then grep -E "func NewTrackingFromContext|func ContextWithLogger|func ContextWithTracer|func ContextWithMetricFactory|func ContextWithHeaderID|func ContextWithSpanAttributes|func AttributesFromContext|func ReplaceAttributes" "$OBS_ROOT_PATH"; fi

   Check if root commons/opentelemetry package deprecation is available in the
   preferred source evidence ref when present:
     if [ -f "$SOURCE_OTEL_DOC_PATH" ]; then grep -c "Deprecated" "$SOURCE_OTEL_DOC_PATH"; fi

   Check if the target lib-observability tracing API exists:
     if [ -f "$OBS_TRACING_PATH" ]; then grep -E "type TelemetryConfig|type Telemetry|func NewTelemetry|func HandleSpanError|func BuildAttributesFromValue|func InjectTraceContext|func GetTraceIDFromContext" "$OBS_TRACING_PATH"; fi

   Check if HTTP span helper deprecations are available in the preferred source
   evidence ref when present:
     if [ -f "$SOURCE_SPAN_HELPERS_PATH" ]; then grep -c "Deprecated" "$SOURCE_SPAN_HELPERS_PATH"; fi

   Check if the target lib-observability span helper API exists:
     if [ -f "$OBS_SPAN_HELPERS_PATH" ]; then grep -E "func SetHandlerSpanAttributes|func SetTenantSpanAttribute|func SetExceptionSpanAttributes|func SetDisputeSpanAttributes" "$OBS_SPAN_HELPERS_PATH"; fi

   If a lib-observability target check fails or the target file is absent → do
   not run that migration family. Continue with other migrations and report:
     "NOTE: lib-observability does not expose <family> target API.
      Skipping <family> migration. If the matching lib-commons source is already
      removed and the app cannot compile, this remains a manual migration
      blocker."

   If target checks pass → matching known imports/symbols may be migrated when
   discovered, regardless of whether the source package still exists.

7. Companion stable dependencies — when present in go.mod, bump known modules
   that already adopted the removed lib-commons observability split:

     GONOSUMDB="github.com/LerianStudio/*" \
     GOPRIVATE="github.com/LerianStudio/*" \
       go get github.com/LerianStudio/lib-auth/v2@v2.8.0 \
              github.com/LerianStudio/lib-license-go/v2@v2.3.5 \
              github.com/LerianStudio/lib-streaming@v1.3.1 \
              github.com/LerianStudio/lib-systemplane@v1.0.0

   Do this before final tidy/build validation. These bumps prevent false manual
   blockers where the application source migrated correctly but older stable
   transitive modules still import removed lib-commons observability packages.
   Do not invent versions for other major lines. If the repo depends on
   lib-auth/v3 and that module still imports removed lib-commons packages,
   report it as a manual dependency blocker. For matcher specifically, ask the
   executor whether they want to replace the lib-auth/v3 pseudo-version with
   github.com/LerianStudio/lib-auth/v2@v2.8.0; do not apply that major-path
   change without explicit confirmation.
```

---

## Step 2: Discover Deprecated Observability Imports

Scan all `.go` files in the repository for deprecated observability imports and
deprecated `commons/net/http` observability middleware symbol usage.
Also scan root `commons` observability context helper usage.

```text
Search patterns (grep -r across *.go files):

MIGRATE targets (match any lib-commons major suffix already used by the repo,
for example /v2, /v4, /v5):
  lib-commons[/vN]/commons/log"
  lib-commons[/vN]/commons/zap"
  lib-commons[/vN]/commons/runtime"
  lib-commons[/vN]/commons/assert"
  lib-commons[/vN]/commons/opentelemetry"
  lib-commons[/vN]/commons/opentelemetry/metrics"
  lib-commons[/vN]/commons/opentelemetry/constants"
  lib-commons[/vN]/commons/opentelemetry/redaction"
  lib-commons[/vN]/commons/systemplane"
  lib-commons[/vN]/commons/systemplane/admin"

SYMBOL-LEVEL MIGRATE targets (only when used from lib-commons[/vN]/commons/net/http):
  RequestInfo
  ResponseMetricsWrapper
  NewRequestInfo
  LogMiddlewareOption
  WithCustomLogger
  WithObfuscationDisabled
  WithHTTPLogging
  WithGrpcLogging
  DefaultMetricsCollectionInterval
  TelemetryMiddleware
  NewTelemetryMiddleware
  WithTelemetry
  EndTracingSpans
  WithTelemetryInterceptor
  EndTracingSpansInterceptor
  StopMetricsCollector
  SetHandlerSpanAttributes
  SetTenantSpanAttribute
  SetExceptionSpanAttributes
  SetDisputeSpanAttributes

SYMBOL-LEVEL MIGRATE targets (only when used from root lib-commons[/vN]/commons):
  NewLoggerFromContext
  ContextWithLogger
  ContextWithTracer
  ContextWithMetricFactory
  ContextWithHeaderID
  TrackingComponents
  NewTrackingFromContext
  ContextWithSpanAttributes
  AttributesFromContext
  ReplaceAttributes

DO NOT MIGRATE targets (not deprecated — skip silently):
  lib-commons[/vN]/commons/net/http"        ← keep unless the file uses observability middleware symbols from it
  lib-commons[/vN]/commons/streaming"
  lib-commons[/vN]/commons/postgres"
  lib-commons[/vN]/commons/mongo"
  lib-commons[/vN]/commons/redis"
  lib-commons[/vN]/commons/rabbitmq"
  lib-commons[/vN]/commons/multitenancy"
  lib-commons[/vN]/commons"                 ← keep unless the file uses observability context helper symbols from it

For each found import, record:
  - file path
  - line number
  - import alias (if any)
  - full import path
  - for commons/net/http, which deprecated observability middleware symbols are used
  - for commons/opentelemetry, whether the import has an explicit alias
  - for commons/opentelemetry, whether the file is helper-only or bootstrap/type-bearing
  - for bootstrap/type-bearing commons/opentelemetry files, whether the telemetry value crosses a remaining lib-commons API boundary
  - for root commons, which deprecated observability context helper symbols are used
  - whether non-observability commons/net/http symbols are also used
  - whether non-observability root commons symbols are also used
```

**Output discovery report:**
```
## Discovery

### Imports to Migrate
| File | Line | Current Import | Target Import |
|------|------|---------------|---------------|
| cmd/main.go | 5 | lib-commons/v5/commons/log | lib-observability/log |
| cmd/main.go | 6 | lib-commons/v5/commons/net/http.WithHTTPLogging | lib-observability/middleware.WithHTTPLogging |
| ...

### Imports NOT Migrated (not deprecated — kept in lib-commons)
| File | Line | Import | Reason |
|------|------|--------|--------|
| ...

### Summary
- Total files to change: X
- Total imports to replace: Y
- Total imports left as-is: Z
```

---

## Step 3: Present Migration Plan and Confirm

<dispatch_required agent="ring:backend-engineer-golang">
Do not proceed with edits until user approves.
</dispatch_required>

Present the full plan using AskUserQuestion:
```
Options:
  1. Apply all migrations as planned
  2. Dry run — show diffs without writing
  3. Select specific packages only
```

If dry_run=true from input, skip this step and show diffs only.

---

## Step 4: Add lib-observability to go.mod

```bash
# lib-observability may not yet be indexed by the Go sum database.
# Always use GONOSUMDB + GOPRIVATE to avoid sum.golang.org 404 errors.
GONOSUMDB="github.com/LerianStudio/lib-observability" \
GOPRIVATE="github.com/LerianStudio/lib-observability" \
  go get github.com/LerianStudio/lib-observability@v1.0.0
# v1.0.0 is the stable target baseline for this migration.
```

Verify it appears in go.mod:
```bash
grep "lib-observability" go.mod
# Expected: github.com/LerianStudio/lib-observability v1.0.0
# Note: the entry may be marked "// indirect" at this stage — import paths have
# not been updated yet (that happens in Step 5). The "// indirect" marker is
# removed after Step 5 (import replacements) and Step 6 (go mod tidy).
```

---

## Step 5: Apply Import Replacements

<dispatch_required agent="ring:backend-engineer-golang">
For each file identified in Step 2:
1. Read the file
2. Replace the import path using the mapping table
3. Preserve any import aliases the file was using
4. No package qualifier changes needed for the same-name package replacements
   (log stays log, assert stays assert, metrics stays metrics, etc.)
5. For root commons/opentelemetry, migrate helper-only files first. Preserve
   explicit aliases. If the import was unaliased, rewrite `opentelemetry.`
   call sites to `tracing.`. For bootstrap/type-bearing files, migrate only
   after confirming the `Telemetry` value does not cross a remaining
   lib-commons API boundary; otherwise leave that file unchanged and report it.
6. For commons/net/http middleware symbols, rewrite only deprecated observability call sites
   to the lib-observability/middleware import alias. Preserve the lib-commons HTTP
   import when the file still uses non-observability HTTP helpers.
7. For root commons observability context helpers, rewrite only deprecated
   observability call sites to the lib-observability import alias. Preserve the
   lib-commons root import when the file still uses non-observability commons helpers.
8. For direct systemplane imports removed from lib-commons v5.2.0, move:
   - `github.com/LerianStudio/lib-commons/v5/commons/systemplane` →
     `github.com/LerianStudio/lib-systemplane`
   - `github.com/LerianStudio/lib-commons/v5/commons/systemplane/admin` →
     `github.com/LerianStudio/lib-systemplane/admin`
   Preserve import aliases and call sites.
9. Write the updated file
</dispatch_required>

For package-level `commons/log`, `commons/zap`, `commons/runtime`, and
`commons/assert`, prefer compile-safe migration over maximum replacement:
- migrate direct app/internal usage first;
- if build validation shows the migrated type is passed into a remaining
  lib-commons API boundary, revert that file or package-family migration;
- report the boundary with file, symbol, and callee;
- do not leave the repository in a broken state unless the source API has
  already been removed and no compile-safe fallback exists.

---

## Step 6: Run go mod tidy

```bash
GONOSUMDB="github.com/LerianStudio/lib-observability" \
GOPRIVATE="github.com/LerianStudio/lib-observability" \
  go mod tidy
```

Check that lib-commons is still present if the app uses non-deprecated packages:
```bash
grep "lib-commons" go.mod
# Should still be there unless the app used ONLY deprecated packages
```

---

## Step 7: Validate Build and Tests

```bash
go build ./...
go vet ./...
go test ./...
```

<block_condition>
- `go build ./...`, `go vet ./...`, or `go test ./...` exits non-zero
</block_condition>

If build fails:
1. Read each compilation error
2. Check for:
   - Transitive dependency failures from `$GOMODCACHE` importing removed
     `lib-commons/v5/commons/log`, `zap`, or
     `opentelemetry` packages. These are dependency blockers. Report the
     dependency module/version and do not modify application source to work
     around them.
   - Indirect API differences between shim and lib-observability (rare)
   - Missing symbols that the shim exposed but lib-observability doesn't (report as PARTIAL)
   - Type mismatches at remaining lib-commons boundaries, especially
     `commons/log.Logger` passed into lib-commons infrastructure config structs,
     CORS helpers, circuitbreaker, streaming builders, auth middleware, or test
     stubs (revert affected file/family and report as MANUAL unless the local
     change can be fixed without changing non-observability lib-commons usage)
3. Fix compilation errors caused by import aliases or safe observability-only rewrites
4. Re-run until `go build ./...` passes or only manual blockers remain. If
   manual blockers remain in deprecated-shim mode, leave those files unmigrated
   so the final diff compiles; if manual blockers remain in removed-api mode,
   report that the repo needs manual work before it can consume the removal
   release.

---

## Step 8: Verify No Remaining Deprecated Imports

```bash
grep -rE 'lib-commons(/v[0-9]+)?/commons/log"' . --include="*.go" | wc -l
grep -rE 'lib-commons(/v[0-9]+)?/commons/zap"' . --include="*.go" | wc -l
grep -rE 'lib-commons(/v[0-9]+)?/commons/runtime"' . --include="*.go" | wc -l
grep -rE 'lib-commons(/v[0-9]+)?/commons/assert"' . --include="*.go" | wc -l
grep -rE 'lib-commons(/v[0-9]+)?/commons/opentelemetry/metrics"' . --include="*.go" | wc -l
grep -rE 'lib-commons(/v[0-9]+)?/commons/opentelemetry/constants"' . --include="*.go" | wc -l
grep -rE 'lib-commons(/v[0-9]+)?/commons/opentelemetry/redaction"' . --include="*.go" | wc -l
```

Each should print `0`.

For root `commons/opentelemetry`, helper-only imports should be gone. Remaining
imports are acceptable only when they are bootstrap/type-bearing files blocked
by a remaining lib-commons API boundary. Report each remaining file and why it
was kept:

```bash
grep -rE 'lib-commons(/v[0-9]+)?/commons/opentelemetry"' . --include="*.go"
```

For `commons/net/http`, do not require the import count to be zero. Instead,
verify no deprecated observability middleware symbols remain qualified by the lib-commons HTTP
alias:

```bash
# Replace libHTTP with the alias discovered in each file, commonly http or libHTTP.
grep -rE 'libHTTP\\.(RequestInfo|ResponseMetricsWrapper|NewRequestInfo|LogMiddlewareOption|WithCustomLogger|WithObfuscationDisabled|WithHTTPLogging|WithGrpcLogging|DefaultMetricsCollectionInterval|TelemetryMiddleware|NewTelemetryMiddleware|WithTelemetry|EndTracingSpans|WithTelemetryInterceptor|EndTracingSpansInterceptor|StopMetricsCollector)' . --include="*.go" | wc -l
grep -rE 'http\\.(RequestInfo|ResponseMetricsWrapper|NewRequestInfo|LogMiddlewareOption|WithCustomLogger|WithObfuscationDisabled|WithHTTPLogging|WithGrpcLogging|DefaultMetricsCollectionInterval|TelemetryMiddleware|NewTelemetryMiddleware|WithTelemetry|EndTracingSpans|WithTelemetryInterceptor|EndTracingSpansInterceptor|StopMetricsCollector)' . --include="*.go" | wc -l
```

Both checks should print `0` for aliases actually used by the target repo.

For root `commons`, do not require the import count to be zero. Instead, verify
no deprecated observability context helper symbols remain qualified by the
lib-commons alias:

```bash
# Replace commons/libCommons with aliases discovered in each file.
grep -rE 'commons\\.(NewLoggerFromContext|ContextWithLogger|ContextWithTracer|ContextWithMetricFactory|ContextWithHeaderID|TrackingComponents|NewTrackingFromContext|ContextWithSpanAttributes|AttributesFromContext|ReplaceAttributes)' . --include="*.go" | wc -l
grep -rE 'libCommons\\.(NewLoggerFromContext|ContextWithLogger|ContextWithTracer|ContextWithMetricFactory|ContextWithHeaderID|TrackingComponents|NewTrackingFromContext|ContextWithSpanAttributes|AttributesFromContext|ReplaceAttributes)' . --include="*.go" | wc -l
```

---

## Step 9: Produce Final Report

```markdown
## Changes Applied

| File | Imports Replaced | Before | After |
|------|-----------------|--------|-------|
| cmd/main.go | 2 | commons/log, commons/runtime | log, runtime |
| ...

## Validation

| Check | Result |
|-------|--------|
| go build ./... | ✅ PASS |
| go vet ./... | ✅ PASS |
| go test ./... | ✅ PASS |
| No remaining deprecated lib-commons observability imports | ✅ PASS |

## Summary

- Files changed: X
- Imports replaced: Y
- Build status: PASS
- Result: PASS
```

---

## Severity Calibration

| Severity | Criteria |
|----------|----------|
| CRITICAL | Build fails after migration and cannot be fixed by import path changes alone |
| HIGH | Symbol exists in lib-commons shim but is missing from lib-observability |
| MEDIUM | Import alias collision requiring manual rename |
| LOW | Unused import warning after migration |

---

## Pressure Resistance

| Pushback | Response |
|---|---|
| "Only one or two deprecated imports, not worth the effort" | Deprecation warnings accumulate. Migrate now to keep the codebase clean. |
| "lib-commons shims still work, why change?" | They are deprecated/being removed. Earlier migration = smaller blast radius. |
| "commons/opentelemetry is similar, migrate it too" | Migrate it only when `lib-observability/tracing` exposes the required API. Preserve explicit aliases; rewrite unaliased `opentelemetry.` qualifiers to `tracing.`; leave bootstrap/type-boundary blockers reported. |
| "What about commons/net/http telemetry middleware?" | If the target exists in lib-observability/middleware and the app uses the known observability symbols, it migrates. Source deprecation is evidence, not a blocker. |
| "Streaming imports will break" | commons/streaming is NOT deprecated. The skill explicitly skips it. |
| "The import paths are simple, just replace everything" | Wrong scope. Only known observability imports/symbols move. Infrastructure clients, streaming, and general commons helpers stay. |

---

## Anti-Rationalization Table

| Rationalization | Why Wrong | Action |
|---|---|---|
| "I'll also replace commons/opentelemetry while I'm at it" | Root `commons/opentelemetry` is API-aware and can cross type boundaries. | Verify `lib-observability/tracing` target symbols first, migrate helper-only files, and leave bootstrap/type-boundary blockers reported. |
| "The tests pass even with mixed imports" | Deprecated/removed observability imports create future breakage risk | Replace all known observability packages and HTTP/gRPC middleware symbols whose target APIs exist |
| "I'll do it later when lib-commons removes the shims" | Migration is harder with more files in flight | Migrate now, reduce future blast radius |
| "go get failed — the module must not be public" | The sum DB may not have indexed it yet | Use GONOSUMDB + GOPRIVATE as shown in Step 4 |
| "The import path is the only thing changing, types are compatible" | Type compatibility depends on each boundary. Some bootstrap paths still cross lib-commons APIs. | Run build validation. Fix safe import/qualifier issues; report bootstrap/type-boundary mismatches as manual blockers. |
| "I can fix every type error ad hoc" | Ad-hoc fixes can migrate non-observability boundaries accidentally. | Keep scope strict. Only fix errors caused by known observability target mappings; report the rest. |
