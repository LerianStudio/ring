/**
 * Ring Unified Plugin
 *
 * Single entry point that matches oh-my-opencode's registration pattern.
 * Combines all Ring functionality into one Plugin export.
 *
 * Features:
 * - Config handler: Injects agents, skills, commands
 * - Tool registration: Custom Ring tools
 * - Event routing: Lifecycle events to hooks
 * - System transform: Context injection
 * - Compaction: Context preservation
 */

import type { Plugin, PluginInput } from "@opencode-ai/plugin"
import type { Config as OpenCodeSdkConfig } from "@opencode-ai/sdk"
// Gate validator (soft block via detect-and-revert)
import { createToolExecuteAfter, createToolExecuteBefore } from "./hooks/factories/gate-validator.js"
import type { RingConfig } from "./config/index.js"
// Config
import { createConfigHandler, loadConfig } from "./config/index.js"
import { createContextInjectionHook, createSessionStartHook } from "./hooks/factories/index.js"
// Hooks
import { hookRegistry } from "./hooks/index.js"
import type { HookContext, HookOutput } from "./hooks/types.js"
// Lifecycle
import { createLifecycleRouter } from "./lifecycle/index.js"
// Tools
import { createRingTools } from "./tools/index.js"

// Utils
import { getSessionId } from "./utils/state.js"

/**
 * Initialize all hooks based on configuration.
 */
function initializeHooks(config: RingConfig): void {
  hookRegistry.clear()
  hookRegistry.setDisabledHooks(config.disabled_hooks)

  const isDisabled = (name: string) => config.disabled_hooks?.includes(name as never) ?? false

  if (!isDisabled("session-start")) {
    hookRegistry.register(createSessionStartHook(config.hooks?.["session-start"]))
  }

  if (!isDisabled("context-injection")) {
    hookRegistry.register(createContextInjectionHook(config.hooks?.["context-injection"]))
  }
}

/**
 * Build a HookContext from available context data.
 */
function buildHookContext(
  sessionId: string,
  directory: string,
  lifecycle: HookContext["lifecycle"],
  event?: { type: string; properties?: Record<string, unknown> },
): HookContext {
  return {
    sessionId,
    directory,
    lifecycle,
    event,
  }
}

/**
 * Ring Unified Plugin
 *
 * Matches oh-my-opencode's Plugin signature:
 * Plugin = (input: PluginInput) => Promise<Hooks>
 *
 * Note: Return type is inferred to allow custom properties
 * that extend the base Hooks interface for Ring-specific functionality.
 */
export const RingUnifiedPlugin: Plugin = async (ctx: PluginInput) => {
  const { directory } = ctx
  const projectRoot = directory

  // Load Ring configuration
  const config = loadConfig(projectRoot)
  const debug = process.env.RING_DEBUG === "true"

  if (debug) {
    console.debug("[ring] Initializing unified plugin")
  }

  // Initialize hooks
  initializeHooks(config)

  // Create config handler for OpenCode config injection
  const configHandler = createConfigHandler({
    projectRoot,
    ringConfig: config,
  })

  // Create lifecycle router (state side-effects only)
  const lifecycleRouter = createLifecycleRouter({
    projectRoot,
    ringConfig: config,
  })

  const sessionId = getSessionId()
  const ringTools = createRingTools(directory)

  // Gate progression validator
  const gateValidatorBefore = createToolExecuteBefore(directory)
  const gateValidatorAfter = createToolExecuteAfter(directory)

  return {
    // Register Ring tools
    tool: ringTools,

    // Config handler - inject agents, skills, commands
    // Type assertion needed: our handler modifies a subset of config properties
    // that are compatible with the SDK's Config type at runtime
    config: configHandler as unknown as (input: OpenCodeSdkConfig) => Promise<void>,

    // Event handler - lifecycle routing + hook execution
    event: async ({ event }) => {
      // Route to lifecycle router
      await lifecycleRouter({ event })

      // Build output object for hooks to modify
      const output: HookOutput = {}
      // Extract sessionID from event properties (may be present in various event types)
      const props = event.properties as Record<string, unknown> | undefined
      const eventSessionId = (props?.sessionID as string) ?? sessionId

      // Build normalized event for hook context
      const normalizedEvent = {
        type: event.type,
        properties: props,
      }

      // Execute hooks based on event type
      if (event.type === "session.created") {
        const hookCtx = buildHookContext(
          eventSessionId,
          directory,
          "session.created",
          normalizedEvent,
        )
        await hookRegistry.executeLifecycle("session.created", hookCtx, output)
      }

      if (event.type === "session.idle") {
        const hookCtx = buildHookContext(eventSessionId, directory, "session.idle", normalizedEvent)
        await hookRegistry.executeLifecycle("session.idle", hookCtx, output)
      }

      if (event.type === "session.error") {
        const hookCtx = buildHookContext(
          eventSessionId,
          directory,
          "session.error",
          normalizedEvent,
        )
        await hookRegistry.executeLifecycle("session.error", hookCtx, output)
      }
    },

    // Gate progression validation (soft block — OpenCode lacks hard deny)
    "tool.execute.before": gateValidatorBefore,
    "tool.execute.after": gateValidatorAfter,

    // System prompt transformation
    "experimental.chat.system.transform": async (
      _input: Record<string, unknown>,
      output: { system: string[] },
    ) => {
      if (!output?.system || !Array.isArray(output.system)) return

      const hookCtx = buildHookContext(sessionId, directory, "chat.params")
      const hookOutput: HookOutput = { system: output.system }
      await hookRegistry.executeLifecycle("chat.params", hookCtx, hookOutput)
    },

    // Compaction context injection
    "experimental.session.compacting": async (
      input: { sessionID: string },
      output: { context: string[] },
    ) => {
      if (!output?.context || !Array.isArray(output.context)) return

      const hookCtx = buildHookContext(input.sessionID, directory, "session.compacting")
      const hookOutput: HookOutput = { context: output.context }
      await hookRegistry.executeLifecycle("session.compacting", hookCtx, hookOutput)
    },
  }
}

export default RingUnifiedPlugin
