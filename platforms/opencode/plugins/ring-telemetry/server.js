import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execFileSync } from "node:child_process";
import crypto from "node:crypto";

const DEFAULT_CONFIG = {
  enabled: true,
  endpoint: "http://127.0.0.1:4800",
  developer_email: "auto",
  heartbeat_interval_writes: 10,
  heartbeat_interval_seconds: 300,
  activity_interval_tools: 5,
  activity_interval_seconds: 30,
  debug: false,
  api_token: "",
  allow_remote_http: false,
};

function configPath() {
  return process.env.RING_TELEMETRY_CONFIG || path.join(os.homedir(), ".ring", "telemetry.json");
}

function readConfig() {
  try {
    if (!fs.existsSync(configPath())) return null;
    const parsed = JSON.parse(fs.readFileSync(configPath(), "utf8"));
    const config = { ...DEFAULT_CONFIG, ...parsed };
    if (config.enabled !== true) return null;
    if (!isEndpointAllowed(config)) return null;
    if (config.developer_email === "auto") {
      config.developer_email = git(["config", "user.email"]) || git(["config", "--global", "user.email"]) || "unknown";
    }
    return config;
  } catch {
    return null;
  }
}

function isLocalEndpoint(endpoint) {
  try {
    const url = new URL(String(endpoint));
    return ["http:", "https:"].includes(url.protocol) && ["localhost", "127.0.0.1", "::1", "[::1]"].includes(url.hostname);
  } catch {
    return false;
  }
}

function isLocalHttpEndpoint(endpoint) {
  try {
    const url = new URL(String(endpoint));
    return url.protocol === "http:" && isLocalEndpoint(endpoint);
  } catch {
    return false;
  }
}

function isEndpointAllowed(config) {
  const endpoint = config?.endpoint;
  if (!endpoint) return false;
  try {
    const url = new URL(String(endpoint));
    if (!["http:", "https:"].includes(url.protocol)) return false;
    if (!isLocalEndpoint(endpoint) && !config.api_token) return false;
    return url.protocol !== "http:" || isLocalHttpEndpoint(endpoint) || config.allow_remote_http === true;
  } catch {
    return false;
  }
}

function git(args, cwd = process.cwd()) {
  try {
    return execFileSync("git", args, { cwd, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
  } catch {
    return "";
  }
}

function repoContext(directory) {
  const repoPath = git(["rev-parse", "--show-toplevel"], directory) || directory || process.cwd();
  return {
    repo: path.basename(repoPath),
    repo_path: repoPath,
    branch: git(["rev-parse", "--abbrev-ref", "HEAD"], repoPath) || "unknown",
  };
}

function debug(config, message) {
  if (!config?.debug) return;
  try {
    const logPath = path.join(os.homedir(), ".ring", "telemetry-debug.log");
    fs.mkdirSync(path.dirname(logPath), { recursive: true });
    fs.appendFileSync(logPath, `${new Date().toISOString()} ${message}\n`);
  } catch {
    // Telemetry must never disrupt OpenCode.
  }
}

function post(config, event, apiPath = "/api/events") {
  if (!config || !event || typeof fetch !== "function" || !isEndpointAllowed(config)) return;
  const headers = { "content-type": "application/json" };
  if (config.api_token) headers.authorization = `Bearer ${config.api_token}`;
  try {
    fetch(`${String(config.endpoint).replace(/\/$/, "")}${apiPath}`, {
      method: "POST",
      headers,
      body: JSON.stringify(event),
      signal: AbortSignal.timeout ? AbortSignal.timeout(2000) : undefined,
    }).catch(() => undefined);
  } catch {
    // Telemetry must never disrupt OpenCode.
  }
}

function eventEnvelope(config, state, eventType, payload = {}) {
  if (!config || !state || !eventType) return null;
  return {
    schema_version: "1.0",
    event_type: eventType,
    timestamp: new Date().toISOString(),
    developer: { email: config.developer_email || "unknown", hostname: os.hostname() },
    context: state.context || repoContext(process.cwd()),
    session: { id: state.id || "unknown", tool: "opencode", model: state.model || "unknown" },
    payload: payload && typeof payload === "object" ? payload : {},
  };
}

function createSessionState(directory) {
  return {
    id: crypto.randomUUID ? crypto.randomUUID() : `${Date.now()}-${process.pid}`,
    model: process.env.OPENCODE_MODEL || process.env.MODEL || "unknown",
    context: repoContext(directory),
    writes_count: 0,
    last_heartbeat_writes: 0,
    last_heartbeat_at: Date.now(),
    files_touched: new Set(),
    activity_count: 0,
    last_activity_count: 0,
    last_activity_at: null,
    last_activity_tool: null,
    last_activity_emit_at: Date.now(),
    tool_counts: {},
    structured: false,
    lastCycleStateByPath: new Map(),
  };
}

function extractToolName(input) {
  const raw = input?.tool_name ?? input?.tool ?? input?.name ?? input?.toolName ?? "unknown";
  const sanitized = String(raw).replace(/[^A-Za-z0-9_.:-]/g, "").slice(0, 80);
  return sanitized || "unknown";
}

function sha256Text(text) {
  return crypto.createHash("sha256").update(text).digest("hex");
}

function lineCount(text) {
  return text.length === 0 ? 0 : text.split(/\r\n|\r|\n/).length;
}

function isSyntheticTextPart(part) {
  return part?.synthetic === true || part?.metadata?.synthetic === true || part?.source === "synthetic";
}

function extractPromptParts(parts) {
  const partCounts = { text: 0, file: 0, agent: 0, subtask: 0, synthetic_text: 0 };
  const textParts = [];
  const syntheticTextParts = [];

  for (const part of Array.isArray(parts) ? parts : []) {
    const type = String(part?.type ?? part?.kind ?? "");
    if (Object.hasOwn(partCounts, type)) partCounts[type] += 1;
    if (type !== "text" || typeof part?.text !== "string") continue;

    if (isSyntheticTextPart(part)) {
      partCounts.synthetic_text += 1;
      syntheticTextParts.push(part.text);
    } else {
      textParts.push(part.text);
    }
  }

  const promptText = textParts.join("\n");
  return { promptText, partCounts };
}

function extractWrite(input) {
  const tool = input?.tool || input?.toolName || input?.name;
  const args = input?.args || input?.input || input?.tool_input || {};
  const filePath = args.file_path || args.path || args.filePath;
  const content = args.content;
  const isWrite = String(tool || "").toLowerCase().includes("write") || Boolean(filePath && typeof content === "string");
  return isWrite && filePath ? { filePath: String(filePath), content } : null;
}

function summarizeChange(before, after) {
  const keys = ["status", "current_gate", "current_task_index", "current_subtask_index", "cycle_id"];
  return Object.fromEntries(keys.flatMap((key) => {
    const beforeValue = before?.[key] ?? null;
    const afterValue = after?.[key] ?? null;
    return beforeValue === afterValue ? [] : [[key, { before: beforeValue, after: afterValue }]];
  }));
}

function lastJsonLine(content) {
  return String(content || "").split(/\r?\n/).filter(Boolean).at(-1) || "";
}

function nearestTrackingIds(filePath) {
  let dir = path.dirname(filePath);
  const ids = { work_id: null, cycle_id: null };
  while (dir && dir !== path.dirname(dir)) {
    const workCandidate = path.join(dir, "current-work.json");
    try {
      if (fs.existsSync(workCandidate)) {
        const state = JSON.parse(fs.readFileSync(workCandidate, "utf8"));
        ids.work_id ||= state.work_id || state.id || state.metadata?.work_id || null;
        ids.cycle_id ||= state.cycle_id || state.metadata?.cycle_id || null;
      }
    } catch {
      return ids;
    }
    const candidate = path.join(dir, "current-cycle.json");
    try {
      if (!ids.cycle_id && fs.existsSync(candidate)) {
        const state = JSON.parse(fs.readFileSync(candidate, "utf8"));
        ids.cycle_id = state.cycle_id || state.id || state.metadata?.cycle_id || null;
      }
    } catch {
      return ids;
    }
    if (ids.work_id && ids.cycle_id) return ids;
    dir = path.dirname(dir);
  }
  return ids;
}

function summarizeWorkItems(items) {
  return items.reduce((summary, item) => {
    const lane = String(item?.lane ?? item?.status ?? "unknown");
    const status = String(item?.status ?? "unknown");
    summary.by_lane[lane] = (summary.by_lane[lane] || 0) + 1;
    summary.by_status[status] = (summary.by_status[status] || 0) + 1;
    summary.total += 1;
    return summary;
  }, { total: 0, by_lane: {}, by_status: {} });
}

function workPayloadFromState(filePath, stateObject, { legacy = false } = {}) {
  if (!stateObject || typeof stateObject !== "object" || Array.isArray(stateObject) || !Array.isArray(stateObject.items)) return null;
  return {
    work_id: stateObject.work_id || (legacy ? stateObject.cycle_id : null) || stateObject.id || stateObject.metadata?.work_id || null,
    workflow: stateObject.workflow || stateObject.cycle_type || stateObject.type || null,
    status: stateObject.status || null,
    state_path: stateObject.state_path || filePath,
    legacy_state_path: stateObject.legacy_state_path || (legacy ? filePath : null),
    items: stateObject.items,
    summary: summarizeWorkItems(stateObject.items),
    state: stateObject,
  };
}

export default {
  id: "ring-telemetry",
  server: async (ctx = {}, _options = {}) => {
    const directory = ctx.directory || process.cwd();
    const config = readConfig();
    const state = createSessionState(directory);
    let started = false;

    if (config) {
      post(config, eventEnvelope(config, state, "session.start", { trigger: "startup" }));
      debug(config, `opencode session.start ${state.id}`);
      started = true;
    }

    function heartbeat(filePath) {
      if (!config) return;
      state.writes_count += 1;
      state.files_touched.add(filePath);
      const now = Date.now();
      const writeDelta = state.writes_count - state.last_heartbeat_writes;
      const timeDelta = Math.floor((now - state.last_heartbeat_at) / 1000);
      if (writeDelta < config.heartbeat_interval_writes && timeDelta < config.heartbeat_interval_seconds) return;

      state.last_heartbeat_writes = state.writes_count;
      state.last_heartbeat_at = now;
      post(config, eventEnvelope(config, state, "session.heartbeat", {
        writes_count: state.writes_count,
        files_touched: Array.from(state.files_touched),
        structured: state.structured,
      }));
    }

    function reportActivity(input) {
      if (!config) return;
      const toolName = extractToolName(input);
      const now = Date.now();
      state.activity_count += 1;
      state.last_activity_at = new Date(now).toISOString();
      state.last_activity_tool = toolName;
      state.tool_counts[toolName] = (state.tool_counts[toolName] || 0) + 1;

      const activityDelta = state.activity_count - state.last_activity_count;
      const timeDelta = Math.floor((now - state.last_activity_emit_at) / 1000);
      if (activityDelta < config.activity_interval_tools && timeDelta < config.activity_interval_seconds) return;

      state.last_activity_count = state.activity_count;
      state.last_activity_emit_at = now;
      post(config, eventEnvelope(config, state, "session.activity", {
        activity_count: state.activity_count,
        tool_counts: { ...state.tool_counts },
        last_activity_at: state.last_activity_at,
        last_activity_tool: state.last_activity_tool,
      }));
    }

    function reportPrompt(input = {}, output = {}) {
      if (!config) return;
      const { promptText, partCounts } = extractPromptParts(output?.parts);
      if (typeof promptText !== "string" || promptText.trim() === "") return;

      post(config, eventEnvelope(config, state, "prompt.submitted", {
        source: "opencode",
        runtime_event: "chat.message",
        runtime_session_id: input?.sessionID ?? null,
        message_id: input?.messageID ?? null,
        agent: input?.agent ?? output?.message?.agent ?? null,
        model: input?.model ?? null,
        message_role: "user",
        prompt_text: promptText,
        prompt_hash: sha256Text(promptText),
        prompt_length: promptText.length,
        prompt_line_count: lineCount(promptText),
        part_counts: partCounts,
      }), "/api/prompts");
    }

    function reportCycleState(filePath, content) {
      if (!config || !filePath.endsWith("current-cycle.json") || typeof content !== "string") return;
      try {
        const after = JSON.parse(content);
        const before = state.lastCycleStateByPath.get(filePath) || null;
        state.lastCycleStateByPath.set(filePath, after);
        state.structured = true;
        post(config, eventEnvelope(config, state, "cycle.state_update", {
          cycle_id: after.cycle_id || after.id || after.metadata?.cycle_id || null,
          cycle_type: after.cycle_type || after.type || null,
          status: after.status || null,
          current_gate: after.current_gate ?? null,
          state_path: filePath,
          change_summary: summarizeChange(before, after),
          state: after,
        }));
        const workPayload = workPayloadFromState(filePath, after, { legacy: true });
        if (workPayload) post(config, eventEnvelope(config, state, "work.state_update", workPayload));
      } catch {
        debug(config, `opencode invalid cycle state ${filePath}`);
      }
    }

    function reportWorkState(filePath, content) {
      if (!config || !filePath.endsWith("current-work.json") || typeof content !== "string") return;
      try {
        const after = JSON.parse(content);
        const workPayload = workPayloadFromState(filePath, after);
        if (!workPayload) return;
        state.structured = true;
        post(config, eventEnvelope(config, state, "work.state_update", workPayload));
      } catch {
        debug(config, `opencode invalid work state ${filePath}`);
      }
    }

    function reportTokenLog(filePath, content) {
      if (!config || !filePath.endsWith("token-log.jsonl")) return;
      if (typeof content !== "string" || content.trim() === "") return;
      try {
        const raw = lastJsonLine(content);
        if (!raw) return;
        const entry = JSON.parse(raw);
        if (!entry || typeof entry !== "object" || Array.isArray(entry)) return;
        const trackingIds = nearestTrackingIds(filePath);
        post(config, eventEnvelope(config, state, "cycle.token_report", {
          ...entry,
          cycle_id: entry.cycle_id || trackingIds.cycle_id,
          work_id: entry.work_id || trackingIds.work_id,
          source: "token-log.jsonl",
        }));
      } catch {
        debug(config, `opencode invalid token log ${filePath}`);
      }
    }

    function end(reason) {
      if (!config) return;
      post(config, eventEnvelope(config, state, "session.end", { reason }));
    }

    return {
      event: async ({ event } = {}) => {
        const type = event?.type || "unknown";
        if (type === "session.idle" || type === "session.error") end(type);
        if (type === "session.created" && !started && config) {
          post(config, eventEnvelope(config, state, "session.start", { trigger: type }));
          started = true;
        }
      },
      "tool.execute.after": async (input) => {
        reportActivity(input);
        const write = extractWrite(input);
        if (!write) return;
        heartbeat(write.filePath);
        reportCycleState(write.filePath, write.content);
        reportWorkState(write.filePath, write.content);
        reportTokenLog(write.filePath, write.content);
      },
      "chat.message": async (input = {}, output = {}) => {
        reportPrompt(input, output);
      },
      "experimental.session.compacting": async () => {
        end("compact");
        state.id = crypto.randomUUID ? crypto.randomUUID() : `${Date.now()}-${process.pid}`;
        state.writes_count = 0;
        state.last_heartbeat_writes = 0;
        state.last_heartbeat_at = Date.now();
        state.files_touched = new Set();
        state.activity_count = 0;
        state.last_activity_count = 0;
        state.last_activity_at = null;
        state.last_activity_tool = null;
        state.last_activity_emit_at = Date.now();
        state.tool_counts = {};
        state.structured = false;
        state.lastCycleStateByPath = new Map();
        if (config) {
          post(config, eventEnvelope(config, state, "session.start", { trigger: "compact" }));
          started = true;
        }
      },
    };
  },
};
