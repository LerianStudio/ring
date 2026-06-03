# Ring-Dev-Team Changelog

## Unreleased

### Changed — Expand observability migration to context and HTTP/gRPC middleware

- `ring:migrate-observability` now treats deprecated `commons/net/http` HTTP/gRPC logging and telemetry middleware symbols as symbol-level migration targets to `lib-observability/middleware`, while keeping non-observability HTTP helpers in lib-commons.
- `ring:migrate-observability` now also migrates deprecated root `commons` observability context helpers to root `lib-observability`.
- `ring:migrate-observability` now migrates deprecated root `commons/opentelemetry` helper-only usage to `lib-observability/tracing`, preserving explicit aliases and leaving bootstrap/type-bearing files in lib-commons when their `Telemetry` value still crosses a lib-commons API boundary.
- Added dual-mode targeting: deprecated-shim mode still uses lib-commons `// Deprecated:` notices as evidence, while removed-api/break-fix mode migrates known observability imports/symbols by static source analysis when lib-commons has already removed the source APIs. Hard gates now depend on lib-observability target APIs, not source-side deprecation notices.
- Added pre-removal reference mode so the skill can use the lib-commons ref immediately before the removal commit as source evidence, then fall through to static break-fix migration when the target app has already bumped to the removal commit.
- Pinned stable migration baselines to lib-commons `v5.2.0` and lib-observability `v1.0.0`.
- Added stable companion dependency guidance for lib-auth `v2.8.0` and lib-license-go `v2.3.5`, avoiding false blockers from old transitive modules after lib-commons removes observability shims.
- Added stable companion guidance for lib-streaming `v1.3.1` and lib-systemplane `v1.0.0`, including direct systemplane import moves from lib-commons to lib-systemplane after lib-commons `v5.2.0`.
- Added matcher-specific handling for the `lib-auth/v3` pseudo-version drift: report it as a blocker and ask before moving to stable `lib-auth/v2@v2.8.0`.
- Tightened root commons alias handling so existing aliases such as `libObservability` are preserved when moving deprecated context helpers to root lib-observability.
- Added explicit dependency-blocker handling for transitive modules that still import removed lib-commons observability packages after the target application bumps to a removal release.
- Tightened root opentelemetry qualifier migration so agents rewrite selector expressions only, never `go.opentelemetry.io` module import paths.

## [1.56.1] — 2026-04-17

### Fixed — Restore Gate 0.5D (Migration Safety) as standalone conditional gate

- **Gate 0.5D restored** at `ring:dev-cycle` Step 12.0.5b as a post-cycle conditional gate, parallel to Gate 0.5G (multi-tenant dual-mode verification). Runs once per cycle when SQL migration files are present in the diff against `origin/main`; skipped otherwise. Fixes an orphan from v1.56.0 where the Prancy Bentley refactor merged 3 general delivery-verification checks into `ring:dev-implementation` Step 7 but left SQL migration safety without a running implementation, even though `docs/standards/golang/migration-safety.md` continued to reference it.
- **Decision model**: BLOCKING findings HARD BLOCK Final Commit; ACKNOWLEDGE findings require explicit user confirmation phrase ("I acknowledge this breaking change and have verified the expand phase deployment"); WARN findings log and continue.
- **State schema**: `state.gate_progress.migration_safety_verification` added (additive; no breaking change).
- **Docs sync**: Updated `docs/standards/golang/migration-safety.md` § Verification Commands and `skills/shared-patterns/migration-safety-checks.md` to point at the new home (dev-cycle Step 12.0.5b) instead of the deprecated `ring:dev-delivery-verification` skill.

## [1.56.0] — 2026-04-17

### Changed — "Prancy Bentley" dev-cycle speedup

Reclassified gate execution cadence to eliminate redundant per-subtask operations while preserving every verification. Target outcome: ~40–50% wall-clock reduction on typical cycles with identical quality output.

- **Cadence migration**: Gates 1 (DevOps), 2 (SRE/Accessibility), 4 (Fuzz/Visual), 5 (Property/E2E), 6 (Integration/Performance — write mode), 7 (Chaos/Review write), 8 (Review with 8 reviewers) now run at **task** cadence. Gates 0, 3, 9 (backend) / 0, 3, 8 (frontend) remain at **subtask** cadence. All 8 reviewers still run; all quality thresholds preserved.
- **Standards pre-cache**: Introduced cycle-level `state.cached_standards` populated at Step 1.5. Sub-skills now read from cache instead of WebFetching per dispatch (~15–25 fetches → ~5).
- **Gate 0.5 merged into Gate 0**: Delivery verification now runs inline as `ring:dev-implementation` Step 7 ("Delivery Verification Exit Check"). `ring:dev-delivery-verification` preserved as deprecated reference.
- **dev-report aggregation**: Single cycle-end dispatch reads `state.tasks[*].accumulated_metrics` instead of N per-task dispatches.
- **Refactor clustering**: `ring:dev-refactor` and `ring:dev-refactor-frontend` now cluster findings by `(file, pattern_category)`. Every finding preserved via `findings:` array for 1:1 traceability; task count drops ~5x for typical refactors.
- **Read-after-Write verification removed**: `Write` already errors on failure; redundant state reads eliminated.
- **Per-subtask visual reports**: Opt-in only via `state.visual_report_granularity == "subtask"` (default: task-level).

### Added
- `dev-team/skills/shared-patterns/standards-cache-protocol.md` — cache-first WebFetch protocol
- `dev-team/skills/shared-patterns/gate-cadence-classification.md` — subtask/task/cycle cadence taxonomy
- State schema v1.1.0 (additive): `cached_standards`, `visual_report_granularity`, per-subtask `gate_progress`, task-level `accumulated_metrics`

### Preserved (no quality regression)
- All 8 reviewers run on every task
- 85% unit test coverage threshold
- WCAG 2.1 AA accessibility checks
- Core Web Vitals + Lighthouse score thresholds
- TDD RED→GREEN enforcement
- Property/fuzz/chaos testing invariants
