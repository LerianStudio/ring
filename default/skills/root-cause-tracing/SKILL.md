---
name: ring-default:root-cause-tracing
description: |
  Backward call-chain tracing - systematically trace bugs from error location back
  through call stack to original trigger. Adds instrumentation when needed.

trigger: |
  - Error happens deep in execution (not at entry point)
  - Stack trace shows long call chain
  - Unclear where invalid data originated
  - systematic-debugging Phase 1 leads you here

skip_when: |
  - Bug at entry point → use systematic-debugging directly
  - Haven't started investigation → use systematic-debugging first
  - Root cause is obvious → just fix it

sequence:
  after: [systematic-debugging]

related:
  complementary: [systematic-debugging]
---

# Root Cause Tracing

## Overview

Bugs often manifest deep in the call stack (git init in wrong directory, file created in wrong location, database opened with wrong path). Your instinct is to fix where the error appears, but that's treating a symptom.

**Core principle:** Trace backward through the call chain until you find the original trigger, then fix at the source.

## When to Use

**Use root-cause-tracing when:**
- Error happens deep in execution (not at entry point)
- Stack trace shows long call chain
- Unclear where invalid data originated
- systematic-debugging Phase 1 leads you here

**Relationship with systematic-debugging:**
- root-cause-tracing is a **SUB-SKILL** of systematic-debugging
- Use during **systematic-debugging Phase 1, Step 5** (Trace Data Flow)
- Can also use standalone if you KNOW bug is deep-stack issue
- After tracing to source, **return to systematic-debugging Phase 2**

**When NOT to use:**
- Bug appears at entry point → Use systematic-debugging Phase 1 directly
- You haven't started systematic-debugging yet → Start there first
- Root cause is obvious → Just fix it
- Still gathering evidence → Continue systematic-debugging Phase 1

## The Tracing Process

1. **Observe Symptom:** `Error: git init failed in /Users/jesse/project/packages/core`
2. **Find Immediate Cause:** `await execFileAsync('git', ['init'], { cwd: projectDir })`
3. **Ask: What Called This?** `WorktreeManager.createSessionWorktree(projectDir)` → `Session.initializeWorkspace()` → `Session.create()` → test at `Project.create()`
4. **Keep Tracing Up:** `projectDir = ''` (empty!) → resolves to `process.cwd()` → source code directory!
5. **Find Original Trigger:** `const context = setupCoreTest()` returns `{ tempDir: '' }` → accessed before beforeEach!

## Adding Stack Traces

When you can't trace manually, add instrumentation before the problematic operation:
```typescript
console.error('DEBUG git init:', { directory, cwd: process.cwd(), stack: new Error().stack });
```

**Critical:** Use `console.error()` in tests (logger may not show). Run: `npm test 2>&1 | grep 'DEBUG'`

**Analyze:** Look for test file names, line numbers, patterns (same test? same parameter?).

## Finding Which Test Causes Pollution

If something appears during tests but you don't know which test:

Use the bisection script: @find-polluter.sh

```bash
./find-polluter.sh '.git' 'src/**/*.test.ts'
```

Runs tests one-by-one, stops at first polluter. See script for usage.

## Real Example: Empty projectDir

**Symptom:** `.git` in `packages/core/` (source code)
**Trace chain:** `git init` in `process.cwd()` ← empty cwd ← WorktreeManager ← Session.create() ← test accessed `context.tempDir` before beforeEach ← `setupCoreTest()` returns `{ tempDir: '' }`
**Root cause:** Top-level variable initialization accessing empty value
**Fix:** Made tempDir a getter that throws if accessed before beforeEach
**Defense-in-depth:** (1) Project.create() validates (2) WorkspaceManager validates (3) NODE_ENV guard (4) Stack trace logging

## Key Principle

**Flow:** Found immediate cause → Can trace up? (yes → trace backwards) → Is this source? (no → keep tracing | yes → fix at source) → Add validation at each layer → Bug impossible

**NEVER fix just where the error appears.** Trace back to find the original trigger.

## Stack Trace Tips

- **In tests:** `console.error()` not logger (may be suppressed)
- **Before operation:** Log before dangerous op, not after fail
- **Include context:** Directory, cwd, env vars, timestamps
- **Capture stack:** `new Error().stack` shows complete chain

## Real-World Impact

5-level trace → fixed at source (getter validation) → 4 layers defense → 1847 tests, zero pollution
