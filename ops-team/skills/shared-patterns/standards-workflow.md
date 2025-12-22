# Standards Loading Workflow

Canonical workflow for loading and applying operational standards across all ops-team agents.

## Standards Loading Process (MANDATORY)

All ops-team agents MUST follow this process before any operational work:

### Step 1: Load Project-Specific Standards

1. Check for `docs/PROJECT_RULES.md` in repository
2. Check for `ops/STANDARDS.md` or `operations/GUIDELINES.md`
3. Check for `.ops-config.yaml` or similar configuration

**⛔ DEDUPLICATION RULE:** PROJECT_RULES.md documents ONLY what Ring Standards do NOT cover.

| Belongs in PROJECT_RULES.md | Does NOT Belong (Ring covers) |
|-----------------------------|-------------------------------|
| External integrations (third-party APIs) | Standard infrastructure patterns |
| Non-standard directory structure | Logging/monitoring standards |
| Project-specific env vars | Security baselines |
| Domain terminology | Incident response procedures |
| Tech stack not in Ring | Cost optimization patterns |

### Step 2: Load Ring Standards via WebFetch

Each agent has a specific WebFetch URL for Ring standards:

| Agent | WebFetch URL |
|-------|--------------|
| platform-engineer | `https://raw.githubusercontent.com/LerianStudio/ring/main/ops-team/docs/standards/platform.md` |
| incident-responder | `https://raw.githubusercontent.com/LerianStudio/ring/main/ops-team/docs/standards/incident.md` |
| cloud-cost-optimizer | `https://raw.githubusercontent.com/LerianStudio/ring/main/ops-team/docs/standards/cost.md` |
| infrastructure-architect | `https://raw.githubusercontent.com/LerianStudio/ring/main/ops-team/docs/standards/architecture.md` |
| security-operations | `https://raw.githubusercontent.com/LerianStudio/ring/main/ops-team/docs/standards/security.md` |

**WebFetch Prompt Template:**
```
"Extract all [domain] standards, patterns, requirements, and best practices"
```

### Step 3: Apply Precedence Rules

| Source | Precedence | Notes |
|--------|------------|-------|
| Project-specific standards | HIGHEST | Always override defaults |
| Ring standards (WebFetch) | MEDIUM | Apply where project doesn't specify |
| Industry best practices | LOWEST | Fallback when nothing else applies |

## Missing Standards Handling

### If No PROJECT_RULES.md Exists

**Offer to CREATE it with user input, following deduplication rules.**

For operations work, certain decisions STILL require user input:

| Decision Category | Action |
|-------------------|--------|
| Cloud provider | Ask user (not in Ring) |
| Region/availability zone | Ask user (project-specific) |
| Cost budgets | Ask user (project-specific) |
| Compliance frameworks | Ask user (project-specific) |

**Creation Flow:**
1. WebFetch Ring Standards FIRST (establishes what is covered)
2. Analyze infrastructure for project-specific information
3. Ask user ONLY for what cannot be detected
4. Generate PROJECT_RULES.md with ONLY project-specific content

**Response Format:**
```markdown
## PROJECT_RULES.md Not Found

I'll help create `docs/PROJECT_RULES.md` with ONLY project-specific information.

**Ring Standards already cover:**
- Infrastructure patterns, logging/monitoring, security baselines
- Incident response, cost optimization patterns

**I need to document (if applicable):**
1. External integrations (third-party cloud services)
2. Non-standard directories
3. Project-specific environment variables
4. Domain terminology

**Questions (only what I couldn't detect):**
1. Which cloud provider(s)?
2. Any compliance frameworks (SOC2, HIPAA, etc.)?
3. Cost budget constraints?
```

### If Existing Infrastructure is Non-Compliant

**Signs of Non-Compliance:**
- No runbooks or playbooks
- Manual scaling processes
- Inconsistent naming conventions
- Missing monitoring/alerting
- Undocumented dependencies

**Required Actions:**
1. Document current state in findings
2. Do NOT assume non-compliant patterns are intentional
3. Propose compliance path with effort estimates
4. Ask user before making breaking changes

## Standards Compliance Verification

When invoked for compliance checking, agents MUST:

1. **Enumerate** all applicable standard categories
2. **Verify** each category against current state
3. **Document** gaps with severity
4. **Propose** remediation with effort estimates

### Output Format for Compliance

```markdown
## Standards Compliance

### [Standard Category] Comparison

| Requirement | Current State | Expected State | Status | Gap |
|-------------|---------------|----------------|--------|-----|
| [requirement] | [current] | [expected] | [Compliant/Non-Compliant] | [description] |

### Remediation Plan

| Gap | Priority | Effort | Recommendation |
|-----|----------|--------|----------------|
| [gap] | [CRITICAL/HIGH/MEDIUM/LOW] | [hours/days] | [specific action] |
```

## Anti-Rationalization for Standards Loading

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Standards loading takes too long" | Standards prevent costly mistakes | **Load standards ALWAYS** |
| "Project doesn't have standards yet" | Ring standards provide baseline | **Use Ring standards as default** |
| "I know these standards already" | Standards evolve. Load fresh. | **WebFetch every time** |
| "Small task doesn't need standards" | Small tasks can cause big problems | **Apply standards uniformly** |
| "Standards conflict with request" | Standards exist for good reasons | **Report conflict as blocker** |

## Standards Update Notification

If loaded standards differ from previous session:

```markdown
## Standards Update Notice

| Standard | Previous Version | Current Version | Key Changes |
|----------|------------------|-----------------|-------------|
| [standard] | [version/date] | [version/date] | [summary] |

**Action Required:** Review changes before proceeding.
```
