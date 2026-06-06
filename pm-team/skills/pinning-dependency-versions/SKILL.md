---
name: ring:pre-dev-dependency-map
description: |
  Gate 6: Technology choices document - explicit, versioned, validated technology
  selections with justifications. Large Track only. HARD BLOCK: Must load Ring Standards
  and PROJECT_RULES.md before proceeding.
---

# Dependency Map — Explicit Technology Choices

## When to use

- Data Model passed Gate 5 validation
- About to select specific technologies
- Large Track workflow (2+ day features)

## Skip when

- Small Track workflow → skip to Task Breakdown
- Technologies already locked → skip to Task Breakdown
- Data Model not validated → complete Gate 5 first

## Sequence

**Runs before:** ring:pre-dev-phases-and-epics
**Runs after:** ring:pre-dev-data-model


Every technology choice must be explicit, versioned, validated against Ring Standards, and justified. The Dependency Map answers WHAT specific products, versions, packages, and infrastructure will be used.

## Step 0: Standards Loading (HARD GATE)

### Step 0.1: Read Technology Decisions from TRD
Read `docs/pre-dev/{feature}/trd.md` — extract: `deployment.model`, `tech_stack.primary`, `project_technologies[]`.

If TRD metadata missing → STOP: "Go back to TRD (Gate 3) and complete Step 0.4."

### Step 0.2: Load Ring Standards via WebFetch

| Standard | URL |
|----------|-----|
| golang/index.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/index.md` |
| typescript.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/typescript.md` |
| frontend.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend.md` |
| devops.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/devops.md` |
| sre.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/sre.md` |

### Step 0.3: Generate PROJECT_RULES.md (OUTPUT)
Using TRD `project_technologies[]`, create `docs/PROJECT_RULES.md` with: deployment model, tech stack, per-category decisions (PRD requirement, technology, version, rationale, cloud service, on-premise alternative), version matrix, security/compliance notes.

## Mandatory Workflow

| Phase | Activities |
|-------|------------|
| **1. Evaluation** | Ring Standards loaded; map TRD components to tech candidates; validate against Ring Standards; map Data Model to storage; map API contracts to protocols; check team expertise; estimate costs |
| **2. Selection** | Per technology: check Ring Standards (mandatory/prohibited), specify exact version, list alternatives with trade-offs, verify compatibility, check security (CVEs), validate licenses, calculate costs |
| **3. Gate 6 Validation** | All dependencies explicit; no conflicts; no critical CVEs; licenses compliant; costs documented; all components mapped |

## Version Rules

1. **Explicit**: `@v1.27.0` not `@latest` or `^1.0.0`
2. **Justified ranges**: If using `>=`, document why
3. **Lock file referenced**: `go.mod`, `package-lock.json`, etc.
4. **Upgrade constraints**: Document why locked/capped
5. **Compatibility**: Document known conflicts

## Include in Dependency Map

- Exact package names with versions (`go.uber.org/zap@v1.27.0`)
- Tech stack with constraints (`Go 1.24+, PostgreSQL 16`)
- Infrastructure specs (`Valkey 8, MinIO`)
- External SDKs, dev tools, security deps, monitoring tools
- Compatibility matrices
- License summary
- Cost analysis

## Never Include

- Implementation code or how to use dependencies
- Task breakdowns or setup instructions
- Architectural patterns (→ TRD)
- Business requirements (→ PRD)

## Output Format

**File:** `docs/PROJECT_RULES.md`
**File:** `docs/pre-dev/{feature}/dependencies.md`

```markdown
# Dependency Map: {Feature Name}

## Technology Decisions

| Category | PRD Requirement | Choice | Version | Rationale | Alternatives Considered |
|----------|----------------|--------|---------|-----------|------------------------|
| Relational DB | Persistent user data | PostgreSQL | 16.2 | Ring standard; team expertise; ACID | MySQL (less preferred), SQLite (no concurrent writes) |
| Cache | Session storage | Valkey | 8.0 | Ring standard; Redis-compatible | Redis (licensing change) |
| Message Queue | Async processing | RabbitMQ | 3.13 | Ring standard; existing infra | Kafka (overkill for volume) |

## Version Matrix

| Package | Version | Lock File | Upgrade Constraint |
|---------|---------|-----------|-------------------|
| go.uber.org/zap | v1.27.0 | go.sum | Stable API; no breaking changes in minor |

## Security & Licenses

| Package | License | CVE Status | Risk |
|---------|---------|-----------|------|
| github.com/jackc/pgx/v5 | MIT | None | Low |

## Cost Analysis

| Component | Shared/Dedicated | Monthly Cost | Notes |
|-----------|-----------------|-------------|-------|
| PostgreSQL (RDS) | Dedicated | R$ 1,490 | 2 vCPU, 8GB RAM |
```

## Gate 6 Validation Checklist

| Category | Requirements |
|----------|--------------|
| **Completeness** | All TRD components have specific technology choices; all dependencies explicit |
| **Versioning** | Exact versions specified; no `@latest`; lock files referenced |
| **Standards Compliance** | Choices validated against Ring Standards; prohibited packages avoided |
| **Security** | No critical CVEs; licenses compliant; security deps included |
| **Costs** | Cost per component documented; shared vs dedicated decisions made |

**Gate Result:** ✅ PASS → Task Breakdown | ⚠️ CONDITIONAL (version gaps or cost estimates missing) | ❌ FAIL (unresolved conflicts or CVEs)
