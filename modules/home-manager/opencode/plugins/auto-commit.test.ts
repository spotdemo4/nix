import { afterEach, describe, expect, test } from "bun:test";
import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  default as autoCommitPlugin,
  captureSnapshot,
  isConventionalSubject,
  prepareTemporaryWorktree,
  recoverIntegration,
  removeTemporaryWorktree,
  replayPreparedCommits,
  snapshotIsCurrent,
  validatePreparedCommits,
  validatePreparedWorktree,
} from "./auto-commit";

const directories: string[] = [];

function git(cwd: string, ...args: string[]) {
  return execFileSync("git", args, { cwd, encoding: "utf8" }).trim();
}

async function createRepository() {
  const root = await mkdtemp(join(tmpdir(), "opencode-auto-commit-test-"));
  directories.push(root);
  git(root, "init", "-b", "main");
  git(root, "config", "user.name", "Test User");
  git(root, "config", "user.email", "test@example.com");
  await writeFile(join(root, "tracked.txt"), "before\n");
  git(root, "add", "tracked.txt");
  git(root, "commit", "-m", "chore: initialize repository");
  return root;
}

async function waitFor(predicate: () => boolean, timeoutMs = 5000) {
  const deadline = Date.now() + timeoutMs;
  while (!predicate()) {
    if (Date.now() >= deadline) throw new Error("timed out waiting for plugin worker");
    await new Promise((resolve) => setTimeout(resolve, 25));
  }
}

async function createLifecycleHarness(options: { dirty?: boolean } = {}) {
  const root = await createRepository();
  if (options.dirty !== false) await writeFile(join(root, "tracked.txt"), "after\n");
  const toasts: Array<{ message: string; variant: string }> = [];
  let aborts = 0;
  let creates = 0;
  let gets = 0;
  let promptCalls = 0;
  let sessionBusy = false;
  let statusCalls = 0;
  let statusFailures = 0;
  let releasePrompt: () => void = () => {};
  const promptGate = new Promise<void>((resolve) => {
    releasePrompt = resolve;
  });

  const client = {
    app: {
      log: async () => ({ data: true }),
    },
    tui: {
      showToast: async ({ body }: { body: { message: string; variant: string } }) => {
        toasts.push(body);
        return { data: true };
      },
    },
    session: {
      get: async () => {
        gets += 1;
        return { data: { id: "parent", directory: root } };
      },
      status: async () => {
        statusCalls += 1;
        if (statusFailures > 0) {
          statusFailures -= 1;
          throw new Error("status unavailable");
        }
        return {
          data: sessionBusy ? { parent: { type: "busy" as const } } : {},
        };
      },
      messages: async () => ({ data: [], response: { headers: new Headers() } }),
      create: async () => {
        creates += 1;
        return { data: { id: `child-${creates}` } };
      },
      prompt: async ({ query }: { query: { directory: string } }) => {
        promptCalls += 1;
        if (promptCalls === 1) await promptGate;
        git(query.directory, "add", "tracked.txt");
        git(
          query.directory,
          "-c",
          "core.hooksPath=/dev/null",
          "commit",
          "-m",
          "fix: update tracked content",
        );
        return { data: { info: {}, parts: [] } };
      },
      delete: async () => ({ data: true }),
      abort: async () => {
        aborts += 1;
        releasePrompt();
        return { data: true };
      },
    },
  };
  const hooks = await autoCommitPlugin({
    client: client as never,
    directory: root,
    experimental_workspace: { register() {} },
    project: {} as never,
    serverUrl: new URL("http://localhost"),
    worktree: root,
    $: undefined as never,
  });

  return {
    get aborts() {
      return aborts;
    },
    get creates() {
      return creates;
    },
    failStatusOnce() {
      statusFailures += 1;
    },
    get gets() {
      return gets;
    },
    hooks,
    releasePrompt,
    root,
    setBusy(value: boolean) {
      sessionBusy = value;
    },
    get statusCalls() {
      return statusCalls;
    },
    toasts,
  };
}

afterEach(async () => {
  await Promise.all(directories.splice(0).map((directory) => rm(directory, { recursive: true })));
});

describe("commit subject validation", () => {
  test("accepts only bounded Conventional Commit subjects", () => {
    expect(isConventionalSubject("fix(opencode): create commits asynchronously")).toBe(true);
    expect(isConventionalSubject("Create commits asynchronously")).toBe(false);
    expect(isConventionalSubject("fix: create commits asynchronously.")).toBe(false);
    expect(isConventionalSubject(`fix: ${"x".repeat(66)}`)).toBe(false);
  });
});

describe("repository snapshots", () => {
  test("materializes tracked and untracked changes without touching the live index", async () => {
    const root = await createRepository();
    await writeFile(join(root, "tracked.txt"), "after\n");
    await writeFile(join(root, "untracked.txt"), "new\n");

    const snapshot = await captureSnapshot(root);
    const temporary = await prepareTemporaryWorktree(root, snapshot);
    directories.push(temporary);

    expect(git(root, "diff", "--cached", "--name-only")).toBe("");
    expect(git(temporary, "status", "--short")).toContain("M tracked.txt");
    expect(git(temporary, "status", "--short")).toContain("?? untracked.txt");

    await removeTemporaryWorktree(root, temporary);
    directories.splice(directories.indexOf(temporary), 1);
  });

  test("detects changes made after capture", async () => {
    const root = await createRepository();
    await writeFile(join(root, "tracked.txt"), "captured\n");
    const snapshot = await captureSnapshot(root);

    expect(await snapshotIsCurrent(root, snapshot)).toBe(true);
    await writeFile(join(root, "tracked.txt"), "changed again\n");
    expect(await snapshotIsCurrent(root, snapshot)).toBe(false);
  });
});

describe("prepared commits", () => {
  test("replays a snapshot subset and leaves unrelated changes uncommitted", async () => {
    const root = await createRepository();
    await writeFile(join(root, "tracked.txt"), "after\n");
    await writeFile(join(root, "unrelated.txt"), "leave me\n");
    const snapshot = await captureSnapshot(root);
    const temporary = await prepareTemporaryWorktree(root, snapshot);
    directories.push(temporary);

    git(temporary, "add", "tracked.txt");
    git(temporary, "commit", "-m", "fix: update tracked content");
    const preparedHash = git(temporary, "rev-parse", "HEAD");
    const prepared = await validatePreparedCommits(temporary, snapshot);
    const created = await replayPreparedCommits(root, snapshot, prepared);

    expect(created).toHaveLength(1);
    expect(created[0]?.hash).toBe(preparedHash);
    expect(git(root, "rev-parse", "HEAD")).toBe(preparedHash);
    expect(git(root, "show", "-s", "--format=%s", "HEAD")).toBe("fix: update tracked content");
    expect(git(root, "status", "--short")).toBe("?? unrelated.txt");

    await removeTemporaryWorktree(root, temporary);
    directories.splice(directories.indexOf(temporary), 1);
  });

  test("does not integrate while another process owns the index lock", async () => {
    const root = await createRepository();
    await writeFile(join(root, "tracked.txt"), "after\n");
    const snapshot = await captureSnapshot(root);
    const temporary = await prepareTemporaryWorktree(root, snapshot);
    directories.push(temporary);

    git(temporary, "add", "tracked.txt");
    git(temporary, "commit", "-m", "fix: update tracked content");
    const prepared = await validatePreparedCommits(temporary, snapshot);
    await writeFile(join(root, ".git", "index.lock"), "held");

    await expect(replayPreparedCommits(root, snapshot, prepared)).rejects.toThrow(
      "index is locked",
    );
    expect(git(root, "rev-parse", "HEAD")).toBe(snapshot.head);
    expect(await readFile(join(root, ".git", "index.lock"), "utf8")).toBe("held");

    await removeTemporaryWorktree(root, temporary);
    directories.splice(directories.indexOf(temporary), 1);
  });

  test("recovers an interrupted integration after the branch advances", async () => {
    const root = await createRepository();
    await writeFile(join(root, "tracked.txt"), "after\n");
    const snapshot = await captureSnapshot(root);
    const temporary = await prepareTemporaryWorktree(root, snapshot);
    directories.push(temporary);

    git(temporary, "add", "tracked.txt");
    git(temporary, "commit", "-m", "fix: update tracked content");
    const prepared = await validatePreparedCommits(temporary, snapshot);
    const finalCommit = prepared.at(-1)!;
    const indexDirectory = await mkdtemp(join(tmpdir(), "opencode-auto-commit-index-test-"));
    directories.push(indexDirectory);
    const finalIndexPath = join(indexDirectory, "index");
    execFileSync("git", ["read-tree", finalCommit.tree], {
      cwd: root,
      env: { ...process.env, GIT_INDEX_FILE: finalIndexPath },
    });
    const finalIndex = await readFile(finalIndexPath);
    await writeFile(join(root, ".git", "index.lock"), finalIndex);
    await writeFile(
      join(root, ".git", "opencode-auto-commit-transaction.json"),
      `${JSON.stringify({
        branch: snapshot.branch,
        finalCommit: finalCommit.hash,
        finalIndexChecksum: createHash("sha256").update(finalIndex).digest("hex"),
        finalTree: finalCommit.tree,
        originalHead: snapshot.head,
      })}\n`,
    );
    git(root, "-c", "core.hooksPath=/dev/null", "update-ref", snapshot.branch, finalCommit.hash);

    expect(await recoverIntegration(root)).toBe(true);
    expect(git(root, "rev-parse", "HEAD")).toBe(finalCommit.hash);
    expect(git(root, "status", "--short")).toBe("");

    await removeTemporaryWorktree(root, temporary);
    directories.splice(directories.indexOf(temporary), 1);
  });

  test("rejects commits containing changes outside the snapshot", async () => {
    const root = await createRepository();
    await writeFile(join(root, "tracked.txt"), "captured\n");
    const snapshot = await captureSnapshot(root);
    const temporary = await prepareTemporaryWorktree(root, snapshot);
    directories.push(temporary);

    await writeFile(join(temporary, "invented.txt"), "not captured\n");
    git(temporary, "add", "invented.txt");
    git(temporary, "commit", "-m", "feat: invent unrelated content");

    await expect(validatePreparedCommits(temporary, snapshot)).rejects.toThrow(
      "outside the captured snapshot",
    );

    await removeTemporaryWorktree(root, temporary);
    directories.splice(directories.indexOf(temporary), 1);
  });

  test("rejects working file edits made by the commit agent", async () => {
    const root = await createRepository();
    await writeFile(join(root, "tracked.txt"), "captured\n");
    const snapshot = await captureSnapshot(root);
    const temporary = await prepareTemporaryWorktree(root, snapshot);
    directories.push(temporary);

    git(temporary, "add", "tracked.txt");
    git(temporary, "commit", "-m", "fix: update tracked content");
    await writeFile(join(temporary, "tracked.txt"), "agent edit\n");

    await expect(validatePreparedWorktree(temporary, snapshot)).rejects.toThrow(
      "modified the captured worktree",
    );

    await removeTemporaryWorktree(root, temporary);
    directories.splice(directories.indexOf(temporary), 1);
  });
});

test("skips sparse checkouts", async () => {
  const root = await createRepository();
  git(root, "sparse-checkout", "init", "--cone");
  await writeFile(join(root, "tracked.txt"), "after\n");

  await expect(captureSnapshot(root)).rejects.toThrow("sparse checkouts are not supported");
});

test("backfills resumed work from duplicate direct idle events", async () => {
  const harness = await createLifecycleHarness();
  const { hooks, root, toasts } = harness;

  await hooks["chat.message"]?.({ sessionID: "parent" });
  await hooks.event?.({
    event: { type: "session.idle", properties: { sessionID: "parent" } },
  });
  await waitFor(() => harness.creates === 1);
  await hooks.event?.({
    event: { type: "session.idle", properties: { sessionID: "parent" } },
  });
  harness.releasePrompt();

  await waitFor(() => toasts.some((toast) => toast.variant === "success"));
  await new Promise((resolve) => setTimeout(resolve, 750));
  expect(harness.creates).toBe(1);
  expect(git(root, "show", "-s", "--format=%s", "HEAD")).toBe("fix: update tracked content");
  expect(toasts.map((toast) => toast.message)).toContain(
    "Preparing automatic commits for resumed work...",
  );
  expect(toasts.some((toast) => toast.variant === "success")).toBe(true);

  await hooks.dispose?.();
});

test("restarts a cancelled worker once after the session becomes idle", async () => {
  const harness = await createLifecycleHarness();
  const { hooks, toasts } = harness;

  await hooks["chat.message"]?.({ sessionID: "parent" });
  await hooks.event?.({
    event: { type: "session.idle", properties: { sessionID: "parent" } },
  });
  await waitFor(() => harness.creates === 1);
  await hooks.event?.({
    event: {
      type: "session.status",
      properties: { sessionID: "parent", status: { type: "busy" } },
    },
  });
  expect(harness.aborts).toBe(1);
  await hooks.event?.({
    event: { type: "session.idle", properties: { sessionID: "parent" } },
  });

  await waitFor(() => harness.creates === 2);
  await waitFor(() => toasts.some((toast) => toast.variant === "success"));
  expect(harness.creates).toBe(2);
  expect(toasts.filter((toast) => toast.variant === "success")).toHaveLength(1);
  expect(toasts.filter((toast) => toast.variant === "warning")).toHaveLength(0);

  await hooks.dispose?.();
});

test("uses text completion to commit mutations without an idle event", async () => {
  const harness = await createLifecycleHarness();
  const { hooks, root, toasts } = harness;
  harness.releasePrompt();

  await hooks["tool.execute.after"]?.({
    args: {},
    callID: "call",
    sessionID: "parent",
    tool: "apply_patch",
  });
  await hooks["experimental.text.complete"]?.({
    messageID: "message",
    partID: "part",
    sessionID: "parent",
  });

  await waitFor(() => toasts.some((toast) => toast.variant === "success"));
  expect(harness.creates).toBe(1);
  expect(git(root, "show", "-s", "--format=%s", "HEAD")).toBe("fix: update tracked content");

  await hooks.dispose?.();
});

test("does not schedule completion fallback for read-only tools", async () => {
  const harness = await createLifecycleHarness();
  const { hooks } = harness;

  await hooks["tool.execute.after"]?.({
    args: {},
    callID: "call",
    sessionID: "parent",
    tool: "read",
  });
  await hooks["experimental.text.complete"]?.({
    messageID: "message",
    partID: "part",
    sessionID: "parent",
  });
  await new Promise((resolve) => setTimeout(resolve, 1250));

  expect(harness.creates).toBe(0);
  await hooks.dispose?.();
});

test("retries a mutation completed while a worker is running", async () => {
  const harness = await createLifecycleHarness();
  const { hooks, root, toasts } = harness;

  await hooks.event?.({
    event: { type: "session.idle", properties: { sessionID: "parent" } },
  });
  await waitFor(() => harness.creates === 1);
  await writeFile(join(root, "tracked.txt"), "after again\n");
  await hooks["tool.execute.after"]?.({
    args: {},
    callID: "call",
    sessionID: "parent",
    tool: "apply_patch",
  });
  await hooks["experimental.text.complete"]?.({
    messageID: "message",
    partID: "part",
    sessionID: "parent",
  });
  harness.releasePrompt();

  await waitFor(() => harness.creates === 2);
  await waitFor(() => toasts.some((toast) => toast.variant === "success"));
  expect(git(root, "show", "HEAD:tracked.txt")).toBe("after again");

  await hooks.dispose?.();
});

test("polls a busy session until completion without an idle event", async () => {
  const harness = await createLifecycleHarness();
  const { hooks, toasts } = harness;
  harness.setBusy(true);

  await hooks["tool.execute.after"]?.({
    args: {},
    callID: "call",
    sessionID: "parent",
    tool: "apply_patch",
  });
  await hooks["experimental.text.complete"]?.({
    messageID: "message",
    partID: "part",
    sessionID: "parent",
  });
  await hooks.event?.({
    event: {
      type: "session.status",
      properties: { sessionID: "parent", status: { type: "busy" } },
    },
  });
  await new Promise((resolve) => setTimeout(resolve, 1250));
  expect(harness.creates).toBe(0);

  harness.releasePrompt();
  harness.setBusy(false);
  await waitFor(() => toasts.some((toast) => toast.variant === "success"));
  expect(harness.creates).toBe(1);

  await hooks.dispose?.();
});

test("clears fallback state after a no-op mutating tool", async () => {
  const harness = await createLifecycleHarness({ dirty: false });
  const { hooks } = harness;

  await hooks["tool.execute.after"]?.({
    args: {},
    callID: "call",
    sessionID: "parent",
    tool: "apply_patch",
  });
  await hooks["experimental.text.complete"]?.({
    messageID: "message",
    partID: "part",
    sessionID: "parent",
  });
  await waitFor(() => harness.gets === 1);
  await new Promise((resolve) => setTimeout(resolve, 1250));

  await hooks["experimental.text.complete"]?.({
    messageID: "message-2",
    partID: "part-2",
    sessionID: "parent",
  });
  await new Promise((resolve) => setTimeout(resolve, 1250));
  expect(harness.gets).toBe(1);

  await hooks.dispose?.();
});

test("retries completion fallback after a transient status failure", async () => {
  const harness = await createLifecycleHarness();
  const { hooks, toasts } = harness;
  harness.failStatusOnce();
  harness.releasePrompt();

  await hooks["tool.execute.after"]?.({
    args: {},
    callID: "call",
    sessionID: "parent",
    tool: "apply_patch",
  });
  await hooks["experimental.text.complete"]?.({
    messageID: "message",
    partID: "part",
    sessionID: "parent",
  });

  await waitFor(() => toasts.some((toast) => toast.variant === "success"), 15_000);
  expect(harness.statusCalls).toBeGreaterThanOrEqual(2);
  expect(harness.creates).toBe(1);

  await hooks.dispose?.();
});
