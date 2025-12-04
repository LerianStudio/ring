---
allowed-tools: Bash(*), Read(*), Glob(*), Grep(*)
description: Answer questions about project structure and documentation without coding
argument-hint: [--question=<question>]
---

# /ring-dev-team:planning:question

## Context

Answer questions about the project structure and documentation by analyzing existing code and files. This command provides information and explanations without making any code changes.

## Instructions

- **CRITICAL**: This is a question-answering task only - DO NOT write, edit, or create any files
- **CRITICAL**: Focus on understanding and explaining existing code and project structure
- **CRITICAL**: Provide clear, informative answers based on project analysis
- **CRITICAL**: If the question requires code changes, explain what would need to be done conceptually without implementing

## Context

This command is designed for information gathering and project understanding. It helps users learn about their codebase by analyzing existing files, structure, and documentation without making modifications.

## Process

### Phase 1: Project Structure Discovery

1. **Execute**: `git ls-files` to understand the complete project structure
2. **Read**: README.md for project overview and key documentation
3. **Analyze**: Identify relevant files and directories for the question

### Phase 2: Targeted Analysis

1. **Search**: Use Glob and Grep tools to locate specific code patterns or files
2. **Read**: Examine relevant source files and documentation
3. **Connect**: Link the question to specific parts of the project

### Phase 3: Comprehensive Response

1. **Answer**: Provide direct response to the user's question
2. **Evidence**: Include supporting details from project structure analysis
3. **References**: Point to relevant documentation and file locations
4. **Concepts**: Explain conceptual approaches where applicable

## Requirements

- Must analyze project structure using git ls-files
- Must read and understand project documentation
- Must provide evidence-based answers with file references
- Must explain concepts without implementing code changes
- Must reference specific file paths using `file_path:line_number` format when applicable
- Must maintain read-only approach - no file modifications allowed

## Examples

```bash
# Ask about project architecture
/ring-dev-team:planning:question --question="How is the authentication system structured?"

# Understand component organization
/ring-dev-team:planning:question --question="Where are the React components located and how are they organized?"

# Learn about configuration
/ring-dev-team:planning:question --question="What configuration files are used and what do they control?"

# Explore testing setup
/ring-dev-team:planning:question --question="How is testing set up in this project and what frameworks are used?"
```

## Formatting

- **Direct Answer**: Clear response to the specific question asked
- **File References**: Use `file_path:line_number` format for code locations
- **Evidence**: Supporting details from actual project files
- **Documentation Links**: References to relevant README or doc sections
- **Conceptual Explanations**: High-level understanding where helpful

## Question

$ARGUMENTS
