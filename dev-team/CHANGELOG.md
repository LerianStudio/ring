# Ring-Dev-Team Changelog

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
