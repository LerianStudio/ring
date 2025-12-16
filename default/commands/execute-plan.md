---
name: execute-plan
description: Execute plan in batches with review checkpoints
argument-hint: "[plan-file-path]"
---

Execute an existing implementation plan with controlled checkpoints and code review between batches. Supports autonomous one-go execution or batch mode with human review at each checkpoint.

## Usage

```
/execute-plan [plan-file-path]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `plan-file-path` | Yes | Path to the plan file (e.g., `docs/plans/2024-01-15-auth-feature.md`) |

## Examples

### Execute a Feature Plan
```
/execute-plan docs/plans/2024-01-15-oauth-integration.md
```
Loads and executes the OAuth integration plan with review checkpoints.

### Execute from Absolute Path
```
/execute-plan /Users/dev/project/docs/plans/2024-01-15-api-refactor.md
```
Executes a plan using its full path.

### Execute Latest Plan
```
/execute-plan docs/plans/2024-01-20-notification-system.md
```
Executes the most recent plan for the notification system feature.

## Process

### Step 1: Load and Review Plan
- Reads the plan file
- Critically reviews for any questions or concerns
- Raises issues with you before starting
- Creates TodoWrite to track progress

### Step 2: Choose Execution Mode (MANDATORY)
You will be asked to choose between:

| Mode | Behavior |
|------|----------|
| **One-go (autonomous)** | Executes all batches continuously with code review between each; no human review until completion |
| **Batch (with review)** | Executes one batch, pauses for human feedback after code review, then continues |

### Step 3: Execute Batch
- Default batch size: first 3 tasks
- Each task is marked in_progress, executed, then completed
- Dispatches to specialized agents when available:
  - Backend Go: `backend-engineer-golang`
  - Backend TypeScript: `backend-engineer-typescript`
  - Frontend React/Next.js/BFF: `frontend-bff-engineer-typescript`
  - Infrastructure: `devops-engineer`
  - Testing: `qa-analyst`
  - Reliability: `sre`

### Step 4: Run Code Review
After each batch, all 3 reviewers run in parallel:
- `code-reviewer` - Architecture and patterns
- `business-logic-reviewer` - Requirements and edge cases
- `security-reviewer` - OWASP and auth validation

**Issue handling by severity:**
| Severity | Action |
|----------|--------|
| Critical/High/Medium | Fix immediately, re-run all reviewers |
| Low | Add `TODO(review):` comment in code |
| Cosmetic/Nitpick | Add `FIXME(nitpick):` comment in code |

### Step 5: Report and Continue
**One-go mode:** Continues to next batch automatically, reports only at final completion.

**Batch mode:** Shows implementation summary, verification output, and code review results. Waits for your feedback before proceeding.

### Step 6: Complete Development
After all tasks complete:
- Uses `finishing-a-development-branch` skill
- Verifies tests pass
- Presents options for branch completion

## Related Commands/Skills

| Command/Skill | Relationship |
|---------------|--------------|
| `/write-plan` | Use first to create the plan file |
| `/brainstorm` | Use before writing-plans if design unclear |
| `writing-plans` | Creates the plan files this command executes |
| `requesting-code-review` | Called automatically after each batch |
| `finishing-a-development-branch` | Called at completion |

## Troubleshooting

### "No plan file found"
Ensure the path is correct. Plans are typically stored in `docs/plans/`. Use `ls docs/plans/` to list available plans.

### "Plan has critical gaps"
The plan was reviewed and found to have issues preventing execution. You'll be asked to clarify or revise the plan before proceeding.

### "Verification failed repeatedly"
Execution stops when a verification step fails multiple times. Review the output to determine if the plan needs revision or if there's an environmental issue.

### "Code review finds Critical issues"
All Critical, High, and Medium issues must be fixed before proceeding. The reviewers will re-run after fixes until the batch passes.

### Execution mode was not asked
If you're not prompted for execution mode, this is a violation of the skill protocol. The mode selection is mandatory regardless of any "just execute" or "don't wait" instructions.

### When NOT to use this command
- No plan exists - use `/write-plan` first
- Plan needs revision - use `/brainstorm` to refine the design
- Working on independent tasks in current session - use `subagent-driven-development` skill directly
