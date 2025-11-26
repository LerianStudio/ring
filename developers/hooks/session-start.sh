#!/bin/bash
# Session start hook for ring-developers plugin
# Injects quick reference for developer specialist agents

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<ring-developers-system>\n**Developer Specialists Available**\n\nUse these specialized agents via Task tool with `subagent_type`:\n\n| Agent | Expertise |\n|-------|----------|\n| `backend-engineer-golang` | Go, APIs, microservices, databases |\n| `frontend-engineer` | React, TypeScript, UI, state management |\n| `devops-engineer` | CI/CD, Docker, Kubernetes, infrastructure |\n| `qa-analyst` | Testing, automation, quality gates |\n| `sre` | Monitoring, reliability, performance |\n\nFor full details and decision guide: Skill tool with \"ring-developers:using-developers\"\n</ring-developers-system>"
  }
}
EOF
