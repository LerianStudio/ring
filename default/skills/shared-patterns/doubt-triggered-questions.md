# Doubt-Triggered Questions Pattern

Add this section to agents and skills that make decisions:

## When to Ask vs Proceed

**Resolution hierarchy (check in order):**

1. **User's dispatch context** - Did they already specify?
2. **CLAUDE.md / repo conventions** - Is there a standard?
3. **Codebase patterns** - What does existing code do?
4. **Pre-dev artifacts** - PRD, TRD, research docs?
5. **Best practice** - Is one approach clearly superior?
6. **→ ASK** - Only if all above fail AND it affects correctness

## Genuine Doubt Criteria

Use `AskUserQuestion` only when ALL of these are true:

□ Cannot resolve from context hierarchy above
□ Multiple approaches are genuinely viable
□ Choice significantly impacts implementation correctness
□ Getting it wrong would waste substantial effort

**Not genuine doubt:**
- Preference questions when conventions exist
- Decisions the codebase already answers
- Choices where one approach is clearly superior
- Questions you could answer with 30 seconds of exploration

## Question Quality

**Good question (shows work):**
```
I found PostgreSQL in docker-compose but MongoDB references in
the config docs. This feature involves time-series metrics which
could work with either. Which database should I extend?

Options:
- PostgreSQL (existing, relational)
- MongoDB (documented, better for time-series)
```

**Bad question (lazy):**
```
Which database should I use?
```

**Structure:**
1. What you found (evidence of exploration)
2. Why you're uncertain (the genuine conflict)
3. Options with trade-offs (show you understand both)
4. Your lean, if any (optional but helpful)

## When to Proceed Without Asking

**Make a justified choice when:**
- One approach is clearly best practice
- Requirements strongly imply a specific solution
- Codebase conventions are established
- Context provided by user is sufficient

**If proceeding without asking:**
1. State assumption explicitly
2. Explain why this choice fits
3. Note what would change the decision

Example:
```
Using PostgreSQL with the existing schema pattern since:
- docker-compose already configures it
- User service follows the same repository pattern
- Would reconsider if you need document-style storage
```

## Anti-Patterns

**Never:**
- Ask what the dispatch context already specifies
- Ask about conventions when CLAUDE.md defines them
- Ask preferences when codebase patterns exist
- Ask multiple questions when one would suffice
- Ask just to "be safe" or "confirm"

**Always:**
- Explore before asking (30 seconds can save a question)
- Include evidence of what you checked
- Provide your recommendation when you have one
- Accept that proceeding with a reasonable default is often better than asking

## Integration with Other Patterns

This pattern complements:
- **state-tracking.md** - Track what context you've gathered
- **failure-recovery.md** - If stuck after 3 attempts, THEN ask
- **exit-criteria.md** - Don't ask to confirm completion; verify with evidence
