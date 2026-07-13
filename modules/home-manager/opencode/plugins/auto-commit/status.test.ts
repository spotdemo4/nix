import { expect, test } from "bun:test";
import { AUTO_COMMIT_SESSION_TITLE, AUTO_COMMIT_TRIGGER } from "./constants";
import autoCommitStatusPlugin, { AutoCommitStatusClient } from "./status";

test("registers the status slot and commit command", async () => {
  const commands: Array<Record<string, unknown>> = [];
  const registrations: Array<{ slots: Record<string, unknown> }> = [];

  await autoCommitStatusPlugin.tui(
    {
      event: { on: () => () => {} },
      keymap: {
        registerLayer: (layer: { commands: Array<Record<string, unknown>> }) => {
          commands.push(...layer.commands);
          return () => {};
        },
      },
      lifecycle: { onDispose: () => () => {} },
      slots: {
        register: (plugin: { slots: Record<string, unknown> }) => {
          registrations.push(plugin);
          return "auto-commit-status";
        },
      },
    } as never,
    undefined,
    {} as never,
  );

  expect(registrations).toHaveLength(1);
  expect(registrations[0]?.slots.sidebar_content).toBeFunction();
  expect(registrations[0]?.slots.sidebar_footer).toBeUndefined();
  expect(commands).toHaveLength(1);
  expect(commands[0]).toMatchObject({
    name: "auto-commit.run",
    namespace: "palette",
    slashName: "commit",
  });
});

test("requests auto commit without starting a model response", async () => {
  const prompts: Array<{ input: Record<string, unknown>; options: Record<string, unknown> }> = [];
  const toasts: Array<Record<string, unknown>> = [];
  let status: { type: string } | undefined;
  let run: (() => Promise<void>) | undefined;

  await autoCommitStatusPlugin.tui(
    {
      client: {
        session: {
          promptAsync: async (input: Record<string, unknown>, options: Record<string, unknown>) => {
            prompts.push({ input, options });
          },
        },
      },
      event: { on: () => () => {} },
      keymap: {
        registerLayer: (layer: { commands: Array<{ run: () => Promise<void> }> }) => {
          run = layer.commands[0]?.run;
          return () => {};
        },
      },
      lifecycle: { onDispose: () => () => {} },
      route: { current: { name: "session", params: { sessionID: "parent" } } },
      slots: { register: () => "auto-commit-status" },
      state: {
        session: {
          get: () => ({
            agent: "build",
            directory: "/workspace",
            id: "parent",
            model: { id: "model", providerID: "provider", variant: "high" },
          }),
          status: () => status,
        },
      },
      ui: { toast: (toast: Record<string, unknown>) => toasts.push(toast) },
    } as never,
    undefined,
    {} as never,
  );

  expect(run).toBeFunction();
  await run?.();

  expect(prompts).toEqual([
    {
      input: {
        agent: "build",
        directory: "/workspace",
        model: { modelID: "model", providerID: "provider" },
        noReply: true,
        parts: [{ ignored: true, synthetic: true, text: AUTO_COMMIT_TRIGGER, type: "text" }],
        sessionID: "parent",
        variant: "high",
      },
      options: { throwOnError: true },
    },
  ]);
  expect(toasts).toContainEqual({
    message: "Automatic commit requested",
    title: "Auto commit",
    variant: "info",
  });

  status = { type: "busy" };
  await run?.();
  expect(prompts).toHaveLength(1);
  expect(toasts).toContainEqual({
    message: "Wait for the session to become idle before running auto commit",
    title: "Auto commit",
    variant: "warning",
  });
});

test("tracks auto-commit generation for its parent session", () => {
  const client = new AutoCommitStatusClient();

  client.sessionCreated({
    id: "child",
    parentID: "parent",
    title: AUTO_COMMIT_SESSION_TITLE,
  });
  expect(client.isGenerating("parent")).toBe(true);
  expect(client.isGenerating("other-parent")).toBe(false);

  client.sessionDeleted({ id: "child" });
  expect(client.isGenerating("parent")).toBe(false);
});

test("ignores unrelated and top-level sessions", () => {
  const client = new AutoCommitStatusClient();

  client.sessionCreated({ id: "unrelated", parentID: "parent", title: "Other work" });
  client.sessionCreated({ id: "top-level", title: AUTO_COMMIT_SESSION_TITLE });

  expect(client.isGenerating("parent")).toBe(false);
});

test("keeps each parent active until all of its auto-commit children finish", () => {
  const client = new AutoCommitStatusClient();

  client.sessionCreated({ id: "child-1", parentID: "parent-1", title: AUTO_COMMIT_SESSION_TITLE });
  client.sessionCreated({ id: "child-2", parentID: "parent-1", title: AUTO_COMMIT_SESSION_TITLE });
  client.sessionCreated({ id: "child-3", parentID: "parent-2", title: AUTO_COMMIT_SESSION_TITLE });

  client.sessionDeleted({ id: "child-1" });
  expect(client.isGenerating("parent-1")).toBe(true);
  expect(client.isGenerating("parent-2")).toBe(true);

  client.sessionDeleted({ id: "child-2" });
  expect(client.isGenerating("parent-1")).toBe(false);
  expect(client.isGenerating("parent-2")).toBe(true);

  client.sessionDeleted({ id: "child-3" });
  expect(client.isGenerating("parent-2")).toBe(false);
});

test("clears completed generation without requiring child deletion", () => {
  const client = new AutoCommitStatusClient();

  client.sessionCreated({ id: "child", parentID: "parent", title: AUTO_COMMIT_SESSION_TITLE });
  client.sessionFinished("child");

  expect(client.isGenerating("parent")).toBe(false);
  client.sessionDeleted({ id: "child" });
  expect(client.isGenerating("parent")).toBe(false);
});
