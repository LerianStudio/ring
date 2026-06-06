# Using Production Readiness Audit

**Skill:** `ring:production-readiness-audit` · **Implementation:** [SKILL.md](SKILL.md)

## Purpose

Evaluate codebase production readiness before deployment, during security/quality reviews, or when assessing technical debt. The audit covers **43 base dimensions + 1 conditional (multi-tenant) = up to 44 dimensions** across 5 categories (Structure, Security, Operations, Quality, Infrastructure).

## Invocation

- **Skill tool:** `Skill tool: "ring:production-readiness-audit"`
- **Command (if available):** `/ring:production-readiness-audit` or `/ring:production-readiness-audit [options]`

## Batch behavior

- Runs **10 explorer agents per batch**; results are **appended incrementally** to a single report file.
- Report path: `docs/audits/production-readiness-{YYYY-MM-DD}-{hh:mm}.md`
- Prevents context bloat while keeping full coverage.

## Output format

- **43 base dimensions + 1 conditional (multi-tenant) = up to 44 dimensions** scored report (**0–430 base, max 440 with multi-tenant**) with severity ratings (CRITICAL/HIGH/MEDIUM/LOW).
- Categories: Code Structure & Patterns, Security & Access Control, Operational Readiness, Quality & Maintainability, Infrastructure & Hardening.

For full protocol, dimensions, and execution steps, see [SKILL.md](SKILL.md).
