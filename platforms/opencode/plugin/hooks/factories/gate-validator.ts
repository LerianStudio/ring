/**
 * Gate Progression Validator — OpenCode Integration
 *
 * Soft block for OpenCode's tool.execute.before/after hooks.
 * OpenCode SDK doesn't support hard blocks (deny), so this uses
 * detect-and-revert:
 *
 * 1. tool.execute.before: Save backup of current-cycle.json
 * 2. tool.execute.after: Validate written state via the same shell
 *    script used by Claude Code. If invalid → revert file + replace
 *    tool output with block message.
 *
 * Reuses: dev-team/hooks/validate-gate-progression.sh (single source of truth)
 */

import * as fs from "node:fs"
import * as path from "node:path"
import { execSync } from "node:child_process"

/** Per-call state: tracks files we need to validate after write */
const pendingValidations = new Map<
  string,
  { filePath: string; previousContent: string | null; timestamp: number }
>()

/** Max age for pending entries (5 minutes) — prevents leaks on tool timeouts */
const PENDING_TTL_MS = 5 * 60 * 1000

/** Evict stale entries on each before hook call */
function evictStale(): void {
  const now = Date.now()
  for (const [key, entry] of pendingValidations) {
    if (now - entry.timestamp > PENDING_TTL_MS) {
      pendingValidations.delete(key)
    }
  }
}

/**
 * Resolve the validate-gate-progression.sh script path.
 */
function findValidatorScript(projectRoot: string): string | null {
  const candidates = [
    path.join(projectRoot, "dev-team", "hooks", "validate-gate-progression.sh"),
    // HOME-based path (skip if HOME undefined — literal "~" won't resolve)
    ...(process.env.HOME
      ? [path.join(process.env.HOME, ".config", "opencode", "hooks", "validate-gate-progression.sh")]
      : []),
    path.join(projectRoot, ".ring", "hooks", "validate-gate-progression.sh"),
  ]

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) return candidate
  }
  return null
}

/**
 * Run the shell validator script and return the result.
 */
function runValidator(
  scriptPath: string,
  toolInput: { file_path: string; content: string },
): { allowed: boolean; reason?: string } {
  const hookInput = JSON.stringify({
    tool_name: "Write",
    tool_input: {
      file_path: toolInput.file_path,
      content: toolInput.content,
    },
  })

  try {
    const result = execSync(`bash "${scriptPath}"`, {
      input: hookInput,
      encoding: "utf-8",
      timeout: 5000,
    })

    if (!result.trim()) return { allowed: true }

    const parsed = JSON.parse(result)
    if (parsed?.hookSpecificOutput?.permissionDecision === "deny") {
      return {
        allowed: false,
        reason:
          parsed.hookSpecificOutput.permissionDecisionReason ??
          "Gate progression validation failed",
      }
    }

    return { allowed: true }
  } catch {
    return { allowed: true } // Fail open
  }
}

/**
 * Hook for tool.execute.before — saves backup if writing current-cycle.json.
 */
export function createToolExecuteBefore(projectRoot: string) {
  return async (
    input: { tool: string; sessionID: string; callID: string },
    output: { args: any },
  ): Promise<void> => {
    const toolName = input.tool?.toLowerCase() ?? ""
    if (toolName !== "file_write" && toolName !== "write") return

    const filePath: string =
      output.args?.file_path ?? output.args?.filePath ?? output.args?.path ?? ""
    if (!filePath.endsWith("current-cycle.json")) return

    const absPath = path.isAbsolute(filePath) ? filePath : path.resolve(projectRoot, filePath)

    let previousContent: string | null = null
    if (fs.existsSync(absPath)) {
      try {
        previousContent = fs.readFileSync(absPath, "utf-8")
      } catch {
        /* proceed without backup */
      }
    }

    evictStale()
    pendingValidations.set(input.callID, { filePath: absPath, previousContent, timestamp: Date.now() })
  }
}

/**
 * Hook for tool.execute.after — validates and reverts if invalid.
 */
export function createToolExecuteAfter(projectRoot: string) {
  const validatorScript = findValidatorScript(projectRoot)
  const debug = process.env.RING_DEBUG === "true"

  if (!validatorScript) {
    if (debug) console.debug("[ring:gate-validator] Validator script not found — disabled")
    return async () => {}
  }

  if (debug) console.debug(`[ring:gate-validator] Active: ${validatorScript}`)

  return async (
    input: { tool: string; sessionID: string; callID: string; args: any },
    output: { title: string; output: string; metadata: any },
  ): Promise<void> => {
    const pending = pendingValidations.get(input.callID)
    if (!pending) return

    pendingValidations.delete(input.callID)

    let writtenContent: string
    try {
      writtenContent = fs.readFileSync(pending.filePath, "utf-8")
    } catch {
      return
    }

    // Temporarily restore previous state so the script's regression check
    // compares against the ORIGINAL state, not the already-written content.
    // NOTE: Non-atomic window between restore and re-write. Acceptable in
    // single-agent usage; concurrent file access could read reverted state.
    if (pending.previousContent !== null) {
      fs.writeFileSync(pending.filePath, pending.previousContent, "utf-8")
    } else {
      try {
        fs.unlinkSync(pending.filePath)
      } catch {
        /* ignore */
      }
    }

    const result = runValidator(validatorScript, {
      file_path: pending.filePath,
      content: writtenContent,
    })

    if (result.allowed) {
      // Valid — restore the new content
      fs.writeFileSync(pending.filePath, writtenContent, "utf-8")
      return
    }

    // BLOCKED — file stays reverted, replace tool output
    if (debug) console.debug(`[ring:gate-validator] BLOCKED: ${result.reason}`)

    // Previous content was already restored above. If there was no previous
    // file, it was already unlinked. No additional revert needed.

    output.title = "⛔ GATE PROGRESSION BLOCKED"
    output.output = [
      "⛔ GATE PROGRESSION BLOCKED — File reverted.",
      "",
      result.reason,
      "",
      "The state file has been reverted to its previous state.",
      "Complete all prerequisite gates before progressing.",
      "Gates execute in order: 0 → 0.5 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9.",
    ].join("\n")
  }
}
