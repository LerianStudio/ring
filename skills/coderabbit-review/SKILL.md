---
name: coderabbit-review
description: Use when requesting external code review via CodeRabbit CLI - provides AI-powered review with severity-based findings, complements Ring's internal reviewers with language-specific best practices
---

# CodeRabbit Review

Run CodeRabbit CLI for external AI-powered code review.

**Core principle:** External validation complements internal reviews. CodeRabbit provides language-specific best practices; Ring reviewers understand your requirements.

## When to Use

**Use CodeRabbit review when:**
- Want external perspective (different from Ring's internal reviewers)
- Need language-specific linting and best practices
- Want to validate against broader code pattern datasets
- Need additional security vulnerability scanning

**Use alongside Ring's internal reviews:**
- **Internal reviews** (code/business/security) - Ring agents in parallel, context-aware
- **External review** (CodeRabbit) - Independent validation, pattern-based

**Don't use as replacement for:**
- Ring's internal reviewers (use both, not either/or)
- Requirements validation (CodeRabbit doesn't know your PRD)
- Business logic verification (CodeRabbit doesn't understand domain)

## Review Types

**All changes (default):**
```bash
/review-cr
```
Reviews both committed and uncommitted changes.

**Committed only:**
```bash
/review-cr committed
```
Reviews only committed changes (staged history).

**Uncommitted only:**
```bash
/review-cr uncommitted
```
Reviews only working directory changes (unstaged).

**Custom base branch:**
```bash
/review-cr --base develop
/review-cr committed --base main
```
Compare against specific branch instead of repository default.

## The Process

### 1. Argument Parsing

Parse arguments in any order:
- Scan for `--base` flag: extract next argument as base branch
- Check for review type: `uncommitted`, `committed`, or `all`
- Defaults: type=`all`, base=repository default branch

### 2. Validation

**Validate base branch if specified:**
```bash
git rev-parse --verify <branch>
```

If branch doesn't exist:
- Message: "Base branch '<branch>' not found. Available branches: <list>"
- Exit gracefully without running review

After validation, sanitize branch name:
```bash
branch_safe=$(echo "$branch" | sed 's/[^a-zA-Z0-9._/-]//g')
```
This prevents command injection via branch names.

**Check for existing CodeRabbit processes:**
```bash
pgrep -f "coderabbit review"
```

If process exists:
- Message: "A CodeRabbit review is already running. Wait for completion or kill process."
- Exit gracefully

### 3. Execute Review

**Run in background:**
```bash
coderabbit review --prompt-only --type <type> [--base <branch_safe>]
```

Use Bash tool with `run_in_background: true`.

**CodeRabbit context sources:**
- `~/.claude/CLAUDE.md` - Your global coding standards
- `<project>/.claude/claude.md` - Project-specific guidelines
- `<project>/.coderabbit.yaml` - CodeRabbit configuration

These provide coding standards and preferences to the review.

### 4. Monitor Progress

**Check every 30 seconds:**
- Use BashOutput tool to monitor background process
- Look for final summary in output
- Maximum wait: 45 minutes (90 checks)

**Progress messages:**
- At 5 minutes: "CodeRabbit is still analyzing... (can take 7-30 minutes for large changesets)"
- Continue monitoring

**If BashOutput fails:**
- Wait 10 seconds and retry once
- If retry fails: "Unable to monitor review process. Check with: ps aux | grep coderabbit"

**If timeout (45 minutes):**
- Report: "Review exceeded 45 minute timeout. Terminating runaway process..."
- Graceful termination:
  ```bash
  pid=$(pgrep -f "coderabbit review")
  kill -TERM $pid
  sleep 5
  pgrep -f "coderabbit review" && kill -KILL $pid
  ```
- Verify termination: `pgrep -f "coderabbit review"` returns nothing
- Message: "CodeRabbit process terminated after timeout. Prevents resource exhaustion."

### 5. Parse and Present Findings

**Extract issues from output:**
- Group by severity: CRITICAL, HIGH, MEDIUM, LOW, INFO
- For each issue:
  - Severity badge (🔴 CRITICAL, 🟠 HIGH, 🟡 MEDIUM, 🔵 LOW, ⚪ INFO)
  - File path and line number
  - Issue description
  - Suggested fix approach (if provided)

**Example output:**
```
🔴 CRITICAL - src/auth.ts:42
JWT secret hardcoded in source code
Fix: Move to environment variable

🟠 HIGH - src/api/users.ts:156
SQL injection vulnerability in query builder
Fix: Use parameterized queries

🟡 MEDIUM - src/utils/validator.ts:89
Missing input validation for email field
Fix: Add email format validation
```

### 6. Create Todos for Critical Issues

**Use TodoWrite for CRITICAL and HIGH severity:**
```
Format: "Fix [severity] in [file]:[line] - [brief description]"
```

Example:
- "Fix CRITICAL in src/auth.ts:42 - Remove hardcoded JWT secret"
- "Fix HIGH in src/api/users.ts:156 - SQL injection vulnerability"

### 7. Prompt for Action

```
CodeRabbit review complete. Found X issues (Y critical, Z high).
Would you like me to fix these issues?
```

## Error Handling

**CodeRabbit CLI not installed:**
```
Message: "CodeRabbit CLI not installed. Install with:
         curl -fsSL https://cli.coderabbit.ai/install.sh | sh"
Exit gracefully
```

**Not authenticated:**
```
Message: "Not authenticated with CodeRabbit. Run: coderabbit auth login"
Exit gracefully
```

**No changes to review:**
```
Message: "No changes found to review. Make some changes first."
Exit gracefully
```

**Review takes longer than expected:**
```
Message at 5 minutes: "CodeRabbit is still analyzing...
                       (this can take 7-30 minutes for large changesets)"
Continue monitoring
```

## Integration with Ring Reviews

**Recommended workflow:**

1. **Internal review first** (fast, context-aware):
   ```
   Dispatch Ring's 3 reviewers in parallel:
   - code-reviewer
   - business-logic-reviewer
   - security-reviewer
   ```

2. **External review second** (validation, patterns):
   ```
   /review-cr
   ```

3. **Compare findings:**
   - Issues found by both → High confidence, fix immediately
   - Issues found only by Ring → Context-specific, trust internal
   - Issues found only by CodeRabbit → Pattern-based, evaluate relevance

4. **Handle by severity:**
   - **Critical/High** (any source) → Fix immediately
   - **Medium** → Fix if time permits
   - **Low** → Add TODO comments
   - **Info** → Consider for future improvements

## Red Flags

**Never:**
- Use CodeRabbit as sole review method (complement Ring's reviewers)
- Skip validation of base branch (security risk)
- Ignore timeouts (can cause resource exhaustion)
- Run multiple CodeRabbit reviews simultaneously (process conflict)

**Always:**
- Sanitize branch names before using in commands
- Monitor for completion (don't fire and forget)
- Create todos for Critical/High issues
- Terminate runaway processes after timeout

## Anti-Patterns

**Wrong:**
- "CodeRabbit found nothing, so we're good" → Still run Ring reviewers
- "Let's run both reviews in parallel" → Run Ring first (faster), then CodeRabbit
- "Skip CodeRabbit, Ring reviews are enough" → External validation catches different issues
- "CodeRabbit says fix, so fix blindly" → Evaluate if pattern applies to your context

**Right:**
- Use Ring reviewers for requirements/business logic
- Use CodeRabbit for language-specific patterns
- Combine findings from both sources
- Prioritize Critical/High from either source

## Required Patterns

This skill uses these universal patterns:
- **State Tracking:** See `skills/shared-patterns/state-tracking.md`
- **Failure Recovery:** See `skills/shared-patterns/failure-recovery.md`
- **Exit Criteria:** See `skills/shared-patterns/exit-criteria.md`
- **TodoWrite:** See `skills/shared-patterns/todowrite-integration.md`

Apply ALL patterns when using this skill.
