---
name: dev-analysis
description: |
  Gate 1 of the development cycle - analyzes codebase context for each task,
  identifies affected files, recommends the appropriate dev-team agent,
  estimates complexity, and documents risks.

trigger: |
  - Starting Gate 1 of development-cycle
  - Need to analyze codebase before implementation
  - Determining which developer agent should handle a task

skip_when: |
  - Analysis already completed for this task -> proceed to Gate 2
  - Task is documentation-only -> skip to appropriate gate
  - Simple config change with known scope -> proceed directly

sequence:
  after: [dev-import-tasks]
  before: [dev-design]

related:
  complementary: [development-cycle, dev-import-tasks, dev-design, ring-default:codebase-explorer]
---

# Dev Analysis (Gate 1)

## Overview

This skill analyzes the codebase to understand the context for each task. It uses `ring-default:codebase-explorer` for deep analysis, identifies files that will be affected, recommends the most appropriate developer agent, estimates complexity, and documents risks.

**Announce at start:** "I'm using the dev-analysis skill to analyze the codebase context for this task."

## Inputs

From Gate 0 (dev-import-tasks):

```json
{
  "id": "TASK-001",
  "title": "Task title",
  "functional_requirements": [...],
  "technical_requirements": [...],
  "acceptance_criteria": [...],
  "references": {...}
}
```

## Step 1: Load Project Configuration

Check for project standards file:

```
1. Look for: docs/STANDARDS.md
2. If exists, extract:
   - Coding standards
   - Architecture patterns
   - Naming conventions
   - Testing requirements
   - Technology stack
   - Preferred patterns
3. If not exists:
   - Infer from existing code patterns
   - Log: "No STANDARDS.md found - inferring from codebase"
```

**Alternative config locations (check in order):**
- `docs/STANDARDS.md`
- `STANDARDS.md`
- `docs/ARCHITECTURE.md`
- `CONTRIBUTING.md` (coding standards section)
- `.github/CONTRIBUTING.md`

### Standards Structure

```json
{
  "project_config": {
    "source": "docs/STANDARDS.md|inferred",
    "language": "go|typescript|python|etc",
    "framework": "fiber|express|fastapi|etc",
    "architecture": "hexagonal|layered|mvc|etc",
    "testing": {
      "framework": "go test|jest|pytest|etc",
      "coverage_minimum": 80,
      "required_types": ["unit", "integration"]
    },
    "conventions": {
      "naming": "camelCase|snake_case|PascalCase",
      "file_structure": "feature-based|layer-based",
      "error_handling": "pattern description"
    }
  }
}
```

## Step 2: Dispatch Codebase Explorer

**REQUIRED:** Use ring-default:codebase-explorer for deep analysis

```
Task tool:
  subagent_type: "ring-default:codebase-explorer"
  model: "opus"
  prompt: |
    Analyze the codebase for implementing this task:

    Task: [id] - [title]

    Functional Requirements:
    [functional_requirements as bullet list]

    Technical Requirements:
    [technical_requirements as bullet list]

    Acceptance Criteria:
    [acceptance_criteria as bullet list]

    References (if available):
    [references]

    I need you to:
    1. Identify all files that will likely be affected by this implementation
    2. Understand the existing architecture patterns
    3. Find similar implementations to use as reference
    4. Identify any potential conflicts or dependencies
    5. Note any technical debt or patterns to avoid

    Use MEDIUM exploration depth (15-25 minutes).

    Report:
    - Affected files (with paths and reasons)
    - Architecture patterns to follow
    - Reference implementations
    - Dependencies and conflicts
    - Recommended approach
```

## Step 3: Analyze Explorer Results

Process the codebase-explorer output:

### 3.1 Extract Affected Files

```json
{
  "affected_files": [
    {
      "path": "internal/handlers/auth.go",
      "reason": "Will add new login endpoint handler",
      "change_type": "modify",
      "risk": "medium"
    },
    {
      "path": "internal/services/auth_service.go",
      "reason": "Will add authentication logic",
      "change_type": "create",
      "risk": "low"
    },
    {
      "path": "internal/repositories/user_repository.go",
      "reason": "Will add user lookup methods",
      "change_type": "modify",
      "risk": "low"
    }
  ]
}
```

### 3.2 Identify Architecture Patterns

```json
{
  "patterns": {
    "architecture": "hexagonal",
    "layer_structure": [
      "handlers (ports/in)",
      "services (application)",
      "repositories (ports/out)",
      "entities (domain)"
    ],
    "dependency_injection": "wire or manual",
    "error_handling": "custom error types with wrapping",
    "logging": "structured logging with zap/zerolog"
  }
}
```

### 3.3 Find Reference Implementations

```json
{
  "references": [
    {
      "file": "internal/handlers/user.go",
      "relevance": "Similar CRUD handler pattern",
      "key_lines": "L15-45"
    },
    {
      "file": "internal/services/user_service.go",
      "relevance": "Service layer structure to follow",
      "key_lines": "L10-80"
    }
  ]
}
```

## Step 4: Recommend Developer Agent

Based on analysis, determine the best agent:

### Decision Matrix

```
1. Detect primary language:
   - .go files dominant → Go agent
   - .ts/.tsx files dominant → TypeScript agent
   - .py files dominant → Python agent
   - Mixed or unknown → Generic backend agent

2. Detect domain:
   - API/backend work → backend-engineer-*
   - UI/frontend work → frontend-engineer-*
   - Infrastructure → devops-engineer
   - Testing-only → qa-analyst

3. Match to agent:
```

| Language | Domain | Recommended Agent |
|----------|--------|-------------------|
| Go | Backend/API | ring-dev-team:backend-engineer-golang |
| TypeScript | Backend | ring-dev-team:backend-engineer-typescript |
| TypeScript | Frontend | ring-dev-team:frontend-engineer-typescript |
| Python | Backend | ring-dev-team:backend-engineer-python |
| Unknown | Backend | ring-dev-team:backend-engineer |
| Any | Frontend (generic) | ring-dev-team:frontend-engineer |
| Any | Frontend (visual) | ring-dev-team:frontend-designer |
| Any | Infrastructure | ring-dev-team:devops-engineer |
| Any | Testing | ring-dev-team:qa-analyst |
| Any | Reliability | ring-dev-team:sre |

### Agent Recommendation Output

```json
{
  "recommended_agent": "ring-dev-team:backend-engineer-golang",
  "reasoning": [
    "Project is Go-based (detected go.mod, .go files)",
    "Task involves API endpoint implementation",
    "Existing patterns match Go hexagonal architecture"
  ],
  "alternative_agents": [
    {
      "agent": "ring-dev-team:backend-engineer",
      "when": "If task spans multiple languages"
    }
  ]
}
```

## Step 5: Estimate Complexity

### Complexity Factors

| Factor | S (Small) | M (Medium) | L (Large) | XL (Extra Large) |
|--------|-----------|------------|-----------|------------------|
| Files affected | 1-3 | 4-7 | 8-15 | 16+ |
| New vs modify | All modify | Mix | Mostly new | New system |
| Dependencies | None | Few internal | Cross-service | External APIs |
| Testing scope | Unit only | Unit + integration | + E2E | + Performance |
| Risk level | Low | Medium | High | Critical |

### Complexity Calculation

```
1. Count affected files
2. Assess change types (create vs modify)
3. Check dependency graph
4. Consider testing requirements
5. Evaluate risk factors

Final complexity = weighted average of factors
```

### Complexity Output

```json
{
  "complexity": "M",
  "factors": {
    "files_affected": 5,
    "new_files": 2,
    "modified_files": 3,
    "dependencies": ["user_service", "token_service"],
    "testing_scope": ["unit", "integration"],
    "risk_areas": ["authentication flow", "token security"]
  },
  "estimated_time": "2-4 hours",
  "confidence": "high"
}
```

## Step 6: Document Risks

### Risk Categories

| Category | Examples |
|----------|----------|
| Technical | Breaking changes, API incompatibility, performance impact |
| Security | Auth bypass, injection vulnerabilities, data exposure |
| Integration | Third-party dependencies, service coupling, data sync |
| Testing | Low coverage areas, flaky tests, missing E2E |
| Operational | Deployment complexity, rollback difficulty, monitoring gaps |

### Risk Assessment Output

```json
{
  "risks": [
    {
      "id": "RISK-001",
      "category": "security",
      "description": "JWT secret must be properly configured",
      "severity": "high",
      "mitigation": "Use environment variable, rotate regularly",
      "gate_impact": "Review gate will check for hardcoded secrets"
    },
    {
      "id": "RISK-002",
      "category": "integration",
      "description": "Token validation depends on user service",
      "severity": "medium",
      "mitigation": "Ensure user service is available, add timeout handling",
      "gate_impact": "Testing gate will need integration test with user service"
    }
  ]
}
```

## Step 7: Build Analysis Output

Complete output for orchestrator:

```json
{
  "task_id": "TASK-001",
  "analysis_completed_at": "ISO timestamp",
  "project_config": {
    "source": "docs/STANDARDS.md",
    "language": "go",
    "framework": "fiber",
    "architecture": "hexagonal"
  },
  "affected_files": [
    {
      "path": "internal/handlers/auth.go",
      "reason": "Add login endpoint handler",
      "change_type": "modify",
      "risk": "medium"
    }
  ],
  "recommended_agent": "ring-dev-team:backend-engineer-golang",
  "agent_reasoning": [
    "Go project",
    "Backend API task",
    "Hexagonal architecture"
  ],
  "complexity": {
    "rating": "M",
    "estimated_time": "2-4 hours",
    "factors": {
      "files_affected": 5,
      "new_files": 2,
      "dependencies": ["user_service"]
    }
  },
  "risks": [
    {
      "id": "RISK-001",
      "category": "security",
      "description": "JWT secret configuration",
      "severity": "high",
      "mitigation": "Use environment variable"
    }
  ],
  "reference_implementations": [
    {
      "file": "internal/handlers/user.go",
      "relevance": "Similar handler pattern"
    }
  ],
  "patterns_to_follow": [
    "Hexagonal architecture",
    "Repository pattern",
    "Custom error types"
  ],
  "technical_requirements_inferred": [
    "Use fiber framework for HTTP handling",
    "Follow existing error handling pattern",
    "Use structured logging"
  ]
}
```

## Error Handling

### Explorer Failure

```
If codebase-explorer fails:

1. Log failure reason
2. Attempt fallback analysis:
   - Use Glob to find relevant files
   - Use Grep to search for patterns
   - Make best-effort recommendations
3. Mark analysis as "partial"
4. Proceed with warnings
```

### No Standards Found

```
If no STANDARDS.md and cannot infer:

1. Log warning
2. Set project_config.source = "unknown"
3. Recommend generic agent (ring-dev-team:backend-engineer)
4. Add risk: "No project standards - may not follow conventions"
```

### Unknown Language

```
If cannot determine language:

1. Check file extensions in project
2. Look for package managers (go.mod, package.json, etc)
3. If still unknown:
   - Recommend ring-dev-team:backend-engineer (generic)
   - Add warning: "Language unknown - using generic agent"
```

## Execution Report

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Iterations | 1 |
| Result | PASS/PARTIAL/FAIL |

### Details
- task_id: [id]
- recommended_agent: [agent]
- complexity: [S/M/L/XL]
- files_affected: [count]
- risks_identified: [count]
- config_source: [path or "inferred"]

### Issues Encountered
- [List of warnings or errors during analysis]
- Or "None"

### Handoff to Next Gate
- Gate 2 (Design) receives:
  - Recommended agent: [agent]
  - Affected files: [list]
  - Patterns to follow: [list]
  - Risks to address: [list]
- Ready to proceed: [yes/no]
- Blocking issues: [list or "none"]
