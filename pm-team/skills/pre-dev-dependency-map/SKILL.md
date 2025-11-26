---
name: pre-dev-dependency-map
description: |
  Gate 6: Technology choices document - explicit, versioned, validated technology
  selections with justifications. Large Track only.

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

**Every technology choice must be explicit, versioned, validated, and justified.**

Using vague or "latest" dependencies creates:
- Unreproducible builds across environments
- Hidden incompatibilities discovered during implementation
- Security vulnerabilities from unvetted versions
- Upgrade nightmares from undocumented constraints

**The Dependency Map answers**: WHAT specific products, versions, packages, and infrastructure we'll use.
**The Dependency Map never answers**: HOW to implement features (that's Tasks/Subtasks).

## When to Use This Skill

Use this skill when:
- Data Model has passed Gate 5 validation
- API Design has passed Gate 4 validation
- TRD has passed Gate 3 validation
- About to select specific technologies
- Tempted to write "@latest" or "newest version"
- Asked to finalize the tech stack
- Before breaking down implementation tasks

## Mandatory Workflow

### Phase 1: Technology Evaluation (Inputs Required)
1. **Approved Data Model** (Gate 5 passed) - data structures defined
2. **Approved API Design** (Gate 4 passed) - contracts specified
3. **Approved TRD** (Gate 3 passed) - architecture patterns locked
4. **Map each TRD component** to specific technology candidates
5. **Map Data Model entities** to storage technologies
6. **Map API contracts** to protocol implementations
7. **Check team expertise** for proposed technologies
8. **Estimate costs** for infrastructure and services

### Phase 2: Stack Selection
For each technology choice:
1. **Specify exact version** (not "latest", not range unless justified)
2. **List alternatives considered** with trade-offs
3. **Verify compatibility** with other dependencies
4. **Check security** for known vulnerabilities
5. **Validate licenses** for compliance
6. **Calculate costs** (infrastructure + services + support)

### Phase 3: Gate 6 Validation
**MANDATORY CHECKPOINT** - Must pass before proceeding to Task Breakdown:
- [ ] All dependencies have explicit versions
- [ ] No version conflicts exist
- [ ] No critical security vulnerabilities
- [ ] All licenses are compliant
- [ ] Team has expertise or learning path
- [ ] Costs are acceptable and documented
- [ ] Compatibility matrix verified
- [ ] All TRD components have dependencies mapped
- [ ] All API contracts have protocol implementations selected
- [ ] All Data Model entities have storage technologies selected

## Explicit Rules

### ✅ DO Include in Dependency Map
- Exact package names with explicit versions (go.uber.org/zap@v1.27.0)
- Technology stack with version constraints (Go 1.24+, PostgreSQL 16)
- Infrastructure services with specifications (Valkey 8, MinIO latest-stable)
- External service SDKs with versions
- Development tool requirements (Go 1.24+, Docker 24+)
- Security dependencies (crypto libraries, scanners)
- Monitoring/observability tools (specific products)
- Compatibility matrices (package A requires package B >= X)
- License summary for all dependencies
- Cost analysis (infrastructure + services)

### ❌ NEVER Include in Dependency Map
- Implementation code or examples
- How to use the dependencies
- Task breakdown or work units
- Step-by-step setup instructions (those go in subtasks)
- Architectural patterns (those were in TRD)
- Business requirements (those were in PRD)

### Version Specification Rules
1. **Explicit versions**: `@v1.27.0` not `@latest` or `^1.0.0`
2. **Justified ranges**: If using `>=`, document why (e.g., security patches)
3. **Lock file referenced**: `go.mod`, `package-lock.json`, etc.
4. **Upgrade constraints**: Document why version is locked/capped
5. **Compatibility**: Document known conflicts or requirements

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

Before proceeding to Task Breakdown, verify:

**Compatibility**:
- [ ] All dependencies have explicit versions documented
- [ ] Version compatibility matrix is complete
- [ ] No known conflicts between dependencies
- [ ] Runtime requirements specified (OS, hardware)
- [ ] Upgrade path exists and is documented

**Security**:
- [ ] All dependencies scanned for vulnerabilities
- [ ] No critical (9.0+) or high (7.0-8.9) CVEs present
- [ ] Security update policy documented
- [ ] Supply chain verified (official sources only)

**Feasibility**:
- [ ] Team has expertise or documented learning path
- [ ] All tools are available/accessible
- [ ] Licensing allows commercial use
- [ ] Costs fit within budget

**Completeness**:
- [ ] Every TRD component has dependencies mapped
- [ ] Development environment fully specified
- [ ] CI/CD dependencies documented
- [ ] Monitoring/observability stack complete

**Documentation**:
- [ ] License summary created
- [ ] Cost analysis completed with estimates
- [ ] Known constraints documented
- [ ] Alternative technologies listed with rationale

**Gate Result**:
- ✅ **PASS**: All checkboxes checked → Proceed to Tasks
- ⚠️ **CONDITIONAL**: Resolve conflicts, add missing versions → Re-validate
- ❌ **FAIL**: Critical vulnerabilities or incompatibilities → Re-evaluate choices

## Common Violations and Fixes

### Violation 1: Vague Version Specifications
❌ **Wrong**:
```yaml
Core Dependencies:
  - Fiber (latest)
  - PostgreSQL driver (current)
  - Zap (newest stable)
```

✅ **Correct**:
```yaml
Core Dependencies:
  - gofiber/fiber/v2@v2.52.0
    Purpose: HTTP router and middleware
    Alternatives Considered: net/http (too low-level), gin (less active)
    Trade-offs: Accepting Express-like API for Go

  - lib/pq@v1.10.9
    Purpose: PostgreSQL driver
    Alternatives Considered: pgx (more complex than needed)
    Constraint: Must remain compatible with database/sql

  - go.uber.org/zap@v1.27.0
    Purpose: Structured logging
    Alternatives Considered: logrus (slower), slog (Go 1.21+ only)
    Trade-offs: Accepting Uber's opinionated API
```

### Violation 2: Missing Security Analysis
❌ **Wrong**:
```yaml
JWT Library: golang-jwt/jwt@v5.0.0
```

✅ **Correct**:
```yaml
JWT Library:
  Package: golang-jwt/jwt@v5.2.0
  Purpose: JWT token generation and validation
  Security:
    - CVE Check: Clean (no known vulnerabilities as of 2024-01-15)
    - OWASP: Follows best practices for token handling
    - Updates: Security patches applied within 24h historically
  Alternatives: cristalhq/jwt (no community), lestrrat-go/jwx (complex)
```

### Violation 3: Undefined Infrastructure
❌ **Wrong**:
```yaml
Infrastructure:
  - Some database (probably Postgres)
  - Cache (Redis or Valkey)
  - Storage for files
```

✅ **Correct**:
```yaml
Infrastructure:
  Database:
    Product: PostgreSQL 16.1
    Rationale: ACID guarantees, proven stability, team expertise
    Configuration: Single primary + 2 read replicas
    Cost: $450/month (managed service) or $120/month (self-hosted)

  Cache:
    Product: Valkey 8.0
    Rationale: Redis fork, OSS license, compatible APIs
    Configuration: 3-node cluster, 16GB RAM total
    Cost: $90/month (managed) or $45/month (self-hosted)

  Object Storage:
    Product: MinIO (latest stable release branch)
    Rationale: S3-compatible, self-hosted, no vendor lock
    Configuration: 4-node distributed setup, 4TB storage
    Cost: $200/month (infrastructure only)
```

## Dependency Resolution Patterns

### For LerianStudio/Midaz Projects (Required)
```yaml
Mandatory Dependencies:
  - lib-commons: @latest (LerianStudio shared library)
  - lib-auth: @latest (Midaz authentication) - Midaz projects only
  - Hexagonal structure via boilerplate
  - Fiber v2.52+ (web framework standard)
  - Zap v1.27+ (logging standard)

Prohibited Choices:
  - Heavy ORMs (use sqlc or raw SQL)
  - Custom auth implementations (use lib-auth)
  - Direct panic() calls in production code
  - Application-level proxies (handled at cloud/infrastructure)

Version Constraints:
  - Go: 1.24+ (for latest stdlib features)
  - PostgreSQL: 16+ (for JSONB improvements)
  - Valkey: 8+ (Redis 7.0 API compatibility)
```

### General Best Practices
```yaml
Prefer:
  - Semantic versioned packages (major.minor.patch)
  - Well-maintained packages (commits within 6 months)
  - Minimal dependency trees (avoid transitive bloat)
  - Standard library when sufficient

Avoid:
  - Deprecated packages (marked or unmaintained >1 year)
  - Single-maintainer critical dependencies
  - Packages with >100 transitive dependencies
  - GPL licenses unless compliance is certain
```

## License Compliance

Document all licenses:

```yaml
License Summary:
  MIT: 45 packages
    - Permissive, commercial use allowed
    - Attribution required in binary distributions

  Apache 2.0: 23 packages
    - Patent grant included
    - Attribution required

  BSD-3-Clause: 12 packages
    - Permissive, attribution required

  Commercial/Proprietary: 2 packages
    - cloud-vendor-sdk: Covered under service agreement
    - monitoring-agent: Free tier for <100 hosts

Compliance Actions:
  - [ ] Attribution file created for distributions
  - [ ] Legal team notified of commercial dependencies
  - [ ] GPL dependencies: None (verified ✓)
```

## Cost Analysis Template

```yaml
Infrastructure Costs (Monthly):
  Compute:
    - Production: 4 containers × $50 = $200
    - Staging: 2 containers × $25 = $50
    - Total: $250/month

  Storage:
    - Database: $450 (managed PostgreSQL 16)
    - Cache: $90 (managed Valkey cluster)
    - Object: $200 (self-hosted MinIO on $50 VMs)
    - Total: $740/month

  Network:
    - Data transfer: ~$30/month (estimated)
    - Load balancer: $20/month
    - Total: $50/month

  Third-Party Services:
    - Auth provider: $100/month (10k MAU)
    - Email service: $50/month
    - Monitoring: $0 (self-hosted)
    - Total: $150/month

Grand Total: $1,190/month base
Scaling Cost: +$150 per 1000 additional users

Cost Validation:
  - Budget: $2,000/month available
  - Margin: 40% buffer for growth
  - Status: ✅ Within budget
```

## Confidence Scoring

Use this to adjust your interaction with the user:

```yaml
Confidence Factors:
  Technology Familiarity: [0-30]
    - Stack used successfully before: 30
    - Similar stack with variations: 20
    - Novel technology choices: 10

  Compatibility Verification: [0-25]
    - All dependencies verified compatible: 25
    - Most dependencies checked: 15
    - Limited verification: 5

  Security Assessment: [0-25]
    - Full CVE scan completed: 25
    - Basic security check done: 15
    - No security review: 5

  Cost Analysis: [0-20]
    - Detailed cost breakdown: 20
    - Rough estimates: 12
    - No cost analysis: 5

Total: [0-100]

Action:
  80+: Generate complete dependency map autonomously
  50-79: Present alternatives for key dependencies
  <50: Ask about team expertise and constraints
```

## Output Location

**Always output to**: `docs/pre-development/dependencies/dep-map-[feature-name].md`

## After Dependency Map Approval

1. ✅ Lock all versions - update only with documented justification
2. 🎯 Create lock files (go.mod, package-lock.json, etc.)
3. 🔒 Set up Dependabot or equivalent for security updates
4. 📋 Proceed to task breakdown with full stack context

## Quality Self-Check

Before declaring Dependency Map complete, verify:
- [ ] Every dependency has explicit version (no @latest)
- [ ] All version conflicts resolved and documented
- [ ] Security scan completed (CVE database checked)
- [ ] All licenses documented and compliant
- [ ] Cost analysis completed with monthly estimates
- [ ] Team expertise verified or learning plan exists
- [ ] Compatibility matrix complete
- [ ] Upgrade constraints documented
- [ ] All TRD components have dependencies mapped
- [ ] Gate 6 validation checklist 100% complete

## The Bottom Line

**If you wrote a Dependency Map without explicit versions, add them now or start over.**

Every dependency must be specific. Period. No @latest. No version ranges without justification. No "we'll figure it out later".

Vague dependencies cause:
- Non-reproducible builds that work on your machine but fail elsewhere
- Security vulnerabilities from unvetted versions
- Incompatibilities discovered during implementation (too late)
- Impossible debugging when "it worked yesterday"

**Be explicit. Be specific. Lock your versions.**

Your deployment engineer will thank you. Your future debugging self will thank you. Your security team will thank you.
