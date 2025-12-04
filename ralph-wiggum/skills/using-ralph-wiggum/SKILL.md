---
name: using-ralph-wiggum
description: |
  Autonomous iterative loops using Stop hooks - Claude continuously works on
  a task until completion promise is emitted, with same prompt re-fed each iteration.

trigger: |
  - Well-defined task with clear success criteria
  - Task has objective verification (tests pass, requirements met)
  - Progress is visible in file changes
  - Want autonomous iteration without human intervention

skip_when: |
  - Design judgment required → use brainstorming
  - Subjective quality assessment → human review needed
  - Strategic pivoting may be needed → interactive approach
  - Success criteria unclear → clarify first
---

# Using Ralph Wiggum Loops

The ralph-wiggum plugin enables **autonomous iterative development** using Stop hooks. Instead of manually re-running prompts, Ralph creates a self-referential loop where Claude continuously works on a task until completion.

---

## Dependencies

Ralph requires certain tools to function. Check your dependencies before starting:

### Required

| Tool | Purpose | Check | Install |
|------|---------|-------|---------|
| **jq** | JSON parsing (transcripts) | `jq --version` | `brew install jq` (macOS) / `apt install jq` (Linux) |

### Recommended

| Tool | Purpose | Check | Install | Without It |
|------|---------|-------|---------|------------|
| **flock** | File locking (prevents race conditions) | `flock --version` | `brew install flock` (macOS) / `apt install util-linux` (Linux) | Ralph works but concurrent access may cause issues |
| **perl** | Multiline promise detection | `perl --version` | Usually pre-installed | Falls back to basic regex (single-line promises only) |

### Quick Dependency Check

Run this to verify your setup:

```bash
echo "=== Ralph Wiggum Dependency Check ===" && \
echo -n "jq: " && (command -v jq &>/dev/null && echo "✅ installed" || echo "❌ MISSING (required)") && \
echo -n "flock: " && (command -v flock &>/dev/null && echo "✅ installed" || echo "⚠️  missing (recommended)") && \
echo -n "perl: " && (command -v perl &>/dev/null && echo "✅ installed" || echo "⚠️  missing (recommended)")
```

**Note:** Ralph will warn you at runtime if optional dependencies are missing, but only once per session.

---

## How Ralph Works

```
User runs: /ralph-wiggum:ralph-loop "Task description" --completion-promise "DONE"
                    ↓
Plugin creates: .claude/ralph-loop-{session-id}.local.md (session-isolated state file)
                    ↓
Claude works on the task...
                    ↓
Session exit attempted
                    ↓
Stop hook intercepts → Checks for <promise>DONE</promise> in output
                    ↓
    ├── Promise found → Allow exit (task complete!)
    ├── Max iterations → Allow exit (safety limit)
    └── Neither → Block exit, re-feed original prompt → Loop continues
```

The key insight: **the prompt never changes** - Claude improves by reading its own previous work in modified files and git history.

---

## Available Commands

| Command | Purpose |
|---------|---------|
| `/ralph-wiggum:ralph-loop` | Start an iterative development loop |
| `/ralph-wiggum:cancel-ralph` | Cancel the active loop |
| `/ralph-wiggum:help` | Detailed technique guide and examples |

---

## Starting a Ralph Loop

```bash
/ralph-wiggum:ralph-loop "PROMPT" --max-iterations N --completion-promise "TEXT"
```

**Parameters:**
- `PROMPT` - Your task description (required, 10-100,000 characters)
- `--max-iterations N` - Safety limit (recommended, default: unlimited)
- `--completion-promise TEXT` - Phrase that signals completion

**Example:**
```bash
/ralph-wiggum:ralph-loop "Build a REST API for todos with CRUD operations and tests. Output <promise>COMPLETE</promise> when all tests pass." --completion-promise "COMPLETE" --max-iterations 30
```

---

## Writing Effective Prompts

### 1. Clear Completion Criteria

❌ **Bad:**
```
Build a todo API and make it good.
```

✅ **Good:**
```markdown
Build a REST API for todos.

Requirements:
- CRUD endpoints (GET, POST, PUT, DELETE)
- Input validation
- Test coverage > 80%
- README with API documentation

Output <promise>COMPLETE</promise> when ALL requirements are met.
```

### 2. Include Self-Correction

❌ **Bad:**
```
Write code for feature X.
```

✅ **Good:**
```markdown
Implement feature X following TDD:
1. Write failing tests
2. Implement feature
3. Run tests
4. If any fail, debug and fix
5. Repeat until all green
6. Output: <promise>DONE</promise>
```

### 3. Always Set Safety Limits

```bash
# RECOMMENDED: Always use --max-iterations
/ralph-wiggum:ralph-loop "Try feature X" --max-iterations 20 --completion-promise "DONE"

# Include stuck-handling in prompt:
"After 15 iterations if not complete:
 - Document blocking issues
 - List attempted approaches
 - Suggest alternatives"
```

---

## When to Use Ralph

### ✅ Good Fit (Ralph Excels)

| Task Type | Why It Works |
|-----------|--------------|
| "Make all tests pass" | Clear, verifiable success criteria |
| "Implement features from spec" | Additive work visible in files |
| "Fix CI pipeline errors" | Objective pass/fail feedback |
| Greenfield with clear requirements | Progress is self-evident |
| "Build X with tests" | Tests provide automatic verification |

**Key pattern:** Tasks where success is **objectively verifiable** and progress is **visible in files**.

### ❌ Poor Fit (Ralph Struggles)

| Task Type | Why It Struggles |
|-----------|------------------|
| "Design a good API" | Requires judgment, no objective criteria |
| "Refactor for maintainability" | Success is subjective |
| "Debug intermittent failure" | May not reproduce consistently |
| Exploratory/architectural work | Needs human course-correction |
| "Make it better" | No clear completion criteria |

**Key pattern:** Tasks requiring **design judgment**, **strategic pivoting**, or **subjective quality assessment**.

### Understanding Ralph's Limitations

Ralph's power comes from **prompt invariance** - the same prompt feeds every iteration. This is both strength and weakness:

**Strength:** Simple, deterministic, no prompt drift
**Weakness:** If the original prompt is flawed or ambiguous, Ralph iterates on a flawed foundation

Claude must infer "what to do next" entirely from file changes and git history. This works when:
- Changes are clearly visible in files
- The task is additive (build more features)
- Success criteria are objective

It struggles when:
- The issue is architectural (not visible in individual files)
- Previous attempts need explicit "don't do this again" memory
- The task requires strategic pivoting based on discoveries

---

## State Management

Ralph tracks state in `.claude/ralph-loop-{session-id}.local.md`:

```yaml
---
active: true
session_id: "a1b2c3d4"
iteration: 5
max_iterations: 30
completion_promise: "COMPLETE"
started_at: 2025-01-26T10:30:00Z
---

Original prompt here...
```

**Session Isolation:** Each Ralph loop gets a unique session ID, so you can run multiple Claude sessions in different directories without conflicts.

**Commands interact with this file:**
- `/ralph-wiggum:ralph-loop` creates it (with unique session ID)
- `/ralph-wiggum:cancel-ralph` finds and removes it
- Stop hook finds and updates it

---

## Safety Features

1. **Max Iterations** - Prevents infinite loops on impossible tasks
2. **Session-Isolated State** - Each loop has unique ID (`ralph-loop-{id}.local.md`)
3. **Active Loop Detection** - Prevents accidental overwrites of running loops
4. **Cancel Command** - Immediately stop any running loop
5. **Completion Promise** - Explicit signal that work is done
6. **Prompt Validation** - Enforces min (10 chars) and max (100,000 chars) prompt length
7. **Atomic File Operations** - State files use atomic write patterns to prevent corruption
8. **File Locking** - Uses flock (when available) to prevent race conditions

---

## Philosophy

Ralph embodies key principles:

1. **Iteration > Perfection** - Don't aim for perfect first try; let the loop refine
2. **Failures Are Data** - Use failures to improve the prompt
3. **Persistence Wins** - Keep trying until success
4. **Operator Skill Matters** - Success depends on writing good prompts

---

## Integration with Ring

Ralph complements other Ring workflows:

- Use **brainstorming** to design the task before starting a Ralph loop
- Include **TDD patterns** in your Ralph prompt for self-verification
- After Ralph completes, run **/ring-default:codereview** for code quality check

**Example workflow:**
```
1. /ring-default:brainstorm "TODO API design"
2. /ralph-wiggum:ralph-loop "Implement TODO API per design..." --max-iterations 30
3. /ring-default:codereview src/
4. /ring-default:commit "feat: add TODO API"
```

---

## Troubleshooting

**Loop not starting?**
- Check if `.claude/ralph-loop-*.local.md` was created
- Verify the prompt is properly quoted
- Check for "already active" error (cancel existing loop first)
- Ensure prompt is at least 10 characters (minimum length)
- Ensure prompt is under 100,000 characters (maximum length)

**Loop not stopping?**
- Ensure `<promise>TEXT</promise>` exactly matches `--completion-promise`
- Check iteration count hasn't hit max

**Want to cancel?**
- Run `/ralph-wiggum:cancel-ralph`
- Or manually: `rm .claude/ralph-loop-*.local.md`

**Multiple sessions?**
- Each session gets its own state file with unique ID
- Only one loop per directory at a time (safety feature)

---

## Learn More

- Original technique: https://ghuntley.com/ralph/
- Ralph Orchestrator: https://github.com/mikeyobrien/ralph-orchestrator
