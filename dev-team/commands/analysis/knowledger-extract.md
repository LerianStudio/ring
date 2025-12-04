---
allowed-tools: Read(*), Glob(*), Grep(*), Bash(*), Write(*), Task(*)
description: Extract and document domain knowledge, business logic, and architectural patterns from codebases
argument-hint: [--focus-path=<file-or-directory-path>] (optional: emphasize specific area while extracting domain knowledge from entire codebase)
---

# /ring-dev-team:analysis:knowledger-extract

## Instructions

Extract and document domain knowledge, business logic, and architectural patterns from the entire codebase. Performs comprehensive analysis to understand the complete domain model and system architecture.

## Usage Options

```bash
/ring-dev-team:analysis:knowledger-extract                                      # Extract domain knowledge from entire codebase
/ring-dev-team:analysis:knowledger-extract --focus-path=src/models/             # Emphasize models while analyzing full codebase
/ring-dev-team:analysis:knowledger-extract --focus-path=src/services/           # Emphasize services while analyzing full codebase
```

## Arguments

- `--focus-path`: File or directory path to emphasize (optional, still analyzes entire codebase for context)

## Benefits of Full Codebase Analysis


- **Complete Domain Context**: Understand full business domain and entity relationships
- **Architectural Patterns**: Identify system-wide patterns and design decisions
- **Cross-Module Dependencies**: Map how different modules interact and share knowledge
- **Comprehensive Documentation**: Generate complete domain knowledge base

## Knowledge Extraction Process


### Initial Setup

Analyze entire codebase to extract comprehensive domain knowledge and architectural patterns.

### 1. Codebase Analysis

- Scan project structure to understand organization
- Identify main modules, packages, and entry points
- Map data flow and component relationships
- Locate configuration and environment files

### 2. Domain Model Discovery

#### Core Entities and Types

```bash
# Find domain models and entities
rg "class|interface|type.*=" --type ts --type js
rg "enum|const.*=" --type ts --type js

# Look for data transfer objects
rg "DTO|Request|Response|Model|Entity" --type ts --type js
```

#### Business Logic Patterns

```bash
# Find service layers and business logic
rg "Service|Handler|Controller|Manager|Repository" -A 3 -B 1
rg "impl.*for|func.*\(|public.*class" -A 5

# Identify validation rules and constraints
rg "validate|verify|check|ensure|require" -A 2 -B 1
```

### 3. API and Interface Documentation

#### REST Endpoints

```bash
# Find HTTP routes and handlers
rg "GET|POST|PUT|DELETE|PATCH" --type ts --type js
rg "Route|Path|Endpoint|@.*Mapping" -A 2 -B 1

# Look for OpenAPI/Swagger definitions
fd "openapi|swagger" --type f
rg "openapi|swagger" --type yaml --type json
```

#### RPC and Internal APIs

```bash
# Find gRPC/ConnectRPC services (preferred)
rg "service|rpc|proto" --type proto
fd "*.proto" --type f

# Find internal service interfaces
rg "trait|interface.*Service|interface.*Handler" -A 5
```

### 4. Data Architecture

#### Database Schema

```bash
# Find migration files and schema definitions
fd "migration|schema" --type f
rg "CREATE TABLE|ALTER TABLE|DROP TABLE" --type sql
rg "Migration|migration" -A 3 -B 1

# Look for ORM models and queries
rg "Model|Entity|@Table|@Column" -A 2
rg "SELECT|INSERT|UPDATE|DELETE" --type sql
```

#### Data Flow Patterns

```bash
# Find data transformation and mapping
rg "map|transform|convert|serialize|deserialize" -A 2 -B 1
rg "JSON.parse|JSON.stringify" --type ts --type js
rg "yaml:|toml:" --type ts --type js
```

### 5. Business Rules and Workflows

#### State Machines and Workflows

```bash
# Find state management and transitions
rg "State|Status|Phase|Stage" -A 3 -B 1
rg "match.*{|switch.*{|if.*state" -A 5

# Look for workflow engines or state machines
rg "workflow|state.*machine|transition|step" -A 2
```

#### Business Logic Patterns

```bash
# Find domain-specific calculations and rules
rg "calculate|compute|process|apply|execute" -A 3 -B 1
rg "business|domain|rule|policy|strategy" -A 2 -B 1

# Look for feature flags and conditional logic
rg "feature.*flag|toggle|enable|disable" -A 2
```

### 6. Configuration and Environment

#### Application Configuration

```bash
# Find configuration structures and defaults
rg "Config|Settings|Options" -A 5 -B 1
rg "default|DefaultConfig|default.*=" -A 3

# Look for environment variable usage
rg "env|ENV|getenv|std::env" -A 1 -B 1
fd ".env*" --type f
```

#### Infrastructure Configuration

```bash
# Find deployment and infrastructure configs
fd "docker|k8s|kubernetes|terraform" --type d
fd "Dockerfile|docker-compose.yml|*.yaml|*.yml" --type f
rg "image:|port:|volume:|secret:" --type yaml
```

### 7. Error Handling and Monitoring

#### Error Patterns

```bash
# Find error definitions and handling
rg "Error|Exception|Err|Result" -A 2 -B 1
rg "try|catch|unwrap|expect|panic" -A 1 -B 1

# Look for error codes and messages
rg "error.*code|error.*message|status.*code" -A 1
```

#### Logging and Observability

```bash
# Find logging and metrics
rg "log|info|warn|error|debug|trace" -A 1
rg "metric|counter|gauge|histogram" -A 1
rg "span|trace|opentelemetry" -A 1
```

### 8. Testing Patterns and Examples

#### Test Structure

```bash
# Find test patterns and examples
fd "test|spec" --type d
rg "test|Test|spec|Spec|describe|it" --type ts --type js -A 2

# Look for test data and fixtures
fd "fixture|mock|stub|testdata" --type f
rg "mock|stub|fake|test.*data" -A 1
```

#### Integration Examples

```bash
# Find integration and end-to-end tests
rg "integration|e2e|end.*to.*end" -A 3
rg "client|api.*test|http.*test" -A 2
```
## Knowledge Artifacts

### Generated Documentation Files

- `docs/architecture.md` - High-level system design
- `docs/domain-model.md` - Business entities and relationships
- `docs/api-reference.md` - API endpoints and usage
- `docs/development-guide.md` - Developer workflows and patterns
- `docs/deployment.md` - Infrastructure and deployment processes

### Decision Records

- Document architectural decisions (ADRs)
- Explain technology choices and trade-offs
- Record domain modeling decisions

### Code Examples

- Common usage patterns and idioms
- Integration examples and recipes
- Error handling best practices

### Output Deliverables

- Comprehensive domain model documentation
- API reference with examples
- Architecture diagrams and explanations
- Developer onboarding guide
- Business logic and workflow documentation
- Configuration and deployment guides
- Testing patterns and examples
- Troubleshooting and debugging guides

## Documentation Synthesis


### Architecture Overview Template

```markdown
# Architecture Overview

## Core Domains

- [List main business domains and entities]

## Service Architecture

- [Describe service layers and boundaries]

## Data Flow

- [Document how data moves through the system]

## Key Patterns

- [Identify recurring design patterns]
```

### Developer Guide Template

```markdown
# Developer Guide

## Getting Started

- [Key entry points and main files]

## Domain Concepts

- [Business terminology and concepts]

## Common Operations

- [Typical development tasks and workflows]

## Testing Strategy

- [How to write and run tests]
```

## Follow-up Actions


### Knowledge Validation

- Review extracted knowledge with domain experts
- Update documentation based on feedback
- Create knowledge documentation
- Set up documentation maintenance processes

### Integration Workflows

- Integrate with onboarding workflow (`/project:onboard`)
- Connect to architecture documentation processes
- Link to code review and development workflows
- Establish knowledge sharing practices

### Maintenance Strategy

- Set up automated knowledge extraction pipelines
- Create processes for keeping documentation current
- Establish review cycles for domain knowledge updates
- Train team on knowledge extraction and documentation practices
