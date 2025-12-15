---
name: ring-tw-team:write-guide
description: Start writing a functional guide with voice, tone, and structure guidance
argument-hint: "[topic]"
arguments:
  - name: topic
    description: The topic or feature to document
    required: true
---

# Write Guide Command

You're starting a functional documentation task. Follow these steps:

## 1. Understand the Topic

**Topic to document:** $ARGUMENTS.topic

First, gather context about this topic:
- What is it and why does it matter?
- Who is the target audience?
- What should readers be able to do after reading?

## 2. Choose Document Type

Select the appropriate structure:

### Conceptual Documentation
For explaining what something is and how it works.

### Getting Started Guide
For helping users accomplish their first task.

### How-To Guide
For task-focused instructions with specific goals.

### Best Practices
For guidance on optimal usage patterns.

## 3. Apply Writing Standards

### Voice and Tone
- Write like you're helping a smart colleague who just joined
- Use "you" not "users"
- Use present tense
- Use active voice
- Be assertive but not arrogant

### Structure
- Sentence case for headings
- Short sentences (one idea each)
- Short paragraphs (2-3 sentences)
- Use `---` dividers between major sections
- Include examples

### Must Include
- Clear value statement at the start
- Key characteristics or steps
- Working examples
- Links to related content
- Next steps at the end

## 4. Dispatch Agent

For complex documentation, dispatch the functional-writer agent:

```
Task tool:
  subagent_type: "functional-writer"
  model: "opus"
  prompt: "Write a [document type] for [topic]. Target audience: [audience].
          The reader should be able to [goal] after reading."
```

## 5. Review Before Publishing

After writing, use the docs-reviewer agent:

```
Task tool:
  subagent_type: "docs-reviewer"
  model: "opus"
  prompt: "Review this documentation for voice, tone, structure, and completeness:
          [paste documentation]"
```

## Quick Reference

### Document Structures

**Conceptual:**
```
# Concept
Definition paragraph
## Key characteristics
## How it works
---
## Related concepts
```

**Getting Started:**
```
# Getting started with X
## Prerequisites
---
## Step 1
## Step 2
---
## Next steps
```

**How-To:**
```
# How to X
## Before you begin
## Steps
## Verification
```

**Best Practices:**
```
# Best practices for X
## Practice 1
- Mistake:
- Best practice:
## Summary
```

## Proceed

**Topic to document:** $ARGUMENTS.topic
