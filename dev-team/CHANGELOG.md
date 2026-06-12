# Ring-Dev-Team Changelog

## Unreleased

### Added — ⛔ Map body hard gate in `lerian_map` source mode (`ring:running-dev-cycle`)

- A Map task with only a title is now NOT executable: the task's Map `body` (the dispatch-ready requirement block) is MANDATORY before execution — the body IS the implementation contract. New ⛔ HARD BLOCK at every Gate 0 dispatch (`gates/gate-0-implementation.md` Step 2.1.5 — Map Body Hard Gate): the gate FAILS ONLY when the local requirement block is empty, title-only, or below the Step 11.5.5 sufficiency bar. Board lag is NOT a failure — a sufficient block with an unconfirmed body push gets ONE best-effort confirmation/retry, then the cycle PROCEEDS with a warning (never blocks on board lag). Options on failure: Elaborate now (ANALYSIS-mode planning agent; synchronous confirmed push when the Map is reachable, degraded fallback queues the push as `pending` and proceeds) / Skip this task (`status = "blocked"` + `blocked` sync hook + surfaced at the epic checkpoint) / Pause the cycle.
- Skipped tasks are excluded from Gate 8's cumulative-diff expectations and Gate 9's criteria aggregation, reported as `SKIPPED (no body)`; the epic passes Gate 9 with skipped tasks only via explicit user acknowledgment at the Step 11.1 approval, and the skipped card stays `blocked` on the board. State schema (additive): task `status` enum gains `"blocked"`, and `lerian_map_sync.matches[]` gains a `body_dispatch` record (mirrors the status `dispatch` lifecycle) so body pushes are trackable.
- Init step 3 body hygiene hardened from advisory to mandatory (current-milestone tasks without sufficient body CANNOT enter the cycle). The gate is a backstop for drift: boards edited mid-cycle, silent write-back failures, derived plans regenerated from a degraded board.

### Added — Lerian Map as an optional task source in `ring:running-dev-cycle`

- The Lerian Map board can now BE the task source for a dev cycle, not just a status mirror. Strictly **opt-in** — users who don't use the Map see zero behavior change (zero Gandalf calls).
- **Cycle-init question 3 changed** from the Yes/No "Lerian Map Sync?" question to a single-select **Task source** question with three mutually exclusive options, explicitly chosen by the user (no silent default): `Local plan` (`task_source = "plan_file"`, today's default behavior), `Local plan + Map sync` (`"plan_file_synced"`, exactly the existing sync behavior), and `Lerian Map (board is the source)` (`"lerian_map"`, new — source mode implies status sync). Resumed cycles without `task_source` infer it from `lerian_map_sync.enabled` and are never re-asked.
- **Board-as-source flow** (`SKILL.md` → `## Lerian Map as Task Source (optional)`): discovery handshake + milestone resolution, Gandalf fetch (milestone → features → tasks incl. `body`), body-hygiene validation for the current milestone (elaborate via ONE ANALYSIS-mode planning agent + push back, or abort), and materialization of a derived `docs/ring:running-dev-cycle/plan-from-map.md` in canonical ring:writing-plans format (`milestone` = Phase, `feature` = Epic, `task` = Task, `body` = dispatch-ready block; headings tagged `[map:#<id>]`). All existing gates run unchanged against the derived plan; the board stays the source of truth for WHAT and STATUS.
- **Rolling-wave write-back:** at each phase boundary (new Step 11.5.5b in `gates/phase-boundary.md`), elaborated task blocks are pushed to the matching Map task `body`; board/local mismatches are surfaced for user reconciliation — never silently created/deleted. Mid-cycle deviations from Gate 8/9 also write back, async fire-and-forget.
- **Degradation:** at INIT an unreachable Map means the source is unavailable → Retry / fall back to a local plan / Abort. DURING the cycle, outages degrade exactly like sync mode (pending + degraded, fire-and-forget reconciliation) and never block gates.
- **State schema** (additive): `task_source` enum + optional `lerian_map_source` object (milestone identity; per-unit ids stay in the `[map:#<id>]` tags + `lerian_map_sync.matches[]`, the existing sync-mode pattern). `ring:managing-dev-cycle` status now shows the task source and, for `lerian_map`, the board/milestone identity.

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

## [1.75.0] — 2026-06-11

### Added — Optional Lerian Map Sync in `ring:running-dev-cycle`

- The development cycle can now keep the Lerian Map kanban board in sync as epics/tasks move through the gates. Strictly **optional and default-off** — when not enabled, the cycle behaves exactly as before (zero Gandalf calls) and no mandatory gate is weakened.
- **Two new optional cycle-init questions**, asked after execution mode and before commit timing:
  - **Lerian Map Sync?** (`No` default / `Yes — sync`).
  - **Testing gate** (`Gate (wait)` / `Bypass`, only asked when sync = Yes) — controls whether the card waits at `Testing` for the user's explicit OK before the PR is opened. Does **not** override the critical Gate 9 acceptance, which always requires explicit user approval per epic.
- **Async fire-and-forget board updates via Gandalf.** All Map I/O goes through the `gandalf-webhook` (no direct Map API call, no new agent, no new credential). Each checkpoint POSTs one transition, gets a `task_id` back in <1s, and continues — Gandalf's background worker applies the update. The cycle never polls or blocks. Visible dispatch log line per push.
- **Repo-based board discovery.** Discovers the product by matching the normalized git remote against the Map's native `repositoryUrl` field; features matched by name (no slug); units matched via `[map:#<board_task_id>]` tags with title-matching fallback. Tags can be auto-injected into the plan after the first discovery (with user confirmation).
- **Status mapped to the real board columns:** `To do → In Progress (Gate 0) → Testing (gates done, awaiting user test) → To Review (PR open) → Done (push to ≥ develop)`, with `Blocked`/`On Hold`/`Canceled` off-path. **`Done` is gated on commit+push-to-develop (PR merge), not Gate 9.**
- **Deferred reconciliation** when Gandalf is unreachable: three states per transition (`pending → dispatched → synced`), best-effort non-blocking verification and pending-drain at the next checkpoint / `--resume` / end of cycle, idempotent absolute-column pushes, and an end-of-cycle pending report.
- **State schema:** additive optional `lerian_map_sync` object in `current-cycle.json` (`gates/state-schema.md`), absent when the feature is off.

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
