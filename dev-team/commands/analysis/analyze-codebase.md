---
allowed-tools: Read(*), Glob(*), Grep(*), LS(*)
description: Comprehensive codebase analysis to understand architecture, patterns, and project structure
argument-hint: (no arguments - analyzes entire codebase)
---

# /ring-dev-team:analysis:analyze-codebase

## Instructions
Perform comprehensive codebase analysis without any arguments - examine the complete project structure, dependencies, and implementation patterns to provide a thorough understanding of the application architecture.

## Purpose
- Understand project type and main technologies
- Map architecture patterns (MVC, microservices, etc.)
- Document directory structure and organization
- Identify dependencies and external integrations
- Assess build and deployment setup
- Provide comprehensive understanding of how the application works

## Scope
Analyzes the entire codebase using native tools (Glob, Read, Grep, LS) to discover project structure, technology stack, architectural patterns, and component relationships without requiring any user-provided parameters.

## Process

### Phase 1: Project Discovery

**Action:** Map entire project structure and identify key files

**Tools:**

- Glob to map entire project structure
- Read key files (README, docs, configs)
- Grep to identify technology patterns
- Read entry points and main files

**Focus:**

- Project type and main technologies
- Architecture patterns (MVC, microservices, etc.)
- Directory structure and organization
- Dependencies and external integrations
- Build and deployment setup

### Phase 2: Architecture Analysis

**Components:**

- Entry points: Main files, index files, app initializers
- Core modules: Business logic organization
- Data layer: Database, models, repositories
- API layer: Routes, controllers, endpoints
- Frontend: Components, views, templates
- Configuration: Environment setup, constants
- Testing: Test structure and coverage

### Phase 3: Pattern Recognition

**Action:** Identify established patterns and conventions

**Patterns:**

- Naming conventions for files and functions
- Code style and formatting rules
- Error handling approaches
- Authentication/authorization flow
- State management strategy
- Communication patterns between modules

### Phase 4: Dependency Mapping

**Relationships:**

- Internal dependencies between modules
- External library usage patterns
- Service integrations
- API dependencies
- Database relationships
- Asset and resource management

### Phase 5: Integration Analysis

**Action:** Identify how components interact

**Integration Points:**

- API endpoints and their consumers
- Database queries and their callers
- Event systems and listeners
- Shared utilities and helpers
- Cross-cutting concerns (logging, auth)

## Output

### Structure
PROJECT OVERVIEW
├── Architecture: [Type]
├── Main Technologies: [List]
├── Key Patterns: [List]
└── Entry Point: [File]

COMPONENT MAP
├── Frontend
│   └── [Structure]
├── Backend
│   └── [Structure]
├── Database
│   └── [Schema approach]
└── Tests
    └── [Test strategy]

KEY INSIGHTS
- [Important finding 1]
- [Important finding 2]
- [Unique patterns]

### Detailed Sections

**Technology Stack:**

- Primary languages and frameworks
- Key dependencies and their purposes
- Development and build tools
- Testing frameworks and strategies

**Architecture Patterns:**

- Overall architectural style (monolith, microservices, etc.)
- Design patterns in use (MVC, Observer, etc.)
- Data flow patterns
- Error handling strategies

**Component Relationships:**

- How major components communicate
- Dependency injection patterns
- Event flow and messaging
- Shared state management

**Configuration Environment:**

- Environment variable usage
- Configuration file structure
- Deployment-specific settings
- Feature flags and toggles

## Analysis Depth

### Large Codebases

For large and complex systems, create a todo list to explore specific areas in detail:

- Specific domain areas
- Complex integration points
- Performance-critical components
- Security implementations

### Mental Model

Provide a complete mental model of how the application works:

- How data flows through the system
- Where business logic is implemented
- How components are structured and interact
- What patterns and conventions are followed
- Where key configurations and settings live

### Practical Application

This analysis serves as the foundation for:

- Understanding existing code before making changes
- Identifying areas for refactoring or improvement
- Planning new feature implementations
- Onboarding new team members
- Documentation and knowledge transfer
