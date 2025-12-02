---
allowed-tools: Read(*), Write(*), Grep(*), LS(*), Task(*)
description: Comprehensively analyze directory structure, architecture patterns, and document findings
argument-hint: [--target-directory=<path>] (optional: defaults to current directory for comprehensive analysis)
---

# /ring-dev-team:analysis:directory-deep-dive

## Instructions

Analyze directory structure, architecture patterns, and provide comprehensive documentation of findings.

## Usage

```bash
/ring-dev-team:analysis:directory-deep-dive                                     # Analyze current directory comprehensively
/ring-dev-team:analysis:directory-deep-dive --target-directory=src/            # Analyze src directory comprehensively
/ring-dev-team:analysis:directory-deep-dive --target-directory=src/components  # Analyze components directory comprehensively
```

## Target Directory

- Performs comprehensive analysis of the specified directory or current working directory
- Always analyzes the full directory structure and subdirectories for complete context

## Task Objectives

1. Investigate the implementation principles and architecture of the code in the target directory and subdirectories

2. Analyze design patterns, dependencies, abstractions, and code organization
3. Document and report on discovered architectural knowledge and patterns
4. Provide actionable insights for future development work

## Investigation Process


### 1. Architecture Analysis

Look for and document:

- **Design patterns** being used throughout the codebase
- **Dependencies** and their purposes in the system
- **Key abstractions** and interfaces that define the architecture
- **Naming conventions** and code organization principles
- **Common implementation patterns** and architectural decisions

### 2. Code Structure Assessment

- Scan project structure to understand organization
- Identify main modules, packages, and entry points
- Map data flow and component relationships
- Locate configuration and environment files
- Analyze testing strategies and coverage

### 3. Documentation and Reporting


Generate comprehensive analysis including:

- **Purpose and responsibility** of the analyzed module
- **Key architectural decisions** and their rationale
- **Important implementation details** and patterns
- **Common patterns** used throughout the code
- **Gotchas** or non-obvious behaviors developers should know

### 4. Knowledge Capture


- Provide structured analysis of the directory and its components
- Include practical guidance for future development work
- Document architectural insights and recommendations

## Analysis Report Structure


The analysis should cover the following aspects in a comprehensive report:

### Directory Overview

- Purpose and responsibility of the analyzed directory
- High-level architectural patterns and decisions
- Organization principles and conventions

### Key Components Analysis

- Major files and their purposes
- Dependencies and relationships
- Design patterns employed

### Architecture Documentation

- Data flow patterns
- Configuration management
- Testing strategies
- Performance and security considerations

### Development Insights

- Common tasks and workflows
- Gotchas and important considerations
- Best practices and recommendations
- Future improvement opportunities

## Example Analysis Report


**Directory Analysis: src/components**

**Directory Overview:**

- Contains all React components organized by feature domain, following atomic design principles
- Hierarchical structure: atoms/ → molecules/ → organisms/ → templates/
- Follows consistent naming conventions and organization patterns

**Key Components Analysis:**

- Button (atoms/Button.tsx): Reusable button component with variants, uses compound components pattern
- UserCard (molecules/UserCard.tsx): User information display, demonstrates composition patterns
- Dependencies flow upward through the atomic hierarchy

**Architecture Documentation:**

- Design Patterns: Compound components, render props, custom hooks, CSS-in-JS
- Testing Strategy: Unit tests (.test.tsx), Storybook for visual testing, 87% coverage
- Configuration: styled-components theme system, component generators available

**Development Insights:**

- Common Tasks: Use npm run generate:component for new components
- Gotchas: Must use theme variables, requires ThemeProvider wrapper
- Best Practices: Check Storybook for usage examples, follow atomic design hierarchy
- Recommendations: Maintain test coverage, document component APIs in Storybook
## Implementation Notes
- This command provides comprehensive directory analysis and architectural documentation
- Focus on practical, actionable information that helps developers understand and work with the code
- Include both high-level architectural concepts and specific implementation details
- Document not just what the code does, but why it's structured the way it is
- Analysis should be thorough and provide valuable insights for future development

## Credit

This command is based on the work of Thomas Landgraf: https://thomaslandgraf.substack.com/p/claude-codes-memory-working-with
