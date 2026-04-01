---
name: ring:dev-dep-security-check
description: |
  Intercepts and audits dependency installations (pip, npm, go) before they
  execute. Validates package identity, checks for known vulnerabilities,
  flags suspicious signals (new package, single maintainer, recent name
  change), and enforces hash pinning in lockfiles. Acts as a supply-chain
  gate for every `install` command in a Lerian codebase.

trigger: |
  - Adding a new dependency to any project
  - Running pip install, npm install, go get, or equivalent
  - Auditing existing dependencies for supply-chain risk
  - Reviewing a PR that adds or updates dependencies
  - Investigating a potential supply-chain compromise

related:
  complementary: [ring:dev-docker-security, ring:dev-sre, ring:dev-implementation]

input_schema:
  required:
    - name: command
      type: string
      description: "The install command to audit (e.g., 'pip install litellm', 'npm install lodash')"
  optional:
    - name: mode
      type: string
      enum: [install, audit, lockfile-check]
      default: install
      description: "install = intercept single command, audit = scan all deps in project, lockfile-check = verify lockfile integrity"
    - name: ecosystem
      type: string
      enum: [pip, npm, go, cargo, all]
      description: "Package ecosystem (auto-detected from command if omitted)"
    - name: severity_threshold
      type: string
      enum: [critical, high, medium, low]
      default: high
      description: "Minimum severity to block installation"
    - name: allow_override
      type: boolean
      default: false
      description: "Allow installation with acknowledged risk (logs override)"

output_schema:
  format: markdown
  required_sections:
    - name: "Package Identity"
      pattern: "^## Package Identity"
      required: true
    - name: "Risk Assessment"
      pattern: "^## Risk Assessment"
      required: true
    - name: "Decision"
      pattern: "^## Decision"
      required: true
  metrics:
    - name: result
      type: enum
      values: [ALLOW, WARN, BLOCK]
    - name: risk_score
      type: integer
      description: "0-100, where 100 is highest risk"
    - name: vulnerabilities_found
      type: integer
---

# Dependency Security Check — Supply Chain Gate

## Overview

Every `pip install`, `npm install`, and `go get` is a trust decision. This skill ensures that trust is verified before code enters your environment.

Supply chain attacks exploit implicit trust in package ecosystems. A single compromised package can exfiltrate credentials, inject backdoors, or pivot into production infrastructure. This skill acts as a gate — intercepting install commands and validating packages before they execute.

## When This Skill Activates

- **New dependency** — any `install` command for a package not in the current lockfile
- **Version change** — updating an existing dependency to a new version
- **Full audit** — scanning all dependencies in a project for supply-chain risk
- **PR review** — when a PR modifies dependency files (go.mod, package.json, requirements.txt, etc.)

## Pre-Install Checks

Before allowing any installation, run ALL of the following checks:

### 1. Package Identity Verification

```
For EVERY package, verify:
├── Does the package name match what the user intended? (typosquatting check)
│   ├── Compare against known popular packages (e.g., "requets" vs "requests")
│   └── Check for homoglyph attacks (e.g., "rnodule" vs "module")
├── Who maintains it?
│   ├── Number of maintainers (1 = higher risk)
│   ├── Maintainer account age
│   └── Maintainer history (other packages, reputation)
├── Package age and history
│   ├── First published date (< 30 days = flag)
│   ├── Version history (sudden ownership transfer = critical flag)
│   └── Download count trajectory (organic growth vs spike)
└── Source repository
    ├── Does the package link to a real repository?
    ├── Does the repository code match the published package?
    └── Is the repository actively maintained?
```

### 2. Vulnerability Database Check

Query these sources for known vulnerabilities:

| Source | Ecosystem | What It Covers |
|--------|-----------|----------------|
| **OSV.dev** | All | Google's aggregated vulnerability database |
| **GitHub Advisory Database** | All | GHSA advisories linked to CVEs |
| **Socket.dev** | npm, pip | Supply chain specific — detects install scripts, network access, obfuscation |
| **PyPI JSON API** | pip | Package metadata, maintainers, release history |
| **npm registry API** | npm | Package metadata, maintainers, install scripts |
| **Go vulnerability DB** (vuln.go.dev) | Go | Official Go vulnerability database |

### 3. Behavioral Analysis

Detect suspicious package behaviors:

| Signal | Risk Level | Description |
|--------|-----------|-------------|
| **Install scripts** | HIGH | `postinstall` (npm), `setup.py` with subprocess calls |
| **Network access at import** | CRITICAL | Package phones home on `import` |
| **File system access outside project** | HIGH | Reads `~/.ssh`, `~/.aws`, keychain, env vars |
| **Obfuscated code** | CRITICAL | Base64 encoded payloads, eval(), exec() |
| **Native binary bundled** | HIGH | Pre-compiled binaries without source |
| **Excessive permissions** | MEDIUM | Package requests more access than its stated purpose |

### 4. Lockfile Integrity

| Ecosystem | Lockfile | Hash Mechanism | Action |
|-----------|----------|----------------|--------|
| Go | `go.sum` | SHA-256 (native) | Verify — Go handles this well |
| npm | `package-lock.json` | `integrity` field (SHA-512) | Verify `integrity` present for ALL deps |
| pip | `requirements.txt` | `--require-hashes` | **Enforce** — pip does NOT do this by default |
| Cargo | `Cargo.lock` | `checksum` field | Verify |

## Risk Scoring

Calculate a composite risk score (0-100):

```
risk_score = weighted_sum(
    typosquatting_similarity    * 25,   # High similarity to popular package
    maintainer_risk             * 20,   # Single/new/transferred maintainer
    package_age_risk            * 15,   # < 30 days old
    vulnerability_count         * 20,   # Known CVEs (weighted by severity)
    behavioral_flags            * 15,   # Install scripts, network access, etc.
    lockfile_integrity          * 5     # Hash missing or mismatch
)
```

### Decision Matrix

| Score | Result | Action |
|-------|--------|--------|
| 0-25 | **ALLOW** | Install proceeds. Log the decision. |
| 26-50 | **WARN** | Install proceeds with warning. Developer must acknowledge. |
| 51-75 | **BLOCK** | Installation blocked. Developer can override with justification (logged). |
| 76-100 | **BLOCK (HARD)** | Installation blocked. No override — requires security team review. |

## Ecosystem-Specific Guidance

### Python (pip)

```bash
# NEVER do this in a Lerian project:
pip install <package>

# ALWAYS do this:
pip install --require-hashes -r requirements.txt

# For new packages, add to requirements.txt first with hash:
# 1. Download in isolated env
# 2. Generate hash: pip hash <package>.whl
# 3. Add to requirements.txt: package==version --hash=sha256:abc123
# 4. Install from lockfile
```

**Key risks:** No native lockfile with hashes. `setup.py` executes arbitrary code during install. PyPI has no maintainer verification.

### Node.js (npm)

```bash
# NEVER do this in CI:
npm install

# ALWAYS do this:
npm ci  # Uses package-lock.json, fails if it doesn't match

# For new packages:
# 1. Review on Socket.dev or npm inspect
# 2. Check for postinstall scripts: npm pack <package> && tar -tf <package>.tgz
# 3. npm install <package> (updates lockfile with integrity hash)
# 4. Commit updated package-lock.json
```

**Key risks:** `postinstall` scripts run with full user permissions. Dependency trees are deep (transitive deps). Name squatting is common.

### Go

```bash
# Go has the best native supply chain security:
# - go.sum provides cryptographic hash verification
# - Go module proxy (proxy.golang.org) caches and serves verified modules
# - GONOSUMCHECK, GONOSUMDB should NEVER be set in Lerian projects

# Verify dependencies:
go mod verify

# Check for vulnerabilities:
govulncheck ./...
```

**Key risks:** Go is stronger by default, but `replace` directives in `go.mod` can bypass verification. CGo packages can include native code.

## Audit Mode — Full Project Scan

When running in `audit` mode, scan the entire dependency tree:

```
For each dependency in the project:
├── Run all Pre-Install Checks (sections 1-4)
├── Flag transitive dependencies separately
├── Generate dependency tree visualization
├── Identify abandoned dependencies (no updates > 2 years)
├── Check for known malicious packages (cross-reference with incident databases)
└── Produce summary report with prioritized actions
```

## PR Review Mode

When reviewing a PR that modifies dependency files:

1. **Diff the lockfile** — identify added, removed, and updated packages
2. **Run Pre-Install Checks on all additions and updates**
3. **Flag lockfile hash changes** for existing deps (potential supply chain attack)
4. **Check if lockfile was regenerated** vs surgically edited (surgical edits = suspicious)
5. **Comment on PR** with risk assessment for each changed dependency

## Integration Points

- **CI/CD Pipeline:** Run `audit` mode on every PR that touches dependency files
- **Pre-commit hook:** Intercept `install` commands locally (optional, developer opt-in)
- **Scheduled scan:** Weekly full audit of all project dependencies
- **Incident response:** When a supply chain attack is disclosed, scan all projects for affected package

## Response to Active Compromise

If a package is confirmed compromised:

1. **Identify all projects using the package** (audit mode across all repos)
2. **Check if the compromised version was installed** (lockfile + CI logs)
3. **Rotate ALL credentials** that were accessible to the compromised environment
4. **Pin to last known-good version** or find alternative
5. **Report to security team** with timeline and blast radius assessment

## References

- [Socket.dev — Supply Chain Security](https://socket.dev)
- [OSV.dev — Open Source Vulnerabilities](https://osv.dev)
- [OpenSSF Scorecard](https://securityscorecards.dev)
- [Sigstore — Package Signing](https://sigstore.dev)
- [SLSA Framework](https://slsa.dev)
