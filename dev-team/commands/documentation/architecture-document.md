---
allowed-tools: Read, Write, Edit, Bash
argument-hint: [--framework=<framework>] [--format=c4-model|arc42|adr|plantuml] (optional: specify documentation framework preference)
---

# /ring-dev-team:documentation:architecture-document

## Instructions

Generate comprehensive architecture documentation: $ARGUMENTS

## Task Objective

Create comprehensive architecture documentation with modern tooling and best practices. Analyzes the entire system to document complete architecture, design decisions, and implementation patterns across the full codebase.

## Framework Selection

Choose appropriate documentation framework based on requirements:

- **C4 Model**: Context, Containers, Components, Code diagrams
- **Arc42**: Comprehensive architecture documentation template
- **Architecture Decision Records (ADRs)**: Decision documentation
- **PlantUML/Mermaid**: Diagram-as-code documentation
- **Structurizr**: C4 model tooling and visualization
- **Draw.io/Lucidchart**: Visual diagramming tools

## Current Architecture Context

- Project structure: !`find . -type f -name "*.json" -o -name "*.yaml" -o -name "*.toml" | head -5`
- Documentation exists: @docs/ or @README.md (if exists)
- Architecture files: !`find . -name "*architecture*" -o -name "*design*" -o -name "*.puml" | head -3`
- Services/containers: @docker-compose.yml or @k8s/ (if exists) - using docker compose v2 syntax
- API definitions: !`find . -name "*api*" -o -name "*openapi*" -o -name "*swagger*" | head -3`

This repository uses a collaborative development approach with specialized agents and structured workflows. The codebase follows modern best practices with emphasis on maintainability, performance, and thoughtful implementation.

## Documentation Process

### 1. Architecture Analysis and Discovery

- Analyze current system architecture and component relationships
- Identify key architectural patterns and design decisions
- Document system boundaries, interfaces, and dependencies
- Assess data flow and communication patterns
- Identify architectural debt and improvement opportunities

### 2. System Context Documentation

- Create high-level system context diagrams
- Document external systems and integrations
- Define system boundaries and responsibilities
- Document user personas and stakeholders
- Create system landscape and ecosystem overview

### 3. Container and Service Architecture

- Document container/service architecture and deployment view
- Create service dependency maps and communication patterns
- Document deployment architecture and infrastructure
- Define service boundaries and API contracts
- Document data persistence and storage architecture

### 4. Component and Module Documentation

- Create detailed component architecture diagrams
- Document internal module structure and relationships
- Define component responsibilities and interfaces
- Document design patterns and architectural styles
- Create code organization and package structure documentation

### 5. Data Architecture Documentation

- Document data models and database schemas
- Create data flow diagrams and processing pipelines
- Document data storage strategies and technologies
- Define data governance and lifecycle management
- Create data integration and synchronization documentation

### 6. Security and Compliance Architecture

- Document security architecture and threat model
- Create authentication and authorization flow diagrams
- Document compliance requirements and controls
- Define security boundaries and trust zones
- Create incident response and security monitoring documentation

### 7. Quality Attributes and Cross-Cutting Concerns

- Document performance characteristics and scalability patterns
- Create reliability and availability architecture documentation
- Document monitoring and observability architecture
- Define maintainability and evolution strategies
- Create disaster recovery and business continuity documentation

### 8. Architecture Decision Records (ADRs)

- Create comprehensive ADR template and process
- Document historical architectural decisions and rationale
- Create decision tracking and review process
- Document trade-offs and alternatives considered
- Set up ADR maintenance and evolution procedures

### 9. Documentation Automation and Maintenance

- Set up automated diagram generation from code annotations
- Configure documentation pipeline and publishing automation
- Set up documentation validation and consistency checking
- Create documentation review and approval process
- Train team on architecture documentation practices and tools
- Set up documentation versioning and change management

## Output Deliverables

### Core Documentation

- **System Architecture Overview** - High-level system design and patterns
- **Component Architecture** - Detailed component relationships and interfaces
- **Data Architecture** - Database schemas, data flow, and storage patterns
- **Infrastructure Architecture** - Deployment, scaling, and operations documentation
- **Security Architecture** - Security controls, threat model, and compliance

### Decision Documentation

- **Architecture Decision Records (ADRs)** - Historical decisions and rationale
- **Technology Choices** - Framework and library selection justification
- **Design Pattern Documentation** - Architectural patterns and their application
- **Trade-off Analysis** - Alternative solutions and selection criteria

### Visual Documentation

- **System Context Diagrams** - External dependencies and integrations
- **Container Diagrams** - High-level system containers and communication
- **Component Diagrams** - Internal structure and component relationships
- **Deployment Diagrams** - Infrastructure and deployment topology
- **Data Flow Diagrams** - Information flow through the system

### Process Documentation

- **Development Workflows** - Code organization and development processes
- **Deployment Processes** - Build, test, and deployment procedures
- **Monitoring and Operations** - Observability and operational procedures
- **Incident Response** - Error handling and recovery procedures

## Documentation Structure

### Architecture Overview Document Template

```markdown
# Architecture Overview

## Executive Summary

[Brief description of system purpose and key architectural decisions]

## System Context

[External systems, users, and boundaries]

## Architecture Principles

[Core principles guiding design decisions]

## High-Level Architecture

[System containers and major components]

## Key Design Decisions

[Major architectural choices and rationale]

## Quality Attributes

[Performance, security, scalability, maintainability]

## Technology Stack

[Languages, frameworks, databases, infrastructure]

## Deployment Architecture

[How system is deployed and operated]
```

### ADR Template

```markdown
# ADR-XXXX: [Decision Title]

## Status

[Proposed | Accepted | Rejected | Deprecated | Superseded]

## Context

[What is the issue that we're seeing that is motivating this decision or change?]

## Decision

[What is the change that we're proposing or have agreed to implement?]

## Consequences

[What becomes easier or more difficult to do and any risks introduced by the change?]

## Alternatives Considered

[What other options were considered and why were they rejected?]
```

### Component Documentation Template

```markdown
# [Component Name]

## Purpose

[What this component does and why it exists]

## Responsibilities

[Key responsibilities and boundaries]

## Interfaces

[Public APIs, events, and integration points]

## Dependencies

[What this component depends on]

## Implementation Notes

[Key implementation details and patterns]

## Configuration

[Configuration options and environment variables]

## Monitoring

[Metrics, logging, and health checks]
```
