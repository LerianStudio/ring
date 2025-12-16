---
name: security-audit
description: Execute infrastructure security audit workflow with compliance validation
argument-hint: "[scope: full|network|iam|data] [frameworks: soc2,pci,gdpr]"
---

# Security Audit Command

This command initiates structured security audit following the ops-security-audit workflow.

## Usage

```
/security-audit full soc2,pci
/security-audit iam soc2
/security-audit network
```

## Workflow

### Step 1: Define Audit Scope

Parse scope and compliance frameworks from arguments.

**Scope options:**
- `full` - Comprehensive infrastructure audit
- `network` - Network security focus (VPC, SG, NACLs)
- `iam` - Identity and access management focus
- `data` - Data protection focus (encryption, access)
- `logging` - Logging and monitoring focus

**Framework options:**
- `soc2` - SOC2 Type II controls
- `pci` - PCI-DSS 4.0 requirements
- `gdpr` - GDPR infrastructure requirements
- `hipaa` - HIPAA technical safeguards
- `none` - Best practices only (no compliance mapping)

**If not provided, ask:**
- What is the audit scope?
- Which compliance frameworks apply?

### Step 2: Dispatch Security Operations Specialist

```
Task tool:
  subagent_type: "security-operations"
  model: "opus"
  prompt: |
    SECURITY AUDIT REQUEST

    **Scope:** [scope]
    **Compliance Frameworks:** [frameworks]
    **Date:** [current date]

    Please perform:
    1. Automated security scanning (Security Hub, Config, GuardDuty)
    2. Manual review of [scope-specific areas]
    3. Compliance mapping to specified frameworks
    4. Vulnerability prioritization
    5. Remediation recommendations

    Scope-specific focus:
    - Full: All security domains
    - Network: VPC, security groups, NACLs, flow logs
    - IAM: Users, roles, policies, MFA, access keys
    - Data: Encryption, access controls, data classification
    - Logging: CloudTrail, audit logs, SIEM integration

    Output required:
    - Security summary
    - Findings by severity
    - Compliance status (if frameworks specified)
    - Prioritized remediation plan
    - Risk assessment
```

### Step 3: Generate Audit Report

Format findings into comprehensive security audit report.

## Output Format

```markdown
# Security Audit Report

**Scope:** [scope]
**Frameworks:** [frameworks]
**Audit Date:** YYYY-MM-DD
**Auditor:** security-operations

## Executive Summary

**Overall Status:** [PASS / NEEDS ATTENTION / CRITICAL FINDINGS]

| Severity | Count | Remediated | Pending |
|----------|-------|------------|---------|
| Critical | X | X | X |
| High | X | X | X |
| Medium | X | X | X |
| Low | X | X | X |

## Findings

### Critical Severity

| ID | Finding | Resource | Risk | Remediation |
|----|---------|----------|------|-------------|
| SEC-001 | [finding] | [resource] | [risk] | [action] |

### High Severity

| ID | Finding | Resource | Risk | Remediation |
|----|---------|----------|------|-------------|
| SEC-002 | [finding] | [resource] | [risk] | [action] |

[Continue for Medium/Low...]

## Compliance Status

### [Framework] Compliance

| Control | Requirement | Status | Gap |
|---------|-------------|--------|-----|
| [control] | [requirement] | [status] | [gap if any] |

**Compliance Summary:** [X]/[Y] controls compliant ([%])

## Remediation Plan

### Priority 1 (24 hours)

| Finding | Owner | Due Date | Status |
|---------|-------|----------|--------|
| SEC-001 | @security | YYYY-MM-DD | Not Started |

### Priority 2 (7 days)

| Finding | Owner | Due Date | Status |
|---------|-------|----------|--------|
| SEC-002 | @platform | YYYY-MM-DD | Not Started |

### Priority 3 (30 days)

[Lower priority items]

## Risk Assessment

| Finding | Business Risk | Likelihood | Impact | Score |
|---------|---------------|------------|--------|-------|
| SEC-001 | [risk] | [L/M/H] | [L/M/H] | [score] |

## Recommendations

### Immediate Actions
1. [Action with specific steps]
2. [Action with specific steps]

### Process Improvements
1. [Improvement recommendation]
2. [Improvement recommendation]

## Next Steps

1. Address all Critical/High findings within SLA
2. Schedule remediation verification
3. Update security policies if needed
4. Schedule next audit: [date]
```

## Scope-Specific Templates

### IAM Audit Focus

Additional output:
```markdown
## IAM Security Assessment

### Root Account

| Check | Status |
|-------|--------|
| MFA enabled | [PASS/FAIL] |
| No access keys | [PASS/FAIL] |
| Not used in 90 days | [PASS/FAIL] |

### User Analysis

| Finding | Count | Risk |
|---------|-------|------|
| Users without MFA | X | High |
| Access keys >90 days | X | Medium |
| Inactive users >90 days | X | Low |

### Policy Analysis

| Finding | Count | Risk |
|---------|-------|------|
| Overly permissive policies | X | High |
| Inline policies | X | Medium |
| Unused permissions | X | Low |
```

### Network Audit Focus

Additional output:
```markdown
## Network Security Assessment

### Security Groups

| Finding | Count | Risk |
|---------|-------|------|
| 0.0.0.0/0 ingress rules | X | High |
| Unused security groups | X | Low |
| Overly permissive rules | X | Medium |

### VPC Configuration

| Check | Status |
|-------|--------|
| Flow logs enabled | [PASS/FAIL] |
| VPC endpoints for AWS services | [PASS/FAIL] |
| No public subnets for DBs | [PASS/FAIL] |
```

### Data Audit Focus

Additional output:
```markdown
## Data Protection Assessment

### Encryption Status

| Resource Type | Total | Encrypted | Unencrypted |
|---------------|-------|-----------|-------------|
| S3 Buckets | X | X | X |
| EBS Volumes | X | X | X |
| RDS Instances | X | X | X |

### Access Controls

| Check | Status |
|-------|--------|
| S3 public access blocked | [PASS/FAIL] |
| KMS key rotation enabled | [PASS/FAIL] |
| Secrets in Secrets Manager | [PASS/FAIL] |
```

## Related Skills

- `ops-security-audit` - Full security audit workflow
- `security-reviewer` - Application security review

## Anti-Rationalization

| Rationalization | Required Action |
|-----------------|-----------------|
| "It's a false positive" | **Document evidence for every dismissal** |
| "Internal only, security optional" | **Internal = majority of breaches** |
| "Too many findings" | **Prioritize by severity, address systematically** |
| "Compliance is checkbox" | **Compliance reflects real security needs** |
