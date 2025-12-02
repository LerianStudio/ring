---
allowed-tools: Read(*), Write(*), Edit(*)
description: Expert prompt engineering and optimization for LLMs and AI systems
argument-hint: [<description or @file>] (text description or file reference)
---

# /shared:utils:prompt-engineer

Expert prompt engineering service for crafting effective prompts for LLMs and AI systems. This command specializes in creating optimized prompts using proven techniques and patterns.

## Instructions

- **CRITICAL**: ALWAYS display the complete prompt text in a clearly marked code block - never just describe it
- **CRITICAL**: Include implementation notes explaining design choices and techniques used
- **CRITICAL**: Provide usage guidelines and expected outcomes
- **CRITICAL**: Apply appropriate prompting techniques based on the input requirements
- **CRITICAL**: Use model-agnostic best practices unless specific model optimization is needed
- **CRITICAL**: ALWAYS save the generated prompt to `docs/prompts/` folder with a descriptive filename (create folder if it doesn't exist)

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
5. **Save Output**: Save the generated prompt to `docs/prompts/` folder (create if doesn't exist)

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

## Usage Examples

```bash
# Create a code review assistant prompt
/shared:utils:prompt-engineer "Create a code review assistant"

# Reference a file with requirements
/shared:utils:prompt-engineer @requirements.md

# Debug performance issues
/shared:utils:prompt-engineer "Help debug React performance issues"

# Create analysis prompts
/shared:utils:prompt-engineer "Analyze financial data trends"

# Generate creative writing assistant
/shared:utils:prompt-engineer "Technical documentation writing assistant"
```

## Required Output Format

Every prompt creation MUST include:

### The Prompt

```
[Complete prompt text will be displayed here in a code block]
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

## Input Processing

The command accepts:

- **Text Description**: Direct requirements or use case description
- **File Reference**: Use @filename to reference requirement files
- **Mixed Input**: Combination of text and file references

Input will be processed to identify the prompt requirements and select appropriate techniques.

## Quality Checklist

Before completing any prompt creation, verify:
☐ Complete prompt text is displayed (not just described)
☐ Prompt is clearly marked with headers or code blocks
☐ Implementation notes explain design choices
☐ Usage instructions are provided
☐ Expected outcomes are described
☐ Appropriate techniques are applied
☐ Best practices are followed
☐ Performance considerations are addressed

## Deliverables

1. **The Complete Prompt** (in formatted code block)
2. **Implementation Notes** (techniques and rationale)
3. **Usage Guidelines** (how to implement effectively)
4. **Expected Outcomes** (what results to anticipate)
5. **Performance Tips** (optimization and best practices)
6. **Saved File** (prompt saved to `docs/prompts/` with descriptive filename)

---

Input provided: $ARGUMENTS

Create an optimized prompt following the above specifications, ensuring the complete prompt text is displayed in a code block with comprehensive implementation guidance.
