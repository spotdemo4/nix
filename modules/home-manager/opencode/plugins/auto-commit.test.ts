import { afterEach, describe, expect, test } from "bun:test";
import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  captureSnapshot,
  isConventionalSubject,
  prepareTemporaryWorktree,
  recoverIntegration,
  removeTemporaryWorktree,
  replayPreparedCommits,
  snapshotIsCurrent,
  validatePreparedCommits,
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
});

test("skips sparse checkouts", async () => {
  const root = await createRepository();
  git(root, "sparse-checkout", "init", "--cone");
  await writeFile(join(root, "tracked.txt"), "after\n");

  await expect(captureSnapshot(root)).rejects.toThrow("sparse checkouts are not supported");
});
