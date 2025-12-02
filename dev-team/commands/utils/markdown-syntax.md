---
allowed-tools: Read(*), Write(*), Edit(*), MultiEdit(*), Grep(*), Glob(*)
description: Format text in markdown syntax or fix existing markdown files with standard conventions
argument-hint: [--input=<file-path-or-text>]
---

# /shared:utils:markdown-syntax

## Instructions

Format text in markdown syntax or identify and fix issues in existing markdown files. Enforces standard markdown conventions and ensures all content is properly structured.

This command can be used in several ways:

1. **Fix existing markdown file**: `/shared:utils:markdown-syntax --input=path/to/file.md`
2. **Format text as markdown**: `/shared:utils:markdown-syntax --input="Your text content here"`
3. **Preview changes without saving (recommended)**: `/shared:utils:markdown-syntax --input=path/to/file.md --dry-run`

## Context

This command ensures all markdown files and text content follow standard markdown conventions, improving readability and consistency across documentation and content files.

## Process

1.  **Analyze Input**
    - If input is a file path, read the file and analyze its markdown syntax.
    - If input is text content, prepare to format it as proper markdown.
    - Identify all markdown issues and formatting problems.

2.  **Fix or Format Content with Standard Conventions**
    - Fix broken headings, lists, links, and other markdown elements.
    - Ensure proper spacing around headers and code blocks.
    - Validate link syntax and image references.
    - Apply consistent formatting for emphasis, bold text, and inline code.
    - **MANDATORY**: Ensure all content is part of a standard markdown structure:
      - Headers: Use `#`, `##`, `###` for hierarchical structure.
      - Lists: Use `-` or `*` for bullets, `1.` for numbered lists.
      - Blockquotes: Use `>` for quotes, citations, or callouts.
      - Code: Use `` ` `` for inline code, ``` for code blocks.
      - Paragraphs: Ensure text blocks are correctly formatted as paragraphs.

3.  **Ensure Consistent Markdown Structure**
    - **PROPER PARAGRAPHS**: Ensure paragraphs are correctly separated by single blank lines.
    - Add missing bullet points to list items where appropriate.
    - Format image/diagram references with proper syntax.
    - Ensure consistent indentation and hierarchy.
    - **VALIDATION**: Verify all content is part of a recognized markdown element.

4.  **Apply Changes**
    - For files: update the file with corrected markdown using `MultiEdit` for efficiency.
    - For text: provide properly formatted markdown output.
    - If `--dry-run` is used, display the proposed changes without modifying the file.
    - Verify all markdown syntax is valid and follows standard conventions.

## Fixes Applied

### Structure & Hierarchy

- **Headers**: Ensure proper `#` spacing and logical hierarchy (h1 → h2 → h3)
- **Sections**: Add missing section headers for content organization
- **Document flow**: Ensure logical progression and proper nesting

### Lists & Content Organization

- **Lists**: Fix indentation and bullet/number formatting
- **Sub-lists**: Proper indentation for nested items
- **Consistency**: Standardize bullet style (`-` vs `*` vs `+`)

### Text Formatting

- **Paragraphs**: Ensure proper separation between paragraphs with a single blank line
- **Links**: Validate `[text](url)` syntax and fix broken references
- **Code blocks**: Ensure proper backtick usage and language tags
- **Inline code**: Use backticks for code snippets and commands
- **Emphasis**: Standardize `*italic*` and `**bold**` formatting
- **Line breaks**: Add proper spacing between sections and paragraphs

### Special Content

- **Tables**: Align columns and fix pipe syntax
- **Blockquotes**: Use `>` for quotes, callouts, and citations
- **Images**: Proper `![alt](src)` syntax with descriptive alt text
- **Horizontal rules**: Use `---` for section breaks

## Example

```bash
# Analyze and fix all markdown issues in README.md
/shared:utils:markdown-syntax --input=README.md
```

```bash
# Preview the changes for README.md without saving them
/shared:utils:markdown-syntax --input=README.md --dry-run
```

```bash
# Format a string of text with proper markdown syntax
/shared:utils:markdown-syntax --input="This is a header\n\nSome text with **bold** and *italic* formatting."
```

## Requirements
## Validation Rules

The command enforces these standard rules:

- ✅ **Paragraphs are correctly formatted** and separated by blank lines
- ✅ **All content is part of a recognized markdown element** (paragraph, header, list, etc.)
- ✅ **Consistent hierarchy** in headers and nested content
- ✅ **Proper spacing** between all markdown elements
- ✅ **Valid syntax** for all markdown constructs

## Output Requirements

The command will:

- Update the specified file with compliant markdown syntax
- Or, display the properly formatted markdown text for manual use
- Report the comprehensive fixes that were applied
- Provide validation confirmation that all conventions are followed

## Quality Assurance

After processing, the command performs a final validation to ensure:

1. All paragraphs are properly formatted and separated
2. All headers follow proper hierarchy
3. Lists are consistently formatted
4. Code blocks have proper syntax highlighting
5. Links and images use correct markdown syntax
6. Document structure is logical and well-organized
