import { afterEach, describe, expect, test } from "bun:test";
import { execFileSync } from "node:child_process";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { gitStatusLabel, inspectGitRepository, parseGitStatus, refreshGitRepository } from "./core";

const directories: string[] = [];

function git(cwd: string, ...args: string[]) {
  return execFileSync("git", args, { cwd, encoding: "utf8" }).trim();
}

function configureUser(directory: string) {
  git(directory, "config", "user.name", "Test User");
  git(directory, "config", "user.email", "test@example.com");
}

async function createRepository(withRemote = false) {
  const base = await mkdtemp(join(tmpdir(), "opencode-git-status-test-"));
  directories.push(base);
  const root = join(base, "root");
  await mkdir(root);
  git(root, "init", "-b", "main");
  configureUser(root);
  await writeFile(join(root, "tracked.txt"), "initial\n");
  git(root, "add", "tracked.txt");
  git(root, "commit", "-m", "chore: initialize repository");

  if (!withRemote) return { base, root };

  const remote = join(base, "remote.git");
  git(base, "init", "--bare", "-b", "main", remote);
  git(root, "remote", "add", "origin", remote);
  git(root, "push", "--set-upstream", "origin", "main");
  return { base, remote, root };
}

afterEach(async () => {
  await Promise.all(directories.splice(0).map((directory) => rm(directory, { recursive: true })));
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
