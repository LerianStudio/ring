import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

import RingTelemetryPlugin from "../../plugins/ring-telemetry/server.js";

async function withPlugin(config, fn) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "ring-opencode-"));
  const configPath = path.join(tmp, "telemetry.json");
  const previousConfig = process.env.RING_TELEMETRY_CONFIG;
  const previousFetch = globalThis.fetch;
  const calls = [];
  fs.writeFileSync(configPath, JSON.stringify(config));
  process.env.RING_TELEMETRY_CONFIG = configPath;
  globalThis.fetch = (url, options = {}) => {
    calls.push({ url: String(url), options });
    return Promise.resolve({ ok: true, status: 202, json: async () => ({ ok: true }) });
  };
  try {
    const plugin = await RingTelemetryPlugin.server({ directory: tmp });
    await fn(plugin, calls);
  } finally {
    if (previousConfig == null) delete process.env.RING_TELEMETRY_CONFIG;
    else process.env.RING_TELEMETRY_CONFIG = previousConfig;
    globalThis.fetch = previousFetch;
    fs.rmSync(tmp, { recursive: true, force: true });
  }
}

test("posts session.start with defensive envelope defaults", async () => {
  await withPlugin({ enabled: true, endpoint: "http://127.0.0.1:4800", developer_email: "dev@example.com" }, async (_plugin, calls) => {
    assert.equal(calls.length, 1);
    assert.equal(calls[0].url, "http://127.0.0.1:4800/api/events");
    const event = JSON.parse(calls[0].options.body);
    assert.equal(event.schema_version, "1.0");
    assert.equal(event.event_type, "session.start");
    assert.equal(event.developer.email, "dev@example.com");
    assert.equal(event.session.tool, "opencode");
    assert.deepEqual(event.payload, { trigger: "startup" });
  });
});

test("remote endpoints require api_token and cleartext opt-in", async () => {
  await withPlugin({ enabled: true, endpoint: "https://telemetry.example.com", developer_email: "dev@example.com" }, async (_plugin, calls) => {
    assert.equal(calls.length, 0);
  });

  await withPlugin({ enabled: true, endpoint: "http://telemetry.example.com", developer_email: "dev@example.com", api_token: "secret" }, async (_plugin, calls) => {
    assert.equal(calls.length, 0);
  });

  await withPlugin({ enabled: true, endpoint: "http://telemetry.example.com", developer_email: "dev@example.com", api_token: "secret", allow_remote_http: true }, async (_plugin, calls) => {
    assert.equal(calls.length, 1);
    assert.equal(calls[0].options.headers.authorization, "Bearer secret");
  });
});

test("compaction emits end for old session and start for new session", async () => {
  await withPlugin({ enabled: true, endpoint: "http://127.0.0.1:4800", developer_email: "dev@example.com" }, async (plugin, calls) => {
    await plugin["experimental.session.compacting"]();
    const events = calls.map((call) => JSON.parse(call.options.body));
    assert.deepEqual(events.map((event) => event.event_type), ["session.start", "session.end", "session.start"]);
    assert.notEqual(events[1].session.id, events[2].session.id);
    assert.deepEqual(events[2].payload, { trigger: "compact" });
  });
});

test("token-log reports use provided hook content only", async () => {
  await withPlugin({ enabled: true, endpoint: "http://127.0.0.1:4800", developer_email: "dev@example.com" }, async (plugin, calls) => {
    const tokenPath = path.join(os.tmpdir(), "token-log.jsonl");
    await plugin["tool.execute.after"]({ tool: "write", args: { file_path: tokenPath, content: "" } });
    assert.equal(calls.length, 1);

    await plugin["tool.execute.after"]({ tool: "write", args: { file_path: tokenPath, content: '{"total_tokens":3}\n' } });
    assert.equal(calls.length, 2);
    assert.equal(calls[1].url, "http://127.0.0.1:4800/api/events");
    const event = JSON.parse(calls[1].options.body);
    assert.equal(event.event_type, "cycle.token_report");
    assert.equal(event.payload.total_tokens, 3);
  });
});

test("heartbeat posts to generic events endpoint", async () => {
  await withPlugin({
    enabled: true,
    endpoint: "http://127.0.0.1:4800",
    developer_email: "dev@example.com",
    heartbeat_interval_writes: 1,
    heartbeat_interval_seconds: 300,
  }, async (plugin, calls) => {
    await plugin["tool.execute.after"]({ tool: "write", args: { file_path: path.join(os.tmpdir(), "notes.md"), content: "changed" } });

    assert.equal(calls.length, 2);
    assert.equal(calls[1].url, "http://127.0.0.1:4800/api/events");
    const event = JSON.parse(calls[1].options.body);
    assert.equal(event.event_type, "session.heartbeat");
    assert.equal(event.payload.writes_count, 1);
  });
});

test("non-write tools emit privacy-safe activity without args", async () => {
  await withPlugin({
    enabled: true,
    endpoint: "http://127.0.0.1:4800",
    developer_email: "dev@example.com",
    activity_interval_tools: 1,
    activity_interval_seconds: 300,
  }, async (plugin, calls) => {
    await plugin["tool.execute.after"]({
      tool: "Bash",
      args: { command: "secret command content", file_path: "/secret/path" },
    });

    assert.equal(calls.length, 2);
    assert.equal(calls[1].url, "http://127.0.0.1:4800/api/events");
    const event = JSON.parse(calls[1].options.body);
    assert.equal(event.event_type, "session.activity");
    assert.deepEqual(event.payload.tool_counts, { Bash: 1 });
    assert.equal(event.payload.activity_count, 1);
    assert.equal(event.payload.last_activity_tool, "Bash");
    assert.equal(JSON.stringify(event.payload).includes("secret command content"), false);
    assert.equal(JSON.stringify(event.payload).includes("/secret/path"), false);
    assert.equal(Object.hasOwn(event.payload, "args"), false);
  });
});

test("todo tools are covered by session.activity only", async () => {
  await withPlugin({
    enabled: true,
    endpoint: "http://127.0.0.1:4800",
    developer_email: "dev@example.com",
    activity_interval_tools: 1,
    activity_interval_seconds: 300,
  }, async (plugin, calls) => {
    await plugin["tool.execute.after"]({
      tool: "TodoWrite",
      args: {
        command: "must not leak",
        todos: [
          { id: "todo-1", content: "Implement todo telemetry", status: "in_progress", priority: "high", extra: "secret" },
          { content: "Validate todo cards", status: "completed", priority: "medium" },
          { content: "Unknown fields normalize", status: "waiting", priority: "urgent" },
        ],
      },
    });

    assert.equal(calls.length, 2);
    assert.equal(calls[1].url, "http://127.0.0.1:4800/api/events");
    const event = JSON.parse(calls[1].options.body);
    assert.equal(event.event_type, "session.activity");
    assert.deepEqual(event.payload.tool_counts, { TodoWrite: 1 });
    assert.equal(JSON.stringify(event.payload).includes("must not leak"), false);
    assert.equal(JSON.stringify(event.payload).includes("secret"), false);
  });
});

test("chat.message emits prompt.submitted with raw prompt text", async () => {
  await withPlugin({ enabled: true, endpoint: "http://127.0.0.1:4800", developer_email: "dev@example.com" }, async (plugin, calls) => {
    await plugin["chat.message"](
      { sessionID: "runtime-session-1", messageID: "message-1", agent: "build", model: "gpt-test" },
      { parts: [{ type: "text", text: "raw prompt secret" }], message: { agent: "fallback-agent" } },
    );

    assert.equal(calls.length, 2);
    assert.equal(calls[1].url, "http://127.0.0.1:4800/api/prompts");
    const event = JSON.parse(calls[1].options.body);
    assert.equal(event.event_type, "prompt.submitted");
    assert.equal(event.payload.source, "opencode");
    assert.equal(event.payload.runtime_event, "chat.message");
    assert.equal(event.payload.runtime_session_id, "runtime-session-1");
    assert.equal(event.payload.message_id, "message-1");
    assert.equal(event.payload.agent, "build");
    assert.equal(event.payload.model, "gpt-test");
    assert.equal(event.payload.message_role, "user");
    assert.equal(event.payload.prompt_text, "raw prompt secret");
    assert.equal(event.payload.prompt_hash, crypto.createHash("sha256").update("raw prompt secret").digest("hex"));
    assert.equal(event.payload.prompt_length, "raw prompt secret".length);
    assert.equal(event.payload.prompt_line_count, 1);
    assert.deepEqual(event.payload.part_counts, { text: 1, file: 0, agent: 0, subtask: 0, synthetic_text: 0 });
  });
});

test("chat.message prefers non-synthetic text and counts all prompt parts", async () => {
  await withPlugin({ enabled: true, endpoint: "http://127.0.0.1:4800", developer_email: "dev@example.com" }, async (plugin, calls) => {
    await plugin["chat.message"](
      { sessionID: "runtime-session-1", messageID: "message-1" },
      {
        parts: [
          { type: "text", text: "synthetic preface", synthetic: true },
          { type: "file", name: "context.md" },
          { type: "agent" },
          { type: "subtask" },
          { type: "text", text: "raw\nuser prompt" },
        ],
      },
    );

    assert.equal(calls.length, 2);
    assert.equal(calls[1].url, "http://127.0.0.1:4800/api/prompts");
    const event = JSON.parse(calls[1].options.body);
    assert.equal(event.payload.prompt_text, "raw\nuser prompt");
    assert.equal(event.payload.prompt_line_count, 2);
    assert.deepEqual(event.payload.part_counts, { text: 2, file: 1, agent: 1, subtask: 1, synthetic_text: 1 });
  });
});

test("chat.message ignores synthetic-only text while keeping counts out of prompt events", async () => {
  await withPlugin({ enabled: true, endpoint: "http://127.0.0.1:4800", developer_email: "dev@example.com" }, async (plugin, calls) => {
    await plugin["chat.message"](
      { sessionID: "runtime-session-1", messageID: "message-1" },
      { parts: [{ type: "text", text: "synthetic preface only", synthetic: true }] },
    );

    assert.equal(calls.length, 1);
    assert.equal(JSON.parse(calls[0].options.body).event_type, "session.start");
  });
});

test("chat.message ignores empty or non-text messages", async () => {
  await withPlugin({ enabled: true, endpoint: "http://127.0.0.1:4800", developer_email: "dev@example.com" }, async (plugin, calls) => {
    await plugin["chat.message"]({ sessionID: "runtime-session-1" }, { parts: [] });
    await plugin["chat.message"]({ sessionID: "runtime-session-1" }, { parts: [{ type: "text", text: "   \n\t" }] });
    await plugin["chat.message"]({ sessionID: "runtime-session-1" }, { parts: [{ type: "file", name: "secret.txt" }] });

    assert.equal(calls.length, 1);
    assert.equal(JSON.parse(calls[0].options.body).event_type, "session.start");
  });
});

test("chat.message post failure does not throw", async () => {
  await withPlugin({ enabled: true, endpoint: "http://127.0.0.1:4800", developer_email: "dev@example.com" }, async (plugin, calls) => {
    let failedFetchAttempts = 0;
    globalThis.fetch = () => {
      failedFetchAttempts += 1;
      return Promise.reject(new Error("offline"));
    };

    await assert.doesNotReject(async () => {
      await plugin["chat.message"]({ sessionID: "runtime-session-1" }, { parts: [{ type: "text", text: "still works" }] });
    });

    assert.equal(calls.length, 1);
    assert.equal(failedFetchAttempts, 1);
  });
});

test("current-work writes emit canonical work.state_update", async () => {
  await withPlugin({ enabled: true, endpoint: "http://127.0.0.1:4800", developer_email: "dev@example.com" }, async (plugin, calls) => {
    const workPath = path.join(os.tmpdir(), "docs", "ring-tracking", "ring:dev-cycle", "current-work.json");
    const content = JSON.stringify({
      workflow: "ring:dev-cycle",
      work_id: "work-1",
      status: "in_progress",
      items: [{ id: "task-1", kind: "task", title: "Implement", status: "in_progress", lane: "in_progress", order: 10 }],
    });
    await plugin["tool.execute.after"]({ tool: "write", args: { file_path: workPath, content } });

    assert.equal(calls.length, 2);
    assert.equal(calls[1].url, "http://127.0.0.1:4800/api/events");
    const event = JSON.parse(calls[1].options.body);
    assert.equal(event.event_type, "work.state_update");
    assert.equal(event.payload.work_id, "work-1");
    assert.equal(event.payload.workflow, "ring:dev-cycle");
    assert.equal(event.payload.items.length, 1);
    assert.deepEqual(event.payload.summary, { total: 1, by_lane: { in_progress: 1 }, by_status: { in_progress: 1 } });
  });
});

test("legacy current-cycle with items also emits transitional work.state_update", async () => {
  await withPlugin({ enabled: true, endpoint: "http://127.0.0.1:4800", developer_email: "dev@example.com" }, async (plugin, calls) => {
    const cyclePath = path.join(os.tmpdir(), "docs", "ring:dev-cycle", "current-cycle.json");
    const content = JSON.stringify({
      cycle_id: "cycle-1",
      cycle_type: "ring:dev-cycle",
      status: "in_progress",
      items: [{ id: "task-1", kind: "task", title: "Implement", status: "in_progress", lane: "in_progress" }],
    });
    await plugin["tool.execute.after"]({ tool: "write", args: { file_path: cyclePath, content } });

    assert.deepEqual(calls.map((call) => JSON.parse(call.options.body).event_type), ["session.start", "cycle.state_update", "work.state_update"]);
    assert.deepEqual(calls.map((call) => call.url), [
      "http://127.0.0.1:4800/api/events",
      "http://127.0.0.1:4800/api/events",
      "http://127.0.0.1:4800/api/events",
    ]);
    const event = JSON.parse(calls[2].options.body);
    assert.equal(event.payload.work_id, "cycle-1");
    assert.equal(event.payload.legacy_state_path, cyclePath);
  });
});
