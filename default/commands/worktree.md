---
name: ring-default:worktree
description: Create isolated git worktree with interactive setup
argument-hint: "[branch-name]"
---

I'm using the using-git-worktrees skill to set up an isolated workspace for your feature work.

**This command will:**
1. Ask you for the feature/branch name
2. Auto-detect or ask about worktree directory location
3. Create the isolated worktree
4. Set up dependencies
5. Verify baseline tests pass

**The skill will systematically:**
- Check for existing `.worktrees/` or `worktrees/` directories
- Check CLAUDE.md for location preferences
- Verify .gitignore (for project-local directories)
- Auto-detect and run project setup (npm install, cargo build, etc.)
- Run baseline tests to ensure clean starting point

**First, let me ask you about your feature:**

Please use the AskUserQuestion tool to gather:

**Question 1:** "What is the name of your feature/branch?"
- Header: "Feature Name"
- This will be used for both the branch name and worktree directory name
- Examples: "auth-system", "user-profiles", "payment-integration"

After getting the feature name, follow the complete using-git-worktrees skill process:

1. **Check for existing directories** (priority order):
   - `.worktrees/` (preferred)
   - `worktrees/` (alternative)
   - If both exist, use `.worktrees/`

2. **Check CLAUDE.md** for worktree directory preferences

3. **If no directory exists and no CLAUDE.md preference**, ask user:
   - Option 1: `.worktrees/` (project-local, hidden)
   - Option 2: `~/.config/ring/worktrees/<project-name>/` (global location)

4. **Verify .gitignore** (if project-local directory):
   - MUST check if directory is in .gitignore
   - If NOT: Add to .gitignore immediately and commit
   - Per Jesse's rule: "Fix broken things immediately"

5. **Create worktree**:
   - Detect project name: `basename "$(git rev-parse --show-toplevel)"`
   - Create: `git worktree add <path> -b <branch-name>`
   - Navigate: `cd <path>`

6. **Run project setup** (auto-detect):
   - Node.js: `npm install` (if package.json exists)
   - Rust: `cargo build` (if Cargo.toml exists)
   - Python: `pip install -r requirements.txt` or `poetry install`
   - Go: `go mod download` (if go.mod exists)

7. **Verify clean baseline**:
   - Run appropriate test command for the project
   - If tests fail: Report failures and ask whether to proceed
   - If tests pass: Report ready

8. **Report completion**:
   ```
   Worktree ready at <full-path>
   Tests passing (N tests, 0 failures)
   Ready to implement <feature-name>
   ```

Follow the complete process defined in `skills/using-git-worktrees/SKILL.md`.
