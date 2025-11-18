---
name: prompt-engineer
description: Use when creating/improving agent prompts, skills, or instructions - reviews and enhances prompts using best practices, can launch subagents to assess codebase context for better prompt crafting
when_to_use: |
  **Mandatory:**
  - Creating new agent definitions (agents/*.md)
  - Creating or updating skills (skills/*/SKILL.md)
  - Writing complex instructions for Claude

  **Recommended:**
  - Refining existing prompts that produce inconsistent results
  - Debugging prompts that don't achieve intended behavior
  - Optimizing prompts for better performance
  - Converting informal instructions to structured prompts
---

# Prompt Engineering Skill

This skill guides you through the process of reviewing and enhancing prompts using industry best practices.

## Overview

**Purpose:** Systematically improve prompts for clarity, completeness, and effectiveness
**Approach:** Apply proven prompt engineering techniques, optionally launch subagents for codebase context
**Output:** Enhanced prompt with documented improvements

**Key Principle:** Great prompts are specific, structured, and provide clear guidance without overconstraining creativity.

---

## Workflow

### Phase 1: Initial Assessment

**Read and understand the prompt:**
1. What is the intended purpose?
2. Who is the audience (Claude, subagent, human)?
3. What context does it assume?
4. What behavior should it produce?

**If prompt context is unclear, use AskUserQuestion to clarify:**
- "What problem should this prompt solve?"
- "What behavior are you trying to achieve?"
- "Are there examples of good/bad outputs?"

### Phase 2: Codebase Analysis (Optional)

**When to launch subagents using Task tool:**
- Prompt references codebase patterns/conventions not visible in prompt
- Need to understand existing similar prompts for consistency
- Require examples from codebase to ground prompt in reality
- Need to verify technical accuracy of prompt instructions

**Subagent strategies:**
```markdown
# Example 1: Find similar patterns
Task: Search codebase for similar agent definitions
Query: "How are other review agents structured?"
Target: agents/*.md files

# Example 2: Understand conventions
Task: Analyze existing skills for patterns
Query: "What frontmatter fields do skills use?"
Target: skills/*/SKILL.md

# Example 3: Get concrete examples
Task: Find real code examples for prompt grounding
Query: "Show error handling patterns in the codebase"
Target: Relevant source files
```

**Launch subagents in parallel when exploring multiple aspects.**

### Phase 3: Apply Best Practices

Review against Anthropic's prompt engineering best practices and the checklist below.

### Phase 4: Create Enhanced Version

Generate improved prompt with:
- All identified issues addressed
- Best practices applied
- Codebase context incorporated (if gathered)
- Clear documentation of changes made

---

## Prompt Engineering Best Practices

### 1. Clarity & Structure ⭐ HIGHEST PRIORITY

**Clear Role Definition**
```markdown
❌ BAD: "You are an agent that helps with code"
✅ GOOD: "You are a Senior Code Reviewer specializing in Python. Your role is to identify bugs, security issues, and suggest improvements."
```

**Structured Organization**
- Use clear sections with headers (##, ###)
- Separate concerns (role, process, examples, anti-patterns)
- Progressive disclosure (general → specific)

**Explicit Task Definition**
```markdown
❌ BAD: "Review the code"
✅ GOOD: "Review the code for: 1) Security vulnerabilities, 2) Performance issues, 3) Code style violations. For each issue, provide file:line location and specific fix."
```

### 2. Provide Context & Examples

**Context Setting**
```markdown
✅ GOOD:
"You are reviewing code in a TypeScript/React codebase that:
- Uses functional components with hooks
- Follows ESLint Airbnb style guide
- Has test coverage requirement of 80%"
```

**Concrete Examples**
```markdown
✅ GOOD:
"Example of good error handling:
\`\`\`typescript
try {
  await operation();
} catch (error) {
  logger.error('Operation failed', { error, context });
  throw new OperationError('User-friendly message', { cause: error });
}
\`\`\`"
```

**Show Don't Tell**
- Provide examples of good vs bad outputs
- Show exact format expected
- Include edge cases

### 3. Specificity & Precision

**Specific Instructions**
```markdown
❌ BAD: "Be thorough"
✅ GOOD: "Check each function for: proper error handling, type safety, documentation, test coverage, edge case handling"
```

**Quantifiable Criteria**
```markdown
❌ BAD: "Code should be maintainable"
✅ GOOD: "Functions should be < 50 lines, cyclomatic complexity < 10, test coverage > 80%"
```

**Explicit Format Requirements**
```markdown
✅ GOOD:
"Output format (required):
## VERDICT: [PASS | FAIL]
## Issues Found
- Critical: [N]
- High: [N]
[Detailed list with file:line references]"
```

### 4. Constraint Definition

**Success Criteria**
```markdown
✅ GOOD:
"Review PASSES if:
- 0 Critical issues
- < 3 High issues
- All tests pass
- Coverage > 80%"
```

**Boundaries & Scope**
```markdown
✅ GOOD:
"Focus ONLY on security. Do NOT review:
- Code style (handled separately)
- Performance (unless security-relevant)
- Business logic correctness"
```

**Anti-Patterns Section**
```markdown
✅ GOOD:
"Do NOT:
- ❌ Suggest changes without explaining why
- ❌ Flag issues without providing file:line location
- ❌ Recommend rewrites without specific justification"
```

### 5. Process & Workflow

**Step-by-Step Process**
```markdown
✅ GOOD:
"1. Read requirements document
2. Analyze implementation against requirements
3. Check for edge cases
4. Verify test coverage
5. Generate report with findings"
```

**Decision Trees**
```markdown
✅ GOOD:
"If Critical issues found:
  → Stop review
  → Report Critical issues
  → Do not proceed to next steps

If no Critical issues:
  → Continue to High issues
  → [...]"
```

**Checklists**
```markdown
✅ GOOD:
"Security Checklist:
- [ ] No hardcoded credentials
- [ ] Input validation present
- [ ] SQL injection prevented
- [ ] XSS protection enabled"
```

### 6. Output Format Specification

**Schema Definition**
```yaml
output_schema:
  format: "markdown"
  required_sections:
    - name: "VERDICT"
      pattern: "^## VERDICT: (PASS|FAIL)$"
      required: true
```

**Template Provision**
```markdown
✅ GOOD:
"Use this EXACT format:
\`\`\`markdown
# Review Report

## VERDICT: [value]

## Summary
[2-3 sentences]

## Issues Found
- Critical: [N]
\`\`\`"
```

### 7. Persona & Tone

**Appropriate Expertise Level**
```markdown
❌ BAD: "You are smart"
✅ GOOD: "You are a Senior Security Engineer with 10 years experience in OWASP Top 10 vulnerabilities, penetration testing, and secure architecture design"
```

**Consistent Tone**
```markdown
✅ GOOD:
"Be constructive and educational in feedback:
- Explain WHY something is problematic
- Show HOW to fix it
- Acknowledge what was done well"
```

### 8. Edge Cases & Error Handling

**Explicit Edge Case Handling**
```markdown
✅ GOOD:
"Edge cases to check:
- Empty input
- Null values
- Zero values
- Very large values
- Concurrent access"
```

**Fallback Behavior**
```markdown
✅ GOOD:
"If requirements document not found:
1. Ask user: 'Where are the requirements?'
2. Do not proceed without requirements
3. Do not make assumptions about requirements"
```

### 9. Context Awareness

**Codebase Context**
```markdown
✅ GOOD:
"This codebase uses:
- Conventional commits (feat:, fix:, docs:)
- Test-driven development (write tests first)
- Pull request reviews (all code reviewed before merge)

Follow these existing patterns in your recommendations."
```

**Consistency Emphasis**
```markdown
✅ GOOD:
"Check for consistency with existing patterns:
- If other functions log entry/exit, this should too
- If error handling uses Result<T, E>, don't suggest exceptions
- Match existing naming conventions"
```

### 10. Measurable Outcomes

**Success Metrics**
```markdown
✅ GOOD:
"After following this prompt, you should be able to:
- Identify all SQL injection vulnerabilities (recall > 95%)
- Provide specific remediation code for each issue
- Complete review in < 15 minutes"
```

---

## Review Checklist

When reviewing a prompt, systematically check:

### Clarity & Structure
- [ ] Clear role definition with expertise level
- [ ] Organized sections with headers
- [ ] Logical flow (general → specific)
- [ ] Purpose statement at top
- [ ] Key principles highlighted

### Instructions & Guidance
- [ ] Specific, actionable instructions
- [ ] Step-by-step process provided
- [ ] Decision trees for complex logic
- [ ] Checklists for systematic review
- [ ] Priority/importance indicators

### Examples & Context
- [ ] Concrete examples (good vs bad)
- [ ] Code snippets where relevant
- [ ] Codebase context provided
- [ ] Edge cases illustrated
- [ ] Anti-patterns shown

### Constraints & Boundaries
- [ ] Clear success/fail criteria
- [ ] Scope explicitly defined
- [ ] What NOT to do specified
- [ ] Output format specified
- [ ] Pass/fail thresholds quantified

### Completeness
- [ ] All necessary context included
- [ ] Fallback behavior defined
- [ ] Error handling specified
- [ ] Edge cases covered
- [ ] Assumptions documented

### Consistency
- [ ] Terminology used consistently
- [ ] Format consistent throughout
- [ ] Tone consistent
- [ ] References to codebase patterns accurate

---

## Issue Categorization

Use these severity levels when identifying issues:

### Critical (Must Fix)
- Ambiguous or contradictory instructions
- Missing essential context that causes failures
- No success criteria or output format
- Unsafe instructions (could cause harm)
- Prompt injection vulnerabilities

### High (Should Fix)
- Vague instructions lacking specificity
- Missing examples for complex tasks
- No anti-patterns section
- Inconsistent terminology
- Missing edge case handling

### Medium (Consider Fixing)
- Could benefit from more examples
- Structure could be clearer
- Missing optional helpful context
- Tone inconsistencies
- Could be more concise

### Low (Nice to Have)
- Additional examples would help
- Minor formatting improvements
- Could add more context
- Optional sections missing

---

## Enhancement Process

### 1. Preserve Intent
- Keep the original purpose unchanged
- Don't add scope beyond original intent
- Maintain author's voice/style where appropriate

### 2. Apply Structured Improvements
- Add clear sections if missing
- Insert examples where helpful
- Define output format explicitly
- Add checklists for systematic work

### 3. Ground in Reality
- Use codebase examples when available (via subagents)
- Reference actual patterns/conventions
- Include real edge cases from domain
- Cite specific files/patterns

### 4. Test Mental Model
Ask yourself:
- "If I had no context, could I follow this?"
- "Would this produce consistent results?"
- "Are the success criteria clear?"
- "Can this be misinterpreted?"

---

## Output Format

Provide your analysis and enhancement in this structure:

```markdown
# Prompt Engineering Review

## VERDICT: [EXCELLENT | GOOD | NEEDS_IMPROVEMENT | POOR]

## Summary
[2-3 sentences about prompt quality and main findings]

## Issues Found
- Critical: [N]
- High: [N]
- Medium: [N]
- Low: [N]

---

## Critical Issues

[For each Critical issue:]

### [Issue Title]
**Category:** [Clarity | Structure | Context | Constraints | Format]
**Impact:** [Why this matters]

**Problem:**
[What's wrong with current prompt]

**Current:**
```
[Problematic section]
```

**Recommendation:**
```
[Improved version]
```

---

## High Issues

[Same format as Critical]

---

## Medium Issues

[More concise format]

---

## Low Issues

[Brief bullet list]

---

## Enhanced Prompt

**Here is the complete enhanced version:**

```markdown
[Full improved prompt with all enhancements applied]
```

**Key Enhancements Made:**
1. [Enhancement 1 with rationale]
2. [Enhancement 2 with rationale]
3. [Enhancement 3 with rationale]

---

## What Was Done Well

[Always acknowledge strengths]
- ✅ [Positive observation 1]
- ✅ [Positive observation 2]

---

## Comparison: Before vs After

**Improvements:**
- **Clarity:** [How clarity improved]
- **Specificity:** [How specificity improved]
- **Examples:** [What examples added]
- **Structure:** [How structure improved]

**Expected Impact:**
- More consistent outputs
- Better handling of edge cases
- Clearer success criteria
- Easier to follow

---

## Next Steps

**If EXCELLENT:**
- ✅ Prompt is production-ready
- ✅ Consider this as template for similar prompts

**If GOOD:**
- ✅ Prompt is usable with minor optional improvements
- ✅ Consider enhancements for future iteration

**If NEEDS_IMPROVEMENT:**
- ❌ Apply Critical/High issue fixes
- ❌ Test enhanced version
- ❌ Re-review after improvements

**If POOR:**
- ❌ Major rework needed
- ❌ Consider starting from scratch with clear requirements
- ❌ Clarify purpose and constraints before proceeding
```

---

## Anthropic Best Practices Reference

Based on Anthropic's prompt engineering documentation:

### 1. Be Clear and Direct
- State exactly what you want
- Use straightforward language
- Avoid unnecessary complexity

### 2. Use Examples (Few-Shot Prompting)
- Provide 2-3 examples of desired output
- Show edge cases
- Include both good and bad examples

### 3. Give Claude a Role
- "You are a [specific expert]"
- Include relevant expertise
- Set appropriate tone

### 4. Use XML Tags for Structure
```xml
<instructions>
  [Clear instructions]
</instructions>

<examples>
  [Examples here]
</examples>

<constraints>
  [Constraints here]
</constraints>
```

### 5. Chain of Thought
- Ask Claude to think step-by-step
- Request reasoning before conclusions
- Break complex tasks into steps

### 6. Prefill Claude's Response
Start the response for Claude to guide format/tone

### 7. Let Claude Say "I Don't Know"
```markdown
"If you're uncertain, say so. Don't make up information."
```

### 8. Long Context Window Usage
- Provide comprehensive context
- Include relevant documentation
- Don't over-summarize

---

## Common Prompt Anti-Patterns

### 1. Vague Instructions
```markdown
❌ "Make it better"
✅ "Improve code by: 1) Adding error handling, 2) Adding type hints, 3) Extracting duplicated logic"
```

### 2. Implicit Assumptions
```markdown
❌ "Review the code" (assumes what "review" means)
✅ "Review for: security vulnerabilities, type safety, error handling, test coverage"
```

### 3. No Examples
```markdown
❌ "Write tests"
✅ "Write tests using this pattern:
test('description', () => {
  // arrange
  // act
  // assert
})"
```

### 4. Conflicting Instructions
```markdown
❌ "Be concise but provide detailed explanations"
✅ "Provide brief summaries (1-2 sentences) followed by detailed explanations (2-3 paragraphs) for critical issues"
```

### 5. Missing Context
```markdown
❌ "Follow the style guide"
✅ "Follow ESLint Airbnb style guide with these modifications: [...]"
```

### 6. No Success Criteria
```markdown
❌ "Do a good job"
✅ "Success = 0 Critical issues, <3 High issues, all tests pass, coverage >80%"
```

---

## Integration with TodoWrite

For complex prompt improvement sessions, use TodoWrite to track progress:

```markdown
1. Read and understand original prompt
2. Launch subagents for codebase context (if needed)
3. Identify issues by severity
4. Create enhanced version
5. Document improvements and rationale
```

Mark each phase as complete as you progress.

---

## Required Patterns

This skill uses these universal patterns:
- **State Tracking:** See `skills/shared-patterns/state-tracking.md`
- **TodoWrite:** See `skills/shared-patterns/todowrite-integration.md`

Apply patterns when working through multi-phase improvements.

---

## Remember

1. **Preserve intent** - Enhance, don't change purpose
2. **Be specific** - Vague prompts produce vague results
3. **Provide examples** - Show, don't just tell
4. **Define success** - Clear criteria prevent ambiguity
5. **Use structure** - Organization aids comprehension
6. **Ground in reality** - Use actual codebase patterns (launch subagents)
7. **Test mentally** - Could someone else follow this?
8. **Follow Anthropic practices** - Leverage proven techniques
9. **Iterate** - Great prompts evolve through testing

Your role is to systematically transform good intentions into effective, actionable prompts that produce consistent, high-quality results.
