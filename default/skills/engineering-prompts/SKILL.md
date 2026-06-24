---
name: ring:engineering-prompts
description: "Expert prompt engineering and optimization for LLMs and AI systems. Covers core patterns (zero-shot, few-shot, CoT, role-playing, constitutional, tree-of-thoughts), common use cases, and a three-phase process. Use when crafting or optimizing prompts for AI systems. Skip when the prompt is trivial or already performing well."
user-invocable: true
argument-hint: "<prompt-goal>"
---

# Engineering Prompts

## When to use
- Crafting new prompts for LLM-based systems or AI assistants
- Optimizing existing prompts that underperform or produce inconsistent results
- Selecting appropriate prompting techniques for a specific use case
- Structuring complex multi-step reasoning prompts

## Skip when
- The prompt is trivial and already producing good results
- The task is a direct code change, not prompt creation
- You need to execute the task described in the prompt rather than create a prompt for it

---

## Scope Boundaries

**THIS SKILL ONLY GENERATES PROMPTS. IT NEVER:**

- Proactively explores, modifies, or debugs any files in the codebase
- Attempts to fix, debug, or improve code in the project
- Performs the task described in the user's input

**Allowed reads:** Files the user explicitly references as input context, and `docs/prompts/` for saving output.

**THE INPUT IS A DESCRIPTION OF WHAT THE PROMPT SHOULD DO, NOT A TASK TO PERFORM.**

Example: `Help debug React performance issues` means:
- CREATE a prompt that helps users debug React performance issues
- DO NOT actually debug any React code

## Process

### Phase 1: Input Analysis

1. **Parse Input**: Analyze the provided description or file content
2. **Identify Use Case**: Determine the intended application and requirements
3. **Select Techniques**: Choose appropriate prompting patterns and methods

### Phase 2: Prompt Construction

1. **Structure Design**: Create clear prompt architecture using proven patterns
2. **Technique Application**: Apply selected prompting techniques (few-shot, chain-of-thought, etc.)
3. **Constraint Setting**: Define boundaries and output format specifications
4. **Validation**: Ensure prompt follows best practices and guidelines

### Phase 3: Documentation & Delivery

1. **Display Prompt**: Show complete prompt text in formatted code block
2. **Implementation Notes**: Explain techniques used and design rationale
3. **Usage Guidelines**: Provide clear instructions for implementation
4. **Performance Tips**: Include optimization suggestions and best practices
5. **Save Output**: Save the generated prompt to `docs/prompts/` directory (create if needed)

## Prompt Engineering Techniques

### Core Patterns

- **Zero-shot**: Direct instruction without examples
- **Few-shot**: Providing examples to guide behavior
- **Chain-of-thought**: Step-by-step reasoning prompts
- **Role-playing**: Assigning specific roles or personas
- **Constitutional**: Setting principles and boundaries
- **Tree-of-thoughts**: Multi-path reasoning approaches

### Common Use Cases

- **Code Review**: Technical analysis and improvement suggestions
- **Debugging**: Problem diagnosis and solution guidance
- **Analysis**: Data interpretation and insight extraction
- **Creative Writing**: Content generation and storytelling
- **Reasoning**: Logic problems and decision support
- **Summarization**: Content condensation and key points
- **Classification**: Categorization and labeling tasks
- **Extraction**: Information retrieval from text or data

## Input Processing

The skill accepts:

- **Text Description**: Direct requirements or use case description
- **File Reference**: Reference requirement files for context
- **Mixed Input**: Combination of text and file references

Input will be processed to identify the prompt requirements and select appropriate techniques.

## Required Output Format

Every prompt creation MUST include:

### The Prompt

```
[Complete prompt text displayed in a code block]
```

### Implementation Notes

- Key techniques used and rationale
- Model-specific optimizations applied
- Expected behavior and outcomes
- Performance considerations

### Usage Guidelines

- How to implement the prompt
- Input format requirements
- Expected output structure
- Error handling strategies

### Optimization Tips

- Performance benchmarks where applicable
- Iteration suggestions
- Common pitfalls to avoid
- Debugging approaches

## Quality Checklist

Before completing any prompt creation, verify:

- [ ] Complete prompt text is displayed (not just described)
- [ ] Prompt is clearly marked with headers or code blocks
- [ ] Implementation notes explain design choices
- [ ] Usage instructions are provided
- [ ] Expected outcomes are described
- [ ] Appropriate techniques are applied
- [ ] Best practices are followed
- [ ] Performance considerations are addressed

## Deliverables

1. **The Complete Prompt** (in formatted code block)
2. **Implementation Notes** (techniques and rationale)
3. **Usage Guidelines** (how to implement effectively)
4. **Expected Outcomes** (what results to anticipate)
5. **Performance Tips** (optimization and best practices)
6. **Saved File** (prompt saved to `docs/prompts/` with descriptive filename)
