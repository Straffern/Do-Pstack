import { describe, expect, it } from "vitest";
import pstackExtension from "../../extensions/pstack.ts";

type Completions = { value: string; label: string }[] | null;

type Handler = (event: unknown, ctx: unknown) => Promise<{ systemPrompt?: string | string[] } | undefined>;

function boot() {
  let command: {
    getArgumentCompletions?: (prefix: string) => Completions;
    handler: (args: string, ctx: unknown) => Promise<void>;
  };
  const messages: string[] = [];
  const handlers = new Map<string, Handler>();
  pstackExtension({
    setLabel() {},
    on(name: string, handler: Handler) {
      handlers.set(name, handler);
    },
    appendEntry() {},
    sendUserMessage(text: string) {
      messages.push(text);
    },
    registerCommand(_name: string, opts: typeof command) {
      command = opts;
    },
  });
  const ctx = {
    mode: "rpc",
    isIdle: () => true,
    sessionManager: {
      getSessionId: () => "s1",
      getSessionFile: () => undefined,
    },
    ui: { setStatus() {}, notify() {} },
  };
  return { command: command!, messages, ctx, beforeAgentStart: handlers.get("before_agent_start")! };
}

describe("poteto-mode completions", () => {
  it("lists on when off and off when on", async () => {
    const { command, ctx } = boot();
    expect(command.getArgumentCompletions?.("")).toEqual([{ value: "on", label: "on" }]);
    await command.handler("", ctx);
    expect(command.getArgumentCompletions?.("")).toEqual([{ value: "off", label: "off" }]);
    await command.handler("off", ctx);
    expect(command.getArgumentCompletions?.("")).toEqual([{ value: "on", label: "on" }]);
  });

  it("does not send on as a skill task", async () => {
    const { command, messages, ctx } = boot();
    await command.handler("on", ctx);
    expect(messages).toEqual(["/skill:do-poteto-mode"]);
  });
});

describe("poteto-mode system prompt", () => {
  const needle = "Pstack Poteto Mode is on for this session";

  it("keeps every omp block and appends one when on", async () => {
    const { command, ctx, beforeAgentStart } = boot();
    const host = ["host block 0", "host block 1"];
    expect(await beforeAgentStart({ systemPrompt: host }, ctx)).toBeUndefined();
    await command.handler("on", ctx);
    const prompt = (await beforeAgentStart({ systemPrompt: host }, ctx))?.systemPrompt as string[];
    expect(prompt.slice(0, host.length)).toEqual(host);
    expect(prompt).toHaveLength(host.length + 1);
    expect(prompt.at(-1)).toContain(needle);
  });

  it("keeps a Pi string prompt and appends after it", async () => {
    const { command, ctx, beforeAgentStart } = boot();
    await command.handler("on", ctx);
    const prompt = (await beforeAgentStart({ systemPrompt: "host text" }, ctx))?.systemPrompt as string;
    expect(prompt.startsWith("host text\n\n")).toBe(true);
    expect(prompt).toContain(needle);
  });

  it("stops adding the block after off", async () => {
    const { command, ctx, beforeAgentStart } = boot();
    await command.handler("on", ctx);
    await command.handler("off", ctx);
    expect(await beforeAgentStart({ systemPrompt: ["host"] }, ctx)).toBeUndefined();
  });
});
