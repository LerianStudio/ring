---
name: ring:dev-dep-security-check
description: |
  Intercepts and audits dependency installations (pip, npm, go) before they execute.
  Validates package identity, checks vulnerabilities, flags supply-chain risk signals,
  and enforces hash pinning in lockfiles.
---

# Dependency Security Check

## When to use
- Adding a new dependency to any project
- Running pip install, npm install, go get, or equivalent
- Auditing existing dependencies for supply-chain risk
- Reviewing a PR that adds or updates dependencies
- Investigating a potential supply-chain compromise

## Skip when
- No dependencies are being added, updated, or audited
- Task involves only internal code changes with no new imports
- Dependency is already vetted and pinned in lockfile

## Related
**Complementary:** ring:dev-docker-security, ring:dev-implementation


Supply-chain gate for every install command in a Lerian codebase.

## Pre-Install Checks

### 1. Package Identity Verification

```
For every package, verify:
├── Typosquatting: compare against known popular packages
│   e.g., "requets" vs "requests", "rnodule" vs "module"
├── Homoglyph attacks: look-alike Unicode characters
├── Maintainer risk:
│   - Single maintainer = higher risk
│   - Account age < 6 months = flag
│   - Recent ownership transfer = CRITICAL flag
└── Package age: < 30 days = flag
```

### 2. Vulnerability Database Check

| Source | Ecosystem | What It Covers |
|--------|-----------|----------------|
| OSV.dev | All | Google aggregated CVEs |
| GitHub Advisory Database | All | GHSA linked to CVEs |
| Socket.dev | npm, pip | Supply-chain: install scripts, network access |
| PyPI JSON API | pip | Metadata, maintainers, release history |
| npm registry API | npm | Metadata, maintainers, install scripts |
| Go vulnerability DB (vuln.go.dev) | Go | Official Go CVE database |

### 3. Behavioral Signals

| Signal | Risk Level | Description |
|--------|-----------|-------------|
| Install scripts | HIGH | `postinstall` (npm), `setup.py` subprocess |
| Network access at import | CRITICAL | Package phones home on import |
| File system access outside project | HIGH | Reads `~/.ssh`, `~/.aws`, env vars |
| Obfuscated code | CRITICAL | Base64 payloads, eval(), exec() |
| Native binary bundled | HIGH | Pre-compiled binaries without source |

### 4. Lockfile Integrity

| Ecosystem | Lockfile | Hash Requirement |
|-----------|----------|-----------------|
| Go | go.sum | SHA-256 native — Go handles automatically |
| npm | package-lock.json | `integrity` field (SHA-512) must be present for ALL deps |
| pip | requirements.txt | `--require-hashes` MUST be enforced |
| Cargo | Cargo.lock | `checksum` field verification |

## Risk Scoring

```
risk_score = weighted_sum(
  typosquatting_similarity * 25,
  maintainer_risk          * 20,
  package_age_risk         * 15,
  vulnerability_count      * 20,  # weighted by severity
  behavioral_flags         * 15,
  lockfile_integrity       * 5
)
```

Score thresholds:
- 0-25: LOW — proceed
- 26-50: MEDIUM — proceed with documentation
- 51-75: HIGH — escalate to Fred before installing
- 76-100: CRITICAL — block installation

## Decision Matrix

| Risk Level | Action |
|-----------|--------|
| LOW (0-25) | ✅ Approve — document in PR |
| MEDIUM (26-50) | ⚠️ Conditional — mitigations required |
| HIGH (51-75) | 🚨 Escalate to Fred before installing |
| CRITICAL (76-100) | ❌ Block — do not install |

## Report Template

```markdown
## Dependency Security Report

Package: {name} @ {version}
Ecosystem: {go|npm|pip}
Risk Score: {score}/100 — {LOW|MEDIUM|HIGH|CRITICAL}

### Verification Results

| Check | Status | Details |
|-------|--------|---------|
| Typosquatting check | PASS/FLAG | {comparison} |
| Maintainer verification | PASS/FLAG | {maintainer count, age} |
| Vulnerability scan | PASS/FLAG | {CVE count, severity} |
| Behavioral analysis | PASS/FLAG | {signals found} |
| Lockfile integrity | PASS/FAIL | {hash present/missing} |

### Decision
{APPROVED|CONDITIONAL|ESCALATE|BLOCKED}

### Required Actions (if not APPROVED)
1. {specific mitigations or alternatives}
```

## Mitigations for MEDIUM Risk

- Pin exact version in lockfile
- Vendor the dependency (copy source into repo)
- Document why this specific package was chosen over alternatives
- Add to security monitoring (e.g., GitHub Dependabot alerts)
