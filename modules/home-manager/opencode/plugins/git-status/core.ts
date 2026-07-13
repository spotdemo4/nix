import { execFile } from "node:child_process";
import { readdir, stat } from "node:fs/promises";
import { basename, isAbsolute, relative, resolve, sep } from "node:path";

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
  signal?: AbortSignal;
  timeoutMs?: number;
};

export type GitRepository = {
  depth: number;
  directory: string;
  gitDirectory: string;
  label: string;
  parent?: string;
  primary: boolean;
  submodule: boolean;
};

export type RepositoryDiscoveryOptions = GitCommandOptions & {
  scanExclusions?: {
    add?: string[];
    remove?: string[];
  };
};

const DEFAULT_TIMEOUT_MS = 15_000;
const DEFAULT_GIT_OUTPUT_BYTES = 16 * 1024 * 1024;
const DISCOVERY_GIT_OUTPUT_BYTES = 64 * 1024 * 1024;
const DEFAULT_SCAN_EXCLUSIONS = [
  ".cache",
  ".direnv",
  ".next",
  ".turbo",
  ".venv",
  "build",
  "dist",
  "node_modules",
  "target",
];

class GitCommandError extends Error {
  constructor(
    message: string,
    readonly stderr: string,
  ) {
    super(message);
  }
}

type RunGitOptions = GitCommandOptions & {
  maxBufferBytes?: number;
};

function runGit(
  directory: string,
  args: string[],
  {
    gitBinary = "git",
    maxBufferBytes = DEFAULT_GIT_OUTPUT_BYTES,
    signal,
    timeoutMs = DEFAULT_TIMEOUT_MS,
  }: RunGitOptions = {},
) {
  return new Promise<string>((resolve, reject) => {
    execFile(
      gitBinary,
      args,
      {
        cwd: directory,
        encoding: "utf8",
        env: { ...process.env, GIT_TERMINAL_PROMPT: "0", LC_ALL: "C" },
        maxBuffer: maxBufferBytes,
        signal,
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

function isMissingPath(error: unknown) {
  const code = (error as NodeJS.ErrnoException | undefined)?.code;
  return code === "ENOENT" || code === "ENOTDIR";
}

function withoutTrailingNewline(output: string) {
  return output.endsWith("\n") ? output.slice(0, -1) : output;
}

function pathIsWithin(root: string, path: string) {
  const fromRoot = relative(root, path);
  return fromRoot === "" || (!isAbsolute(fromRoot) && fromRoot !== ".." && !fromRoot.startsWith(`..${sep}`));
}

function displayPath(value: string) {
  return value.replace(/[\x00-\x1f\x7f]/g, (character) => {
    return `\\x${character.charCodeAt(0).toString(16).padStart(2, "0")}`;
  });
}

type RepositoryIdentity = {
  directory: string;
  gitDirectory: string;
};

async function repositoryIdentity(
  directory: string,
  options: GitCommandOptions,
): Promise<RepositoryIdentity | undefined> {
  try {
    const [topLevel, gitDirectory] = await Promise.all([
      runGit(directory, ["rev-parse", "--show-toplevel"], options),
      runGit(directory, ["rev-parse", "--absolute-git-dir"], options),
    ]);
    return {
      directory: resolve(withoutTrailingNewline(topLevel)),
      gitDirectory: resolve(withoutTrailingNewline(gitDirectory)),
    };
  } catch (error) {
    if (isNotRepository(error)) return undefined;
    throw error;
  }
}

async function findRepositoryCandidates(
  root: string,
  excluded: Set<string>,
  signal?: AbortSignal,
) {
  const candidates = new Set<string>([root]);
  const pending = [root];

  while (pending.length > 0) {
    signal?.throwIfAborted();
    const directory = pending.pop();
    if (!directory) continue;

    let entries;
    try {
      entries = await readdir(directory, { withFileTypes: true });
    } catch (error) {
      if (directory === root || !isMissingPath(error)) throw error;
      continue;
    }

    if (entries.some((entry) => entry.name === ".git")) candidates.add(directory);
    for (const entry of entries) {
      if (!entry.isDirectory() || entry.name === ".git" || excluded.has(entry.name)) continue;
      pending.push(resolve(directory, entry.name));
    }
  }

  return [...candidates].sort((left, right) => left.length - right.length || left.localeCompare(right));
}

async function listInitializedSubmodules(
  repository: RepositoryIdentity,
  options: GitCommandOptions,
) {
  const entries = (
    await runGit(repository.directory, ["ls-files", "--stage", "-z"], {
      ...options,
      maxBufferBytes: DISCOVERY_GIT_OUTPUT_BYTES,
    })
  ).split("\0");
  const submodules: RepositoryIdentity[] = [];
  const paths = new Set<string>();

  for (const entry of entries) {
    options.signal?.throwIfAborted();
    const match = /^160000 [0-9a-f]+ [0-3]\t([\s\S]+)$/.exec(entry);
    if (!match || paths.has(match[1])) continue;

    const path = match[1];
    paths.add(path);
    const directory = resolve(repository.directory, path);
    if (!pathIsWithin(repository.directory, directory)) continue;

    try {
      if (!(await stat(directory)).isDirectory()) continue;
    } catch (error) {
      if (!isMissingPath(error)) throw error;
      continue;
    }
    const identity = await repositoryIdentity(directory, options);
    if (!identity || identity.directory !== directory) continue;
    const superproject = await runGit(
      directory,
      ["rev-parse", "--show-superproject-working-tree"],
      options,
    );

    if (
      resolve(withoutTrailingNewline(superproject)) !== repository.directory
    ) {
      continue;
    }
    submodules.push(identity);
  }

  return submodules;
}

function repositoryLabel(workspace: string, directory: string) {
  const fromWorkspace = relative(workspace, directory);
  if (fromWorkspace === "") return displayPath(basename(directory));
  if (isAbsolute(fromWorkspace) || fromWorkspace === ".." || fromWorkspace.startsWith(`..${sep}`)) {
    return displayPath(basename(directory));
  }
  return displayPath(fromWorkspace);
}

export async function discoverGitRepositories(
  workspace: string,
  options: RepositoryDiscoveryOptions = {},
): Promise<GitRepository[]> {
  options.signal?.throwIfAborted();
  const root = resolve(workspace);
  const excluded = new Set(DEFAULT_SCAN_EXCLUSIONS);
  for (const name of options.scanExclusions?.remove ?? []) excluded.delete(name);
  for (const name of options.scanExclusions?.add ?? []) excluded.add(name);

  const identities = new Map<string, RepositoryIdentity>();
  const discoveryErrors: unknown[] = [];
  for (const candidate of await findRepositoryCandidates(root, excluded, options.signal)) {
    options.signal?.throwIfAborted();
    try {
      const identity = await repositoryIdentity(candidate, options);
      if (identity) identities.set(identity.gitDirectory, identity);
    } catch (error) {
      discoveryErrors.push(error);
    }
  }
  if (discoveryErrors.length > 0) throw discoveryErrors[0];

  const parents = new Map<string, string>();
  const inspected = new Set<string>();
  const inspectSubmodules = async (repository: RepositoryIdentity): Promise<void> => {
    options.signal?.throwIfAborted();
    if (inspected.has(repository.gitDirectory)) return;
    inspected.add(repository.gitDirectory);

    const submodules = await listInitializedSubmodules(repository, options);
    for (const submodule of submodules) {
      identities.set(submodule.gitDirectory, submodule);
      parents.set(submodule.gitDirectory, repository.gitDirectory);
      await inspectSubmodules(submodule);
    }
  };

  for (const identity of [...identities.values()].sort(
    (left, right) => left.directory.length - right.directory.length,
  )) {
    await inspectSubmodules(identity);
  }

  const depth = (gitDirectory: string) => {
    let result = 0;
    let current = parents.get(gitDirectory);
    const visited = new Set<string>();
    while (current && !visited.has(current)) {
      visited.add(current);
      result += 1;
      current = parents.get(current);
    }
    return result;
  };
  const repositories = [...identities.values()].map((identity): GitRepository => {
    const parent = parents.get(identity.gitDirectory);
    return {
      depth: depth(identity.gitDirectory),
      directory: identity.directory,
      gitDirectory: identity.gitDirectory,
      label: repositoryLabel(root, identity.directory),
      ...(parent ? { parent } : {}),
      primary: pathIsWithin(identity.directory, root),
      submodule: parent !== undefined,
    };
  });

  const byParent = new Map<string | undefined, GitRepository[]>();
  for (const repository of repositories) {
    const siblings = byParent.get(repository.parent) ?? [];
    siblings.push(repository);
    byParent.set(repository.parent, siblings);
  }
  for (const siblings of byParent.values()) {
    siblings.sort((left, right) => {
      if (left.primary !== right.primary) return left.primary ? -1 : 1;
      return left.label.localeCompare(right.label);
    });
  }

  const sorted: GitRepository[] = [];
  const append = (repository: GitRepository) => {
    sorted.push(repository);
    for (const child of byParent.get(repository.gitDirectory) ?? []) append(child);
  };
  for (const repository of byParent.get(undefined) ?? []) append(repository);
  return sorted;
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
        "-c",
        "core.fsmonitor=false",
        "status",
        "--porcelain=v2",
        "--branch",
        "--untracked-files=normal",
        "--ignore-submodules=dirty",
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
    await runGit(
      directory,
      ["fetch", "--quiet", "--no-write-fetch-head", "--no-recurse-submodules"],
      options,
    );
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
