---
name: ralph-loop
description: "Start Ralph Wiggum loop in current session"
argument-hint: "PROMPT [--max-iterations N] [--completion-promise TEXT]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-ralph-loop.sh)"]
hide-from-slash-command-tool: "true"
---

# Ralph Loop Command

Execute the setup script to initialize the Ralph loop:

```bash
bash -c '
# Disable glob expansion to prevent command injection from user-provided prompts
set -f
"'"${CLAUDE_PLUGIN_ROOT}"'/scripts/setup-ralph-loop.sh" "'"$ARGUMENTS"'"
SETUP_EXIT_CODE=$?
set +f

# If setup failed, do not continue with promise display
if [ $SETUP_EXIT_CODE -ne 0 ]; then
  exit $SETUP_EXIT_CODE
fi

# Extract and display completion promise if set (find session-based state file)
STATE_FILE=$(find .claude -maxdepth 1 -name "ralph-loop-*.local.md" -type f 2>/dev/null | head -1)
if [ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ]; then
  PROMISE=$(grep "^completion_promise:" "$STATE_FILE" | sed "s/completion_promise: *//" | sed "s/^\"\(.*\)\"$/\1/")
  if [ -n "$PROMISE" ] && [ "$PROMISE" != "null" ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "CRITICAL - Ralph Loop Completion Promise"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "To complete this loop, output this EXACT text:"
    echo "  <promise>$PROMISE</promise>"
    echo ""
    echo "STRICT REQUIREMENTS (DO NOT VIOLATE):"
    echo "  ✓ Use <promise> XML tags EXACTLY as shown above"
    echo "  ✓ The statement MUST be completely and unequivocally TRUE"
    echo "  ✓ Do NOT output false statements to exit the loop"
    echo "  ✓ Do NOT lie even if you think you should exit"
    echo ""
    echo "IMPORTANT - Do not circumvent the loop:"
    echo "  Even if you believe you are stuck, the task is impossible,"
    echo "  or you have been running too long - you MUST NOT output a"
    echo "  false promise statement. The loop is designed to continue"
    echo "  until the promise is GENUINELY TRUE. Trust the process."
    echo ""
    echo "  If the loop should stop, the promise statement will become"
    echo "  true naturally. Do not force it by lying."
    echo "═══════════════════════════════════════════════════════════"
  fi
fi
'
```

Please work on the task. When you try to exit, the Ralph loop will feed the SAME PROMPT back to you for the next iteration. You'll see your previous work in files and git history, allowing you to iterate and improve.

CRITICAL RULE: If a completion promise is set, you may ONLY output it when the statement is completely and unequivocally TRUE. Do not output false promises to escape the loop, even if you think you're stuck or should exit for other reasons. The loop is designed to continue until genuine completion.
