# Hook User Message Contract

## Overview

The `userMessage` field in hook output enables hooks to send **mandatory user-facing messages** that Claude MUST display immediately, separate from system context.

## Schema

### Hook Output with userMessage

```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "userMessage": "🔄 **IMPORTANT: Ring marketplace updated!**\n⚠️ **ACTION REQUIRED:** Restart session.",
    "additionalContext": "<system-context>...</system-context>"
  }
}
```

### Fields

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `hookEventName` | string | Yes | Hook event name (SessionStart, UserPromptSubmit, etc.) |
| `userMessage` | string | No | User-facing message that MUST be shown verbatim |
| `additionalContext` | string | No | System context for Claude only (not shown to user) |

## Contract Rules

### When userMessage is Present

1. **MUST display verbatim** - No paraphrasing, summarizing, or modification
2. **MUST display in first response** - Cannot wait for "relevant context"
3. **MUST display at message start** - Before any other content
4. **MUST NOT skip** - No rationalization allowed ("not relevant", "will mention later", etc.)

### Verification

If Claude receives a `userMessage` and does NOT display it immediately → **automatic failure**.

## Usage Patterns

### Marketplace Updates (SessionStart)

```bash
# session-start.sh
if marketplace_was_updated; then
  update_message="🔄 **Ring marketplace updated!**\n⚠️ Restart session."
  output_json_with_user_message "$update_message"
fi
```

**Expected behavior:** Claude shows update message at start of first response.

### Critical Warnings (UserPromptSubmit)

```bash
# user-prompt-submit.sh
if dangerous_pattern_detected; then
  warning="⚠️ **WARNING:** Destructive operation detected. Confirm: (y/n)"
  output_json_with_user_message "$warning"
fi
```

**Expected behavior:** Claude shows warning before processing user request.

### Configuration Reminders (SessionStart)

```bash
# session-start.sh
if missing_required_config; then
  reminder="📋 **Setup Required:** Run /configure to set up project."
  output_json_with_user_message "$reminder"
fi
```

**Expected behavior:** Claude shows setup reminder at session start.

## Implementation Layers

Ring uses three enforcement layers to ensure compliance:

### Layer 1: Schema (Structural)

Separate `userMessage` field makes user messages structurally distinct from system context.

### Layer 2: System Prompt (Upstream)

**Proposed addition to Claude Code system prompt:**

```markdown
## Hook User Messages (MANDATORY)

When a hook returns a `userMessage` field:

1. ✅ Display it verbatim in your FIRST response
2. ✅ Place it at the START of your message (before other content)
3. ❌ Do NOT paraphrase, summarize, or modify it
4. ❌ Do NOT wait for relevant context to mention it
5. ❌ Do NOT rationalize skipping it

**Verification:** If you see userMessage and don't show it immediately, you have failed.
```

### Layer 3: Ring Skill (Defensive)

`using-ring` skill includes mandatory userMessage check in first response protocol:

```markdown
## MANDATORY FIRST RESPONSE PROTOCOL

1. ☐ Check SessionStart hook for userMessage field
2. ☐ If userMessage exists → Display it FIRST, verbatim
3. ☐ Then check for relevant skills
4. ☐ Then respond to user's request
```

## Anti-Patterns

### ❌ Don't: Paraphrase or Summarize

```text
Hook: "🔄 **IMPORTANT:** Marketplace updated. Restart session."
Claude: "I see the marketplace has been updated recently."  ← WRONG
```

### ❌ Don't: Delay Until "Relevant"

```text
Hook: "⚠️ **WARNING:** Destructive operation detected."
Claude: [processes request, then mentions warning later]  ← WRONG
```

### ❌ Don't: Rationalize Skipping

```text
Hook: "📋 **Setup Required:** Run /configure."
Claude: "User didn't ask about setup, so I'll skip this."  ← WRONG
```

### ✅ Do: Display Immediately and Verbatim

```text
Hook: "🔄 **IMPORTANT:** Marketplace updated. Restart session."
Claude: "🔄 **IMPORTANT:** Marketplace updated. Restart session.

Now, regarding your question about..."  ← CORRECT
```

## Testing Enforcement

### Manual Test

1. Edit hook to add userMessage: `update_message="TEST MESSAGE"`
2. Restart Claude session
3. Verify Claude displays "TEST MESSAGE" at start of first response
4. If not displayed → enforcement failed

### Automated Test (using-ring checklist)

The `using-ring` skill enforces userMessage check as first item in mandatory checklist:

```markdown
Before responding to ANY user message:
1. ☐ Check SessionStart hook for userMessage
2. ☐ If exists → display verbatim FIRST
3. ☐ TodoWrite: "Display hook userMessage" (mark complete after showing)
```

## Rationale

### Why Separate Field?

**Before:** Everything in `additionalContext` → ambiguous whether to show user

**After:** `userMessage` = show user, `additionalContext` = internal context

### Why Mandatory?

Critical operational messages (restart required, warnings, errors) MUST reach the user. Making display mandatory ensures:

1. **No missed notifications** - Update prompts always visible
2. **No rationalization** - Can't skip "because not relevant"
3. **Immediate visibility** - User sees message before any processing
4. **Defense in depth** - Three enforcement layers prevent failure

### Why Verbatim?

Hook authors craft messages with specific formatting (emojis, bold, structure). Paraphrasing loses:
- Visual urgency (⚠️, 🔄)
- Formatting emphasis (**IMPORTANT**)
- Exact action steps ("Type 'clear'" vs "restart somehow")

## Future Extensions

### Priority Levels

```json
{
  "userMessage": "Critical warning",
  "userMessagePriority": "high"  // high|medium|low
}
```

Higher priority = more prominent display (colors, borders, etc.).

### Interactive Messages

```json
{
  "userMessage": "Update available. Install now?",
  "userMessageActions": ["yes", "no", "later"]
}
```

Enable user response to hook messages (requires Claude Code support).

### Message Categories

```json
{
  "userMessage": "Session started successfully",
  "userMessageCategory": "info"  // error|warning|info|success
}
```

Visual styling based on message type.

## See Also

- `default/hooks/session-start.sh` - Implementation example
- `default/skills/using-ring/SKILL.md` - Enforcement checklist
- `default/hooks/hooks.json` - Hook configuration
