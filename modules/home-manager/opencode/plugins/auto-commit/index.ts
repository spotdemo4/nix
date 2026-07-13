import type { Plugin, PluginModule } from "@opencode-ai/plugin";
import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdtemp, open, readFile, rename, rm, unlink } from "node:fs/promises";
import { tmpdir } from "node:os";
import { isAbsolute, join, relative, resolve, sep } from "node:path";
import { AUTO_COMMIT_SESSION_TITLE, AUTO_COMMIT_TRIGGER } from "./constants";
import { discoverGitRepositories, selectGitWorkspace } from "../git-status/core";

const AGENT = "auto-committer";
const GIT_TIMEOUT_MS = 120_000;
const STARTUP_GIT_TIMEOUT_MS = 5_000;
const ROOT_DISCOVERY_TTL_MS = 30_000;
const ROOT_STATUS_TIMEOUT_MS = 5_000;
const MAX_CONCURRENT_ROOT_STATUS = 4;
const IDLE_DELAY_MS = 500;
const COMPLETION_DELAY_MS = 1000;
const MAX_STATUS_RETRIES = 5;
const SESSION_TIMEOUT_MS = 15 * 60_000;
const SHUTDOWN_TIMEOUT_MS = 10_000;
const MAX_HISTORY_LENGTH = 80_000;
const MAX_PART_LENGTH = 12_000;
const MESSAGE_PAGE_SIZE = 100;
const MUTATION_TOOLS = new Set(["apply_patch", "bash", "edit", "write"]);

type SessionMessage = {
  info: { role: string };
  parts: Array<{
    synthetic?: boolean;
    type: string;
    text?: string;
    tool?: string;
    state?: { status?: string; input?: unknown };
  }>;
};

type GitOptions = {
  acceptedExitCodes?: number[];
  env?: NodeJS.ProcessEnv;
  input?: string | Buffer;
  timeoutMs?: number;
};

type GitResult = {
  code: number;
  stderr: string;
  stdout: string;
};

export type RepositorySnapshot = {
  branch: string;
  gitlinks: GitlinkChange[];
  head: string;
  headTree: string;
  snapshotCommit: string;
  snapshotTree: string;
};

export type GitlinkChange = {
  newHash?: string;
  oldHash?: string;
  path: string;
};

export type PreparedCommit = {
  hash: string;
  subject: string;
  tree: string;
};

export type InitializedSubmodule = {
  directory: string;
  path: string;
};

type Worker = {
  cancelled: boolean;
  child?: { directory: string; id: string };
  promise?: Promise<void>;
  rerun: boolean;
  temporaryWorktree?: { directory: string; repository: string };
};

type CreatedCommit = {
  hash: string;
  repository: string;
  subject: string;
};

type RepositoryTreeResult = {
  attempted: number;
  created: CreatedCommit[];
  skipped: string[];
};

type RepositoryRoot = {
  directory: string;
  issue?: string;
  name: string;
};

type RepositoryInspection = {
  branch: string;
  indexClean: boolean;
  ownChanges: boolean;
  sparseCheckout: boolean;
};

type IntegrationTransaction = {
  branch: string;
  finalCommit: string;
  finalIndexChecksum: string;
  finalTree: string;
  originalHead: string;
};

export class AutoCommitSkipped extends Error {
  constructor(
    message: string,
    readonly visible = true,
  ) {
    super(message);
  }
}

function runGit(cwd: string, args: string[], options: GitOptions = {}): Promise<GitResult> {
  return new Promise((resolve, reject) => {
    const child = spawn("git", args, {
      cwd,
      detached: process.platform !== "win32",
      env: {
        ...process.env,
        GIT_EDITOR: "true",
        GIT_SEQUENCE_EDITOR: "true",
        GIT_TERMINAL_PROMPT: "0",
        ...options.env,
      },
      stdio: ["pipe", "pipe", "pipe"],
    });
    const stdout: Buffer[] = [];
    const stderr: Buffer[] = [];
    let timedOut = false;
    let killTimeout: NodeJS.Timeout | undefined;
    const kill = (signal: NodeJS.Signals) => {
      if (child.pid && process.platform !== "win32") {
        try {
          process.kill(-child.pid, signal);
          return;
        } catch {
          // Fall back to the direct child if its process group already exited.
        }
      }
      child.kill(signal);
    };
    const timeout = setTimeout(() => {
      timedOut = true;
      kill("SIGTERM");
      killTimeout = setTimeout(() => kill("SIGKILL"), 5000);
    }, options.timeoutMs ?? GIT_TIMEOUT_MS);

    child.stdout.on("data", (chunk: Buffer) => stdout.push(chunk));
    child.stderr.on("data", (chunk: Buffer) => stderr.push(chunk));
    child.on("error", (error) => {
      clearTimeout(timeout);
      if (killTimeout) clearTimeout(killTimeout);
      reject(error);
    });
    child.on("close", (code) => {
      clearTimeout(timeout);
      if (killTimeout) clearTimeout(killTimeout);
      const result = {
        code: code ?? -1,
        stdout: Buffer.concat(stdout).toString(),
        stderr: Buffer.concat(stderr).toString(),
      };
      if (timedOut) {
        reject(new Error(`git ${args.join(" ")} timed out`));
        return;
      }
      if ((options.acceptedExitCodes ?? [0]).includes(result.code)) {
        resolve(result);
        return;
      }

      reject(
        new Error(
          [`git ${args.join(" ")} exited with ${result.code}`, result.stderr.trim()]
            .filter(Boolean)
            .join(": "),
        ),
      );
    });

    if (options.input !== undefined) child.stdin.end(options.input);
    else child.stdin.end();
  });
}

async function gitOutput(cwd: string, args: string[], options?: GitOptions) {
  return (await runGit(cwd, args, options)).stdout.trim();
}

async function withTimeout<T>(promise: Promise<T>, timeoutMs: number, description: string) {
  let timeout: NodeJS.Timeout | undefined;
  try {
    return await Promise.race([
      promise,
      new Promise<never>((_, reject) => {
        timeout = setTimeout(() => reject(new Error(`${description} timed out`)), timeoutMs);
      }),
    ]);
  } finally {
    if (timeout) clearTimeout(timeout);
  }
}

async function someConcurrent<T>(
  items: T[],
  limit: number,
  predicate: (item: T) => Promise<boolean>,
) {
  let found = false;
  let next = 0;
  const worker = async () => {
    while (!found && next < items.length) {
      const index = next;
      next += 1;
      if (await predicate(items[index])) found = true;
    }
  };
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, () => worker()));
  return found;
}

async function indexIsClean(root: string) {
  const result = await runGit(root, ["diff", "--cached", "--quiet", "--exit-code"], {
    acceptedExitCodes: [0, 1],
  });
  return result.code === 0;
}

async function inspectRepository(root: string): Promise<RepositoryInspection> {
  const head = await gitOutput(root, ["rev-parse", "HEAD"]);
  const [headTree, branchResult, sparseCheckout, indexClean, worktreeTree] = await Promise.all([
    gitOutput(root, ["rev-parse", `${head}^{tree}`]),
    runGit(root, ["symbolic-ref", "-q", "HEAD"], { acceptedExitCodes: [0, 1] }),
    runGit(root, ["config", "--bool", "core.sparseCheckout"], {
      acceptedExitCodes: [0, 1],
    }),
    indexIsClean(root),
    writeWorktreeTree(root, head),
  ]);
  return {
    branch: branchResult.stdout.trim(),
    indexClean,
    ownChanges: worktreeTree !== headTree,
    sparseCheckout: sparseCheckout.stdout.trim() === "true",
  };
}

async function listTreeGitlinks(root: string, tree: string) {
  const entries = (await runGit(root, ["ls-tree", "-r", "-z", tree])).stdout.split("\0");
  const gitlinks = new Map<string, string>();
  for (const entry of entries) {
    if (!entry) continue;
    const match = /^160000 commit ([0-9a-f]+)\t([\s\S]+)$/.exec(entry);
    if (match) gitlinks.set(match[2], match[1]);
  }
  return gitlinks;
}

function gitPathHasControlCharacters(path: string) {
  for (let index = 0; index < path.length; index += 1) {
    const codeUnit = path.charCodeAt(index);
    if (codeUnit < 0x20 || codeUnit === 0x7f) return true;
  }
  return false;
}

async function findGitlinkChanges(root: string, oldTree: string, newTree: string) {
  const [oldGitlinks, newGitlinks] = await Promise.all([
    listTreeGitlinks(root, oldTree),
    listTreeGitlinks(root, newTree),
  ]);
  return [...new Set([...oldGitlinks.keys(), ...newGitlinks.keys()])]
    .sort()
    .flatMap((path): GitlinkChange[] => {
      if (gitPathHasControlCharacters(path)) {
        throw new AutoCommitSkipped(
          "gitlink paths containing control characters are not supported",
        );
      }
      const oldHash = oldGitlinks.get(path);
      const newHash = newGitlinks.get(path);
      return oldHash === newHash ? [] : [{ path, oldHash, newHash }];
    });
}

async function applyGitlinkChanges(root: string, changes: GitlinkChange[], env: NodeJS.ProcessEnv) {
  for (const change of changes) {
    if (change.newHash) {
      await runGit(
        root,
        ["update-index", "--add", "--cacheinfo", "160000", change.newHash, change.path],
        { env },
      );
    } else {
      await runGit(root, ["update-index", "--force-remove", "--", change.path], { env });
    }
  }
}

export async function writeWorktreeTree(
  root: string,
  head: string,
  gitlinks: GitlinkChange[] = [],
) {
  const indexDirectory = await mkdtemp(join(tmpdir(), "opencode-auto-commit-index-"));
  const index = join(indexDirectory, "index");
  const env = { GIT_INDEX_FILE: index };

  try {
    await runGit(root, ["read-tree", head], { env });
    await runGit(root, ["add", "-A", "--"], { env });
    await applyGitlinkChanges(root, gitlinks, env);
    return await gitOutput(root, ["write-tree"], { env });
  } finally {
    await rm(indexDirectory, { force: true, recursive: true });
  }
}

export async function captureSnapshot(root: string): Promise<RepositorySnapshot> {
  const repository = await runGit(root, ["rev-parse", "--is-inside-work-tree"], {
    acceptedExitCodes: [0, 128],
  });
  if (repository.code !== 0 || repository.stdout.trim() !== "true") {
    throw new AutoCommitSkipped("the session is not inside a Git worktree", false);
  }

  const head = await gitOutput(root, ["rev-parse", "HEAD"]);
  const headTree = await gitOutput(root, ["rev-parse", `${head}^{tree}`]);
  const sparseCheckout = await runGit(root, ["config", "--bool", "core.sparseCheckout"], {
    acceptedExitCodes: [0, 1],
  });
  if (sparseCheckout.stdout.trim() === "true") {
    throw new AutoCommitSkipped("sparse checkouts are not supported");
  }
  if (!(await indexIsClean(root))) {
    throw new AutoCommitSkipped("the Git index contains staged changes");
  }

  const snapshotTree = await writeWorktreeTree(root, head);
  if (snapshotTree === headTree) {
    throw new AutoCommitSkipped("there are no changes to commit", false);
  }

  const branchResult = await runGit(root, ["symbolic-ref", "-q", "HEAD"], {
    acceptedExitCodes: [0, 1],
  });
  const branch = branchResult.stdout.trim();
  if (!branch.startsWith("refs/heads/")) throw new AutoCommitSkipped("HEAD is detached");

  const gitlinks = await findGitlinkChanges(root, headTree, snapshotTree);

  const identity = {
    GIT_AUTHOR_EMAIL: "auto-commit@opencode.local",
    GIT_AUTHOR_NAME: "OpenCode Auto Commit",
    GIT_COMMITTER_EMAIL: "auto-commit@opencode.local",
    GIT_COMMITTER_NAME: "OpenCode Auto Commit",
  };
  const snapshotCommit = await gitOutput(
    root,
    ["commit-tree", snapshotTree, "-p", head, "-m", "OpenCode auto-commit snapshot"],
    { env: identity },
  );

  return { branch, gitlinks, head, headTree, snapshotCommit, snapshotTree };
}

export async function snapshotIsCurrent(root: string, snapshot: RepositorySnapshot) {
  if ((await gitOutput(root, ["rev-parse", "HEAD"])) !== snapshot.head) return false;
  if ((await gitOutput(root, ["symbolic-ref", "-q", "HEAD"])) !== snapshot.branch) return false;
  if (!(await indexIsClean(root))) return false;
  return (await writeWorktreeTree(root, snapshot.head)) === snapshot.snapshotTree;
}

export async function prepareTemporaryWorktree(root: string, snapshot: RepositorySnapshot) {
  const directory = await mkdtemp(join(tmpdir(), "opencode-auto-commit-worktree-"));

  try {
    await runGit(root, ["worktree", "add", "--detach", directory, snapshot.head]);
    await runGit(directory, ["read-tree", "--reset", "-u", snapshot.snapshotTree]);
    await runGit(directory, ["reset", "--mixed", snapshot.head]);
    return directory;
  } catch (error) {
    await removeTemporaryWorktree(root, directory).catch(async () => {
      await rm(directory, { force: true, recursive: true });
      await runGit(root, ["worktree", "prune"]).catch(() => undefined);
    });
    throw error;
  }
}

export async function removeTemporaryWorktree(root: string, directory: string) {
  try {
    await runGit(root, ["worktree", "remove", "--force", directory]);
  } catch (error) {
    await rm(directory, { force: true, recursive: true });
    await runGit(root, ["worktree", "prune"]);
    throw error;
  }
}

export async function listInitializedSubmodules(root: string): Promise<InitializedSubmodule[]> {
  const entries = (await runGit(root, ["ls-files", "--stage", "-z"])).stdout.split("\0");
  const submodules: InitializedSubmodule[] = [];

  for (const entry of entries) {
    const match = /^160000 [0-9a-f]+ 0\t([\s\S]+)$/.exec(entry);
    if (!match) continue;
    const path = match[1];
    const directory = resolve(root, path);
    const fromRoot = relative(root, directory);
    if (fromRoot === ".." || fromRoot.startsWith(`..${sep}`) || isAbsolute(fromRoot)) continue;

    const [topLevel, superproject] = await Promise.all([
      runGit(root, ["-C", directory, "rev-parse", "--show-toplevel"], {
        acceptedExitCodes: [0, 128],
      }),
      runGit(root, ["-C", directory, "rev-parse", "--show-superproject-working-tree"], {
        acceptedExitCodes: [0, 128],
      }),
    ]);
    if (topLevel.code !== 0 || superproject.code !== 0) continue;
    const topLevelPath = topLevel.stdout.endsWith("\n")
      ? topLevel.stdout.slice(0, -1)
      : topLevel.stdout;
    const superprojectPath = superproject.stdout.endsWith("\n")
      ? superproject.stdout.slice(0, -1)
      : superproject.stdout;
    if (resolve(topLevelPath) !== directory || resolve(superprojectPath) !== resolve(root)) {
      continue;
    }
    submodules.push({ directory, path });
  }

  return submodules;
}

export async function recoverIntegrationTree(
  root: string,
  visited = new Set<string>(),
): Promise<boolean> {
  const gitDirectory = await gitOutput(root, ["rev-parse", "--absolute-git-dir"]);
  if (visited.has(gitDirectory)) return false;
  visited.add(gitDirectory);

  let recovered = false;
  for (const submodule of await listInitializedSubmodules(root)) {
    recovered = (await recoverIntegrationTree(submodule.directory, visited)) || recovered;
  }
  return (await recoverIntegration(root)) || recovered;
}

export function isConventionalSubject(subject: string) {
  return (
    subject.length <= 65 &&
    /^(feat|fix|refactor|docs|style|test|perf|ci|build|chore)(\([a-z0-9][a-z0-9._/-]*\))?!?: [a-z0-9].*[^.!?]$/.test(
      subject,
    )
  );
}

export async function validatePreparedCommits(
  directory: string,
  snapshot: RepositorySnapshot,
): Promise<PreparedCommit[]> {
  const hashes = (await gitOutput(directory, ["rev-list", "--reverse", `${snapshot.head}..HEAD`]))
    .split("\n")
    .filter(Boolean);
  const prepared: PreparedCommit[] = [];
  let parent = snapshot.head;

  for (const hash of hashes) {
    const parents = (await gitOutput(directory, ["show", "-s", "--format=%P", hash]))
      .split(" ")
      .filter(Boolean);
    if (parents.length !== 1 || parents[0] !== parent) {
      throw new Error(`prepared commit ${hash} is not a linear child of ${parent}`);
    }

    const subject = await gitOutput(directory, ["show", "-s", "--format=%s", hash]);
    if (!isConventionalSubject(subject)) {
      throw new Error(`prepared commit has an invalid subject: ${subject}`);
    }

    const tree = await gitOutput(directory, ["show", "-s", "--format=%T", hash]);
    const parentTree = await gitOutput(directory, ["show", "-s", "--format=%T", parent]);
    if (tree === parentTree) throw new Error(`prepared commit ${hash} is empty`);

    const merge = await runGit(
      directory,
      ["merge-tree", "--write-tree", hash, snapshot.snapshotCommit],
      { acceptedExitCodes: [0, 1] },
    );
    if (merge.code !== 0 || merge.stdout.trim().split("\n")[0] !== snapshot.snapshotTree) {
      throw new Error(`prepared commit ${hash} contains changes outside the captured snapshot`);
    }

    prepared.push({ hash, subject, tree });
    parent = hash;
  }

  return prepared;
}

export async function validatePreparedWorktree(directory: string, snapshot: RepositorySnapshot) {
  if (
    (await writeWorktreeTree(directory, snapshot.head, snapshot.gitlinks)) !== snapshot.snapshotTree
  ) {
    throw new Error("the auto-commit agent modified the captured worktree");
  }
}

async function buildIndex(root: string, tree: string) {
  const indexDirectory = await mkdtemp(join(tmpdir(), "opencode-auto-commit-final-index-"));
  const index = join(indexDirectory, "index");
  try {
    await runGit(root, ["read-tree", tree], { env: { GIT_INDEX_FILE: index } });
    return await readFile(index);
  } finally {
    await rm(indexDirectory, { force: true, recursive: true });
  }
}

async function liveIndexPath(root: string) {
  const value = await gitOutput(root, ["rev-parse", "--git-path", "index"]);
  return isAbsolute(value) ? value : resolve(root, value);
}

async function transactionPath(root: string) {
  const value = await gitOutput(root, [
    "rev-parse",
    "--git-path",
    "opencode-auto-commit-transaction.json",
  ]);
  return isAbsolute(value) ? value : resolve(root, value);
}

function checksum(value: Buffer) {
  return createHash("sha256").update(value).digest("hex");
}

export async function recoverIntegration(root: string) {
  const transactionFile = await transactionPath(root);
  let transaction: IntegrationTransaction;
  try {
    transaction = JSON.parse(await readFile(transactionFile, "utf8")) as IntegrationTransaction;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") return false;
    throw new Error("invalid auto-commit recovery transaction", { cause: error });
  }

  const index = await liveIndexPath(root);
  const lock = `${index}.lock`;
  const current = await gitOutput(root, ["rev-parse", transaction.branch]);
  let lockContents: Buffer | undefined;
  try {
    lockContents = await readFile(lock);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
  }

  if (lockContents && checksum(lockContents) !== transaction.finalIndexChecksum) {
    throw new Error("the Git index lock does not match the interrupted auto-commit transaction");
  }

  if (current === transaction.finalCommit) {
    if (lockContents) {
      await rename(lock, index);
    } else if ((await gitOutput(root, ["write-tree"])) !== transaction.finalTree) {
      throw new Error("the interrupted auto-commit advanced HEAD without installing its index");
    }
  } else if (current === transaction.originalHead) {
    if (lockContents) await unlink(lock);
  } else {
    throw new Error("the branch changed after an interrupted auto-commit transaction");
  }

  await unlink(transactionFile);
  return true;
}

export async function replayPreparedCommits(
  root: string,
  snapshot: RepositorySnapshot,
  commits: PreparedCommit[],
  shouldContinue: () => boolean | Promise<boolean> = () => true,
) {
  if (!(await snapshotIsCurrent(root, snapshot))) {
    throw new AutoCommitSkipped("the repository changed while commits were prepared");
  }
  if (commits.length === 0) return [];
  if (!(await shouldContinue())) {
    throw new AutoCommitSkipped("the parent session resumed", false);
  }

  const finalCommit = commits.at(-1)!;
  const finalIndex = await buildIndex(root, finalCommit.tree);
  const index = await liveIndexPath(root);
  const lock = `${index}.lock`;
  const transactionFile = await transactionPath(root);
  const transaction: IntegrationTransaction = {
    branch: snapshot.branch,
    finalCommit: finalCommit.hash,
    finalIndexChecksum: checksum(finalIndex),
    finalTree: finalCommit.tree,
    originalHead: snapshot.head,
  };
  let lockHandle: Awaited<ReturnType<typeof open>> | undefined;
  let ownsIndexLock = false;
  let ownsTransaction = false;
  let indexInstalled = false;
  let refUpdated = false;

  try {
    try {
      const transactionHandle = await open(transactionFile, "wx", 0o600);
      ownsTransaction = true;
      await transactionHandle.writeFile(`${JSON.stringify(transaction)}\n`);
      await transactionHandle.sync();
      await transactionHandle.close();
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "EEXIST") {
        throw new AutoCommitSkipped("another auto-commit transaction needs recovery");
      }
      throw error;
    }

    try {
      lockHandle = await open(lock, "wx", 0o600);
      ownsIndexLock = true;
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "EEXIST") {
        throw new AutoCommitSkipped("the Git index is locked by another process");
      }
      throw error;
    }

    if (!(await snapshotIsCurrent(root, snapshot))) {
      throw new AutoCommitSkipped("the repository changed before integration");
    }
    if (!(await shouldContinue())) {
      throw new AutoCommitSkipped("the parent session resumed", false);
    }

    await lockHandle.writeFile(finalIndex);
    await lockHandle.sync();
    await lockHandle.close();
    lockHandle = undefined;

    await runGit(root, [
      "-c",
      "core.hooksPath=/dev/null",
      "update-ref",
      snapshot.branch,
      finalCommit.hash,
      snapshot.head,
    ]);
    refUpdated = true;
    await rename(lock, index);
    ownsIndexLock = false;
    indexInstalled = true;
    await unlink(transactionFile);
    ownsTransaction = false;
  } catch (error) {
    await lockHandle?.close().catch(() => undefined);
    if (!refUpdated) {
      const current = await gitOutput(root, ["rev-parse", snapshot.branch]).catch(() => "");
      refUpdated = current === finalCommit.hash;
    }
    if (!refUpdated) {
      if (ownsIndexLock) await unlink(lock).catch(() => undefined);
      if (ownsTransaction) await unlink(transactionFile).catch(() => undefined);
      throw error;
    }
    if (indexInstalled) {
      return commits.map(({ hash, subject }) => ({ hash, subject }));
    }

    try {
      if (ownsIndexLock) {
        await rename(lock, index);
        ownsIndexLock = false;
        indexInstalled = true;
      }
      if (ownsTransaction) await unlink(transactionFile);
      return commits.map(({ hash, subject }) => ({ hash, subject }));
    } catch (indexError) {
      if (indexInstalled) {
        return commits.map(({ hash, subject }) => ({ hash, subject }));
      }
      const rolledBack = await runGit(root, [
        "-c",
        "core.hooksPath=/dev/null",
        "update-ref",
        snapshot.branch,
        snapshot.head,
        finalCommit.hash,
      ])
        .then(() => true)
        .catch(() => false);
      if (rolledBack) {
        if (ownsIndexLock) await unlink(lock).catch(() => undefined);
        if (ownsTransaction) await unlink(transactionFile).catch(() => undefined);
      }
      const detail = indexError instanceof Error ? indexError.message : String(indexError);
      throw new Error(`failed to install the final Git index: ${detail}`, { cause: error });
    }
  }

  return commits.map(({ hash, subject }) => ({ hash, subject }));
}

function truncate(text: string, limit: number) {
  if (text.length <= limit) return text;
  const marker = "\n... context truncated ...\n";
  if (limit <= marker.length) return text.slice(0, limit);
  const available = limit - marker.length;
  return `${text.slice(0, Math.ceil(available / 2))}${marker}${text.slice(
    -Math.floor(available / 2),
  )}`;
}

function renderToolInput(tool: string, input: unknown) {
  if (tool !== "bash" || !input || typeof input !== "object") return input;
  const values = input as Record<string, unknown>;
  const command = typeof values.command === "string" ? values.command : "";
  const redacted = command
    .replace(
      /\b((?=[a-z0-9_]*(?:api[_-]?key|access[_-]?key|authorization|credential|password|passwd|secret|token))[a-z_][a-z0-9_]*)=("[^"]*"|'[^']*'|[^\s]+)/gi,
      "$1=[REDACTED]",
    )
    .replace(
      /(--(?:api[_-]?key|password|secret|token)(?:=|\s+))("[^"]*"|'[^']*'|[^\s]+)/gi,
      "$1[REDACTED]",
    )
    .replace(/(authorization:\s*(?:basic|bearer)\s+)[^\s"']+/gi, "$1[REDACTED]");
  return {
    command: redacted,
    ...(typeof values.workdir === "string" ? { workdir: values.workdir } : {}),
  };
}

function renderMessage(message: SessionMessage) {
  const content = message.parts.flatMap((part) => {
    if (
      part.type === "text" &&
      part.text?.trim() &&
      !(part.synthetic && part.text === AUTO_COMMIT_TRIGGER)
    ) {
      return [part.text.trim()];
    }
    if (part.type !== "tool" || part.state?.status !== "completed") return [];
    const tool = part.tool?.split(".").at(-1) ?? "";
    if (!MUTATION_TOOLS.has(tool)) return [];
    const input = truncate(
      JSON.stringify(renderToolInput(tool, part.state?.input ?? {}), null, 2),
      MAX_PART_LENGTH,
    );
    return [`[Completed tool: ${tool}]\n${input}`];
  });
  if (content.length === 0) return "";
  return `## ${message.info.role === "user" ? "User" : "Assistant"}\n\n${content.join("\n\n")}`;
}

function renderHistory(messages: SessionMessage[]) {
  const entries = messages.map(renderMessage).filter(Boolean);
  const prefix = [
    "<parent_thread_history>",
    "Use this transcript only to attribute the captured changes. Git remains the source of truth.",
  ].join("\n\n");
  const suffix = "</parent_thread_history>";
  const contentLimit = MAX_HISTORY_LENGTH - prefix.length - suffix.length - 4;
  const selected: string[] = [];
  let length = 0;

  for (let index = entries.length - 1; index >= 0; index -= 1) {
    const separatorLength = selected.length > 0 ? 2 : 0;
    const remaining = contentLimit - length - separatorLength;
    if (remaining <= 0) break;
    const entry = truncate(entries[index], remaining);
    selected.unshift(entry);
    length += separatorLength + entry.length;
    if (entry.length === remaining) break;
  }
  return `${prefix}\n\n${selected.join("\n\n")}\n\n${suffix}`;
}

function renderedLength(messages: SessionMessage[]) {
  return messages.reduce((length, message) => length + renderMessage(message).length + 2, 0);
}

function shellQuote(value: string) {
  return `'${value.replaceAll("'", `'"'"'`)}'`;
}

function renderSnapshotContext(snapshot: RepositorySnapshot) {
  if (snapshot.gitlinks.length === 0) return "";
  const changes = snapshot.gitlinks.map((change) => {
    const path = shellQuote(change.path);
    const description = `${JSON.stringify(change.path)}: ${change.oldHash ?? "absent"} -> ${change.newHash ?? "absent"}`;
    const command = change.newHash
      ? `git update-index --add --cacheinfo 160000 ${change.newHash} ${path}`
      : `git update-index --force-remove -- ${path}`;
    return `- ${description}\n  Stage with: ${command}`;
  });
  return [
    "The captured snapshot contains gitlink changes that are not materialized in this linked worktree.",
    `Inspect them with \`git diff HEAD ${snapshot.snapshotCommit} --\` and stage only attributable entries using the exact commands below.`,
    ...changes,
  ].join("\n");
}

const autoCommitPlugin = (async ({ client, directory, project, worktree }) => {
  const gitProject = project.vcs === "git";
  const workspace = selectGitWorkspace(directory, worktree);
  if (gitProject) {
    const repository = await runGit(workspace, ["rev-parse", "--is-inside-work-tree"], {
      acceptedExitCodes: [0, 128],
      timeoutMs: STARTUP_GIT_TIMEOUT_MS,
    }).catch(() => undefined);
    if (!repository || repository.code !== 0 || repository.stdout.trim() !== "true") return {};
  }

  const busySessions = new Set<string>();
  const mutationGenerations = new Map<string, number>();
  const resumedSessions = new Set<string>();
  const statusFailures = new Map<string, number>();
  const timers = new Map<string, NodeJS.Timeout>();
  const workers = new Map<string, Worker>();
  const discoveryController = new AbortController();
  let repositoryRootCache: { expires: number; roots: RepositoryRoot[] } | undefined;
  let repositoryRootPromise: Promise<RepositoryRoot[]> | undefined;
  let disposed = false;
  let mutationSequence = 0;

  const log = async (level: "debug" | "info" | "warn" | "error", message: string) => {
    await client.app
      .log({ body: { service: "auto-commit", level, message } })
      .catch(() => undefined);
  };

  const notify = async (variant: "info" | "success" | "warning" | "error", message: string) => {
    await client.tui
      .showToast({
        body: { title: "Auto commit", message, variant, duration: 6000 },
        query: { directory },
      })
      .catch(() => undefined);
  };

  if (gitProject) {
    try {
      if (await recoverIntegrationTree(workspace)) {
        await log("warn", "Recovered an interrupted auto-commit integration");
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      await log("error", `Auto-commit recovery failed: ${message}`);
      return {};
    }
  }

  const repositoryRoots = async (force = false) => {
    if (gitProject) return [{ directory: workspace, name: "." }];
    if (!force && repositoryRootCache && repositoryRootCache.expires > Date.now()) {
      return repositoryRootCache.roots;
    }
    if (repositoryRootPromise) return repositoryRootPromise;

    repositoryRootPromise = discoverGitRepositories(workspace, {
      allowPartial: true,
      signal: discoveryController.signal,
      timeoutMs: STARTUP_GIT_TIMEOUT_MS,
    })
      .then((repositories) => {
        const roots: RepositoryRoot[] = repositories
          .filter((repository) => !repository.submodule)
          .map((repository) => ({ directory: repository.directory, name: repository.label }));
        for (const root of roots) {
          const nested = roots.some((candidate) => {
            if (candidate === root) return false;
            const path = relative(root.directory, candidate.directory);
            return path !== ".." && !path.startsWith(`..${sep}`) && !isAbsolute(path);
          });
          if (nested) root.issue = "contains an independent nested repository";
        }
        repositoryRootCache = { expires: Date.now() + ROOT_DISCOVERY_TTL_MS, roots };
        return roots;
      })
      .finally(() => {
        repositoryRootPromise = undefined;
      });
    return repositoryRootPromise;
  };

  const loadHistory = async (sessionID: string) => {
    const messages: SessionMessage[] = [];
    const cursors = new Set<string>();
    let before: string | undefined;

    do {
      const response = await client.session.messages({
        path: { id: sessionID },
        query: { limit: MESSAGE_PAGE_SIZE, ...(before ? { before } : {}) },
      });
      if (!response.data) throw new Error("failed to load parent session messages");
      messages.unshift(...(response.data as SessionMessage[]));
      const cursor = response.response.headers.get("x-next-cursor") ?? undefined;
      if (!cursor || cursors.has(cursor)) break;
      cursors.add(cursor);
      before = cursor;
    } while (renderedLength(messages) < MAX_HISTORY_LENGTH);

    return renderHistory(messages);
  };

  const sessionIsIdle = async (sessionID: string) => {
    const response = await client.session.status({ query: { directory } });
    statusFailures.delete(sessionID);
    const status = response.data?.[sessionID];
    if (!status || status.type === "idle") {
      busySessions.delete(sessionID);
      return true;
    }
    return false;
  };

  const runWorker = async (sessionID: string, worker: Worker) => {
    const mutationGeneration = mutationGenerations.get(sessionID);
    const resumed = resumedSessions.delete(sessionID);
    let retryPending = false;
    let history: Promise<string> | undefined;
    let preparationNotified = false;

    const shouldContinue = async () =>
      !worker.cancelled && !disposed && (await sessionIsIdle(sessionID));

    const mergeResult = (target: RepositoryTreeResult, source: RepositoryTreeResult) => {
      target.attempted += source.attempted;
      target.created.push(...source.created);
      target.skipped.push(...source.skipped);
    };

    type RepositoryNode = {
      children: RepositoryNode[];
      issue?: string;
      name: string;
      needsProcessing: boolean;
      repository: string;
    };

    const inspectRepositoryTree = async (
      repository: string,
      name: string,
    ): Promise<RepositoryNode> => {
      const [inspection, submodules] = await Promise.all([
        inspectRepository(repository),
        listInitializedSubmodules(repository),
      ]);
      const children: RepositoryNode[] = [];
      for (const submodule of submodules) {
        if (gitPathHasControlCharacters(submodule.path)) {
          throw new AutoCommitSkipped(
            "submodule paths containing control characters are not supported",
          );
        }
        children.push(
          await inspectRepositoryTree(
            submodule.directory,
            relative(workspace, submodule.directory) || submodule.path,
          ),
        );
      }

      const needsProcessing =
        inspection.ownChanges || children.some((child) => child.needsProcessing);
      let issue: string | undefined;
      if (needsProcessing && inspection.sparseCheckout) {
        issue = "sparse checkouts are not supported";
      } else if (needsProcessing && !inspection.indexClean) {
        issue = "the Git index contains staged changes";
      } else if (needsProcessing && !inspection.branch.startsWith("refs/heads/")) {
        issue = "HEAD is detached; check out a branch before committing";
      }
      return { children, issue, name, needsProcessing, repository };
    };

    const processRepositoryTree = async (
      node: RepositoryNode,
      root: boolean,
    ): Promise<RepositoryTreeResult> => {
      const { children, issue, name: repositoryName, repository } = node;
      const result: RepositoryTreeResult = { attempted: 0, created: [], skipped: [] };
      if (!(await shouldContinue())) {
        throw new AutoCommitSkipped("the parent session resumed", false);
      }

      if (issue) {
        if (root) throw new AutoCommitSkipped(issue);
        result.skipped.push(`${repositoryName}: ${issue}`);
        await log("warn", `Skipped recursive auto commit in ${repositoryName}: ${issue}`);
        return result;
      }
      if (!node.needsProcessing) return result;

      for (const child of children) {
        mergeResult(result, await processRepositoryTree(child, false));
      }

      if (!(await shouldContinue())) {
        throw new AutoCommitSkipped("the parent session resumed", false);
      }

      let snapshot: RepositorySnapshot;
      try {
        snapshot = await captureSnapshot(repository);
      } catch (error) {
        if (
          error instanceof AutoCommitSkipped &&
          error.message === "there are no changes to commit"
        ) {
          return result;
        }
        if (error instanceof AutoCommitSkipped && !root) {
          const detail = error.message;
          result.skipped.push(`${repositoryName}: ${detail}`);
          await log("warn", `Skipped recursive auto commit in ${repositoryName}: ${detail}`);
          return result;
        }
        throw error;
      }

      const secondTree = await writeWorktreeTree(repository, snapshot.head);
      if (secondTree !== snapshot.snapshotTree || !(await shouldContinue())) {
        retryPending = true;
        throw new AutoCommitSkipped("the worktree or session changed during capture");
      }
      result.attempted += 1;

      if (!preparationNotified) {
        preparationNotified = true;
        await notify(
          "info",
          resumed
            ? "Preparing automatic commits for resumed work..."
            : "Preparing automatic commits...",
        );
      }
      history ??= loadHistory(sessionID);

      const temporary = await prepareTemporaryWorktree(repository, snapshot);
      worker.temporaryWorktree = { directory: temporary, repository };
      try {
        const child = await client.session.create({
          body: {
            parentID: sessionID,
            title: AUTO_COMMIT_SESSION_TITLE,
          },
          query: { directory: temporary },
        });
        if (!child.data) throw new Error("failed to create the auto-commit session");
        worker.child = { directory: temporary, id: child.data.id };

        const snapshotContext = renderSnapshotContext(snapshot);
        const prompt = await withTimeout(
          client.session.prompt({
            body: {
              agent: AGENT,
              parts: [
                {
                  type: "text",
                  text: [
                    `Create atomic commits for repository ${JSON.stringify(repositoryName)} from the changes in the parent thread that are present in this detached worktree.`,
                    "Do not ask questions. Leave ambiguous or unrelated changes uncommitted.",
                    snapshotContext,
                    await history,
                  ]
                    .filter(Boolean)
                    .join("\n\n"),
                },
              ],
            },
            path: { id: child.data.id },
            query: { directory: temporary },
          }),
          SESSION_TIMEOUT_MS,
          "the auto-commit session",
        );
        if (!prompt.data) throw new Error("the auto-commit agent did not complete");
        if (!(await shouldContinue())) {
          throw new AutoCommitSkipped("the parent session resumed", false);
        }

        await validatePreparedWorktree(temporary, snapshot);
        const commits = await validatePreparedCommits(temporary, snapshot);
        if (commits.length === 0) {
          await log(
            "info",
            `No attributable changes to commit in ${repositoryName} for session ${sessionID}`,
          );
          return result;
        }

        const created = await replayPreparedCommits(repository, snapshot, commits, shouldContinue);
        result.created.push(
          ...created.map(({ hash, subject }) => ({ hash, repository: repositoryName, subject })),
        );
        await log(
          "info",
          `Created ${created.length} automatic commit(s) in ${repositoryName} for session ${sessionID}`,
        );
        return result;
      } finally {
        const child = worker.child;
        if (child?.directory === temporary) {
          await withTimeout(
            client.session.delete({
              path: { id: child.id },
              query: { directory: child.directory },
            }),
            SHUTDOWN_TIMEOUT_MS,
            "deleting the auto-commit session",
          ).catch(() => undefined);
          worker.child = undefined;
        }
        await removeTemporaryWorktree(repository, temporary).catch(async (error) => {
          const message = error instanceof Error ? error.message : String(error);
          await log("warn", `Failed to clean temporary worktree for ${repositoryName}: ${message}`);
        });
        if (worker.temporaryWorktree?.directory === temporary) {
          worker.temporaryWorktree = undefined;
        }
      }
    };

    try {
      const session = await client.session.get({ path: { id: sessionID } });
      if (!session.data || session.data.parentID || worker.cancelled || disposed) return;
      const result: RepositoryTreeResult = { attempted: 0, created: [], skipped: [] };
      const roots = await repositoryRoots(true);
      if (worker.cancelled || disposed) return;
      for (const root of roots) {
        if (worker.cancelled || disposed) return;
        if (root.issue) {
          result.skipped.push(`${root.name}: ${root.issue}`);
          await log("warn", `Skipped automatic commits in ${root.name}: ${root.issue}`);
          continue;
        }
        try {
          await recoverIntegrationTree(root.directory);
          const repositoryTree = await inspectRepositoryTree(root.directory, root.name);
          mergeResult(result, await processRepositoryTree(repositoryTree, true));
        } catch (error) {
          if (
            gitProject ||
            retryPending ||
            (error instanceof AutoCommitSkipped && !error.visible)
          ) {
            throw error;
          }
          const message = error instanceof Error ? error.message : String(error);
          result.skipped.push(`${root.name}: ${message}`);
          await log("warn", `Skipped automatic commits in ${root.name}: ${message}`);
        }
      }
      if (mutationGenerations.get(sessionID) === mutationGeneration) {
        mutationGenerations.delete(sessionID);
      }

      if (result.skipped.length > 0) {
        await notify("warning", `Skipped:\n${result.skipped.join("\n")}`);
      }
      if (result.created.length > 0) {
        await notify(
          "success",
          result.created
            .map(({ hash, repository, subject }) => `${repository}: ${hash.slice(0, 7)} ${subject}`)
            .join("\n"),
        );
      } else if (result.attempted > 0) {
        await notify("warning", "No attributable changes were committed");
      }
    } catch (error) {
      if (worker.cancelled || disposed) return;
      const message = error instanceof Error ? error.message : String(error);
      if (error instanceof AutoCommitSkipped) {
        if (
          error.message === "there are no changes to commit" &&
          mutationGenerations.get(sessionID) === mutationGeneration
        ) {
          mutationGenerations.delete(sessionID);
        }
        await log("info", `Auto commit deferred for session ${sessionID}: ${message}`);
        if (error.visible) await notify("warning", `Deferred: ${message}`);
      } else {
        await log("error", `Auto commit failed for session ${sessionID}: ${message}`);
        await notify("error", message);
      }
    } finally {
      if (worker.child) {
        await withTimeout(
          client.session.delete({
            path: { id: worker.child.id },
            query: { directory: worker.child.directory },
          }),
          SHUTDOWN_TIMEOUT_MS,
          "deleting the auto-commit session",
        ).catch(() => undefined);
      }
      if (worker.temporaryWorktree) {
        await removeTemporaryWorktree(
          worker.temporaryWorktree.repository,
          worker.temporaryWorktree.directory,
        ).catch(async (error) => {
          const message = error instanceof Error ? error.message : String(error);
          await log("warn", `Failed to clean temporary worktree: ${message}`);
        });
      }
      workers.delete(sessionID);
      const pendingGeneration = mutationGenerations.get(sessionID);
      const newerMutation =
        pendingGeneration !== undefined && pendingGeneration !== mutationGeneration;
      if ((worker.rerun || retryPending || newerMutation) && !disposed) {
        schedule(sessionID, COMPLETION_DELAY_MS);
      }
    }
  };

  const schedule = (sessionID: string, delay = IDLE_DELAY_MS) => {
    if (workers.has(sessionID)) return;
    const existing = timers.get(sessionID);
    if (existing) clearTimeout(existing);
    timers.set(
      sessionID,
      setTimeout(() => {
        void (async () => {
          timers.delete(sessionID);
          if (disposed) return;
          if (!(await sessionIsIdle(sessionID))) {
            if (mutationGenerations.has(sessionID)) {
              schedule(sessionID, COMPLETION_DELAY_MS);
            }
            return;
          }
          const existingWorker = workers.get(sessionID);
          if (existingWorker) return;
          const worker: Worker = { cancelled: false, rerun: false };
          workers.set(sessionID, worker);
          worker.promise = runWorker(sessionID, worker).catch(async (error) => {
            const message = error instanceof Error ? error.message : String(error);
            await log("error", `Auto-commit worker cleanup failed: ${message}`);
          });
        })().catch(async (error) => {
          const message = error instanceof Error ? error.message : String(error);
          await log("error", `Auto-commit scheduling failed: ${message}`);
          if (!mutationGenerations.has(sessionID) || disposed) return;
          const failures = (statusFailures.get(sessionID) ?? 0) + 1;
          statusFailures.set(sessionID, failures);
          if (failures > MAX_STATUS_RETRIES) {
            await notify("warning", "Deferred: unable to read the session status");
            return;
          }
          schedule(sessionID, Math.min(COMPLETION_DELAY_MS * 2 ** failures, 10_000));
        });
      }, delay),
    );
  };

  const markMutation = (sessionID: string) => {
    mutationSequence += 1;
    mutationGenerations.set(sessionID, mutationSequence);
  };

  return {
    "chat.message": async ({ sessionID }, { parts }) => {
      const manual = parts.some(
        (part) => part.type === "text" && part.synthetic && part.text === AUTO_COMMIT_TRIGGER,
      );
      if (manual) {
        markMutation(sessionID);
        schedule(sessionID);
        return;
      }

      const dirty = await someConcurrent(
        await repositoryRoots().catch(() => []),
        MAX_CONCURRENT_ROOT_STATUS,
        async (root) =>
          Boolean(
            await gitOutput(root.directory, ["status", "--porcelain=v1"], {
              timeoutMs: ROOT_STATUS_TIMEOUT_MS,
            }).catch(() => ""),
          ),
      );
      if (dirty) {
        markMutation(sessionID);
        resumedSessions.add(sessionID);
      }
    },
    "tool.execute.after": async ({ sessionID, tool }) => {
      const name = tool.split(".").at(-1) ?? tool;
      if (MUTATION_TOOLS.has(name)) markMutation(sessionID);
    },
    "experimental.text.complete": async ({ sessionID }) => {
      if (!mutationGenerations.has(sessionID)) return;
      const worker = workers.get(sessionID);
      if (worker) {
        worker.rerun = true;
        return;
      }
      schedule(sessionID, COMPLETION_DELAY_MS);
    },
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        const { sessionID } = event.properties;
        busySessions.delete(sessionID);
        schedule(sessionID);
        return;
      }
      if (event.type !== "session.status") return;
      const { sessionID, status } = event.properties;
      if (status.type === "idle") {
        busySessions.delete(sessionID);
        schedule(sessionID);
        return;
      }

      busySessions.add(sessionID);
      const timer = timers.get(sessionID);
      if (timer) clearTimeout(timer);
      timers.delete(sessionID);
      const worker = workers.get(sessionID);
      if (!worker) {
        if (mutationGenerations.has(sessionID)) schedule(sessionID, COMPLETION_DELAY_MS);
        return;
      }
      worker.cancelled = true;
      worker.rerun = true;
      if (worker.child) {
        await withTimeout(
          client.session.abort({
            path: { id: worker.child.id },
            query: { directory: worker.child.directory },
          }),
          SHUTDOWN_TIMEOUT_MS,
          "aborting the auto-commit session",
        ).catch(() => undefined);
      }
    },
    dispose: async () => {
      disposed = true;
      discoveryController.abort();
      for (const timer of timers.values()) clearTimeout(timer);
      timers.clear();
      for (const worker of workers.values()) {
        worker.cancelled = true;
        if (worker.child) {
          await withTimeout(
            client.session.abort({
              path: { id: worker.child.id },
              query: { directory: worker.child.directory },
            }),
            SHUTDOWN_TIMEOUT_MS,
            "aborting the auto-commit session",
          ).catch(() => undefined);
        }
      }
      await withTimeout(
        Promise.allSettled(
          [...workers.values()].flatMap((worker) => (worker.promise ? [worker.promise] : [])),
        ),
        SHUTDOWN_TIMEOUT_MS,
        "stopping auto-commit workers",
      ).catch(() => undefined);
    },
  };
}) satisfies Plugin;

export default {
  id: "auto-commit",
  server: autoCommitPlugin,
} satisfies PluginModule;
