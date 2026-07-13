import { afterEach, describe, expect, test } from "bun:test";
import { execFileSync } from "node:child_process";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { basename, join } from "node:path";
import {
  discoverGitRepositories,
  gitStatusLabel,
  inspectGitRepository,
  parseGitStatus,
  refreshGitRepository,
} from "./core";
import gitStatusPlugin from "./index";

const directories: string[] = [];

function git(cwd: string, ...args: string[]) {
  return execFileSync("git", args, { cwd, encoding: "utf8" }).trim();
}

function gitInput(cwd: string, input: string, ...args: string[]) {
  return execFileSync("git", args, { cwd, encoding: "utf8", input }).trim();
}

function configureUser(directory: string) {
  git(directory, "config", "user.name", "Test User");
  git(directory, "config", "user.email", "test@example.com");
}

async function initializeRepository(root: string) {
  await mkdir(root, { recursive: true });
  git(root, "init", "-b", "main");
  configureUser(root);
  await writeFile(join(root, "tracked.txt"), "initial\n");
  git(root, "add", "tracked.txt");
  git(root, "commit", "-m", "chore: initialize repository");
}

async function createRepository(withRemote = false) {
  const base = await mkdtemp(join(tmpdir(), "opencode-git-status-test-"));
  directories.push(base);
  const root = join(base, "root");
  await initializeRepository(root);

  if (!withRemote) return { base, root };

  const remote = join(base, "remote.git");
  git(base, "init", "--bare", "-b", "main", remote);
  git(root, "remote", "add", "origin", remote);
  git(root, "push", "--set-upstream", "origin", "main");
  return { base, remote, root };
}

async function addSubmodule(root: string, path: string) {
  const { root: source } = await createRepository();
  git(root, "-c", "protocol.file.allow=always", "submodule", "add", source, path);
  const directory = join(root, path);
  configureUser(directory);
  git(root, "commit", "-am", `chore: add ${path} submodule`);
  return directory;
}

afterEach(async () => {
  await Promise.all(directories.splice(0).map((directory) => rm(directory, { recursive: true })));
});

test("registers in append-mode sidebar content rather than the single-winner footer", async () => {
  const directory = await mkdtemp(join(tmpdir(), "opencode-git-status-slot-test-"));
  directories.push(directory);
  const registrations: Array<{ slots: Record<string, unknown> }> = [];
  const disposers: Array<() => void> = [];

  await gitStatusPlugin.tui(
    {
      event: { on: () => () => {} },
      lifecycle: {
        onDispose: (dispose: () => void) => {
          disposers.push(dispose);
          return () => {};
        },
      },
      slots: {
        register: (plugin: { slots: Record<string, unknown> }) => {
          registrations.push(plugin);
          return "git-status";
        },
      },
      state: { path: { directory, worktree: directory } },
    } as never,
    undefined,
    {} as never,
  );

  expect(registrations).toHaveLength(1);
  expect(registrations[0]?.slots.sidebar_content).toBeFunction();
  expect(registrations[0]?.slots.sidebar_footer).toBeUndefined();
  for (const dispose of disposers) dispose();
});

describe("Git porcelain parsing", () => {
  test("parses branch, upstream, divergence, and worktree changes", () => {
    const status = parseGitStatus(`# branch.oid abc123
# branch.head feature
# branch.upstream origin/feature
# branch.ab +2 -3
1 .M N... 100644 100644 100644 abc123 abc123 tracked.txt
? untracked.txt
`);

    expect(status).toEqual({
      ahead: 2,
      behind: 3,
      branch: "feature",
      detached: false,
      dirty: true,
      upstream: "origin/feature",
    });
    expect(gitStatusLabel(status)).toBe("Out of sync +2/-3 | Uncommitted");
  });

  test("labels each requested repository state", () => {
    const base = {
      ahead: 0,
      behind: 0,
      branch: "main",
      detached: false,
      dirty: false,
      upstream: "origin/main",
    };

    expect(gitStatusLabel(base)).toBe("Clean");
    expect(gitStatusLabel({ ...base, dirty: true })).toBe("Uncommitted");
    expect(gitStatusLabel({ ...base, behind: 2 })).toBe("Pull 2");
    expect(gitStatusLabel({ ...base, ahead: 3 })).toBe("Push 3");
    expect(gitStatusLabel({ ...base, ahead: 1, behind: 4 })).toBe("Out of sync +1/-4");
    expect(gitStatusLabel({ ...base, upstream: undefined })).toBe("Clean | No upstream");
  });

  test("recognizes detached HEAD", () => {
    const status = parseGitStatus(`# branch.oid abc123
# branch.head (detached)
`);

    expect(status.detached).toBe(true);
    expect(status.branch).toBe("detached");
    expect(gitStatusLabel(status)).toBe("Clean");
  });
});

describe("Git repository inspection", () => {
  test("reports clean, dirty, ahead, behind, and diverged repositories", async () => {
    const { base, remote, root } = await createRepository(true);
    if (!remote) throw new Error("remote repository was not created");

    expect(await inspectGitRepository(root)).toMatchObject({
      ahead: 0,
      behind: 0,
      dirty: false,
      upstream: "origin/main",
    });

    await writeFile(join(root, "tracked.txt"), "dirty\n");
    expect(await inspectGitRepository(root)).toMatchObject({ dirty: true });
    git(root, "reset", "--hard", "HEAD");

    await writeFile(join(root, "tracked.txt"), "local\n");
    git(root, "commit", "-am", "feat: add local change");
    expect(await inspectGitRepository(root)).toMatchObject({ ahead: 1, behind: 0 });
    git(root, "reset", "--hard", "origin/main");

    const peer = join(base, "peer");
    git(base, "clone", remote, peer);
    configureUser(peer);
    await writeFile(join(peer, "remote.txt"), "remote\n");
    git(peer, "add", "remote.txt");
    git(peer, "commit", "-m", "feat: add remote change");
    git(peer, "push");
    git(root, "fetch", "--quiet");
    expect(await inspectGitRepository(root)).toMatchObject({ ahead: 0, behind: 1 });

    await writeFile(join(root, "local.txt"), "local\n");
    git(root, "add", "local.txt");
    git(root, "commit", "-m", "feat: diverge locally");
    expect(await inspectGitRepository(root)).toMatchObject({ ahead: 1, behind: 1 });
  });

  test("reports repositories without upstreams and detached HEADs", async () => {
    const { root } = await createRepository();

    const branch = await inspectGitRepository(root);
    expect(branch).toMatchObject({
      branch: "main",
      detached: false,
    });
    expect(branch?.upstream).toBeUndefined();

    git(root, "checkout", "--detach");
    const detached = await inspectGitRepository(root);
    expect(detached).toMatchObject({
      branch: "detached",
      detached: true,
    });
    expect(detached?.upstream).toBeUndefined();
  });

  test("silently ignores non-repositories", async () => {
    const directory = await mkdtemp(join(tmpdir(), "opencode-git-status-empty-"));
    directories.push(directory);

    expect(await inspectGitRepository(directory)).toBeUndefined();
  });

  test("retains cached tracking state when a fetch fails", async () => {
    const { base, root } = await createRepository(true);
    git(root, "remote", "set-url", "origin", join(base, "missing.git"));

    const result = await refreshGitRepository(root);

    expect(result.fetchFailed).toBe(true);
    expect(result.status).toMatchObject({
      ahead: 0,
      behind: 0,
      upstream: "origin/main",
    });
  });
});

describe("Git repository discovery", () => {
  test("discovers independent repositories recursively", async () => {
    const workspace = await mkdtemp(join(tmpdir(), "opencode-git-status-workspace-"));
    directories.push(workspace);
    await initializeRepository(join(workspace, "alpha"));
    await initializeRepository(join(workspace, "groups", "beta"));

    const repositories = await discoverGitRepositories(workspace);

    expect(
      repositories.map(({ depth, label, submodule }) => ({ depth, label, submodule })),
    ).toEqual([
      { depth: 0, label: "alpha", submodule: false },
      { depth: 0, label: "groups/beta", submodule: false },
    ]);
  });

  test("applies default and configurable scan exclusions", async () => {
    const workspace = await mkdtemp(join(tmpdir(), "opencode-git-status-exclusions-"));
    directories.push(workspace);
    await initializeRepository(join(workspace, "node_modules", "dependency"));
    await initializeRepository(join(workspace, "projects", "visible"));

    expect((await discoverGitRepositories(workspace)).map(({ label }) => label)).toEqual([
      "projects/visible",
    ]);
    expect(
      (
        await discoverGitRepositories(workspace, {
          scanExclusions: { add: ["projects"], remove: ["node_modules"] },
        })
      ).map(({ label }) => label),
    ).toEqual(["node_modules/dependency"]);
  });

  test("discovers and orders initialized submodules recursively without duplicates", async () => {
    const { root } = await createRepository();
    const child = await addSubmodule(root, "node_modules/child");
    await addSubmodule(child, "nested/grandchild");
    git(root, "add", "node_modules/child");
    git(root, "commit", "-m", "chore: record nested submodule");

    const repositories = await discoverGitRepositories(root);

    expect(
      repositories.map(({ depth, label, submodule }) => ({ depth, label, submodule })),
    ).toEqual([
      { depth: 0, label: basename(root), submodule: false },
      { depth: 1, label: "node_modules/child", submodule: true },
      { depth: 2, label: "node_modules/child/nested/grandchild", submodule: true },
    ]);
  });

  test("retains submodule hierarchy while its gitlink is conflicted", async () => {
    const { root } = await createRepository();
    const child = await addSubmodule(root, "node_modules/child");
    const hash = git(child, "rev-parse", "HEAD");
    git(root, "update-index", "--force-remove", "node_modules/child");
    gitInput(
      root,
      [1, 2, 3].map((stage) => `160000 ${hash} ${stage}\tnode_modules/child\n`).join(""),
      "update-index",
      "--index-info",
    );

    const repositories = await discoverGitRepositories(root);

    expect(
      repositories.map(({ depth, label, submodule }) => ({ depth, label, submodule })),
    ).toEqual([
      { depth: 0, label: basename(root), submodule: false },
      { depth: 1, label: "node_modules/child", submodule: true },
    ]);
  });

  test("escapes control characters in repository labels", async () => {
    const workspace = await mkdtemp(join(tmpdir(), "opencode-git-status-label-"));
    directories.push(workspace);
    await initializeRepository(join(workspace, "line\nbreak"));

    expect((await discoverGitRepositories(workspace)).map(({ label }) => label)).toEqual([
      "line\\x0abreak",
    ]);
  });

  test("reports submodule worktree changes only on the submodule row", async () => {
    const { root } = await createRepository();
    const child = await addSubmodule(root, "modules/child");
    await writeFile(join(child, "tracked.txt"), "dirty\n");

    expect(await inspectGitRepository(root)).toMatchObject({ dirty: false });
    expect(await inspectGitRepository(child)).toMatchObject({ dirty: true });

    git(child, "commit", "-am", "feat: update child");
    expect(await inspectGitRepository(root)).toMatchObject({ dirty: true });
    expect(await inspectGitRepository(child)).toMatchObject({ dirty: false });
  });
});
