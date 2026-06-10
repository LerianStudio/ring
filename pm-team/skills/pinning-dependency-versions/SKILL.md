---
name: ring:pinning-dependency-versions
description: "Pinning an explicit versioned dependency manifest (dependencies.md plus PROJECT_RULES.md): exact package versions, CVE and license checks, compatibility matrices, and per-component cost analysis against Ring Standards. Gate 6 of ring:planning-large-features; runs after ring:designing-data-model, before ring:writing-plans. Use when the schema is validated and you are about to lock products and versions. Skip for Small Track or when versions are already locked."
---

# Dependency Map — Explicit Technology Choices

## When to use

- Schema (schema.sql / schema.prisma) passed Gate 5 validation
- About to select specific technologies
- Large Track workflow (2+ day features)

## Skip when

- Small Track workflow → skip to ring:writing-plans
- Technologies already locked → skip to ring:writing-plans
- Schema not validated → complete Gate 5 first

## Sequence

**Runs before:** ring:writing-plans
**Runs after:** ring:designing-data-model


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
| **1. Evaluation** | Ring Standards loaded; map TRD components to tech candidates; validate against Ring Standards; map the schema file (schema.sql / schema.prisma) to storage; map openapi.yaml contracts to protocols; check team expertise; estimate costs |
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

**Gate Result:** ✅ PASS → Plan (ring:writing-plans) | ⚠️ CONDITIONAL (version gaps or cost estimates missing) | ❌ FAIL (unresolved conflicts or CVEs)
