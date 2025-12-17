---
name: pre-dev-dependency-map
description: |
  Gate 6: Technology choices document - explicit, versioned, validated technology
  selections with justifications. Large Track only. HARD BLOCK: Must load Ring Standards
  and PROJECT_RULES.md before proceeding.

trigger: |
  - Data Model passed Gate 5 validation
  - About to select specific technologies
  - Tempted to write "@latest" or "newest version"
  - Large Track workflow (2+ day features)

skip_when: |
  - Small Track workflow → skip to Task Breakdown
  - Technologies already locked → skip to Task Breakdown
  - Data Model not validated → complete Gate 5 first

sequence:
  after: [pre-dev-data-model]
  before: [pre-dev-task-breakdown]
---

# Dependency Map - Explicit Technology Choices

## Foundational Principle

**Every technology choice must be explicit, versioned, validated against Ring Standards, and justified.**

Using vague or "latest" dependencies creates:
- Unreproducible builds across environments
- Hidden incompatibilities discovered during implementation
- Security vulnerabilities from unvetted versions

**The Dependency Map answers**: WHAT specific products, versions, packages, and infrastructure we'll use.
**The Dependency Map never answers**: HOW to implement features (that's Tasks/Subtasks).

---

## ⛔ HARD BLOCK: Standards Loading (Step 0)

**This is a HARD GATE. Do NOT proceed without loading Ring Standards and TRD decisions.**

### Step 0.1: Read Technology Decisions from TRD

Read `docs/pre-dev/{feature-name}/trd.md` and extract: `deployment.model`, `tech_stack.primary`, `project_technologies[]`

**If TRD metadata missing:** BLOCKER → Go back to TRD (Gate 3) and complete Step 0.4

### Step 0.2: Load Ring Standards via WebFetch

| Standard | URL | Purpose |
|----------|-----|---------|
| **golang.md** | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang.md` | Go coding patterns |
| **typescript.md** | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/typescript.md` | TypeScript patterns |
| **frontend.md** | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend.md` | Frontend patterns |
| **devops.md** | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/devops.md` | DevOps patterns |
| **sre.md** | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/sre.md` | Observability, logging |

**Ring Standards** = coding patterns, observability, logging, error handling (shared across ALL projects)
**PROJECT_RULES.md** = specific technologies, versions, database choices (specific to THIS project)

### Step 0.3: Generate PROJECT_RULES.md (OUTPUT)

Using TRD `project_technologies[]`, create `docs/PROJECT_RULES.md` with: deployment model, tech stack, per-category decisions (PRD requirement, technology, version, rationale, cloud service, on-premise alternative), version matrix, security/compliance.

### Pressure Resistance for Step 0

| Pressure | Response |
|----------|----------|
| "TRD doesn't have technology decisions" | "Go back to TRD (Gate 3) and complete Step 0.4 (PRD analysis)." |
| "Ring Standards are optional" | "Ring Standards define coding patterns. PROJECT_RULES.md defines technologies. Both needed." |
| "Just use defaults" | "Defaults come from PRD analysis in TRD. Read TRD first." |
| "Skip to save time" | "PROJECT_RULES.md is the output. Cannot skip the output." |

---

## Mandatory Workflow

| Phase | Activities |
|-------|------------|
| **1. Evaluation** | Ring Standards loaded (Step 0); PROJECT_RULES.md loaded; Data Model (Gate 5), API Design (Gate 4), TRD (Gate 3) passed; map TRD components to tech candidates; validate against Ring Standards; map Data Model to storage; map API contracts to protocols; check team expertise; estimate costs |
| **2. Selection** | Per technology: check Ring Standards (mandatory/prohibited), check PROJECT_RULES.md overrides, specify exact version, list alternatives with trade-offs, verify compatibility, check security (CVEs), validate licenses, calculate costs |
| **3. Gate 6 Validation** | All dependencies explicit, no conflicts, no critical CVEs, licenses compliant, team expertise, costs documented, all components mapped |

## Explicit Rules

### ✅ DO Include
Exact package names with versions (`go.uber.org/zap@v1.27.0`), tech stack with constraints (`Go 1.24+, PostgreSQL 16`), infrastructure specs (`Valkey 8, MinIO`), external SDKs, dev tools, security deps, monitoring tools, compatibility matrices, license summary, cost analysis

### ❌ NEVER Include
Implementation code, how to use dependencies, task breakdowns, setup instructions, architectural patterns (TRD), business requirements (PRD)

### Version Rules
1. **Explicit**: `@v1.27.0` not `@latest` or `^1.0.0`
2. **Justified ranges**: If using `>=`, document why
3. **Lock file referenced**: `go.mod`, `package-lock.json`, etc.
4. **Upgrade constraints**: Document why locked/capped
5. **Compatibility**: Document known conflicts

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "Latest version is always best" | Latest is untested in your context. Pick specific, validate. |
| "I'll use flexible version ranges" | Ranges cause non-reproducible builds. Lock versions. |
| "Version numbers don't matter much" | They matter critically. Specify or face build failures. |
| "We can update versions later" | Document constraints now. Future you needs context. |
| "The team knows the stack already" | Document it anyway. Teams change, memories fade. |
| "Security scanning can happen in CI" | Security analysis must happen before committing. Do it now. |
| "We'll figure out costs in production" | Costs must be estimated before building. Calculate now. |
| "Compatibility issues will surface in tests" | Validate compatibility NOW. Don't wait for failures. |
| "License compliance is legal's problem" | You're responsible for your dependencies. Check licenses. |
| "I'll just use what the project template has" | Templates may be outdated/insecure. Validate explicitly. |

## Red Flags - STOP

If you catch yourself writing any of these in a Dependency Map, **STOP**:

- Version placeholders: `@latest`, `@next`, `^X.Y.Z` without justification
- Vague descriptions: "latest stable", "current version", "newest"
- Missing version numbers: Just package names without versions
- Unchecked compatibility: Not verifying version conflicts
- Unvetted security: Not checking vulnerability databases
- Unknown licenses: Not documenting license types
- Estimated costs as "TBD" or "unknown"
- "We'll use whatever is default" (no default without analysis)

**When you catch yourself**: Stop and specify the exact version after proper analysis.

## Gate 6 Validation Checklist

| Category | Requirements |
|----------|--------------|
| **Standards Compliance (HARD BLOCK)** | Ring Standards loaded; PROJECT_RULES.md loaded; mandatory deps included (or justified); no prohibited choices (or justified); version constraints respected; deviations documented |
| **Compatibility** | All deps have explicit versions; version matrix complete; no known conflicts; runtime requirements specified; upgrade path documented |
| **Security** | All deps scanned for vulnerabilities; no critical (9.0+) or high (7.0-8.9) CVEs; security update policy documented; supply chain verified |
| **Feasibility** | Team has expertise or learning path; tools available; licensing allows commercial use; costs fit budget |
| **Completeness** | Every TRD component mapped; dev environment specified; CI/CD deps documented; monitoring stack complete |
| **Documentation** | License summary; cost analysis; known constraints; alternatives with rationale |

**Gate Result:** ✅ PASS (all checked) → Task Breakdown | ⚠️ CONDITIONAL (standards not loaded) → Complete Step 0 | ❌ FAIL (critical CVEs, incompatibilities, standards not loaded)

## Common Violations

| Violation | Wrong | Correct |
|-----------|-------|---------|
| **Vague Versions** | `Fiber (latest), PostgreSQL (current), Zap (newest stable)` | `gofiber/fiber/v2@v2.52.0` with purpose, alternatives considered, trade-offs; `lib/pq@v1.10.9` with constraint; `go.uber.org/zap@v1.27.0` with rationale |
| **Missing Security** | `JWT Library: golang-jwt/jwt@v5.0.0` (no analysis) | Package + purpose + security (CVE check date, OWASP compliance, update history) + alternatives |
| **Undefined Infrastructure** | `Some database (probably Postgres), Cache (Redis or Valkey), Storage for files` | Per component: product + version + rationale + configuration + cost (managed vs self-hosted) |

## Dependency Resolution Patterns

### Standards-Driven Validation

If language cannot be auto-detected, use AskUserQuestion with tech stack options (Go Backend, TypeScript Backend, TypeScript Frontend, Full-Stack TypeScript).

| Selection | Standards to Load |
|-----------|-------------------|
| Go Backend | golang.md + devops.md + sre.md |
| TypeScript Backend | typescript.md + devops.md + sre.md |
| TypeScript Frontend | frontend.md + devops.md |
| Full-Stack TypeScript | typescript.md + frontend.md + devops.md + sre.md |

**Validation Flow:** Standards loaded → Extract mandatory/prohibited/constraints → Check PROJECT_RULES.md → Validate each selection → Document compliance or justified deviations

### Best Practices

**Prefer:** Semantic versioned packages, well-maintained (commits within 6 months), minimal dependency trees, standard library when sufficient
**Avoid:** Deprecated packages (>1 year unmaintained), single-maintainer critical deps, >100 transitive deps, GPL unless compliance certain

### Authentication Dependencies (Mandatory for Auth Features)

**If TRD specifies authentication/authorization requirements, include these dependencies:**

| Tech Stack | Auth Requirement | Mandatory Dependency | Reference |
|------------|------------------|---------------------|-----------|
| Go Backend | User authentication | `github.com/LerianStudio/lib-auth/v2` | `golang.md` → Access Manager Integration |
| Go Backend | Service-to-service auth | `github.com/LerianStudio/lib-auth/v2` | `golang.md` → Access Manager Integration |
| Go Backend | User + permissions (RBAC) | `github.com/LerianStudio/lib-auth/v2` | `golang.md` → Access Manager Integration |

**For Go services, the dependency entry MUST include:**

```markdown
### Authentication

**Package:** `github.com/LerianStudio/lib-auth/v2@vX.Y.Z`
**Purpose:** Integration with Lerian Access Manager (plugin-auth + identity)
**Rationale:** Standard authentication library for all Lerian Go services
**Environment Variables:** PLUGIN_AUTH_ADDRESS, PLUGIN_AUTH_ENABLED
**Additional (if S2S):** CLIENT_ID, CLIENT_SECRET
**Reference:** See `golang.md` → Access Manager Integration for implementation patterns
```

**CRITICAL:** Go services MUST use lib-auth for authentication. Direct integration with plugin-auth is FORBIDDEN.

**Implementation Requirement (from TRD):**
- Every protected endpoint MUST have route middleware: `auth.Authorize(applicationName, resource, action)`
- Middleware is applied per-route, not globally
- See `golang.md` → Access Manager Integration → Router Setup for patterns

### Licensing Dependencies (Mandatory for Licensed Products)

**If TRD specifies this is a licensed product/plugin, include these dependencies:**

| Tech Stack | License Requirement | Mandatory Dependency | Reference |
|------------|---------------------|---------------------|-----------|
| Go Backend | Single-org (global) license | `github.com/LerianStudio/lib-license-go/v2` | `golang.md` → License Manager Integration |
| Go Backend | Multi-org license | `github.com/LerianStudio/lib-license-go/v2` | `golang.md` → License Manager Integration |

**For Go services, the dependency entry MUST include:**

```markdown
### Licensing

**Package:** `github.com/LerianStudio/lib-license-go/v2/middleware@vX.Y.Z`
**Purpose:** Integration with Lerian License Manager for product licensing
**Rationale:** Standard licensing library for all Lerian licensed Go services
**Environment Variables:** LICENSE_KEY, ORGANIZATION_IDS
**Mode:** Global (ORGANIZATION_IDS=global) or Multi-org (comma-separated org IDs)
**Reference:** See `golang.md` → License Manager Integration for implementation patterns
```

**CRITICAL:** Go services MUST use lib-license-go for licensing. Custom license validation is FORBIDDEN.

**Implementation Requirement (from TRD):**
- License middleware applied GLOBALLY: `f.Use(lc.Middleware())`
- Middleware applied early in chain (first after Fiber creation)
- Graceful shutdown MUST include: `licenseClient.GetLicenseManagerShutdown()`
- See `golang.md` → License Manager Integration → Router Setup for patterns

## License & Cost Templates

**License Summary:** Document count by type (MIT, Apache 2.0, BSD-3-Clause, Commercial), compliance actions (attribution file, legal notification, GPL verification)

**Cost Analysis:** Monthly breakdown by category (Compute: containers × cost, Storage: managed DB + cache + object, Network: transfer + load balancer, Third-Party: auth + email + monitoring), grand total, scaling cost per additional users, budget validation

## Confidence Scoring

| Factor | Points | Criteria |
|--------|--------|----------|
| Technology Familiarity | 0-30 | Used before: 30, Similar: 20, Novel: 10 |
| Compatibility Verification | 0-25 | All verified: 25, Most checked: 15, Limited: 5 |
| Security Assessment | 0-25 | Full CVE scan: 25, Basic check: 15, No review: 5 |
| Cost Analysis | 0-20 | Detailed breakdown: 20, Rough estimates: 12, None: 5 |

**Action:** 80+ autonomous generation | 50-79 present alternatives | <50 ask about expertise/constraints

## Output & After Approval

**Output to:** `docs/pre-dev/{feature-name}/dependency-map.md`

1. ✅ Lock all versions - update only with documented justification
2. 🎯 Create lock files (go.mod, package-lock.json, etc.)
3. 🔒 Set up Dependabot or equivalent for security updates
4. 📋 Proceed to task breakdown with full stack context

## The Bottom Line

**If you skipped loading Ring Standards, STOP and go back to Step 0.**

**If you wrote a Dependency Map without explicit versions, add them now or start over.**

Two non-negotiable requirements:
1. **Ring Standards MUST be loaded** - Technology choices validated against organizational baseline
2. **Every dependency MUST be explicit** - No @latest, no vague versions, no "we'll figure it out"

**Load standards first. Be explicit. Be specific. Lock your versions.**
