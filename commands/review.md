Use the full-reviewer agent to run parallel code review (all 3 reviewers simultaneously).

**Usage:**
- `/ring:review` - Review all changed files
- `/ring:review <file-path>` - Review specific file
- `/ring:review <pattern>` - Review files matching pattern

**Example:**
```
User: /ring:review src/auth.ts
Assistant: Starting parallel review of src/auth.ts (3 reviewers in parallel)...
[Invokes full-reviewer agent which dispatches all 3 reviewers]
```

**The agent will:**
1. Dispatch all 3 reviewers in parallel (code, business logic, security)
2. Wait for all reviewers to complete
3. Aggregate findings by severity
4. Return consolidated report

**After completion:**
- Show consolidated findings from all 3 reviewers
- Highlight critical/high/medium issues requiring fixes
- Identify low/cosmetic issues for TODO/FIXME comments
- Provide clear next steps
