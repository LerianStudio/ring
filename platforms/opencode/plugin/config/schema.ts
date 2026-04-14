/**
 * Ring Configuration Schema
 *
 * Defines the structure for Ring's layered configuration system.
 * Uses Zod for runtime validation.
 */

import { z } from "zod"

/**
 * Hook names that can be disabled.
 */
export const HookNameSchema = z.enum(["session-start", "context-injection"])

/**
 * Agent names that can be disabled.
 */
export const AgentNameSchema = z.enum([
  "code-reviewer",
  "security-reviewer",
  "business-logic-reviewer",
  "test-reviewer",
  "nil-safety-reviewer",
  "consequences-reviewer",
  "dead-code-reviewer",
  "performance-reviewer",
  "codebase-explorer",
  "write-plan",
  "backend-engineer-golang",
  "backend-engineer-typescript",
  "frontend-engineer",
  "frontend-designer",
  "devops-engineer",
  "sre",
  "qa-analyst",
])

/**
 * Skill names that can be disabled.
 */
export const SkillNameSchema = z.enum([
  "using-ring-opencode",
  "test-driven-development",
  "requesting-code-review",
  "writing-plans",
  "executing-plans",
  "brainstorming",
  "linting-codebase",
  "using-git-worktrees",
  "exploring-codebase",
  "handoff-tracking",
  "interviewing-user",
  "receiving-code-review",
  "using-dev-team",
  "writing-skills",
  "dev-cycle",
  "dev-devops",
  "dev-feedback-loop",
  "dev-implementation",
  "dev-refactor",
  "dev-sre",
  "dev-testing",
  "dev-validation",
])

/**
 * Command names that can be disabled.
 */
export const CommandNameSchema = z.enum([
  "brainstorm",
  "codereview",
  "commit",
  "create-handoff",
  "dev-cancel",
  "dev-cycle",
  "dev-refactor",
  "dev-report",
  "dev-status",
  "execute-plan",
  "explore-codebase",
  "lint",
  "worktree",
  "write-plan",
])

/**
 * Experimental features configuration.
 */
export const ExperimentalConfigSchema = z.object({
  /** Enable preemptive compaction */
  preemptiveCompaction: z.boolean().default(false),
  /** Compaction threshold (0.5-0.95) */
  compactionThreshold: z.number().min(0.5).max(0.95).default(0.8),
  /** Enable aggressive tool output truncation */
  aggressiveTruncation: z.boolean().default(false),
})

/**
 * Main Ring configuration schema.
 */
export const RingConfigSchema = z.object({
  /** Schema URL for IDE support */
  $schema: z.string().optional(),

  /** Disabled hooks (won't be loaded) */
  disabled_hooks: z.array(HookNameSchema).default([]),

  /** Disabled agents (won't be available) */
  disabled_agents: z.array(AgentNameSchema).default([]),

  /** Disabled skills (won't be loaded) */
  disabled_skills: z.array(SkillNameSchema).default([]),

  /** Disabled commands (won't be registered) */
  disabled_commands: z.array(CommandNameSchema).default([]),

  /** Experimental features */
  experimental: ExperimentalConfigSchema.optional().default({
    preemptiveCompaction: false,
    compactionThreshold: 0.8,
    aggressiveTruncation: false,
  }),

  /** Custom hook configurations */
  hooks: z.record(z.string(), z.record(z.string(), z.unknown())).optional(),
})

/**
 * Inferred TypeScript types from schemas.
 */
export type HookName = z.infer<typeof HookNameSchema>
export type AgentName = z.infer<typeof AgentNameSchema>
export type SkillName = z.infer<typeof SkillNameSchema>
export type CommandName = z.infer<typeof CommandNameSchema>
export type ExperimentalConfig = z.infer<typeof ExperimentalConfigSchema>
export type RingConfig = z.infer<typeof RingConfigSchema>

/**
 * Default configuration values.
 * M3: Derived from schema to ensure consistency with defaults defined in Zod.
 */
export const DEFAULT_RING_CONFIG: RingConfig = RingConfigSchema.parse({})
