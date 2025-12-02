---
allowed-tools: Read(*), Glob(*), Grep(*), Edit(*), MultiEdit(*), Write(*), Bash(*), WebSearch(*), WebFetch(*)
description: Comprehensive security analysis and remediation with vulnerability detection and automated fixing
argument-hint: [--focus-area=<area>] [--paths=<paths>] [--git-scope=<scope>] [--full]
---

# /ring-dev-team:security:security-scan

Perform comprehensive security assessment and automated remediation: $ARGUMENTS

## Usage Patterns

```bash
# Git-focused security analysis (recommended for active development)
/ring-dev-team:security:security-scan --git-scope=all-changes           # Scan all changed files
/ring-dev-team:security:security-scan --git-scope=staged               # Scan staged files before commit
/ring-dev-team:security:security-scan --git-scope=branch               # Scan feature branch changes
/ring-dev-team:security:security-scan --git-scope=last-commit          # Scan last commit changes

# Traditional scope-based scanning
/ring-dev-team:security:security-scan --focus-area=api                 # Focus on API security
/ring-dev-team:security:security-scan --paths=src/auth/                # Scan specific paths
/ring-dev-team:security:security-scan --full                           # Full project security scan
```

**Arguments:**

- `--focus-area`: Specific area to focus security analysis (api, auth, data, etc.)
- `--paths`: Specific file or directory paths to scan
- `--git-scope`: Git scope for focusing on specific changes - staged|unstaged|all-changes|branch|last-commit|commit-range=<range>
- `--full`: Comprehensive full-project security analysis

## Current Environment

- Dependency scan: !`npm audit --audit-level=moderate 2>/dev/null || pip check 2>/dev/null || echo "No package manager detected"`
- Environment files: @.env\* (if exists)
- Security config: @.github/workflows/security.yml or @security/ (if exists)
- Recent commits: !`git log --oneline --grep="security\|fix" -10`

## Initial Setup

### Git Scope Analysis (when --git-scope used)

If `--git-scope` is specified:

```bash
# Source git utilities
if ! source .claude/utils/git-utilities.sh; then
    echo "Error: Could not load git utilities. Please ensure git-utilities.sh exists." >&2
    exit 1
fi

# Process git scope (this function handles validation, stats, and file listing)
target_files=$(process_git_scope "$git_scope")
```

**Git-Scope Security Benefits:**

- **Focused Analysis**: Target security review on recently changed code where vulnerabilities are most likely introduced
- **Performance**: Faster scans on large codebases by focusing on changed files
- **Workflow Integration**: Scan staged files before commits, branch changes before merges
- **Risk Mitigation**: Catch security issues early in development workflow

## Security Analysis Process

I'll perform comprehensive security analysis using a structured 10-step approach with automated remediation:

### Step 1: Environment Setup & Assessment

- Identify the technology stack and framework
- Check for existing security tools and configurations
- Review deployment and infrastructure setup

### Step 2: Dependency Security Analysis

- Scan all dependencies for known vulnerabilities using `npm audit`, `pip check`, `cargo audit`
- Check for outdated packages with security issues
- Review dependency sources and integrity

### Step 3: Authentication & Authorization Review

- Review authentication mechanisms and implementation
- Check for proper session management
- Verify authorization controls and access restrictions
- Examine password policies and storage

### Step 4: Input Validation & Sanitization Assessment

- Check all user input validation and sanitization
- Look for SQL injection vulnerabilities
- Identify potential XSS (Cross-Site Scripting) issues
- Review file upload security and validation

### Step 5: Data Protection Analysis

- Identify sensitive data handling practices
- Check encryption implementation for data at rest and in transit
- Review data masking and anonymization practices
- Verify secure communication protocols (HTTPS, TLS)

### Step 6: Secrets Management Audit

- Scan for hardcoded secrets, API keys, and passwords
- Check for proper secrets management practices
- Review environment variable security
- Identify exposed configuration files

### Step 7: Error Handling & Logging Review

- Review error messages for information disclosure
- Check logging practices for security events
- Verify sensitive data is not logged
- Assess error handling robustness

### Step 8: Infrastructure Security Assessment

- Review containerization security (Docker, etc.)
- Check CI/CD pipeline security
- Examine cloud configuration and permissions
- Assess network security configurations

### Step 9: Security Headers & CORS Analysis

- Check security headers implementation
- Review CORS configuration
- Verify CSP (Content Security Policy) settings
- Examine cookie security attributes

### Step 10: Vulnerability Categorization & Remediation

**Risk Categorization:**

- **Critical**: Immediate exploitation possible - Fix immediately
- **High**: Serious vulnerabilities requiring prompt attention
- **Medium**: Should be addressed in near term
- **Low**: Best practice improvements

## Automated Remediation Process

**Common Remediation Patterns:**

- API keys → Environment variables
- Hardcoded endpoints → Configuration files
- XSS vulnerabilities → Input sanitization
- Outdated packages → Security updates
- Unsafe operations → Secure alternatives

**Execution Process:**

1. Create git checkpoint before fixes
2. Fix vulnerability safely with code changes
3. Verify fix doesn't break functionality
4. Document remediation steps
5. Move to next vulnerability by priority

**Validation Steps:**

- Test functionality preserved
- Verify vulnerability resolved
- Check for new issues introduced
- Update security documentation

## Usage Examples

```bash
# Full project security scan
/ring-dev-team:security:security-scan --full

# Focus on specific paths
/ring-dev-team:security:security-scan --paths=src/api/

# Target specific security areas
/ring-dev-team:security:security-scan --focus-area=auth
/ring-dev-team:security:security-scan --focus-area=secrets-management
/ring-dev-team:security:security-scan --focus-area=dependencies
```

## Safety Guarantees

**Protection Measures:**

- Git checkpoint before fixes
- Functionality preservation testing
- No security regression
- Clear audit trail

**Never Will:**

- Expose secrets in commits
- Break existing functionality
- Log sensitive data

## Process Summary

1. **Assessment** - Analyze codebase using 10-step security audit approach
2. **Detection** - Identify vulnerabilities across all security domains
3. **Categorization** - Classify risks by severity and impact
4. **Remediation** - Implement secure solutions with automated fixing
5. **Verification** - Ensure fixes work without breaking functionality
6. **Reporting** - Document all findings and improvements made

Use automated security scanning tools when available and provide manual review for complex security patterns.

## Security Report

**Final Deliverables:**

- **Vulnerability Summary**: Issues found by severity level (Critical, High, Medium, Low)
- **Risk Assessment**: Overall security posture evaluation
- **Remediation Results**: Fixes implemented and verified
- **Recommendations**: Future security improvements with specific remediation steps
- **Code References**: Include file references and line numbers for all findings
