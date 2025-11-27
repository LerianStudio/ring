---
name: cancel-ralph
description: "Cancel active Ralph Wiggum loop"
allowed-tools: ["Bash"]
hide-from-slash-command-tool: "true"
---

# Cancel Ralph

```bash
bash -c '
STATE_FILE=$(find .claude -maxdepth 1 -name "ralph-loop-*.local.md" -type f 2>/dev/null | head -1)
if [[ -n "$STATE_FILE" ]] && [[ -f "$STATE_FILE" ]]; then
  ITERATION=$(grep "^iteration:" "$STATE_FILE" | sed "s/iteration: *//")
  SESSION_ID=$(grep "^session_id:" "$STATE_FILE" | sed "s/session_id: *//" | tr -d "\"")
  echo "FOUND_LOOP=true"
  echo "ITERATION=$ITERATION"
  echo "SESSION_ID=$SESSION_ID"
  echo "STATE_FILE=$STATE_FILE"
else
  echo "FOUND_LOOP=false"
fi
'
```

Check the output above:

1. **If FOUND_LOOP=false**:
   - Say "No active Ralph loop found."

2. **If FOUND_LOOP=true**:
   - Use Bash to remove the state file shown in STATE_FILE
   - Report: "Cancelled Ralph loop (session: SESSION_ID, was at iteration ITERATION)"
