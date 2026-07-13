import { describe, expect, test } from "bun:test";
import type { GitResult, GitRunner } from "./core";
import { gitTimeouts } from "./core";
import { PushStatusClient, registerPushPlugin } from "./index";

const ok = (stdout = "", stderr = ""): GitResult => ({ code: 0, stderr, stdout });

function createRunner(overrides: Record<string, GitResult> = {}) {
  const calls: Array<{ args: string[]; cwd: string; signal?: AbortSignal; timeoutMs: number }> = [];
  const defaults: Record<string, GitResult> = {
    "symbolic-ref --quiet --short HEAD": ok("main\n"),
    "status --short --branch": ok("## main...origin/main\n"),
    "for-each-ref --format=%(upstream:short)%00%(upstream:remotename)%00%(upstream:remoteref) -- refs/heads/main":
      ok("origin/main\0origin\0refs/heads/main\n"),
    "log --oneline -10": ok("abc1234 feat: change\n"),
    push: ok("", "To example.test:repo.git\n"),
  };
  const run: GitRunner = async (cwd, args, timeoutMs, signal) => {
    calls.push({ args, cwd, signal, timeoutMs });
    const key = args.includes("push") ? "push" : args.join(" ");
    return overrides[key] ?? defaults[key] ?? ok();
  };
  return { calls, run };
}

function createApi(options: { parentID?: string; status?: { type: string } } = {}) {
  const commands: Array<{ run: () => Promise<void>; [key: string]: unknown }> = [];
  const eventHandlers = new Map<string, Set<(event: unknown) => void>>();
  const prompts: Array<{ input: Record<string, unknown>; options: Record<string, unknown> }> = [];
  const registrations: Array<{ order: number; slots: Record<string, unknown> }> = [];
  const toasts: Array<Record<string, unknown>> = [];
  const disposals: Array<() => void> = [];
  const lifecycle = new AbortController();
  const api = {
    client: {
      session: {
        promptAsync: async (
          input: Record<string, unknown>,
          requestOptions: Record<string, unknown>,
        ) => {
          prompts.push({ input, options: requestOptions });
        },
      },
    },
    event: {
      on: (type: string, handler: (event: unknown) => void) => {
        const handlers = eventHandlers.get(type) ?? new Set();
        handlers.add(handler);
        eventHandlers.set(type, handlers);
        return () => handlers.delete(handler);
      },
    },
    keymap: {
      registerLayer: (layer: { commands: typeof commands }) => {
        commands.push(...layer.commands);
        return () => {};
      },
    },
    lifecycle: {
      signal: lifecycle.signal,
      onDispose: (dispose: () => void) => disposals.push(dispose),
    },
    route: { current: { name: "session", params: { sessionID: "parent" } } },
    slots: {
      register: (plugin: { order: number; slots: Record<string, unknown> }) => {
        registrations.push(plugin);
        return "push-status";
      },
    },
    state: {
      session: {
        get: () => ({
          agent: "build",
          directory: "/workspace",
          id: "parent",
          model: { id: "model", providerID: "provider", variant: "high" },
          ...(options.parentID ? { parentID: options.parentID } : {}),
        }),
        status: () => options.status,
      },
    },
    ui: { toast: (toast: Record<string, unknown>) => toasts.push(toast) },
  };
  const emit = (type: string, properties: Record<string, unknown> = {}) => {
    for (const handler of eventHandlers.get(type) ?? []) handler({ type, properties });
  };
  return {
    api,
    commands,
    disposals,
    emit,
    lifecycle,
    prompts,
    registrations,
    toasts,
  };
}

describe("push TUI plugin", () => {
  test("registers the push slash command and status slot", async () => {
    const { api, commands, disposals, registrations } = createApi();
    const { run } = createRunner();

    await registerPushPlugin(api as never, undefined, run);

    expect(commands).toHaveLength(1);
    expect(commands[0]).toMatchObject({
      name: "push.run",
      namespace: "palette",
      slashName: "push",
    });
    expect(disposals).toHaveLength(1);
    expect(registrations).toHaveLength(1);
    expect(registrations[0]?.order).toBe(45);
    expect(registrations[0]?.slots.sidebar_content).toBeFunction();
    expect(registrations[0]?.slots.sidebar_footer).toBeUndefined();
  });

  test("tracks running pushes by session", () => {
    const client = new PushStatusClient();
    let notifications = 0;
    client.subscribe(() => notifications++);

    expect(client.start("parent-1", "/workspace-1")).toBe(true);
    expect(client.start("parent-1", "/workspace-1")).toBe(false);
    expect(client.start("parent-2", "/workspace-2")).toBe(true);
    expect(client.isRunning("parent-1")).toBe(true);
    expect(client.isRunning("parent-2")).toBe(true);

    client.finish("parent-1");
    expect(client.isRunning("parent-1")).toBe(false);
    expect(client.isRunning("parent-2")).toBe(true);
    expect(notifications).toBe(4);
  });

  test("cancels pushes only for files inside their workspace", () => {
    const client = new PushStatusClient();
    client.start("parent", "/workspace");

    client.cancelFile("/other/tracked.txt");
    expect(client.signal("parent")?.aborted).toBe(false);

    client.cancelFile("/workspace/tracked.txt");
    expect(client.signal("parent")?.aborted).toBe(true);
  });

  test("pushes directly without starting an agent", async () => {
    const { api, commands, prompts, toasts } = createApi();
    const { calls, run } = createRunner();
    await registerPushPlugin(api as never, undefined, run);

    await commands[0]?.run();

    const push = calls.find((call) => call.args.includes("push"));
    expect(push).toMatchObject({
      args: [
        "-c",
        "remote.origin.mirror=false",
        "push",
        "--no-force",
        "--no-force-with-lease",
        "--no-force-if-includes",
        "--no-mirror",
        "--no-follow-tags",
        "--no-recurse-submodules",
        "--porcelain",
        "--",
        "origin",
        "HEAD:refs/heads/main",
      ],
      cwd: "/workspace",
      timeoutMs: gitTimeouts.push,
    });
    expect(prompts).toHaveLength(0);
    expect(toasts).toContainEqual({
      message: "Pushed main to origin/main",
      title: "Push",
      variant: "success",
    });
  });

  test("reports an unchanged porcelain push accurately", async () => {
    const { api, commands, toasts } = createApi();
    const { run } = createRunner({
      push: ok("=\tHEAD:refs/heads/main\t[up to date]\nDone\n"),
    });
    await registerPushPlugin(api as never, undefined, run);

    await commands[0]?.run();

    expect(toasts.at(-1)).toEqual({
      message: "Everything up-to-date",
      title: "Push",
      variant: "success",
    });
  });

  test("hands a rejected push to an isolated build subtask", async () => {
    const { api, commands, prompts, toasts } = createApi();
    const { run } = createRunner({
      push: {
        code: 1,
        stderr: "! [rejected] main -> main (fetch first)\n",
        stdout: "",
      },
    });
    await registerPushPlugin(api as never, undefined, run);

    await commands[0]?.run();

    expect(prompts).toHaveLength(1);
    expect(prompts[0]?.options).toEqual({ throwOnError: true });
    expect(prompts[0]?.input).toMatchObject({
      agent: "build",
      directory: "/workspace",
      model: { modelID: "model", providerID: "provider" },
      sessionID: "parent",
      variant: "high",
    });
    const parts = prompts[0]?.input.parts as Array<Record<string, unknown>>;
    expect(parts).toHaveLength(1);
    expect(parts[0]).toMatchObject({
      agent: "build",
      description: "Rebase and push current branch",
      type: "subtask",
    });
    expect(parts[0]?.command).toBeUndefined();
    expect(parts[0]?.prompt).toContain("Never use `--force`");
    expect(parts[0]?.prompt).toContain("Never use a bare `git push`");
    expect(toasts).toContainEqual({
      message: "the direct push failed; handed off to the build agent",
      title: "Push",
      variant: "info",
    });
  });

  test("does not push without an upstream and delegates the blocker", async () => {
    const { api, commands, prompts } = createApi();
    const { calls, run } = createRunner({
      "for-each-ref --format=%(upstream:short)%00%(upstream:remotename)%00%(upstream:remoteref) -- refs/heads/main":
        ok("\n"),
    });
    await registerPushPlugin(api as never, undefined, run);

    await commands[0]?.run();

    expect(calls.some((call) => call.args.includes("push"))).toBe(false);
    expect(prompts).toHaveLength(1);
    const parts = prompts[0]?.input.parts as Array<Record<string, unknown>>;
    expect(parts[0]?.prompt).toContain("no supported configured upstream");
  });

  test("submits a fallback if the session became busy", async () => {
    const options: { status?: { type: string } } = {};
    const { api, commands, prompts, toasts } = createApi(options);
    const { run: baseRunner } = createRunner({
      push: { code: 1, stderr: "rejected\n", stdout: "" },
    });
    const run: GitRunner = async (...args) => {
      const result = await baseRunner(...args);
      if (args[1].includes("push")) options.status = { type: "busy" };
      return result;
    };
    await registerPushPlugin(api as never, undefined, run);

    await commands[0]?.run();

    expect(prompts).toHaveLength(1);
    expect(toasts.at(-1)).toEqual({
      message: "the direct push failed; handed off to the build agent",
      title: "Push",
      variant: "info",
    });
  });

  test("cancels an active push when a workspace file changes", async () => {
    const { api, commands, emit, prompts, toasts } = createApi({ status: { type: "busy" } });
    const run: GitRunner = async (_cwd, _args, _timeoutMs, signal) =>
      new Promise((resolve) => {
        const cancelled = () => resolve({ code: null, error: "cancelled", stderr: "", stdout: "" });
        if (signal?.aborted) cancelled();
        else signal?.addEventListener("abort", cancelled, { once: true });
      });
    await registerPushPlugin(api as never, undefined, run);

    const execution = commands[0]?.run();
    emit("file.watcher.updated", { event: "change", file: "/workspace/tracked.txt" });
    await execution;

    expect(prompts).toHaveLength(0);
    expect(toasts.at(-1)).toEqual({
      message: "Push cancelled because workspace files changed",
      title: "Push",
      variant: "warning",
    });
  });

  test("cancels before reporting a pending fallback handoff", async () => {
    const { api, commands, emit, prompts, toasts } = createApi();
    let releasePrompt = () => {};
    let promptStarted = () => {};
    const promptGate = new Promise<void>((resolve) => {
      releasePrompt = resolve;
    });
    const started = new Promise<void>((resolve) => {
      promptStarted = resolve;
    });
    api.client.session.promptAsync = async (
      input: Record<string, unknown>,
      requestOptions: Record<string, unknown>,
    ) => {
      prompts.push({ input, options: requestOptions });
      promptStarted();
      await promptGate;
    };
    const { run } = createRunner({
      push: { code: 1, stderr: "rejected\n", stdout: "" },
    });
    await registerPushPlugin(api as never, undefined, run);

    const execution = commands[0]?.run();
    await started;
    emit("file.edited", { file: "/workspace/tracked.txt" });
    releasePrompt();
    await execution;

    expect(toasts.at(-1)).toEqual({
      message: "Push cancelled because workspace files changed",
      title: "Push",
      variant: "warning",
    });
  });

  test("stops quietly when the plugin lifecycle is cancelled", async () => {
    const { api, commands, lifecycle, prompts, toasts } = createApi();
    const run: GitRunner = async (_cwd, _args, _timeoutMs, signal) =>
      new Promise((resolve) => {
        const cancelled = () => resolve({ code: null, error: "cancelled", stderr: "", stdout: "" });
        if (signal?.aborted) cancelled();
        else signal?.addEventListener("abort", cancelled, { once: true });
      });
    await registerPushPlugin(api as never, undefined, run);

    const execution = commands[0]?.run();
    lifecycle.abort();
    await execution;

    expect(prompts).toHaveLength(0);
    expect(toasts).toHaveLength(0);
  });

  test("stops quietly when the plugin is disposed", async () => {
    const { api, commands, disposals, prompts, toasts } = createApi();
    const run: GitRunner = async (_cwd, _args, _timeoutMs, signal) =>
      new Promise((resolve) => {
        const cancelled = () => resolve({ code: null, error: "cancelled", stderr: "", stdout: "" });
        if (signal?.aborted) cancelled();
        else signal?.addEventListener("abort", cancelled, { once: true });
      });
    await registerPushPlugin(api as never, undefined, run);

    const execution = commands[0]?.run();
    await disposals[0]?.();
    await execution;

    expect(prompts).toHaveLength(0);
    expect(toasts).toHaveLength(0);
  });

  test("refuses child sessions before running Git", async () => {
    const { api, commands, prompts, toasts } = createApi({ parentID: "root" });
    const { calls, run } = createRunner();
    await registerPushPlugin(api as never, undefined, run);

    await commands[0]?.run();

    expect(calls).toHaveLength(0);
    expect(prompts).toHaveLength(0);
    expect(toasts.at(-1)?.variant).toBe("warning");
  });

  test("pushes while the parent session is busy", async () => {
    const { api, commands, toasts } = createApi({ status: { type: "busy" } });
    const { calls, run } = createRunner();
    await registerPushPlugin(api as never, undefined, run);

    await commands[0]?.run();

    expect(calls.some((call) => call.args.includes("push"))).toBe(true);
    expect(toasts.at(-1)?.variant).toBe("success");
  });
});
