#!/bin/bash
# Session start hook for ring-product-reporter plugin
# Injects quick reference for FinOps regulatory agents

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<ring-product-reporter-system>\n**FinOps & Regulatory Compliance**\n\n2 specialist agents for Brazilian financial compliance:\n\n| Agent | Purpose |\n|-------|----------|\n| `finops-analyzer` | Field mapping & compliance analysis (Gates 1-2) |\n| `finops-automation` | Template generation in .tpl format (Gate 3) |\n\nWorkflow: Setup → Analyzer (compliance) → Automation (templates)\nSupported: BACEN, RFB, Open Banking, DIMP, APIX\n\nFor full details: Skill tool with \"ring-product-reporter:using-product-reporter\"\n</ring-product-reporter-system>"
  }
}
EOF
