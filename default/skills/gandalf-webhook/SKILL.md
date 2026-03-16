---
name: gandalf-webhook
description: Send tasks to Gandalf (AI team member) via webhook and get responses back. Publish to Alfarrábio, send Slack notifications, ask for business context, and more.
allowed-tools: Bash, Read, Write
metadata:
  user_invocable: true
---

# Gandalf Webhook

Send tasks to Gandalf and get responses back. Gandalf is Lerian's AI team member running on a dedicated Mac mini with access to Slack, Google Workspace, GitHub, Jira, Alfarrábio (report server), and more.

## Endpoint

```
POST http://gandalf.heron-justitia.ts.net:18792/task
```

Tailscale only. No auth token — identity resolved from your Tailscale node.

## Actions

### `publish` — instant (<1s)

Write content directly to Alfarrábio and get the URL back. No agent bootstrap.

```bash
curl -s -X POST http://gandalf.heron-justitia.ts.net:18792/task \
  -H "Content-Type: application/json" \
  -d '{
    "action": "publish",
    "message": "My Report Title",
    "content": "<html>...full report...</html>",
    "context": "optional context"
  }'
```

Response (synchronous):
```json
{
  "ok": true,
  "task_id": "a1b2c3d4",
  "status": "done",
  "response": "https://alfarrabio.lerian.net/my-report-title.html"
}
```

### `notify` — instant (<1s)

Send a Slack message. Prefix with `#channel:` to target a specific channel.

```bash
curl -s -X POST http://gandalf.heron-justitia.ts.net:18792/task \
  -H "Content-Type: application/json" \
  -d '{
    "action": "notify",
    "message": "#pull-requests: PR #1900 lib-commons v4 ready for review"
  }'
```

Without `#channel:` prefix, sends to #gandalf-notifications.

### `ask` — full agent (~30-60s)

Open a full OpenClaw agent session. Use for anything that needs intelligence: business context, analysis, cross-tool tasks. This is the default when `action` is omitted.

```bash
# Send task
RESP=$(curl -s -X POST http://gandalf.heron-justitia.ts.net:18792/task \
  -H "Content-Type: application/json" \
  -d '{
    "action": "ask",
    "message": "What is the current status of the Voluti integration?",
    "context": "investigating INC-72"
  }')
TASK_ID=$(echo $RESP | jq -r .task_id)

# Poll until done
for i in $(seq 1 60); do
  RESULT=$(curl -s http://gandalf.heron-justitia.ts.net:18792/task/$TASK_ID)
  STATUS=$(echo $RESULT | jq -r .status)
  if [ "$STATUS" != "processing" ]; then
    echo $RESULT | jq .
    break
  fi
  sleep 5
done
```

## Fields

| Field | Required | Description |
|-------|----------|-------------|
| `message` | Yes | What to do. For `publish`, this becomes the report title. |
| `action` | No | `publish` (instant), `notify` (instant), `ask` (full agent). Default: `ask`. |
| `content` | No | Inline content (HTML, markdown, text). Required for `publish`. Max 5MB. |
| `context` | No | What you're working on (repo, PR, feature). |

## Polling (for `ask` only)

```
GET http://gandalf.heron-justitia.ts.net:18792/task/{task_id}
```

`publish` and `notify` return the result synchronously — no polling needed.

## When to Use What

| Need | Action | Speed |
|------|--------|-------|
| Publish HTML/markdown report | `publish` | <1s |
| Send Slack notification | `notify` | <1s |
| Ask business/product question | `ask` | 30-60s |
| Complex cross-tool task | `ask` | 30-300s |
| Anything without `action` field | `ask` | 30-300s |

## Constraints

- **Rate limit:** 10 requests/min per Tailscale node
- **Content limit:** 5MB inline
- **Agent timeout:** 300s (for `ask` actions)
- **Tailscale only:** not accessible from the public internet
- **No file uploads:** send content inline as JSON string

## Health Check

```bash
curl -s http://gandalf.heron-justitia.ts.net:18792/health
```
