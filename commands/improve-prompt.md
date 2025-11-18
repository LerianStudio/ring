Use the prompt-engineer agent to review and enhance a prompt using best practices.

**Usage:**
- `/ring:improve-prompt <file-path>` - Review and enhance prompt in file
- `/ring:improve-prompt` - Review prompt from conversation context

**Example:**
```
User: /ring:improve-prompt agents/my-agent.md
Assistant: Analyzing prompt in agents/my-agent.md...
[Invokes prompt-engineer agent]
```

**The agent will:**
1. Analyze the current prompt for clarity, structure, and completeness
2. Launch subagents if needed to understand codebase context
3. Identify issues (Critical/High/Medium/Low)
4. Provide enhanced version with specific improvements
5. Explain what was improved and why

**After completion:**
- Review the enhanced prompt version
- Compare before/after improvements
- Apply enhancements to your prompt
- Re-test to verify improvements

**Best for:**
- Creating new agent definitions
- Improving existing skills
- Optimizing prompts with inconsistent results
- Learning prompt engineering best practices

