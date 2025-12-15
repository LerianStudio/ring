---
name: ring-default:brainstorm
description: Interactive design refinement using Socratic method
argument-hint: "[topic]"
---

Transform rough ideas into fully-formed designs through structured questioning and alternative exploration. This command initiates an interactive design session using the Socratic method to refine your concept before implementation.

## Usage

```
/brainstorm [topic]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `topic` | Yes | The feature, product, or system you want to design (e.g., "user authentication", "payment processing", "notification system") |

## Examples

### Starting a Feature Design
```
/brainstorm OAuth2 integration
```
Initiates a design session for adding OAuth2 authentication to your application.

### Architectural Decision
```
/brainstorm microservices migration strategy
```
Explores approaches for migrating from monolith to microservices architecture.

### New Product Concept
```
/brainstorm real-time collaboration feature
```
Refines requirements and design for a collaborative editing feature.

## Process

The brainstorming session follows these phases:

### 1. Autonomous Recon (Prep)
- Inspects repository structure, documentation, and recent commits
- Forms initial understanding of the codebase context
- Shares findings before asking questions

### 2. Understanding (Phase 1)
- Shares synthesized understanding for validation
- Asks targeted questions (max 3) to fill knowledge gaps
- Gathers: purpose, constraints, success criteria

### 3. Exploration (Phase 2)
- Proposes 2-3 different architectural approaches
- Presents trade-offs for each option
- Recommends preferred approach with rationale
- Uses `AskUserQuestion` for approach selection

### 4. Design Presentation (Phase 3)
- Presents design in 200-300 word sections
- Covers: architecture, components, data flow, error handling, testing
- Validates each section incrementally
- Requires explicit approval ("Approved", "Looks good", "Proceed")

### 5. Design Documentation (Phase 4)
- Writes validated design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Commits the design document to git

### 6. Worktree Setup (Phase 5, if implementing)
- Sets up isolated git worktree for development
- Prepares clean workspace for implementation

### 7. Planning Handoff (Phase 6, if implementing)
- Creates detailed implementation plan using `writing-plans` skill
- Breaks design into bite-sized executable tasks

## Related Commands/Skills

| Command/Skill | Relationship |
|---------------|--------------|
| `/write-plan` | Use after brainstorming when design is complete |
| `/execute-plan` | Use after planning to implement the design |
| `writing-plans` | Underlying skill for creating implementation plans |

## Troubleshooting

### "Design not validated"
The session requires explicit approval from you before proceeding. Responses like "interesting" or "I see" do not count as approval. Say "approved", "looks good", or "proceed" to advance.

### "Too many questions"
Each phase has a maximum of 3 questions. If you're being asked more, it indicates insufficient autonomous research. Request the agent to explore the codebase first.

### "Skipping phases"
The process is phase-locked. You cannot skip ahead until the current phase is complete. If you need to go faster, provide explicit approval at each checkpoint.

### When NOT to use this command
- Design is already complete and validated - use `/write-plan`
- Have a detailed plan ready to execute - use `/execute-plan`
- Just need task breakdown from existing design - use `/write-plan`
