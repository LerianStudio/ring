---
name: defense-in-depth
description: |
  Multi-layer validation pattern - validates data at EVERY layer it passes through
  to make bugs structurally impossible, not just caught.

trigger: |
  - Bug caused by invalid data reaching deep layers
  - Single validation point can be bypassed
  - Need to prevent bug category, not just instance

skip_when: |
  - Validation already exists at all layers → check other issues
  - Simple input validation sufficient → add single check

related:
  complementary: [root-cause-tracing]
---

# Defense-in-Depth Validation

## Overview

When you fix a bug caused by invalid data, adding validation at one place feels sufficient. But that single check can be bypassed by different code paths, refactoring, or mocks.

**Core principle:** Validate at EVERY layer data passes through. Make the bug structurally impossible.

## Why Multiple Layers

Single validation: "We fixed the bug"
Multiple layers: "We made the bug impossible"

Different layers catch different cases:
- Entry validation catches most bugs
- Business logic catches edge cases
- Environment guards prevent context-specific dangers
- Debug logging helps when other layers fail

## The Four Layers

| Layer | Purpose | Example |
|-------|---------|---------|
| **1. Entry Point** | Reject invalid input at API boundary | `if (!workingDir \|\| !existsSync(workingDir)) throw new Error(...)` |
| **2. Business Logic** | Ensure data makes sense for operation | `if (!projectDir) throw new Error('projectDir required')` |
| **3. Environment Guards** | Prevent dangerous ops in contexts | `if (NODE_ENV === 'test' && !path.startsWith(tmpdir())) throw...` |
| **4. Debug Instrumentation** | Capture context for forensics | `logger.debug('About to git init', { directory, cwd, stack })` |

## Applying the Pattern

**Steps:** (1) Trace data flow (origin → error) (2) Map all checkpoints (3) Add validation at each layer (4) Test each layer (try to bypass layer 1, verify layer 2 catches it)

## Example

**Bug:** Empty `projectDir` caused `git init` in source code

**Flow:** Test setup (`''`) → `Project.create(name, '')` → `WorkspaceManager.createWorkspace('')` → `git init` in `process.cwd()`

**Layers added:** L1: `Project.create()` validates not empty/exists/writable | L2: `WorkspaceManager` validates not empty | L3: Refuse git init outside tmpdir in tests | L4: Stack trace logging

**Result:** 1847 tests passed, bug impossible to reproduce

## Key Insight

All four layers necessary - each caught bugs others missed: different code paths bypassed entry validation | mocks bypassed business logic | edge cases needed environment guards | debug logging identified structural misuse.

**Don't stop at one validation point.** Add checks at every layer.
