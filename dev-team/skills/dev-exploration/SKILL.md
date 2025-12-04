---
name: dev-exploration
description: |
  Executes codebase-explorer to gather architectural insights for dev-analysis.
  Returns structured findings about patterns, anti-patterns, and standards compliance.

trigger: |
  - Called by dev-analysis skill (Step 3, Phase 1)
  - Need deep architectural understanding before standards check
  - Project audit requires pattern discovery

skip_when: |
  - Simple file search → Use built-in Explore
  - Already have architectural insights from previous exploration
  - Single component analysis → Use codebase-explorer directly

sequence:
  after: [dev-analysis]

related:
  complementary: [dev-analysis, ring-default:codebase-explorer]
---

# Dev Exploration Skill

Execute `ring-default:codebase-explorer` to gather architectural insights for standards analysis.

## Purpose

This skill wraps the codebase-explorer agent to provide structured input for dev-analysis. It translates raw exploration output into actionable findings for the analysis pipeline.

## Input Required

From dev-analysis Step 1 & 2:
- `language`: Detected project language (Go, TypeScript, etc.)
- `project_type`: Backend API, Frontend, Full-stack, CLI
- `standards_file`: Path to agent standards being used

## Execution

Dispatch codebase-explorer with standards context:

```
Task tool:
  subagent_type: "ring-default:codebase-explorer"
  model: "opus"
  prompt: |
    Perform a THOROUGH exploration of this codebase for standards analysis.

    ## Context
    - Language: {language}
    - Project Type: {project_type}
    - Standards Reference: {standards_file}

    ## Focus Areas

    ### 1. Directory Structure
    - Does it follow {language} conventions?
    - Is there clear separation of concerns?
    - Expected: src/, internal/, pkg/ (Go) or src/, lib/, components/ (TS)

    ### 2. Architectural Patterns
    Check for and document:
    - DDD patterns (Entities, Value Objects, Aggregates, Repositories)
    - Clean/Hexagonal Architecture (Ports, Adapters, Use Cases)
    - Layer separation (domain → application → infrastructure)
    - Dependency direction (should point inward)

    ### 3. Code Patterns
    Identify:
    - Error handling approach
    - Logging patterns
    - Input validation
    - Configuration management
    - Dependency injection

    ### 4. Anti-Patterns
    Flag any:
    - Circular dependencies
    - Domain depending on infrastructure
    - Business logic in handlers/controllers
    - Global mutable state
    - Magic numbers/strings
    - Ignored errors

    ### 5. Technical Debt
    Note:
    - TODO/FIXME comments without issue references
    - Deprecated patterns still in use
    - Inconsistent naming conventions
    - Missing abstractions

    ## Output Format

    Structure your response as:

    ## EXPLORATION SUMMARY
    [2-3 sentences describing overall architecture health]

    ## PATTERNS FOUND
    | Pattern | Location | Compliance |
    |---------|----------|------------|
    | [name]  | [path:line] | GOOD/PARTIAL/MISSING |

    ## ANTI-PATTERNS DETECTED
    | Issue | Location | Severity | Description |
    |-------|----------|----------|-------------|
    | [type] | [path:line] | Critical/High/Medium/Low | [what's wrong] |

    ## ARCHITECTURE INSIGHTS
    [Key findings about structure and design]

    ## RECOMMENDATIONS
    [Prioritized list of improvements]
```

## Output

The skill produces structured findings for dev-analysis Step 4:

```yaml
exploration_results:
  summary: "Brief architecture health assessment"

  patterns_found:
    - name: "Repository Pattern"
      location: "internal/repository/"
      compliance: "GOOD"
    - name: "DDD Entities"
      location: "internal/domain/"
      compliance: "PARTIAL"

  anti_patterns:
    - issue: "Domain imports infrastructure"
      location: "internal/domain/user.go:15"
      severity: "High"
      description: "Domain entity imports database package"

  insights:
    - "Clean architecture structure present but not enforced"
    - "Error handling inconsistent across layers"

  recommendations:
    - priority: "Critical"
      action: "Remove infrastructure imports from domain"
    - priority: "High"
      action: "Standardize error wrapping"
```

## Integration with dev-analysis

```
dev-analysis workflow:
├── Step 1: Detect language
├── Step 2: Load standards
├── Step 3: Scan codebase
│   ├── Phase 1: dev-exploration ← THIS SKILL
│   │   └── Returns: exploration_results
│   └── Phase 2: qa + devops + sre (parallel)
├── Step 4: Compile findings (uses exploration_results)
└── ...
```

## When to Use Directly

While primarily called by dev-analysis, you can use this skill directly:

```bash
# Standalone exploration for architecture review
"Use dev-exploration skill to analyze this Go codebase against DDD standards"
```

Output will be the same structured format, useful for:
- Pre-refactoring assessment
- Architecture documentation
- Onboarding new team members
- Technical debt inventory
