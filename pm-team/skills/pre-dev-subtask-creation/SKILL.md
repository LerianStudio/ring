---
name: pre-dev-subtask-creation
description: |
  Gate 8: Zero-context implementation steps - 2-5 minute atomic subtasks with
  complete code, exact commands, TDD pattern. Large Track only.

trigger: |
  - Tasks passed Gate 7 validation
  - Need absolute implementation clarity
  - Creating work for engineers with zero codebase context
  - Large Track workflow (2+ day features)

skip_when: |
  - Small Track workflow → execute tasks directly
  - Tasks simple enough without breakdown
  - Tasks not validated → complete Gate 7 first

sequence:
  after: [pre-dev-task-breakdown]
  before: [executing-plans, subagent-driven-development]
---

# Subtask Creation - Bite-Sized, Zero-Context Steps

## Overview

Write comprehensive implementation subtasks assuming the engineer has zero context for our codebase. Each subtask breaks down into 2-5 minute steps following RED-GREEN-REFACTOR. Complete code, exact commands, explicit verification. **DRY. YAGNI. TDD. Frequent commits.**

**Announce at start:** "I'm using the pre-dev-subtask-creation skill to create implementation subtasks."

**Context:** This should be run after Gate 7 validation (approved tasks exist).

**Save subtasks to:** `docs/pre-development/subtasks/T-[task-id]/ST-[task-id]-[number]-[description].md`

## When to Use

Use this skill when:
- Tasks have passed Gate 7 validation
- About to write implementation instructions
- Tempted to write "add validation here..." (placeholder)
- Tempted to say "update the user service" (which part?)
- Creating work units for developers or AI agents

**When NOT to use:**
- Before Gate 7 validation
- For trivial changes (<10 minutes total)
- When engineer has full context (rare)

## Foundational Principle

**Every subtask must be completable by anyone with zero context about the system.**

Requiring context creates bottlenecks, onboarding friction, and integration failures.

**Subtasks answer**: Exactly what to create/modify, with complete code and verification.
**Subtasks never answer**: Why the system works this way (context is removed).

## Bite-Sized Step Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Subtask Document Header

**Every subtask MUST start with this header:**

```markdown
# ST-[task-id]-[number]: [Subtask Name]

> **For Agents:** REQUIRED SUB-SKILL: Use ring:executing-plans to implement this subtask step-by-step.

**Goal:** [One sentence describing what this builds]

**Prerequisites:**
```bash
# Verification commands
cd /path/to/project
npm list dependency-name
# Expected output: dependency@version
```

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

---
```

## Step Structure (TDD Cycle)

```markdown
### Step 1: Write the failing test

```typescript
// tests/exact/path/test.ts
import { functionName } from '../src/module';

describe('FeatureName', () => {
  it('should do specific behavior', () => {
    const result = functionName(input);
    expect(result).toBe(expected);
  });
});
```

### Step 2: Run test to verify it fails

```bash
npm test tests/exact/path/test.ts
# Expected output: FAIL - "functionName is not defined"
```

### Step 3: Write minimal implementation

```typescript
// src/exact/path/module.ts
export function functionName(input: string): string {
  return expected;
}
```

### Step 4: Run test to verify it passes

```bash
npm test tests/exact/path/test.ts
# Expected output: PASS - 1 test passed
```

### Step 5: Commit

```bash
git add tests/exact/path/test.ts src/exact/path/module.ts
git commit -m "feat: add specific feature"
```
```

## Explicit Rules

### ✅ DO Include in Subtasks
- Exact file paths (absolute or from root)
- Complete file contents (if creating)
- Complete code snippets (if modifying)
- All imports and dependencies
- Step-by-step TDD cycle (numbered)
- Verification commands (copy-pasteable)
- Expected output (exact)
- Rollback procedures (exact commands)
- Prerequisites (what must exist first)

### ❌ NEVER Include in Subtasks
- Placeholders: "...", "TODO", "implement here"
- Vague instructions: "update the service", "add validation"
- Assumptions: "assuming setup is done"
- Context requirements: "you need to understand X first"
- Incomplete code: "add the rest yourself"
- Missing imports: "import necessary packages"
- Undefined success: "make sure it works"
- No verification: "test it manually"

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "The developer will figure out imports" | Imports are context. Provide them explicitly. |
| "TODO comments are fine for simple parts" | TODOs require decisions. Make them now. |
| "They'll know which service to update" | They won't. Specify the exact file path. |
| "The verification steps are obvious" | Obvious ≠ documented. Write exact commands. |
| "Rollback isn't needed for simple changes" | Simple changes fail too. Always provide rollback. |
| "This needs system understanding" | Then you haven't removed context. Simplify more. |
| "I'll provide the template, they fill it" | Templates are incomplete. Provide full code. |
| "The subtask description explains it" | Descriptions need interpretation. Give exact steps. |
| "They can look at similar code for reference" | That's context. Make subtask self-contained. |
| "This is too detailed, we're not that formal" | Detailed = parallelizable = faster. Be detailed. |
| "Steps are too small, feels like hand-holding" | Small steps = verifiable progress. Stay small. |

## Red Flags - STOP

If you catch yourself writing any of these in a subtask, **STOP and rewrite**:

- Code placeholders: `...`, `// TODO`, `// implement X here`
- Vague file references: "the user service", "the auth module"
- Assumption phrases: "assuming you have", "make sure you"
- Incomplete imports: "import required packages"
- Missing paths: Not specifying where files go
- Undefined verification: "test that it works"
- Steps longer than 5 minutes
- Context dependencies: "you need to understand X"
- No TDD cycle in implementation steps

**When you catch yourself**: Expand the subtask until it's completely self-contained.

## Gate 8 Validation Checklist

Before declaring subtasks ready:

**Atomicity:**
- [ ] Each step has single responsibility (2-5 minutes)
- [ ] No step depends on understanding system architecture
- [ ] Subtasks can be assigned to anyone (developer or AI)

**Completeness:**
- [ ] All code provided in full (no placeholders)
- [ ] All file paths are explicit and exact
- [ ] All imports listed explicitly
- [ ] All prerequisites documented
- [ ] TDD cycle followed in every implementation

**Verifiability:**
- [ ] Test commands are copy-pasteable
- [ ] Expected output is exact (not subjective)
- [ ] Commands run from project root (or specify directory)

**Reversibility:**
- [ ] Rollback commands provided
- [ ] Rollback doesn't require system knowledge

**Gate Result:**
- ✅ **PASS**: All checkboxes checked → Ready for implementation
- ⚠️ **CONDITIONAL**: Add missing details → Re-validate
- ❌ **FAIL**: Too much context required → Decompose further

## Example Subtask

```markdown
# ST-001-01: Create User Model with Validation

> **For Agents:** REQUIRED SUB-SKILL: Use ring:executing-plans to implement this subtask step-by-step.

**Goal:** Create a User model class with email and password validation in the auth service.

**Prerequisites:**
```bash
cd /path/to/project
npm list zod bcrypt
# Expected: zod@3.22.4, bcrypt@5.1.1
```

**Files:**
- Create: `src/domain/entities/User.ts`
- Create: `src/domain/entities/__tests__/User.test.ts`
- Modify: `src/domain/entities/index.ts`

---

### Step 1: Write the failing test

Create file: `src/domain/entities/__tests__/User.test.ts`

```typescript
import { UserModel } from '../User';

describe('UserModel', () => {
  const validUserData = {
    email: 'test@example.com',
    password: 'securePassword123',
    firstName: 'John',
    lastName: 'Doe'
  };

  it('should create user with valid data', () => {
    const user = new UserModel(validUserData);
    expect(user.getData().email).toBe(validUserData.email);
  });

  it('should throw on invalid email', () => {
    const invalidData = { ...validUserData, email: 'invalid' };
    expect(() => new UserModel(invalidData)).toThrow('Invalid email format');
  });
});
```

### Step 2: Run test to verify it fails

```bash
npm test src/domain/entities/__tests__/User.test.ts
# Expected: FAIL - "Cannot find module '../User'"
```

### Step 3: Write minimal implementation

Create file: `src/domain/entities/User.ts`

```typescript
import { z } from 'zod';
import bcrypt from 'bcrypt';

export const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email('Invalid email format'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  firstName: z.string().min(1, 'First name is required'),
  lastName: z.string().min(1, 'Last name is required'),
  createdAt: z.date().default(() => new Date()),
  updatedAt: z.date().default(() => new Date())
});

export type User = z.infer<typeof UserSchema>;

export class UserModel {
  private data: User;

  constructor(data: Partial<User>) {
    this.data = UserSchema.parse({
      ...data,
      id: data.id || crypto.randomUUID(),
      createdAt: data.createdAt || new Date(),
      updatedAt: data.updatedAt || new Date()
    });
  }

  async hashPassword(): Promise<void> {
    const saltRounds = 10;
    this.data.password = await bcrypt.hash(this.data.password, saltRounds);
  }

  async comparePassword(candidatePassword: string): Promise<boolean> {
    return bcrypt.compare(candidatePassword, this.data.password);
  }

  getData(): User {
    return this.data;
  }
}
```

### Step 4: Run test to verify it passes

```bash
npm test src/domain/entities/__tests__/User.test.ts
# Expected: PASS - 2 tests passed
```

### Step 5: Update exports

Modify file: `src/domain/entities/index.ts`

Add or append:
```typescript
export { UserModel, UserSchema, type User } from './User';
```

### Step 6: Verify type checking

```bash
npm run typecheck
# Expected: No errors
```

### Step 7: Commit

```bash
git add src/domain/entities/User.ts src/domain/entities/__tests__/User.test.ts src/domain/entities/index.ts
git commit -m "feat: add User model with validation

- Add Zod schema for user validation
- Implement password hashing with bcrypt
- Add comprehensive tests"
```

### Rollback

If issues occur:
```bash
rm src/domain/entities/User.ts
rm src/domain/entities/__tests__/User.test.ts
git checkout -- src/domain/entities/index.ts
git status
```
```

## Confidence Scoring

Use this to adjust your interaction with the user:

```yaml
Confidence Factors:
  Step Atomicity: [0-30]
    - All steps 2-5 minutes: 30
    - Most steps appropriately sized: 20
    - Steps too large or vague: 10

  Code Completeness: [0-30]
    - Zero placeholders, all code complete: 30
    - Mostly complete with minor gaps: 15
    - Significant placeholders or TODOs: 5

  Context Independence: [0-25]
    - Anyone can execute without questions: 25
    - Minor context needed: 15
    - Significant domain knowledge required: 5

  TDD Coverage: [0-15]
    - All implementation follows RED-GREEN-REFACTOR: 15
    - Most steps include tests: 10
    - Limited test coverage: 5

Total: [0-100]

Action:
  80+: Generate complete subtasks autonomously
  50-79: Present approach options for complex steps
  <50: Ask about codebase structure and patterns
```

## Execution Handoff

After creating subtasks, offer execution choice:

**"Subtasks complete and saved to `docs/pre-development/subtasks/T-[id]/`. Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per subtask, review between subtasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use ring:subagent-driven-development
- Stay in this session
- Fresh subagent per subtask + code review

**If Parallel Session chosen:**
- Guide them to open new session in worktree
- **REQUIRED SUB-SKILL:** New session uses ring:executing-plans

## Quality Self-Check

Before declaring subtasks complete, verify:
- [ ] Every step is truly atomic (2-5 minutes)
- [ ] Zero context required to complete any step
- [ ] All code is complete (no "...", "TODO", placeholders)
- [ ] All file paths are explicit (absolute or from root)
- [ ] All imports are listed explicitly
- [ ] TDD cycle followed (test → fail → implement → pass → commit)
- [ ] Verification steps included with exact commands
- [ ] Expected output specified for every command
- [ ] Rollback plans provided with exact commands
- [ ] Prerequisites documented (what must exist first)
- [ ] Gate 8 validation checklist 100% complete

## The Bottom Line

**If you wrote a subtask with "TODO" or "..." or "add necessary imports", delete it and rewrite with complete code.**

Subtasks are not instructions. Subtasks are complete, copy-pasteable implementations following TDD.

- "Add validation" is not a step. [Complete validation code with test] is a step.
- "Update the service" is not a step. [Exact file path + exact code changes with test] is a step.
- "Import necessary packages" is not a step. [Complete list of imports] is a step.

Every subtask must be completable by someone who:
- Just joined the team yesterday
- Has never seen the codebase before
- Doesn't know the business domain
- Won't ask questions (you're unavailable)
- Follows TDD religiously

If they can't complete it with zero questions while following RED-GREEN-REFACTOR, **it's not atomic enough.**

**Remember: DRY. YAGNI. TDD. Frequent commits.**
