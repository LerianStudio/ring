---
name: ring-default:explore-codebase
description: Autonomous two-phase codebase exploration with adaptive agents
argument-hint: "[target]"
---

Autonomously discover codebase structure, then explore deeply with adaptive agents. The system first learns the architecture, then dispatches targeted explorers based on what it found.

## Usage

```
/explore-codebase [target]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `target` | Yes | Feature, component, or system to explore (e.g., "account creation", "transaction processing", "authentication system") |

## What This Command Does

**Two-Phase Autonomous Exploration:**

### Phase 1: Discovery (Meta-Exploration)
1. **Discovers structure** - Launches 3-4 agents to understand the codebase
2. **Identifies perspectives** - Finds architecture, components, layers, organization
3. **Creates structural map** - Documents what was discovered with evidence

### Phase 2: Deep Dive (Adaptive Exploration)
4. **Adapts to structure** - Generates N explorers based on Phase 1 discoveries
5. **Explores target** - Each agent investigates target in their assigned area
6. **Synthesizes findings** - Integrates discovery + deep dives into unified understanding
7. **Provides guidance** - Recommends next steps based on your goal

## The Autonomous Flow

```
Target: "account creation"
           │
           ▼
    ┌──────────────┐
    │  Phase 1:    │  Launch 4 discovery agents in parallel:
    │  Discovery   │  • Architecture pattern?
    │              │  • Components/modules?
    │              │  • Layers/boundaries?
    └──────┬───────┘  • Organization principle?
           │
           │  Discovered: 3 components, hexagonal architecture, 4 layers each
           │
           ▼
    ┌──────────────┐
    │  Phase 2:    │  Launch 3 deep-dive agents (adapted to discoveries):
    │  Deep Dive   │  • Onboarding component
    │              │  • Transaction component
    │              │  • CRM component
    └──────┬───────┘  Each explores "account creation" in their area
           │
           ▼
    ┌──────────────┐
    │  Synthesis   │  • Integrate discoveries + deep dives
    │              │  • Cross-cutting insights
    │              │  • Implementation guidance
    └──────────────┘
```

## Process Details

This command invokes the `exploring-codebase` skill which handles:

### Phase 1: Discovery Pass (3-4 parallel agents)

**Architecture Discovery Agent:**
- Identifies architecture pattern (hexagonal, layered, microservices, etc.)
- Documents evidence (directory structure, naming, separation)
- Provides confidence level

**Component Discovery Agent:**
- Enumerates major components/modules/services
- Maps dependencies between components
- Identifies shared libraries

**Layer Discovery Agent:**
- Discovers layers within components
- Documents layer communication patterns
- Identifies violations or cross-cutting concerns

**Organization Discovery Agent:**
- Understands organizing principle (by layer, by feature, by domain)
- Documents file naming conventions
- Maps test and config organization

### Phase 2: Adaptive Deep Dive (N agents based on discoveries)

The number and focus of agents adapts to Phase 1 findings:

| What Phase 1 Found | Phase 2 Strategy |
|--------------------|------------------|
| 3 components × 4 layers | Launch 3 agents (one per component) |
| Single component, clear layers | Launch 4 agents (one per layer) |
| 5 microservices | Launch 5 agents (one per service) |
| 6 features (feature-organized) | Launch 6 agents (one per feature) |

**Each deep dive agent receives:**
- Context from Phase 1 discoveries
- Focused scope (specific component/layer/service)
- Target to explore within that scope
- Boundaries to respect

**Each deep dive agent produces:**
- How target is implemented in their area
- Execution flow with file:line references
- Patterns observed
- Integration points with other areas

### Phase 3: Synthesis

- Integrates Phase 1 structural map with Phase 2 deep dives
- Identifies cross-cutting insights
- Documents consistent patterns
- Highlights variations between areas
- Provides actionable implementation guidance

## Examples

### Example 1: Exploring Account Creation

```bash
/explore-codebase account creation
```

**Phase 1 might discover:**
- Hexagonal architecture
- 3 components (onboarding, transaction, crm)
- 4 layers per component (HTTP, UseCase, Repository, Domain)

**Phase 2 adapts with 3 agents:**
- Agent 1: Explore account creation in onboarding component
- Agent 2: Check for account references in transaction component
- Agent 3: Check for account references in CRM component

**Result:** Comprehensive understanding of how account creation works across all components

### Example 2: Exploring Transaction Processing

```bash
/explore-codebase transaction processing
```

**Phase 1 might discover:**
- Microservices architecture
- 5 services (auth, user, order, payment, notification)
- Event-driven communication

**Phase 2 adapts with 5 agents:**
- One agent per service exploring transaction handling
- Focus on event publishing/subscribing
- Document inter-service data flow

**Result:** End-to-end understanding of transactions across services

### Example 3: Exploring Authentication

```bash
/explore-codebase authentication system
```

**Phase 1 might discover:**
- Monolithic layered architecture
- MVC pattern with 3 layers

**Phase 2 adapts with 3 agents:**
- Agent 1: Auth in Controller layer
- Agent 2: Auth in Service layer
- Agent 3: Auth in Data Access layer

**Result:** Vertical slice of authentication through all layers

## Output

The command produces a **comprehensive synthesis document** with:

### Executive Summary
2-3 sentences about architecture + how target works

### Phase 1: Discovery Findings
- Architecture pattern (with evidence)
- Component structure (with responsibilities)
- Layer organization (with boundaries)
- Technology stack
- Structural diagram

### Phase 2: Deep Dive Findings
For each discovered area:
- Scope explored
- Target implementation (with file:line)
- Execution flow
- Patterns observed
- Integration points

### Cross-Cutting Insights
- Pattern consistency across areas
- Pattern variations and why
- Integration points between areas
- Data flow across boundaries
- Key design decisions

### Implementation Guidance
Context-aware recommendations for:
- **Adding functionality:** Where to put code, patterns to follow
- **Modifying functionality:** Files to change, ripple effects
- **Debugging:** Where to start, what to inspect

### Next Steps
Recommendations based on your goal (implementation, debugging, or learning)

## When to Use

**Use this command when:**
- You need end-to-end understanding of a feature
- Starting work on unfamiliar codebase
- Planning changes spanning multiple components
- Need architecture context before implementation
- Exploring complex system interactions

**Don't use when:**
- Looking for specific file/function (use grep/find)
- Already familiar with the structure
- Simple single-file change needed
- Just viewing an error location (use read)

## Key Advantages of Two-Phase Approach

### 1. Adaptive to Any Architecture
- Discovers structure rather than assuming it
- Works with hexagonal, microservices, MVC, monoliths, etc.
- Handles mixed patterns (e.g., hexagonal within each microservice)

### 2. Efficient Parallelization
- Phase 1: 3-4 discovery agents run in parallel
- Phase 2: N deep-dive agents run in parallel (N adapts)
- Faster than sequential exploration

### 3. Thorough Understanding
- Structural context (Phase 1) + Implementation details (Phase 2)
- No blind spots from single-lens exploration
- Cross-cutting insights from synthesis

### 4. Actionable Guidance
- Not just "what exists" but "where to make changes"
- Pattern recommendations based on actual codebase
- Integration points clearly documented

## Related Commands/Skills

| Command/Skill | Relationship |
|---------------|--------------|
| `/brainstorm` | Use explore-codebase in Phase 1 for context |
| `/write-plan` | Use explore-codebase before planning implementation |
| `/execute-plan` | Use if plan execution reveals gaps in understanding |
| `exploring-codebase` | Underlying skill with full logic and prompts |
| `dispatching-parallel-agents` | Pattern used twice (discovery + deep dive) |
| `systematic-debugging` | Use explore-codebase before debugging |

## Troubleshooting

### "Discovery phase found unclear structure"
**Cause:** Codebase may have inconsistent or legacy patterns
**Solution:** Review discovery agent outputs, may need manual interpretation

### "Deep dive agents didn't find the target"
**Cause:** Target may not exist in that area (valid finding) OR target named differently
**Solution:** Check if agents noted "not found in this area" - may be expected

### "Contradictions between agents"
**Cause:** Different parts of codebase use different patterns (common in legacy code)
**Solution:** Synthesis phase should document variations - may indicate refactoring opportunities

### "Too many deep dive agents (long exploration)"
**Cause:** Phase 1 discovered many components/layers
**Solution:** Refine target to be more specific, or use a subset scope

### "Not enough detail in results"
**Cause:** Target may be too broad or vague
**Solution:** Be more specific: "account creation API endpoint" vs "accounts"

## Advanced Usage

### Narrow Scope
Focus discovery on specific area:
```bash
/explore-codebase transaction processing in payment service only
```

### Deep Exploration
Request comprehensive analysis:
```bash
/explore-codebase authentication (include all integrations and edge cases)
```

### Comparative Analysis
Run twice to understand changes:
```bash
# Before refactoring
/explore-codebase user management

# After refactoring
/explore-codebase user management
# Compare the two synthesis documents
```

## Performance & Cost

- **Discovery Phase:** 3-4 agents × ~2-3 min each = ~3-5 minutes total (parallel)
- **Deep Dive Phase:** N agents × ~3-5 min each = ~3-5 minutes total (parallel)
- **Total Time:** ~6-10 minutes for comprehensive exploration
- **Model Used:** Haiku (cost-effective for exploration)
- **Cost:** Minimal - optimized for efficiency

## What Makes This Different

### vs. Traditional Exploration:
- Traditional: Assume structure → explore sequentially
- This command: **Discover structure → adapt exploration**

### vs. Fixed-Perspective Exploration:
- Fixed: Always use same 4 perspectives (feature flow, patterns, components, data)
- This command: **Perspectives adapt to what Phase 1 discovers**

### vs. Manual Navigation:
- Manual: Guess where to look, follow imports, repeat
- This command: **Systematic discovery + targeted deep dives + synthesis**

## Example Discoveries

### Microservices Codebase
**Phase 1:** "Found 8 microservices with event-driven architecture"
**Phase 2:** 8 deep-dive agents, one per service
**Synthesis:** Event flow diagram + service responsibilities + integration points

### Hexagonal Monolith
**Phase 1:** "Found single app with hexagonal architecture, 4 layers"
**Phase 2:** 4 deep-dive agents, one per layer
**Synthesis:** Dependency inversion patterns + layer boundaries + adapter implementations

### Feature-Organized Codebase
**Phase 1:** "Found 12 features, each self-contained with own layers"
**Phase 2:** 12 deep-dive agents, one per feature
**Synthesis:** Shared code patterns + feature independence + cross-feature integration

## Next Steps After Exploration

The command suggests appropriate follow-up:

**If you're implementing something:**
```
Ready to create implementation plan? Use /write-plan
```

**If you're setting up workspace:**
```
Ready for isolated workspace? Use /worktree
```

**If you're debugging:**
```
Ready to investigate? Use systematic-debugging skill
```

**If you're designing:**
```
Ready to refine design? Use /brainstorm
```

## Real-World Workflow

```bash
# 1. Understand the codebase
/explore-codebase payment processing

# 2. Review synthesis document (architecture + implementation)

# 3. Based on findings, plan your changes
/write-plan add-refund-support

# 4. Set up isolated workspace
/worktree feature/add-refund-support

# 5. Execute the plan
/execute-plan <plan-file>
```

## Key Takeaways

✅ **Autonomous** - Discovers structure, doesn't assume it
✅ **Adaptive** - Deep dive agents match discovered architecture
✅ **Efficient** - Parallel exploration in both phases
✅ **Thorough** - Structural context + implementation details
✅ **Actionable** - Synthesis provides implementation guidance
✅ **Universal** - Works with any codebase architecture
