---
allowed-tools: Read(*), Glob(*), Grep(*), Edit(*), MultiEdit(*), Bash(*), Task(*), TodoWrite(*)
description: Unified code improvement with multiple modes for refactor, standardize, simplify, and beautify
argument-hint: [--mode=refactor|standardize|simplify|beautify] [--target=<path>] [--git-scope=<scope>] [--apply-fixes]
---

# /ring-dev-team:quality:code-improve

## Instructions

Unified code improvement command supporting multiple enhancement modes for comprehensive code quality improvements with both automated fixes and manual recommendations.

**Purpose:**

- Apply automated code improvements with multiple enhancement strategies
- Support refactor, standardize, simplify, and beautify modes
- Git-focused improvements for active development workflows
- Safe automated fixes with manual review options

**Scope:**

Covers comprehensive code enhancement including architectural refactoring, style standardization, complexity reduction, and readability improvements across the entire codebase or targeted areas.

## Context

This command provides mode-based code improvement functionality, allowing developers to apply specific types of enhancements based on their current needs while maintaining code safety and functionality.

## Usage Examples

### Mode-Based Examples

```bash
# Refactor Mode - Architectural improvements
/ring-dev-team:quality:code-improve --mode=refactor --target=src/components/   # Refactor components
/ring-dev-team:quality:code-improve --mode=refactor --git-scope=branch         # Refactor branch changes

# Standardize Mode - Consistency improvements
/ring-dev-team:quality:code-improve --mode=standardize --target=src/           # Standardize directory
/ring-dev-team:quality:code-improve --mode=standardize --git-scope=staged      # Standardize staged files

# Simplify Mode - Complexity reduction
/ring-dev-team:quality:code-improve --mode=simplify --target=src/utils/        # Simplify utilities
/ring-dev-team:quality:code-improve --mode=simplify --git-scope=all-changes    # Simplify all changes

# Beautify Mode - Readability improvements
/ring-dev-team:quality:code-improve --mode=beautify --target=src/hooks/        # Beautify hooks
/ring-dev-team:quality:code-improve --mode=beautify --apply-fixes              # Auto-apply safe fixes
```

## Process

### Mode Selection

Determine improvement mode and validate parameters:

**Modes:**

- **refactor**: Architectural improvements and design pattern application
- **standardize**: Consistency and coding standards enforcement
- **simplify**: Complexity reduction and readability enhancement
- **beautify**: Visual structure and naming improvements

### Git Scope Analysis

Process git scope when specified:

**Scopes:**

- **staged**: Focus on staged files only
- **all-changes**: All uncommitted changes
- **branch**: Feature branch changes vs main/master
- **last-commit**: Most recent commit changes

### Improvement Execution

Apply mode-specific improvements based on selection:

**Safety:**

- Preserve all functionality and business logic
- Run tests if available to validate changes
- Create git checkpoints for significant modifications
- Apply improvements incrementally with validation

## Improvement Modes

### Refactor Mode

**Purpose:** Analyze code for refactoring opportunities and apply architectural improvements

**Focus:**

- Extract large components into smaller, focused components
- Apply SOLID principles and design patterns
- Identify and eliminate code smells
- Improve component composition and reusability

**Techniques:**

- Extract custom hooks from complex components
- Split large functions into smaller, focused functions
- Apply dependency injection patterns
- Implement proper separation of concerns

### Standardize Mode

**Purpose:** Apply consistent coding standards and naming conventions

**Focus:**

- Consistent naming conventions across codebase
- Standardized file and directory organization
- Uniform code formatting and style
- Consistent error handling patterns

**Techniques:**

- Apply consistent camelCase/PascalCase naming
- Standardize import organization and structure
- Enforce consistent API response formats
- Unify configuration and constant management

### Simplify Mode

**Purpose:** Reduce complexity and improve code readability

**Focus:**

- Simplify complex conditionals and nested structures
- Replace imperative patterns with functional approaches
- Extract and name complex expressions
- Reduce cognitive load through clarity

**Techniques:**

- Use early returns instead of nested conditions
- Replace loops with array methods (map, filter, reduce)
- Extract boolean expressions into named variables
- Simplify JSX conditional rendering

### Beautify Mode

**Purpose:** Improve visual structure and code aesthetics

**Focus:**

- Clear, descriptive variable and function names
- Logical code organization and spacing
- Improved type annotations and documentation
- Enhanced readability through structure

**Techniques:**

- Apply descriptive naming for variables and functions
- Organize code sections with clear logical flow
- Add missing type annotations and interfaces
- Remove unused code and optimize imports

## Safety Requirements

### Functionality Preservation

- All business logic must remain identical
- Test suites must continue to pass
- No breaking changes to public APIs
- Preserve performance characteristics

### Validation Process

- Apply changes incrementally with validation
- Run available test suites after modifications
- Check TypeScript compilation if applicable
- Validate linting and formatting standards

### Rollback Capability

- Create git checkpoints before major changes
- Provide clear before/after comparisons
- Document all modifications made
- Support easy rollback of changes

## Automated Fixes

### Safe Improvements

- Remove unused imports and variables
- Fix consistent indentation and spacing
- Add missing semicolons and trailing commas
- Convert var to const/let where appropriate
- Extract magic numbers into named constants

### Manual Review Required

- Complex architectural refactoring
- Performance optimization changes
- Security-related modifications
- Logic flow alterations

## Deliverables

- Mode-specific code improvements applied
- Detailed report of changes made
- Before/after code examples for key improvements
- List of manual review items requiring attention
- Recommendations for follow-up improvements
- Documentation of any breaking changes (if unavoidable)
