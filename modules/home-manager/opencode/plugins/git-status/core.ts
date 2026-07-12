import { execFile } from "node:child_process";

export type GitStatus = {
  ahead: number;
  behind: number;
  branch: string;
  detached: boolean;
  dirty: boolean;
  upstream?: string;
};

export type GitCommandOptions = {
  gitBinary?: string;
  timeoutMs?: number;
};

const DEFAULT_TIMEOUT_MS = 15_000;

class GitCommandError extends Error {
  constructor(
    message: string,
    readonly stderr: string,
  ) {
    super(message);
  }
}

function runGit(
  directory: string,
  args: string[],
  { gitBinary = "git", timeoutMs = DEFAULT_TIMEOUT_MS }: GitCommandOptions = {},
) {
  return new Promise<string>((resolve, reject) => {
    execFile(
      gitBinary,
      args,
      {
        cwd: directory,
        encoding: "utf8",
        env: { ...process.env, GIT_TERMINAL_PROMPT: "0", LC_ALL: "C" },
        timeout: timeoutMs,
      },
      (error, stdout, stderr) => {
        if (error) {
          reject(new GitCommandError(error.message, stderr));
          return;
        }
        resolve(stdout);
      },
    );
  });
}

function isNotRepository(error: unknown) {
  return error instanceof GitCommandError && /not a git repository/i.test(error.stderr);
}

export function parseGitStatus(output: string): GitStatus {
  let ahead = 0;
  let behind = 0;
  let branch = "unknown";
  let detached = false;
  let dirty = false;
  let upstream: string | undefined;

  for (const line of output.split("\n")) {
    if (!line) continue;
    if (!line.startsWith("# ")) {
      dirty = true;
      continue;
    }

    if (line.startsWith("# branch.head ")) {
      const value = line.slice("# branch.head ".length);
      detached = value === "(detached)";
      branch = detached ? "detached" : value;
      continue;
    }
    if (line.startsWith("# branch.upstream ")) {
      upstream = line.slice("# branch.upstream ".length);
      continue;
    }

    const divergence = /^# branch\.ab \+(\d+) -(\d+)$/.exec(line);
    if (divergence) {
      ahead = Number(divergence[1]);
      behind = Number(divergence[2]);
    }
  }

  return { ahead, behind, branch, detached, dirty, ...(upstream ? { upstream } : {}) };
}

export async function inspectGitRepository(
  directory: string,
  options: GitCommandOptions = {},
): Promise<GitStatus | undefined> {
  try {
    const output = await runGit(
      directory,
      [
        "status",
        "--porcelain=v2",
        "--branch",
        "--untracked-files=normal",
        "--ignore-submodules=none",
      ],
      options,
    );
    return parseGitStatus(output);
  } catch (error) {
    if (isNotRepository(error)) return undefined;
    throw error;
  }
}

export async function refreshGitRepository(
  directory: string,
  options: GitCommandOptions = {},
): Promise<{ status?: GitStatus; fetchFailed: boolean }> {
  const status = await inspectGitRepository(directory, options);
  if (!status?.upstream) return { status, fetchFailed: false };

  try {
    await runGit(directory, ["fetch", "--quiet", "--no-write-fetch-head"], options);
    return {
      status: (await inspectGitRepository(directory, options)) ?? status,
      fetchFailed: false,
    };
  } catch {
    return { status, fetchFailed: true };
  }
}

export function gitStatusLabel(status: GitStatus) {
  const labels: string[] = [];

  if (status.ahead > 0 && status.behind > 0) {
    labels.push(`Out of sync +${status.ahead}/-${status.behind}`);
  } else if (status.behind > 0) {
    labels.push(`Pull ${status.behind}`);
  } else if (status.ahead > 0) {
    labels.push(`Push ${status.ahead}`);
  }

  if (status.dirty) labels.push("Uncommitted");
  if (labels.length === 0) labels.push("Clean");
  if (!status.upstream && !status.detached) labels.push("No upstream");

  return labels.join(" | ");
}
