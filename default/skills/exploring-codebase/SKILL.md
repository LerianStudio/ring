---
name: ring-default:exploring-codebase
description: |
  Autonomous two-phase codebase exploration - first discovers natural perspectives
  (layers, components, boundaries), then dispatches adaptive deep-dive explorers
  based on what was discovered. Synthesizes findings into actionable insights.

trigger: |
  - Need to understand how a feature/system works across the codebase
  - Starting work on unfamiliar codebase or component
  - Planning changes that span multiple layers/components
  - User asks "how does X work?" for non-trivial X
  - Need architecture understanding before implementation

skip_when: |
  - Pure reference lookup (function signature, type definition)
  - Checking if specific file exists (yes/no question)
  - Reading error message from known file location

  WARNING: These are NOT valid skip reasons:
  - "I already know the architecture" → Prior knowledge is incomplete
  - "Simple question about location" → Location without context is incomplete
  - "Production emergency, no time" → High stakes demand MORE rigor
  - "Colleague told me structure" → High-level ≠ implementation details

related:
  similar: [ring-default:dispatching-parallel-agents, ring-default:systematic-debugging]
  sequence_after: [ring-default:brainstorming]
  sequence_before: [ring-default:writing-plans, ring-default:executing-plans]
---

# Autonomous Two-Phase Codebase Exploration

## Overview

Traditional exploration assumes structure upfront or explores sequentially. This skill takes an autonomous two-phase approach: **discover** the natural perspectives of the codebase first, then **deep dive** into each discovered perspective with targeted explorers.

**Core principle:** Let the codebase reveal its own structure, then explore each structure element thoroughly with adaptive parallel agents.

**MANDATORY ANNOUNCEMENT at start:**

"I'm using the exploring-codebase skill to autonomously discover and explore the codebase structure.

Before proceeding, I've checked the Red Flags table and confirmed:
- [X] Production pressure makes me WANT to skip discovery → Using skill anyway
- [X] I think I 'already know' the structure → Discovery will validate assumptions
- [X] This seems like a simple question → Location without context is incomplete
- [X] Colleague gave me high-level info → Discovery finds what they forgot

The skill's core principle: **When pressure is highest, systematic approach matters most.**"

## 🚨 Red Flags: When You're About to Make a Mistake

**STOP and use this skill if you catch yourself thinking:**

| Red Flag Thought | What It Means | Do This Instead |
|------------------|---------------|-----------------|
| "I already know this architecture" | ⚠️ Dunning-Kruger | Run discovery to validate assumptions |
| "Grep is faster for this simple question" | ⚠️ Optimizing for feeling productive | One exploration > multiple follow-ups |
| "Production is down, no time for process" | ⚠️ Panic mode | High stakes demand MORE rigor |
| "Colleague told me the structure" | ⚠️ Trusting abstractions | Discovery finds what they forgot |
| "Being pragmatic means skipping this" | ⚠️ Conflating speed with value | Real pragmatism = doing it right |
| "This is overkill for..." | ⚠️ Underestimating complexity | Incomplete understanding compounds |
| "I'll explore progressively if I get stuck" | ⚠️ Reactive vs proactive | Discovery prevents getting stuck |
| "Let me just quickly check..." | ⚠️ Ad-hoc investigation trap | Systematic > ad-hoc |

**If 2+ red flags triggered: YOU NEED THIS SKILL.**

## 💥 Violation Consequences: Real Costs of Skipping

**"What's the worst that could happen if I skip discovery?"**

### Consequence 1: The Cascade Effect
**Scenario:** Skip discovery → Fix in wrong component → Break integration → New production issue

**Example:**
- Bug: "Account creation failing"
- Assumption: "It's in onboarding component"
- Reality: Transaction component has new validation that breaks onboarding
- Your fix: Modify onboarding (wrong component)
- Result: Original bug persists, NEW bug in onboarding, 2 issues instead of 1

**Discovery would have revealed:** Transaction component owns the validation now.

### Consequence 2: The Multiple Round-Trip Effect
**Scenario:** Grep for location → Answer question → User asks follow-up → Grep again → Another follow-up

**Example:**
- Q1: "Where is validation?" → Grep → Answer: `validation.go:45`
- Q2: "How does it integrate?" → Read files → Answer: "Called from use case"
- Q3: "What else validates?" → Grep again → Answer: "Assert package + HTTP layer"
- **Total: 3 round trips, 15 minutes, incomplete mental model**

**Exploration would have provided:** All answers in one comprehensive document, 10 minutes total.

### Consequence 3: The Stale Knowledge Effect
**Scenario:** "I already know" → Work based on old mental model → Code has changed → Wrong implementation

**Example:**
- Your knowledge: "3 components (onboarding, transaction, crm)"
- Reality: New `audit` component added last month for compliance
- Your fix: Modify account creation in onboarding
- Missing: Audit component now logs all account operations
- Result: Account created but not audited, compliance violation

**Discovery would have revealed:** 4 components now, audit is mandatory.

### Consequence 4: The Hidden Dependencies Effect
**Scenario:** Skip discovery → Miss shared libraries → Duplicate code → Technical debt

**Example:**
- Task: Add account validation rule
- Grep finds: `create-account.go` has validation
- You add: New validation in same file
- Discovery would reveal: `pkg/validator/account.go` has shared validation library
- Result: Duplicate logic, inconsistent validation across codebase

**Discovery would have revealed:** Centralized validation library for reuse.

### Cost Summary Table

| Skip Reason | Time "Saved" | Actual Cost | Net Loss |
|-------------|--------------|-------------|----------|
| "I already know" | 6-10 min | 2+ hours debugging stale knowledge | -110 to -114 min |
| "Simple question" | 6-10 min | 3 round trips × 5 min each = 15 min | -5 to -9 min |
| "Production emergency" | 6-10 min | Wrong fix + cascade = 2+ hours | -110 to -114 min |
| "Colleague told me" | 6-10 min | Missing component/library = 1+ hour rework | -50 to -54 min |

**Pattern:** Every "time-saving" skip costs more time than it saves.**

## The Two-Phase Flow

### Phase 1: Discovery Pass (Meta-Exploration)
**Goal:** Understand "What IS this codebase?"

Launch 3-4 **discovery agents** to identify:
- Architecture pattern (hexagonal, layered, microservices, etc.)
- Major components/modules
- Natural boundaries and layers
- Organization principles
- Key technologies and frameworks

**Output:** Structural map of the codebase

### Phase 2: Deep Dive Pass (Adaptive Exploration)
**Goal:** Understand "How does [target] work in each discovered area?"

Based on Phase 1 discoveries, launch **N targeted explorers** (where N adapts):
- One explorer per discovered perspective/component/layer
- Each explorer focuses on the target within their scope
- Number and type of explorers match codebase structure

**Output:** Comprehensive understanding of target across all perspectives

## When to Use

**Decision flow:**
- Need codebase understanding? → Is it trivial (single file/function)? → Yes = Use Read/Grep directly
- No → Is it unfamiliar territory or spans multiple areas? → Yes = **Two-phase exploration**
- Are you about to make changes spanning multiple components? → Yes = **Two-phase exploration**

**Use when:**
- Understanding how a feature works in an unfamiliar codebase
- Starting work on new component/service
- Planning architectural changes
- Need to find where to implement new functionality
- User asks "how does X work?" for complex X in unknown codebase

**Don't use when:**
- Pure reference lookup: "What's the signature of function X?"
- File existence check: "Does utils.go exist?"
- Reading known error location: "Show me line 45 of errors.go"

**COMMON TRAPS - These SEEM like valid skip reasons but are NOT:**

### ❌ Trap 1: "Simple Question About Location"
**Rationalization:** "User just asked 'where is X?' - grep is faster"

**Reality:** Location questions lead to "how does X work?" next
- Question: "Where is validation logic?"
- Grep answer: `validation.go:45`
- Follow-up: "How does it integrate with the system?"
- Follow-up: "What else validates this?"
- **Result:** 3 questions, incomplete picture, wasted time

**Counter:** Run exploration once, answer current + future questions.

### ❌ Trap 2: "I Already Know the Architecture"
**Rationalization:** "I worked here before, discovery is redundant"

**Reality:** Prior knowledge is dangerously incomplete
- You know high-level (components exist)
- You don't know details (how they're wired, what changed)
- Assumptions about "known" code cause most bugs

**Counter:** Discovery validates assumptions and reveals what changed.

### ❌ Trap 3: "Production Emergency, No Time"
**Rationalization:** "Production is down, skip the process"

**Reality:** High stakes demand MORE rigor, not less
- 6-10 min discovery prevents hours of wrong assumptions
- Production bugs from incomplete context cost >> discovery time
- "I know where to look" under stress = peak Dunning-Kruger

**Counter:** See "When Pressure is Highest" section below.

### ❌ Trap 4: "Colleague Told Me Structure"
**Rationalization:** "They said '3 microservices', why rediscover?"

**Reality:** High-level descriptions miss critical details
- "3 microservices" doesn't mention shared libraries, background jobs, API gateways
- Mental models are abstractions, not complete maps
- People forget to mention "obvious" infrastructure

**Counter:** Use colleague info as validation context, not replacement for discovery.

## When Pressure is Highest, Use Skill Most

**CRITICAL INSIGHT: Production emergencies DEMAND systematic understanding.**

### The Emergency Trap

**False logic:** "Production down → Skip process → Fix faster"
**True logic:** "Production down → Need accuracy → Use systematic approach"

### Why Discovery Matters MORE Under Pressure

| Shortcut Path | Systematic Path |
|---------------|-----------------|
| Grep "CreateAccount" (30 sec) | Run two-phase exploration (6-10 min) |
| Read 2-3 files (2 min) | Get complete architecture + target impl |
| Make assumption-based fix (10 min) | Fix with full context (5 min) |
| Fix breaks something else (2 hours) | Fix correct first time |
| **Total: 2+ hours + new bugs** | **Total: 15-20 minutes, done right** |

### The "Surgeon Textbook" Analogy is Wrong

**Bad analogy:** "Surgeon doesn't read textbook while patient bleeds"
**Correct analogy:** "Surgeon checks vitals before operating"

Discovery is NOT reading theory - it's gathering critical context:
- ✅ Discovery = Checking patient vitals (essential context)
- ❌ Reading textbooks = Reading unnecessary theory

**You wouldn't skip vitals because "emergency" - same principle applies here.**

### Production Emergency Protocol

When production is down:

1. **Acknowledge the pressure** - "This is urgent, I feel pressure to skip discovery"
2. **Recognize the trap** - "That pressure is EXACTLY when I need systematic approach"
3. **Invest 6-10 minutes** - Run two-phase exploration
4. **Fix with confidence** - Full context prevents cascading failures

**Reality check:** If you don't have 6-10 minutes for discovery, you don't have 2+ hours to undo wrong fixes.

## Real vs False Pragmatism

### False Pragmatism (Shortcuts that Backfire)

| Shortcut | Seems Pragmatic | Actual Result |
|----------|-----------------|---------------|
| "Skip discovery, I already know" | Saves 6-10 min | Hours debugging wrong assumptions |
| "Grep for simple questions" | Faster than exploration | Multiple follow-up questions, incomplete picture |
| "Production emergency, no process" | Fixes faster | Wrong fix, breaks more things |
| "Colleague told me structure" | Use existing knowledge | Miss shared libs, background jobs, actual impl |

### Real Pragmatism (Invest to Save)

| Systematic Approach | Costs | Saves |
|---------------------|-------|-------|
| 6-10 min two-phase exploration | 6-10 minutes | Hours of debugging wrong assumptions |
| Complete understanding first | Discovery time | Multiple follow-up questions |
| Systematic under pressure | Feeling "slow" | Fixing wrong thing, cascading failures |
| Validate colleague's mental model | Discovery vs assumption | Missing critical infrastructure |

**Real pragmatism = Doing it right when stakes are high.**

**False pragmatism = Taking shortcuts that create bigger problems.**

### When Pragmatism Tells You to Skip...

If you think "being pragmatic means skipping this," ask:

1. **Am I conflating "fast" with "good"?** Speed without accuracy is just fast failure.
2. **Am I optimizing for feeling productive?** Grep gives quick dopamine, but incomplete understanding.
3. **Am I making excuses under pressure?** High stakes demand MORE rigor, not less.
4. **Am I assuming I know more than I do?** Dunning-Kruger peaks under stress.

**If you answered yes to any: Use the skill anyway.**

## Rationalization Table

When you're tempted to skip the skill, check this table:

| Rationalization | Why It Feels Right | Why It's Wrong | Counter |
|-----------------|--------------------|-----------------|---------|
| **"I already know the architecture"** | You worked here before | Prior knowledge is high-level abstractions | Discovery reveals what you don't know to ask |
| **"Simple question, grep is faster"** | Just need a file location | Leads to follow-ups, incomplete picture | One exploration answers current + future questions |
| **"Production emergency, no time"** | Every second counts | Wrong fix wastes hours, creates new bugs | 6-10 min discovery prevents hours of wrong assumptions |
| **"Colleague told me the structure"** | They work here, they'd know | Mental models miss details (shared libs, jobs) | Use as validation context, not replacement |
| **"Being pragmatic not dogmatic"** | Process shouldn't be rigid | Shortcuts under pressure cause bigger problems | Real pragmatism = right approach when stakes high |
| **"Match tool to scope"** | Simple task = simple tool | Context-free answer requires follow-ups | Comprehensive once > multiple partial searches |
| **"Skip discovery to save time"** | 3-5 min vs 6-10 min | Saving 5 min, losing hours on wrong assumptions | False economy - incomplete understanding compounds |
| **"Progressive investigation works"** | Start narrow, expand if stuck | Ad-hoc misses systematic patterns | Discovery first prevents getting stuck |

## Process

Copy this checklist to track progress:

```
Two-Phase Exploration Progress:
- [ ] Phase 0: Scope Definition (exploration target identified)
- [ ] Phase 1: Discovery Pass (structure discovered - 3-4 agents)
- [ ] Phase 2: Deep Dive Pass (N adaptive explorers launched)
- [ ] Phase 3: Result Collection (all agents completed)
- [ ] Phase 4: Synthesis (discovery + deep dive integrated)
- [ ] Phase 5: Action Recommendations (next steps identified)
```

## Phase 0: Scope Definition

**Step 0.1: Identify Exploration Target**

From user request, extract:
- **Core subject:** What feature/system/component to explore?
- **Context clue:** Why are they asking? (planning change, debugging, learning)
- **Depth needed:** Surface understanding or comprehensive dive?

**Step 0.2: Set Exploration Boundaries**

Define scope to keep agents focused:
- **Include:** Directories/components relevant to target
- **Exclude:** Build config, vendor code, generated files (unless specifically needed)
- **Target specificity:** "account creation" vs "entire onboarding service"

## Phase 1: Discovery Pass (Meta-Exploration)

**Goal:** Discover the natural structure of THIS codebase

**Step 1.1: Launch Discovery Agents in Parallel**

**CRITICAL: Single message with 3-4 Task tool calls**

Dispatch discovery agents simultaneously:

```
Task(subagent_type="Explore", description="Architecture discovery",
     prompt="[Architecture Discovery prompt]")

Task(subagent_type="Explore", description="Component discovery",
     prompt="[Component Discovery prompt]")

Task(subagent_type="Explore", description="Layer discovery",
     prompt="[Layer Discovery prompt]")

Task(subagent_type="Explore", description="Organization discovery",
     prompt="[Organization Discovery prompt]")
```

See **Discovery Agent Prompts** section below for templates.

**Step 1.2: Collect Discovery Results**

Wait for all discovery agents to complete. Extract from results:

**Structural Elements:**
- Architecture pattern(s) used
- List of major components/services
- Layers within components (if applicable)
- Directory organization principle
- Technology stack per component

**Perspective Matrix:**
Create a matrix of discovered perspectives:
```
Components: [A, B, C]
Layers (per component): [HTTP, UseCase, Repository, Domain]
Boundaries: [Component boundaries, Layer boundaries]
Organization: [By feature, By layer, By domain]
```

**Step 1.3: Determine Deep Dive Strategy**

Based on discoveries, decide exploration approach:

| Discovery Result | Deep Dive Strategy |
|------------------|-------------------|
| 3 components × 4 layers | Launch 3 explorers (one per component) |
| Single component, clear layers | Launch 4 explorers (one per layer) |
| Microservices architecture | Launch N explorers (one per service) |
| Monolith by feature | Launch explorers per major feature |
| Mix of patterns | Adaptive: explore each unique area |

**Step 1.4: Validate Discovery Quality**

✅ **Quality checks:**
- [ ] Architecture pattern clearly identified
- [ ] Major components/modules enumerated
- [ ] Boundaries and layers documented
- [ ] File paths provided as evidence
- [ ] No major "unknown" areas remaining

If quality insufficient: Re-run specific discovery agents with refined prompts.

## Phase 2: Deep Dive Pass (Adaptive Exploration)

**Goal:** Explore target within each discovered perspective

**Step 2.1: Generate Adaptive Prompts**

For each discovered perspective, create a targeted prompt:

**Template structure:**
```
Explore [TARGET] in [DISCOVERED_COMPONENT/LAYER].

Context from discovery:
- This is the [COMPONENT_NAME] which handles [RESPONSIBILITY]
- Architecture: [PATTERN]
- Location: [DIRECTORY_PATHS]
- Related components: [DEPENDENCIES]

Task:
1. Find how [TARGET] is implemented in this area
2. Trace execution flow within this scope
3. Identify key files and functions (with file:line references)
4. Document patterns and conventions used
5. Note integration points with other areas

Boundaries:
- Stay within [DIRECTORY_SCOPE]
- Maximum depth: [BASED_ON_LAYER]
- Focus on [TARGET] specifically

Output format: [Structured report with file:line references]
```

**Step 2.2: Dispatch Adaptive Explorers in Parallel**

**CRITICAL: Single message with N Task tool calls** (N = number of discovered perspectives)

Example for 3-component system:
```
Task(subagent_type="Explore", description="Explore target in Component A",
     prompt="[Adaptive prompt for Component A]")

Task(subagent_type="Explore", description="Explore target in Component B",
     prompt="[Adaptive prompt for Component B]")

Task(subagent_type="Explore", description="Explore target in Component C",
     prompt="[Adaptive prompt for Component C]")
```

**Agent Configuration:**
- **subagent_type:** `Explore` (fast agent specialized for codebase exploration)
- **model:** `haiku` (fast, cost-effective)
- **run_in_background:** No (await results for synthesis)

**Step 2.3: Await All Deep Dive Agents**

Block until all N agents complete. Do not proceed with partial results.

## Phase 3: Result Collection

**Step 3.1: Organize Findings**

Separate results into two buckets:

**Discovery Results (from Phase 1):**
- Architecture map
- Component catalog
- Layer definitions
- Organization principles

**Deep Dive Results (from Phase 2):**
- Per-perspective exploration reports
- File:line references for target
- Patterns observed in each area
- Integration points discovered

**Step 3.2: Quality Check Deep Dives**

For each deep dive agent result:
- ✅ Check completeness (did it find the target?)
- ✅ Verify file:line references provided
- ✅ Confirm it stayed within scope
- ⚠️ Note gaps ("target not found in this area" is valid)
- ⚠️ Identify conflicts between areas

**Step 3.3: Cross-Reference Discovery vs Deep Dive**

Validate that deep dives align with discovered structure:
- Do findings match the architecture pattern?
- Are all discovered components covered?
- Are there surprises (things not in discovery)?

If major misalignment: Investigation needed (discovery was incomplete or incorrect).

## Phase 4: Synthesis

**Step 4.1: Integrate Discovery + Deep Dive**

Create unified understanding by layering deep dives onto discovery:

**Integration process:**
1. Start with structural map (from Phase 1)
2. Overlay target implementation (from Phase 2 per area)
3. Identify how target flows across discovered boundaries
4. Document patterns consistent across areas
5. Highlight variations between areas

**Step 4.2: Create Synthesis Document**

**Output format:**

```markdown
# Autonomous Codebase Exploration: [Target]

## Executive Summary
[2-3 sentences: architecture + how target works]

---

## Phase 1: Discovery Findings

### Architecture Pattern
[Pattern name with evidence]

### Component Structure
[Components discovered with responsibilities]

### Layer Organization
[Layers identified with boundaries]

### Technology Stack
[Key technologies per area]

### Structural Diagram
[ASCII/markdown diagram of discovered structure]

---

## Phase 2: Deep Dive Findings

### [Discovered Area 1 - e.g., "Onboarding Component"]
**Scope:** `components/onboarding/`
**Target Implementation:**
- Entry point: `path/to/file.ext:line`
- Flow: [step-by-step with file:line references]
- Patterns: [patterns observed]
- Integration: [how it connects to other areas]

### [Discovered Area 2 - e.g., "Transaction Component"]
**Scope:** `components/transaction/`
**Target Implementation:**
- Entry point: `path/to/file.ext:line`
- Flow: [step-by-step with file:line references]
- Patterns: [patterns observed]
- Integration: [how it connects to other areas]

[... repeat for each discovered area ...]

---

## Cross-Cutting Insights

### Pattern Consistency
[Where patterns are consistent across areas]

### Pattern Variations
[Where implementation differs and why]

### Integration Points
[How discovered areas interact for target]

### Data Flow
[How data flows across boundaries]

### Key Design Decisions
[Architectural choices evident from exploration]

---

## Implementation Guidance

### For Adding New Functionality
**Where to add code:**
- In [Component]: `path/to/directory/`
- In [Layer]: Follow pattern from `example/file.ext:line`

**Patterns to follow:**
- [Pattern 1] as seen in `file.ext:line`
- [Pattern 2] as seen in `file.ext:line`

**Integration requirements:**
- Connect to [Component A] via [interface]
- Update [Component B] to handle [scenario]

### For Modifying Existing Functionality
**Files to change:**
- Primary: `path/file.ext:line`
- Secondary impacts: `path/file2.ext:line`

**Ripple effects:**
- Changes in [Component A] require updates in [Component B]

### For Debugging
**Start investigation in:**
- [Component/Layer]: `path/file.ext:line`

**Data inspection points:**
- [Layer 1]: `file.ext:line` - [what to check]
- [Layer 2]: `file.ext:line` - [what to check]

**Common failure points:**
- [Area identified from cross-cutting analysis]

---

## Appendix: Discovery Evidence

[File:line references supporting structural discoveries]
```

**Step 4.3: Validate Synthesis**

✅ **Completeness check:**
- [ ] Both Phase 1 and Phase 2 integrated
- [ ] All discovered areas covered in deep dive
- [ ] Cross-cutting insights identified
- [ ] Implementation guidance specific and actionable

## Phase 5: Action Recommendations

Based on synthesis, provide context-aware next steps:

**If user's goal is implementation:**
```
Based on autonomous exploration:

**Codebase Structure:**
- Architecture: [Discovered pattern]
- Components: [List with responsibilities]

**To implement [TARGET]:**
1. Add new code in: [Component/Layer] at `path/`
2. Follow pattern: [Pattern name] from `file.ext:line`
3. Integrate with: [Other components] via [mechanism]
4. Test using: [Test pattern discovered]

**Critical files to understand:**
- `file1.ext:line` - [why important]
- `file2.ext:line` - [why important]

Ready to create implementation plan? (Use /ring-default:write-plan)
```

**If user's goal is debugging:**
```
Based on autonomous exploration:

**Investigation starting points:**
- [Component A]: `file.ext:line` - [what to check]
- [Component B]: `file.ext:line` - [what to check]

**Data flow for [TARGET]:**
[Origin] → [Transform 1] → [Validation] → [Destination]

**Common failure modes:**
- [Pattern from cross-cutting analysis]

Ready to investigate systematically? (Use ring-default:systematic-debugging)
```

**If user's goal is learning:**
```
Based on autonomous exploration:

**Codebase organization:**
- [Discovered architecture pattern]
- [N components] with [responsibilities]

**Reading path for [TARGET]:**
1. Start: `file1.ext:line` - [entry point]
2. Then: `file2.ext:line` - [core logic]
3. Finally: `file3.ext:line` - [persistence/output]

**Key patterns to understand:**
- [Pattern 1]: Explained in `file.ext:line`
- [Pattern 2]: Explained in `file.ext:line`

**Related areas to explore next:**
- [Connection found during exploration]
```

## Discovery Agent Prompts

### Template: Architecture Discovery Agent

```markdown
**Goal:** Discover the architecture pattern(s) used in this codebase.

**Scope:** Entire codebase (focus on [TARGET_AREA if specified])

**Task:**
1. Examine directory structure at top level
2. Identify architectural pattern(s):
   - Hexagonal (Ports & Adapters)?
   - Layered (N-tier)?
   - Microservices?
   - Monolith (modular or big ball)?
   - Clean Architecture?
   - MVC/MVVM?
   - Event-driven?
   - Other or mixed?
3. Document evidence for pattern identification:
   - Directory names suggesting layers/boundaries
   - Presence of "adapters", "ports", "domain", "infrastructure"
   - Service separation or monolithic structure
4. Note if multiple patterns coexist (e.g., hexagonal within each microservice)

**Evidence to collect:**
- Directory structure (top 2-3 levels)
- Key directory names that indicate architecture
- Example file paths showing layer separation
- README or docs mentioning architecture

**Output format:**
```
## Architecture Discovery

### Primary Pattern: [Pattern Name]
**Evidence:**
- Directory structure shows: [what indicates this pattern]
- Example paths:
  - `path/to/adapter/` - [adapter layer]
  - `path/to/domain/` - [domain layer]
  - `path/to/infrastructure/` - [infrastructure layer]

### Confidence: [High/Medium/Low]
[Explain confidence level]

### Secondary Patterns: [If any]
[Any mixed or nested patterns]

### Architectural Diagram:
```
[ASCII diagram of discovered architecture]
```

### Key Insights:
- [Any notable architectural decisions or trade-offs visible]
```
```

### Template: Component Discovery Agent

```markdown
**Goal:** Identify all major components/modules/services in the codebase.

**Scope:** Entire codebase (focus on [TARGET_AREA if specified])

**Task:**
1. Identify major components:
   - By directory (e.g., `services/`, `components/`, `modules/`)
   - By responsibility (what each component does)
   - By deployment unit (if microservices)
2. For each component, document:
   - Name and location (directory path)
   - Primary responsibility (one sentence)
   - Key technologies used (language, framework)
   - Size/scope (small, medium, large)
3. Map dependencies between components:
   - Which components depend on which?
   - Are dependencies clean or tangled?
4. Identify shared libraries or common code

**Evidence to collect:**
- List of top-level directories
- README files describing components
- Import/dependency patterns
- Package.json, go.mod, or similar dependency files

**Output format:**
```
## Component Discovery

### Components Identified: [N]

#### Component 1: [Name]
- **Location:** `path/to/component/`
- **Responsibility:** [One sentence]
- **Technology:** [Language + framework]
- **Size:** [Lines of code or file count]
- **Key entry points:**
  - `file1.ext` - [purpose]
  - `file2.ext` - [purpose]

#### Component 2: [Name]
[... same structure ...]

### Dependency Map:
```
[Component A] ──→ [Component B]
              ──→ [Shared Lib]
[Component B] ──→ [Shared Lib]
[Component C] ──→ [Component A]
              ──→ [Shared Lib]
```

### Shared Libraries:
- `lib/common/` - [what it provides]
- `pkg/utils/` - [what it provides]

### Dependency Health:
✅ Clean: [Examples]
⚠️ Tangled: [Examples of circular or unclear dependencies]
```
```

### Template: Layer Discovery Agent

```markdown
**Goal:** Discover layers/boundaries within components.

**Scope:** [Specific component if multi-component, else entire codebase]

**Task:**
1. Within each component, identify layers:
   - Presentation/API layer (HTTP handlers, controllers, etc.)
   - Business logic layer (use cases, services, domain)
   - Data access layer (repositories, database)
   - Infrastructure layer (external integrations)
2. Document how layers are separated:
   - By directory?
   - By naming convention?
   - By file organization?
3. Check for layer violations:
   - Does presentation layer directly access database?
   - Does business logic depend on infrastructure?
4. Identify patterns used for layer communication:
   - Dependency injection?
   - Interfaces/abstractions?
   - Direct coupling?

**Evidence to collect:**
- Directory structure showing layer separation
- File naming conventions indicating layer
- Import patterns (what imports what)
- Interface/abstraction usage

**Output format:**
```
## Layer Discovery

### Component: [Name]

#### Layers Identified:

##### Layer 1: [Name - e.g., "HTTP/API Layer"]
- **Location:** `path/to/layer/`
- **Responsibility:** [What it does]
- **Key files:**
  - `file1.ext` - [purpose]
  - `file2.ext` - [purpose]
- **Dependencies:** [What it depends on]

##### Layer 2: [Name - e.g., "Business Logic"]
[... same structure ...]

##### Layer 3: [Name - e.g., "Data Access"]
[... same structure ...]

### Layer Communication Pattern:
[How layers interact - interfaces, DI, direct calls, etc.]

### Layer Diagram:
```
┌─────────────────────┐
│   HTTP/API Layer    │
└─────────┬───────────┘
          │
┌─────────▼───────────┐
│   Business Logic    │
└─────────┬───────────┘
          │
┌─────────▼───────────┐
│   Data Access       │
└─────────────────────┘
```

### Layer Health:
✅ Clean separation: [Evidence]
⚠️ Violations found: [Examples with file:line]

### Repeat for other components if multi-component system
```
```

### Template: Organization Discovery Agent

```markdown
**Goal:** Understand the organizing principle of this codebase.

**Scope:** Entire codebase

**Task:**
1. Identify primary organization principle:
   - By layer (all controllers together, all models together)
   - By feature (each feature has its own directory with all layers)
   - By domain (organized around business domains)
   - By component type (frontend, backend, shared)
   - Mixed or unclear
2. Document file naming conventions:
   - kebab-case, snake_case, camelCase?
   - Suffixes or prefixes? (e.g., `UserController`, `user.controller.ts`)
3. Identify test organization:
   - Co-located with source?
   - Separate test directory?
   - Naming convention for tests?
4. Note configuration and build setup:
   - Where are config files?
   - Build tool used?
   - Environment-specific configs?

**Evidence to collect:**
- Directory structure examples
- File naming examples
- Test file locations
- Config file locations

**Output format:**
```
## Organization Discovery

### Primary Organization: [Principle Name]
**Evidence:**
- Feature X has all its files in: `path/to/feature/`
- OR: Controllers are all in: `path/controllers/`, Models in: `path/models/`

**Example structure:**
```
[Show representative directory tree]
```

### File Naming Convention:
- **Style:** [kebab-case, snake_case, camelCase, etc.]
- **Pattern:** [Describe pattern]
- **Examples:**
  - `example-file-1.ext`
  - `example-file-2.ext`

### Test Organization:
- **Location:** [Co-located or separate]
- **Pattern:** `*.test.ext`, `*_test.ext`, `test/*`, etc.
- **Examples:**
  - Source: `src/service.ts`
  - Test: `src/service.test.ts`

### Configuration:
- **Location:** `path/to/configs/`
- **Environment handling:** [How envs are managed]
- **Build tool:** [Make, npm, cargo, etc.]

### Key Insights:
- [Notable organizational choices]
- [Any inconsistencies or legacy patterns]
```
```

## Deep Dive Agent Prompts

### Template: Adaptive Deep Dive Agent

```markdown
**Goal:** Explore [TARGET] within [DISCOVERED_PERSPECTIVE].

**Context from Discovery Phase:**
- **Architecture:** [Discovered pattern]
- **This area is:** [Component/Layer/Module name]
- **Responsibility:** [What this area handles]
- **Location:** [Directory paths]
- **Technologies:** [Stack for this area]
- **Related areas:** [Dependencies/connections]

**Task:**
1. **Find [TARGET] in this area:**
   - Search for relevant files containing [TARGET] implementation
   - Identify entry points (APIs, handlers, functions)
   - Document with file:line references

2. **Trace execution flow:**
   - Follow [TARGET] through this area's layers/components
   - Document each step with file:line
   - Note data transformations
   - Identify validation/error handling

3. **Document patterns:**
   - What patterns are used in this area for [TARGET]?
   - Error handling approach
   - Testing approach
   - Integration approach with other areas

4. **Identify integration points:**
   - How does this area connect to others for [TARGET]?
   - What interfaces/APIs are used?
   - What data is passed between areas?

**Boundaries:**
- **Stay within:** [Directory scope for this perspective]
- **Maximum depth:** [Based on layer - don't trace into frameworks]
- **Focus:** [TARGET] specifically (don't document unrelated code)

**Output Format:**
```
## Deep Dive: [TARGET] in [PERSPECTIVE_NAME]

### Overview
[2-3 sentences about how [TARGET] works in this area]

### Entry Points
**File:** `path/to/file.ext:line`
**Function/Handler:** `functionName`
**Triggered by:** [API call, event, function call, etc.]

### Execution Flow

#### Step 1: [Layer/Stage Name]
- **File:** `path/to/file.ext:line`
- **What happens:** [Description]
- **Key code:**
  ```[language]
  [Relevant snippet if helpful]
  ```

#### Step 2: [Next Layer/Stage]
[... same structure ...]

[... repeat for all steps ...]

### Data Transformations
- **Input format:** [Describe]
- **Transform 1:** At `file.ext:line` - [what changes]
- **Transform 2:** At `file.ext:line` - [what changes]
- **Output format:** [Describe]

### Patterns Observed
- **Error handling:** [Approach with example]
- **Validation:** [Where and how]
- **Testing:** [Test patterns if visible]
- **Integration:** [How it connects to other areas]

### Integration Points

#### Outbound: Calls to Other Areas
- **To [Area X]:** Via `interface/api` at `file.ext:line`
  - Purpose: [Why]
  - Data passed: [What]

#### Inbound: Called by Other Areas
- **From [Area Y]:** Via `interface/api` at `file.ext:line`
  - Purpose: [Why]
  - Data received: [What]

### Key Files for [TARGET]
1. `path/file1.ext:line` - [Primary implementation]
2. `path/file2.ext:line` - [Secondary/helper]
3. `path/file3.ext:line` - [Integration point]

### Notes
- [Any discoveries not fitting above categories]
- [Gaps: "Could not find X in this area"]
- [Surprises: "Unexpected implementation choice"]
```
```

## Common Mistakes

| ❌ Bad | ✅ Good |
|--------|---------|
| Skip discovery, assume structure | Always run Phase 1 discovery first |
| Use same deep dive agents for all codebases | Adapt Phase 2 agents based on Phase 1 |
| Accept vague discoveries | Require file:line evidence |
| Run explorers sequentially | Dispatch all in parallel (per phase) |
| Skip synthesis step | Always integrate discovery + deep dive |
| Provide raw dumps | Synthesize into actionable guidance |
| Use for single file lookup | Use Read/Grep instead |

## Integration with Other Skills

| Skill | When to use together |
|-------|----------------------|
| **brainstorming** | Use exploring-codebase in Phase 1 (Understanding) to gather context |
| **writing-plans** | Use exploring-codebase before creating implementation plans |
| **executing-plans** | Use exploring-codebase if plan execution reveals gaps |
| **systematic-debugging** | Use exploring-codebase to understand system before debugging |
| **dispatching-parallel-agents** | This skill is built on that pattern (twice!) |

## Output Format

When skill completes, provide:

### 1. Synthesis Document
[As defined in Phase 4.2 - includes both discovery and deep dive]

### 2. Structural Insights
```
**Discovered Architecture:**
- Pattern: [Name]
- Components: [List]
- Layers: [List]
- Organization: [Principle]

**[TARGET] Implementation:**
- Present in: [N components/layers]
- Entry points: [List with file:line]
- Integration: [How areas connect]
- Patterns: [Consistent patterns observed]
```

### 3. Next Step Recommendations
[As defined in Phase 5 - context-aware based on user goal]

## Verification

After completing exploration:

✅ **Phase 1 (Discovery) completeness:**
- [ ] Architecture pattern identified with evidence
- [ ] All major components/modules enumerated
- [ ] Layers/boundaries documented
- [ ] Organization principle clear
- [ ] File:line references for structural elements

✅ **Phase 2 (Deep Dive) completeness:**
- [ ] All discovered perspectives explored
- [ ] [TARGET] found and documented in each area
- [ ] Execution flows traced with file:line
- [ ] Integration points identified
- [ ] Patterns documented per area

✅ **Synthesis quality:**
- [ ] Discovery and deep dive integrated
- [ ] Cross-cutting insights identified
- [ ] Inconsistencies explained
- [ ] Implementation guidance specific
- [ ] Next steps clear and actionable

## Adaptive Examples

### Example 1: Microservices Architecture

**Phase 1 Discovery finds:**
- 5 microservices (Auth, User, Order, Payment, Notification)
- Each service is independent
- Event-driven communication via message bus

**Phase 2 adapts:**
- Launch 5 deep dive agents (one per service)
- Each explores target within their service
- Focus on event publishing/subscribing for integration

### Example 2: Monolithic Hexagonal Architecture

**Phase 1 Discovery finds:**
- Single application
- Hexagonal architecture (adapters + domain)
- 4 layers: HTTP → Application → Domain → Infrastructure

**Phase 2 adapts:**
- Launch 4 deep dive agents (one per layer)
- Each explores target within their layer
- Focus on dependency inversion at boundaries

### Example 3: Feature-Organized Monolith

**Phase 1 Discovery finds:**
- Features organized in separate directories
- Each feature has its own layers
- 6 major features identified

**Phase 2 adapts:**
- Launch 6 deep dive agents (one per feature)
- Each explores target within their feature
- Focus on shared code and cross-feature integration

## Key Principles

| Principle | Application |
|-----------|-------------|
| **Discover, then dive** | Phase 1 discovery informs Phase 2 exploration |
| **Adaptive parallelization** | Number and type of agents matches structure |
| **Evidence-based** | All discoveries backed by file:line references |
| **Autonomous** | Codebase reveals its own structure |
| **Synthesis required** | Raw outputs must be integrated |
| **Action-oriented** | Always end with next steps |
| **Quality gates** | Verify each phase before proceeding |

## Required Patterns

This skill uses these universal patterns:
- **State Tracking:** See `skills/shared-patterns/state-tracking.md`
- **Failure Recovery:** See `skills/shared-patterns/failure-recovery.md`
- **TodoWrite:** See `skills/shared-patterns/todowrite-integration.md`

Apply ALL patterns when using this skill.

## Notes

- **Performance:** Two phases complete faster than naive sequential exploration
- **Cost:** Uses `haiku` model (cost-effective for exploration)
- **Adaptability:** Works for any architecture (hexagonal, microservices, MVC, etc.)
- **Scalability:** Handles codebases from small (2-3 components) to large (10+ services)
- **Reusability:** Synthesis documents serve as permanent reference
