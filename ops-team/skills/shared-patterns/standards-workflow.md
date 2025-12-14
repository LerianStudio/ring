# Standards Loading Workflow

Canonical workflow for loading and applying operational standards across all ops-team agents.

## Standards Loading Process (MANDATORY)

All ops-team agents MUST follow this process before any operational work:

### Step 1: Load Project-Specific Standards

1. Check for `PROJECT_RULES.md` in repository root
2. Check for `ops/STANDARDS.md` or `operations/GUIDELINES.md`
3. Check for `.ops-config.yaml` or similar configuration

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

**This is a HARD BLOCK for certain decisions:**

| Decision Category | Action |
|-------------------|--------|
| Cloud provider | STOP. Ask user. |
| Region/availability zone | STOP. Ask user. |
| Cost budgets | STOP. Ask user. |
| Security requirements | STOP. Ask user. |
| Compliance frameworks | STOP. Ask user. |

**Blocker Report Format:**
```markdown
## Blockers

### Missing Project Standards

| Decision | Options | Impact | Needed From |
|----------|---------|--------|-------------|
| [decision] | [option A, option B] | [impact of choice] | User |

**Cannot proceed without:**
- [ ] [specific requirement]
- [ ] [specific requirement]

Please provide guidance or create PROJECT_RULES.md with:
- [required information]
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
