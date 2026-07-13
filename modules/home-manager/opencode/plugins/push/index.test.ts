import { describe, expect, test } from "bun:test";
import type { GitResult, GitRunner } from "./core";
import { gitTimeouts } from "./core";
import { registerPushPlugin } from "./index";

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
  const prompts: Array<{ input: Record<string, unknown>; options: Record<string, unknown> }> = [];
  const toasts: Array<Record<string, unknown>> = [];
  const disposals: Array<() => void> = [];
  const lifecycle = new AbortController();
  const api = {
    client: {
      session: {
        promptAsync: async (input: Record<string, unknown>, requestOptions: Record<string, unknown>) => {
          prompts.push({ input, options: requestOptions });
        },
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
  return { api, commands, disposals, lifecycle, prompts, toasts };
}

describe("push TUI plugin", () => {
  test("registers the push slash command", async () => {
    const { api, commands, disposals } = createApi();
    const { run } = createRunner();

    await registerPushPlugin(api as never, undefined, run);

    expect(commands).toHaveLength(1);
    expect(commands[0]).toMatchObject({
      name: "push.run",
      namespace: "palette",
      slashName: "push",
    });
    expect(disposals).toHaveLength(1);
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

  test("does not submit a fallback if the session became busy", async () => {
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

    expect(prompts).toHaveLength(0);
    expect(toasts.at(-1)).toEqual({
      message: "the direct push failed; retry when the session is idle",
      title: "Push",
      variant: "warning",
    });
  });

  test("stops quietly when the plugin lifecycle is cancelled", async () => {
    const { api, commands, lifecycle, prompts, toasts } = createApi();
    const run: GitRunner = async (_cwd, _args, _timeoutMs, signal) =>
      new Promise((resolve) => {
        const cancelled = () =>
          resolve({ code: null, error: "cancelled", stderr: "", stdout: "" });
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

  test("refuses child or busy sessions before running Git", async () => {
    for (const options of [{ parentID: "root" }, { status: { type: "busy" } }]) {
      const { api, commands, prompts, toasts } = createApi(options);
      const { calls, run } = createRunner();
      await registerPushPlugin(api as never, undefined, run);

      await commands[0]?.run();

      expect(calls).toHaveLength(0);
      expect(prompts).toHaveLength(0);
      expect(toasts.at(-1)?.variant).toBe("warning");
    }
  });
});
