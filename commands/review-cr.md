---
name: review-cr
description: Run CodeRabbit CLI code review with parameter support
---

I'm using the coderabbit-review skill to run external code review.

**Arguments:** {{args}}

The coderabbit-review skill will:
1. Parse arguments (type: all/committed/uncommitted, --base branch)
2. Validate base branch and check for existing processes
3. Run CodeRabbit CLI in background with monitoring
4. Present findings grouped by severity
5. Create todos for Critical/High issues
6. Prompt: "Would you like me to fix these issues?"

Follow the complete process defined in `skills/coderabbit-review/SKILL.md`.
