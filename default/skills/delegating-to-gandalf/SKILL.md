---
name: ring:gandalf-webhook
description: Send tasks to Gandalf (AI team member) via webhook and get responses back. Publish to Alfarrábio, send Slack notifications, ask for business context, and more.
---

# Gandalf Webhook

## When to use
- Need to publish content to Alfarrábio (report server)
- Need to send Slack notifications via Gandalf
- Need to ask Gandalf for business context or information
- Need to delegate a task to Gandalf (AI team member on dedicated Mac mini)

## Skip when
- Not connected to Lerian's Tailscale network
- Task can be completed locally without Gandalf's capabilities

Send tasks to Gandalf and get responses. Tailscale only. No auth token.

```
POST http://gandalf.heron-justitia.ts.net:18792/task
```

## Actions

### `publish` — instant (<1s)

Write content to Alfarrábio, get URL back.

```bash
curl -s -X POST http://gandalf.heron-justitia.ts.net:18792/task \
  -H "Content-Type: application/json" \
  -d '{"action": "publish", "message": "Report Title", "content": "<html>...</html>"}'
```

Response: `{"ok": true, "task_id": "...", "status": "done", "response": "https://alfarrabio.lerian.net/..."}`

### `notify` — instant (<1s)

Send Slack message. Prefix with `#channel:` to target specific channel (default: #gandalf-notifications).

```bash
curl -s -X POST http://gandalf.heron-justitia.ts.net:18792/task \
  -H "Content-Type: application/json" \
  -d '{"action": "notify", "message": "#pull-requests: PR #1900 ready for review"}'
```

### `ask` — full agent (~30-60s)

Open a full agent session. Use for business context, analysis, cross-tool tasks.

```bash
# Send task
RESP=$(curl -s -X POST http://gandalf.heron-justitia.ts.net:18792/task \
  -H "Content-Type: application/json" \
  -d '{"action": "ask", "message": "What is the status of Voluti integration?", "context": "investigating INC-72"}')
TASK_ID=$(echo $RESP | jq -r .task_id)

# Poll until done — exit ONLY on terminal states
for i in $(seq 1 60); do
  RESULT=$(curl -s http://gandalf.heron-justitia.ts.net:18792/task/$TASK_ID)
  STATUS=$(echo $RESULT | jq -r .status)
  case "$STATUS" in
    completed|failed|error) echo $RESULT | jq . && break ;;
    processing) sleep 5 ;;
    *) sleep 5 ;;  # transient/unknown state — keep polling
  esac
done
```

## Fields

| Field | Required | Description |
|-------|----------|-------------|
| `message` | Yes | What to do. For `publish`, becomes the report title. |
| `action` | No | `publish`, `notify`, `ask` (default). |
| `content` | **Required for `publish`** | HTML/markdown/text for `publish`. Max 5MB. Omit for `notify` and `ask`. |
| `context` | No | What you're working on (repo, PR, feature). |

`publish` and `notify` are synchronous — no polling needed.

## When to Use What

| Need | Action | Speed |
|------|--------|-------|
| Publish HTML/markdown report | `publish` | <1s |
| Send Slack notification | `notify` | <1s |
| Ask business/product question | `ask` | 30-60s |
| Complex cross-tool task | `ask` | 30-300s |

## Constraints

- MUST respect rate limit: 10 requests/min per Tailscale node
- MUST keep content under 5MB inline
- MUST handle agent timeout: 300s maximum
- REQUIRED: Tailscale network only — MUST NOT call from public internet
- REQUIRED: No file uploads — content MUST be inline as JSON string

## Health Check

```bash
curl -s http://gandalf.heron-justitia.ts.net:18792/health
```
