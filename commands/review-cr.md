---
name: review-cr
description: Run CodeRabbit CLI code review with parameter support
---

Run a CodeRabbit CLI code review on current changes.

**Usage:**
- `/review-cr` - Review all changes (committed + uncommitted)
- `/review-cr uncommitted` - Review only working directory changes
- `/review-cr committed` - Review only committed changes
- `/review-cr --base <branch>` - Compare against specific branch
- `/review-cr uncommitted --base develop` - Combine options

**What this does:**
1. Parses command arguments to extract type and base branch
2. Runs `coderabbit review --prompt-only` with specified options in background
3. Monitors the review process periodically
4. When complete, presents structured findings with severity levels
5. Creates todos for critical/high priority issues
6. Prompts user: "Would you like me to fix these issues?"

**Implementation:**

Parse the arguments provided after `/review-cr`:
- Arguments can be provided in any order
- Scan all arguments for `--base` flag: if found, extract next argument as base branch
- Check remaining arguments for review type (`uncommitted`, `committed`, or `all`)
- Default type: `all`
- Default base: repository default branch (no flag)

Validate base branch if specified:
- Before executing CodeRabbit, validate that the base branch exists
- Use: `git rev-parse --verify <branch>` to check branch existence
- If branch doesn't exist:
  - Message: "Base branch '<branch>' not found. Available branches: <list branches>"
  - Exit gracefully without running review
- After git validation succeeds, sanitize the branch name:
  - Use: `branch_safe=$(echo "$branch" | sed 's/[^a-zA-Z0-9._/-]//g')`
  - This removes any unsafe characters that could be used for command injection
  - Use `branch_safe` in all subsequent commands

Check for existing CodeRabbit processes:
- Before starting a new review, check if CodeRabbit is already running
- Use: `pgrep -f "coderabbit review"`
- If process exists:
  - Message: "A CodeRabbit review is already running in the background. Please wait for it to complete or kill the process before starting a new review."
  - Exit gracefully without starting new review

Execute the review:
```bash
coderabbit review --prompt-only --type <type> [--base <branch>]
```

Run this command in the background using the Bash tool with `run_in_background: true`.

Monitor progress:
- Use BashOutput tool to check for completion
- Check every 30 seconds until output contains final summary
- Maximum wait time: 45 minutes (90 checks)
- If BashOutput tool fails:
  - Wait 10 seconds and retry once
  - If retry fails, report error: "Unable to monitor review process. Check background processes with: ps aux | grep coderabbit"
- If maximum wait time exceeded:
  - Report: "Review exceeded 45 minute timeout. Terminating runaway process to prevent resource exhaustion..."
  - Terminate the process using graceful then forceful approach:
    1. Get process ID: `pid=$(pgrep -f "coderabbit review")`
    2. If PID found, attempt graceful termination: `kill -TERM $pid`
    3. Wait 5 seconds: `sleep 5`
    4. Check if still running: `pgrep -f "coderabbit review"`
    5. If still running, force termination: `kill -KILL $pid`
    6. Verify termination: `pgrep -f "coderabbit review"` should return nothing
  - Final message: "CodeRabbit process terminated after 45-minute timeout. This prevents runaway processes from consuming system resources indefinitely."
  - Exit with cleanup confirmation
- Estimated time: 7-30+ minutes depending on changeset size

Parse and present findings:
- Extract issues from --prompt-only output
- Group by severity: CRITICAL, HIGH, MEDIUM, LOW, INFO
- For each issue, show:
  - Severity badge (🔴 CRITICAL, 🟠 HIGH, 🟡 MEDIUM, 🔵 LOW, ⚪ INFO)
  - File path and line number
  - Issue description
  - Suggested fix approach (if provided)

Create todos for important issues:
- Use TodoWrite tool to create todos for CRITICAL and HIGH severity issues
- Format: "Fix [severity] in [file]:[line] - [brief description]"

Prompt for action:
"CodeRabbit review complete. Found X issues (Y critical, Z high).
Would you like me to fix these issues?"

**Error handling:**

If CodeRabbit CLI not found:
- Message: "CodeRabbit CLI not installed. Install with: curl -fsSL https://cli.coderabbit.ai/install.sh | sh"
- Exit gracefully

If not authenticated:
- Message: "Not authenticated with CodeRabbit. Run: coderabbit auth login"
- Exit gracefully

If no changes to review:
- Message: "No changes found to review. Make some changes first."
- Exit gracefully

If review takes longer than expected:
- Message at 5 minutes: "CodeRabbit is still analyzing... (this can take 7-30 minutes for large changesets)"
- Continue monitoring

**Configuration notes:**

CodeRabbit automatically reads context from:
- `~/.claude/CLAUDE.md` (your global instructions)
- `<project>/.claude/claude.md` (project-specific instructions)
- `<project>/.coderabbit.yaml` (CodeRabbit-specific configuration)

These files provide coding standards and preferences to the review process.
