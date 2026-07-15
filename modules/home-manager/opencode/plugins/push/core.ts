import { spawn } from "node:child_process";
import type { GitRepository } from "../git-status/core";

const MAX_OUTPUT_BYTES = 1024 * 1024;
const INSPECTION_TIMEOUT_MS = 10_000;
const PUSH_TIMEOUT_MS = 120_000;

export type GitResult = {
  code: number | null;
  error?: string;
  stderr: string;
  stdout: string;
};

export type GitRunner = (
  cwd: string,
  args: string[],
  timeoutMs: number,
  signal?: AbortSignal,
) => Promise<GitResult>;

export type PushOutcome =
  | {
      type: "pushed";
      branch: string;
      output: string;
      upstream: string;
    }
  | {
      type: "skipped";
      reason: string;
    }
  | {
      type: "fallback";
      reason: string;
    };

export type RepositoryPushOutcome = {
  outcome: PushOutcome;
  repository: GitRepository;
};

function output(result: GitResult) {
  return [result.stdout.trim(), result.stderr.trim()].filter(Boolean).join("\n");
}

export function createGitRunner(binary = "git"): GitRunner {
  return (cwd, args, timeoutMs, signal) =>
    new Promise((resolve) => {
      const child = spawn(binary, args, {
        cwd,
        detached: process.platform !== "win32",
        env: { ...process.env, GIT_TERMINAL_PROMPT: "0" },
        stdio: ["ignore", "pipe", "pipe"],
      });
      const stdout: Buffer[] = [];
      const stderr: Buffer[] = [];
      let outputBytes = 0;
      let problem: string | undefined;
      let settled = false;
      let killTimeout: NodeJS.Timeout | undefined;

      const kill = (signal: NodeJS.Signals) => {
        if (child.pid && process.platform !== "win32") {
          try {
            process.kill(-child.pid, signal);
            return;
          } catch {
            // The process group may have exited before its direct child.
          }
        }
        child.kill(signal);
      };
      const finish = (result: GitResult) => {
        if (settled) return;
        settled = true;
        clearTimeout(timeout);
        if (killTimeout) clearTimeout(killTimeout);
        signal?.removeEventListener("abort", abort);
        resolve(result);
      };
      const collect = (chunks: Buffer[], chunk: Buffer) => {
        outputBytes += chunk.length;
        if (outputBytes > MAX_OUTPUT_BYTES) {
          problem = "git output exceeded 1 MiB";
          kill("SIGKILL");
          return;
        }
        chunks.push(chunk);
      };
      const stop = (message: string) => {
        if (settled) return;
        problem = message;
        kill("SIGTERM");
        killTimeout = setTimeout(() => kill("SIGKILL"), 5000);
      };
      const abort = () => stop(`git ${args[0] ?? "command"} was cancelled`);
      const timeout = setTimeout(
        () => stop(`git ${args[0] ?? "command"} timed out after ${timeoutMs} ms`),
        timeoutMs,
      );

      child.stdout.on("data", (chunk: Buffer) => collect(stdout, chunk));
      child.stderr.on("data", (chunk: Buffer) => collect(stderr, chunk));
      child.on("error", (error: NodeJS.ErrnoException) => {
        finish({ code: null, error: error.message, stderr: "", stdout: "" });
      });
      child.on("close", (code) => {
        finish({
          code,
          ...(problem ? { error: problem } : {}),
          stderr: Buffer.concat(stderr).toString(),
          stdout: Buffer.concat(stdout).toString(),
        });
      });
      if (signal?.aborted) abort();
      else signal?.addEventListener("abort", abort, { once: true });
    });
}

export async function attemptPush(
  cwd: string,
  runGit: GitRunner,
  signal?: AbortSignal,
  options: { skipDetached?: boolean; verifySubmodules?: boolean } = {},
): Promise<PushOutcome> {
  const branchResult = await runGit(
    cwd,
    ["symbolic-ref", "--quiet", "--short", "HEAD"],
    INSPECTION_TIMEOUT_MS,
    signal,
  );
  const branch = branchResult.code === 0 ? branchResult.stdout.trim() : undefined;
  if (!branch) {
    if (options.skipDetached && branchResult.code === 1 && !branchResult.error) {
      return {
        type: "skipped",
        reason: "detached submodule; its superproject push will verify the commit",
      };
    }
    return { type: "fallback", reason: "the current branch could not be determined" };
  }

  const [status, upstreamResult, recentCommits] = await Promise.all([
    runGit(cwd, ["status", "--short", "--branch"], INSPECTION_TIMEOUT_MS, signal),
    runGit(
      cwd,
      [
        "for-each-ref",
        "--format=%(upstream:short)%00%(upstream:remotename)%00%(upstream:remoteref)",
        "--",
        `refs/heads/${branch}`,
      ],
      INSPECTION_TIMEOUT_MS,
      signal,
    ),
    runGit(cwd, ["log", "--oneline", "-10"], INSPECTION_TIMEOUT_MS, signal),
  ]);
  const inspectionFailure = [status, recentCommits].find((result) => result.code !== 0);
  if (inspectionFailure) {
    return { type: "fallback", reason: "Git inspection failed" };
  }

  const [upstream, remote, remoteRef] = upstreamResult.stdout.trimEnd().split("\0");
  if (
    upstreamResult.code !== 0 ||
    !upstream ||
    !remote ||
    remote === "." ||
    !/^[A-Za-z0-9][A-Za-z0-9._/-]*$/.test(remote) ||
    !remoteRef?.startsWith("refs/heads/")
  ) {
    return { type: "fallback", reason: "the current branch has no supported configured upstream" };
  }

  const pushed = await runGit(
    cwd,
    [
      "-c",
      `remote.${remote}.mirror=false`,
      "push",
      "--no-force",
      "--no-force-with-lease",
      "--no-force-if-includes",
      "--no-mirror",
      "--no-follow-tags",
      options.verifySubmodules ? "--recurse-submodules=check" : "--no-recurse-submodules",
      "--porcelain",
      "--",
      remote,
      `HEAD:${remoteRef}`,
    ],
    PUSH_TIMEOUT_MS,
    signal,
  );
  if (pushed.code !== 0 || pushed.error) {
    return { type: "fallback", reason: "the direct push failed" };
  }

  return { type: "pushed", branch, output: output(pushed), upstream };
}

function repositoriesInPushOrder(repositories: GitRepository[]) {
  const repositoriesByGitDirectory = new Map(
    repositories.map((repository) => [repository.gitDirectory, repository]),
  );
  const children = new Map<string, GitRepository[]>();
  const roots: GitRepository[] = [];

  for (const repository of repositories) {
    if (repository.parent && repositoriesByGitDirectory.has(repository.parent)) {
      const siblings = children.get(repository.parent) ?? [];
      siblings.push(repository);
      children.set(repository.parent, siblings);
    } else {
      roots.push(repository);
    }
  }

  const ordered: GitRepository[] = [];
  const visited = new Set<string>();
  const append = (repository: GitRepository) => {
    if (visited.has(repository.gitDirectory)) return;
    visited.add(repository.gitDirectory);
    for (const child of children.get(repository.gitDirectory) ?? []) append(child);
    ordered.push(repository);
  };
  for (const repository of roots) append(repository);
  for (const repository of repositories) append(repository);
  return ordered;
}

export async function attemptRepositoryPushes(
  repositories: GitRepository[],
  runGit: GitRunner,
  signal?: AbortSignal,
): Promise<{ cancelled: boolean; outcomes: RepositoryPushOutcome[] }> {
  const blocked = new Set<string>();
  const repositoriesByGitDirectory = new Map(
    repositories.map((repository) => [repository.gitDirectory, repository]),
  );
  const superprojects = new Set(
    repositories.flatMap((repository) => (repository.parent ? [repository.parent] : [])),
  );
  const outcomes: RepositoryPushOutcome[] = [];

  for (const repository of repositoriesInPushOrder(repositories)) {
    if (signal?.aborted) return { cancelled: true, outcomes };
    const outcome = blocked.has(repository.gitDirectory)
      ? ({
          type: "fallback",
          reason: "a submodule requires agent intervention",
        } satisfies PushOutcome)
      : await attemptPush(repository.directory, runGit, signal, {
          skipDetached: repository.submodule,
          verifySubmodules: superprojects.has(repository.gitDirectory),
        });
    outcomes.push({ outcome, repository });
    if (signal?.aborted) return { cancelled: true, outcomes };
    if (outcome.type !== "fallback") continue;

    let parent = repository.parent;
    const visited = new Set<string>();
    while (parent && !visited.has(parent)) {
      visited.add(parent);
      blocked.add(parent);
      parent = repositoriesByGitDirectory.get(parent)?.parent;
    }
  }

  return { cancelled: false, outcomes };
}

function promptJson(value: string) {
  return JSON.stringify(value)
    .replaceAll("<", "\\u003c")
    .replaceAll(">", "\\u003e")
    .replaceAll("&", "\\u0026");
}

export function renderFallbackPrompt(
  outcomes: Array<RepositoryPushOutcome & { outcome: Extract<PushOutcome, { type: "fallback" }> }>,
) {
  const repositories = outcomes
    .map(
      ({ outcome, repository }, index) =>
        `${index + 1}. ${promptJson(repository.label)} at ${promptJson(repository.directory)}: ${outcome.reason}`,
    )
    .join("\n");

  return `Push the affected Git repositories to their configured upstreams in the listed order. Submodules are listed before their superprojects.

<affected_repositories>
${repositories}
</affected_repositories>

1. Work through every listed repository in order. Inspect its current branch, status, configured upstream, and recent commits again where needed.
2. Resolve the current branch's configured upstream remote and \`refs/heads/...\` destination. If the fast-path failure warrants another push attempt, substitute those values into \`git -c remote.<remote>.mirror=false push --no-force --no-force-with-lease --no-force-if-includes --no-mirror --no-follow-tags --no-recurse-submodules -- <remote> HEAD:<upstream-ref>\`. For a superproject, replace \`--no-recurse-submodules\` with \`--recurse-submodules=check\` so Git verifies that referenced submodule commits are available remotely without pushing them recursively. Never use a bare \`git push\` or a plus-prefixed refspec.
3. If the push was rejected because the remote branch has commits that are not local, fetch the upstream and rebase the current branch onto it. Do not merge.
4. If the rebase has conflicts, inspect each conflict and the relevant surrounding changes, resolve it while preserving both sides' intent, stage the resolved files, and continue the rebase. Repeat until the rebase completes.
5. If rebasing a submodule changes its HEAD, inspect each affected superproject before pushing it. When its committed gitlink still names the pre-rebase commit, stage only that gitlink and create a narrow Conventional Commit with \`git -c core.hooksPath=/dev/null commit\`. Do not alter a gitlink that was already changed for another reason.
6. Run relevant lightweight checks when conflict resolution changed files, then retry with the same explicit non-force remote, refspec, and disabled behaviors from step 2.

Never use \`--force\`, \`--force-with-lease\`, destructive reset commands, or discard unrelated working-tree changes. Use \`--autostash\` when a rebase is blocked by pre-existing tracked changes. If the upstream is missing or checks fail after resolution, report the blocker instead of guessing or pushing broken changes. If a conflict cannot be resolved confidently, abort the rebase before reporting the blocker.`;
}

export const gitTimeouts = {
  inspection: INSPECTION_TIMEOUT_MS,
  push: PUSH_TIMEOUT_MS,
};
