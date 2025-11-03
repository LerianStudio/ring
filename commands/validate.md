Validate skill compliance using the compliance validator.

**Usage:**
- `/ring:validate <skill-name>` - Check compliance for skill
- `/ring:validate <skill-name> <rule-id>` - Check specific rule

**Example:**
```bash
User: /ring:validate test-driven-development
Assistant: Running compliance check for test-driven-development...

[Runs lib/compliance-validator.sh]
[Shows results: which rules passed/failed]
```

**The validator checks:**
- Compliance rules defined in skill frontmatter
- File existence patterns
- Command execution requirements
- Git diff ordering (test before code)

**Output:**
- ✓ PASS: All rules satisfied
- ✗ FAIL: Shows which rules violated and why
