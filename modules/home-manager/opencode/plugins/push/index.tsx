/** @jsxImportSource @opentui/solid */
import type { PluginOptions } from "@opencode-ai/plugin";
import type { TuiPlugin, TuiPluginApi, TuiPluginModule } from "@opencode-ai/plugin/tui";
import { isAbsolute, relative, resolve, sep } from "node:path";
import { createSignal, onCleanup, Show } from "solid-js";
import {
  discoverGitRepositories,
  selectGitWorkspace,
  type GitRepository,
  type RepositoryDiscoveryOptions,
} from "../git-status/core";
import {
  attemptRepositoryPushes,
  createGitRunner,
  renderFallbackPrompt,
  type GitRunner,
  type RepositoryPushOutcome,
} from "./core";

const PLUGIN_ID = "push";
const REPOSITORY_CACHE_TTL_MS = 30_000;

type RepositoryDiscoverer = (
  workspace: string,
  options: RepositoryDiscoveryOptions,
) => ReturnType<typeof discoverGitRepositories>;

function pathIsInside(root: string, path: string) {
  const fromRoot = relative(root, resolve(root, path));
  return (
    fromRoot === "" ||
    (fromRoot !== ".." && !fromRoot.startsWith(`..${sep}`) && !isAbsolute(fromRoot))
  );
}

export class PushStatusClient {
  private disposed = false;
  private readonly listeners = new Set<() => void>();
  private readonly running = new Map<string, { controller: AbortController; directory: string }>();

  subscribe(listener: () => void) {
    this.listeners.add(listener);
    listener();
    return () => this.listeners.delete(listener);
  }

  isRunning(sessionID: string) {
    return this.running.has(sessionID);
  }

  start(sessionID: string, directory: string) {
    if (this.disposed || this.running.has(sessionID)) return false;
    this.running.set(sessionID, { controller: new AbortController(), directory });
    this.emit();
    return true;
  }

  signal(sessionID: string) {
    return this.running.get(sessionID)?.controller.signal;
  }

  cancelFile(path: string) {
    for (const active of this.running.values()) {
      if (pathIsInside(active.directory, path)) active.controller.abort();
    }
  }

  cancelAll() {
    for (const active of this.running.values()) active.controller.abort();
  }

  isDisposed() {
    return this.disposed;
  }

  finish(sessionID: string) {
    if (!this.running.delete(sessionID)) return;
    this.emit();
  }

  dispose() {
    this.disposed = true;
    this.cancelAll();
    this.running.clear();
    this.listeners.clear();
  }

  private emit() {
    for (const listener of this.listeners) listener();
  }
}

function View(props: { api: TuiPluginApi; client: PushStatusClient; sessionID: string }) {
  const [running, setRunning] = createSignal(false);
  const unsubscribe = props.client.subscribe(() => {
    setRunning(props.client.isRunning(props.sessionID));
  });
  const theme = () => props.api.theme.current;
  onCleanup(unsubscribe);

  return (
    <Show when={running()}>
      <text>
        <span style={{ fg: theme().textMuted }}>Push </span>
        <span style={{ fg: theme().info }}>Pushing...</span>
      </text>
    </Show>
  );
}

function isUpToDate(result: RepositoryPushOutcome) {
  return result.outcome.type === "pushed" && result.outcome.output.includes("[up to date]");
}

function renderSuccess(results: RepositoryPushOutcome[]) {
  const skipped = results.filter((result) => result.outcome.type === "skipped");
  if (results.every((result) => isUpToDate(result) || result.outcome.type === "skipped")) {
    if (skipped.length > 0) {
      return [
        "Everything up-to-date",
        ...skipped.map(({ outcome, repository }) =>
          outcome.type === "skipped"
            ? `${repository.label}: skipped (${outcome.reason})`
            : `${repository.label}: up-to-date`,
        ),
      ].join("\n");
    }
    return results.length === 1
      ? "Everything up-to-date"
      : `Everything up-to-date in ${results.length} repositories`;
  }
  if (results.length === 1) {
    const result = results[0];
    if (result.outcome.type !== "pushed") return "Push did not complete";
    return `Pushed ${result.outcome.branch} to ${result.outcome.upstream}`;
  }

  return [
    "Push results:",
    ...results.map((result) => {
      if (result.outcome.type === "skipped") {
        return `${result.repository.label}: skipped (${result.outcome.reason})`;
      }
      if (result.outcome.type !== "pushed") return `${result.repository.label}: incomplete`;
      return isUpToDate(result)
        ? `${result.repository.label}: up-to-date`
        : `${result.repository.label}: ${result.outcome.branch} -> ${result.outcome.upstream}`;
    }),
  ].join("\n");
}

function renderHandoff(results: RepositoryPushOutcome[]) {
  const fallback = results.filter(
    (
      result,
    ): result is RepositoryPushOutcome & {
      outcome: Extract<RepositoryPushOutcome["outcome"], { type: "fallback" }>;
    } => result.outcome.type === "fallback",
  );
  if (results.length === 1 && fallback.length === 1) {
    return `${fallback[0].outcome.reason}; handed off to the build agent`;
  }

  const direct = results.filter((result) => result.outcome.type === "pushed");
  const skipped = results.filter((result) => result.outcome.type === "skipped");
  return [
    ...(direct.length > 0
      ? [
          `${direct.length} ${direct.length === 1 ? "repository" : "repositories"} completed directly.`,
        ]
      : []),
    ...skipped.map(({ outcome, repository }) =>
      outcome.type === "skipped"
        ? `${repository.label}: skipped (${outcome.reason})`
        : `${repository.label}: skipped`,
    ),
    "Handed off to the build agent:",
    ...fallback.map(({ outcome, repository }) => `${repository.label}: ${outcome.reason}`),
  ].join("\n");
}

function renderCancellation(results: RepositoryPushOutcome[]) {
  const completed = results.filter((result) => result.outcome.type === "pushed");
  if (completed.length === 0) return "Push cancelled because workspace files changed";
  return [
    "Push cancelled because workspace files changed",
    "Completed before cancellation:",
    ...completed.map(({ outcome, repository }) =>
      outcome.type === "pushed"
        ? `${repository.label}: ${outcome.branch} -> ${outcome.upstream}`
        : repository.label,
    ),
  ].join("\n");
}

export async function registerPushPlugin(
  api: TuiPluginApi,
  options?: PluginOptions,
  runner?: GitRunner,
  discover: RepositoryDiscoverer = discoverGitRepositories,
) {
  const binary = typeof options?.gitBinary === "string" ? options.gitBinary : "git";
  const runGit = runner ?? createGitRunner(binary);
  const client = new PushStatusClient();
  const workspace = selectGitWorkspace(api.state.path.directory, api.state.path.worktree);
  let repositoryCache: { expires: number; repositories: GitRepository[] } | undefined;

  const unregister = [
    api.keymap.registerLayer({
      commands: [
        {
          category: "VCS",
          desc: "Push workspace repositories, using an agent only when Git needs intervention",
          name: "push.run",
          namespace: "palette",
          slashName: "push",
          title: "Push workspace repositories",
          async run() {
            const sessionID =
              api.route.current.name === "session" && "params" in api.route.current
                ? api.route.current.params?.sessionID
                : undefined;
            if (typeof sessionID !== "string") {
              api.ui.toast({
                title: "Push",
                message: "Open a session before pushing",
                variant: "warning",
              });
              return;
            }

            const session = api.state.session.get(sessionID);
            if (!session || session.parentID) {
              api.ui.toast({
                title: "Push",
                message: "Push can only run from a top-level session",
                variant: "warning",
              });
              return;
            }
            if (!client.start(sessionID, workspace)) {
              api.ui.toast({
                title: "Push",
                message: "A push is already running",
                variant: "warning",
              });
              return;
            }

            const signal = AbortSignal.any([api.lifecycle.signal, client.signal(sessionID)!]);
            let results: RepositoryPushOutcome[] = [];
            try {
              let repositories: GitRepository[];
              if (repositoryCache && repositoryCache.expires > Date.now()) {
                repositories = repositoryCache.repositories;
              } else {
                repositories = await discover(workspace, {
                  allowPartial: false,
                  gitBinary: binary,
                  signal,
                });
                if (!signal.aborted) {
                  repositoryCache = {
                    expires: Date.now() + REPOSITORY_CACHE_TTL_MS,
                    repositories,
                  };
                }
              }
              if (api.lifecycle.signal.aborted || client.isDisposed()) return;
              if (signal.aborted) {
                api.ui.toast({
                  title: "Push",
                  message: "Push cancelled because workspace files changed",
                  variant: "warning",
                });
                return;
              }
              if (repositories.length === 0) {
                api.ui.toast({
                  title: "Push",
                  message: "No Git repositories found in the workspace",
                  variant: "warning",
                });
                return;
              }

              const push = await attemptRepositoryPushes(repositories, runGit, signal);
              results = push.outcomes;
              if (api.lifecycle.signal.aborted || client.isDisposed()) return;
              if (push.cancelled || signal.aborted) {
                api.ui.toast({
                  title: "Push",
                  message: renderCancellation(results),
                  variant: "warning",
                });
                return;
              }
              const fallback = results.filter(
                (
                  result,
                ): result is RepositoryPushOutcome & {
                  outcome: Extract<RepositoryPushOutcome["outcome"], { type: "fallback" }>;
                } => result.outcome.type === "fallback",
              );
              if (fallback.length === 0) {
                api.ui.toast({
                  title: "Push",
                  message: renderSuccess(results),
                  variant: "success",
                });
                return;
              }

              await api.client.session.promptAsync(
                {
                  sessionID,
                  directory: session.directory,
                  agent: session.agent,
                  model: session.model
                    ? { providerID: session.model.providerID, modelID: session.model.id }
                    : undefined,
                  variant: session.model?.variant,
                  parts: [
                    {
                      type: "subtask",
                      agent: "build",
                      description: "Rebase and push workspace repositories",
                      prompt: renderFallbackPrompt(fallback),
                    },
                  ],
                },
                { signal, throwOnError: true },
              );
              if (api.lifecycle.signal.aborted || client.isDisposed()) return;
              if (signal.aborted) {
                api.ui.toast({
                  title: "Push",
                  message: renderCancellation(results),
                  variant: "warning",
                });
                return;
              }
              api.ui.toast({
                title: "Push",
                message: renderHandoff(results),
                variant: "info",
              });
            } catch (error) {
              if (api.lifecycle.signal.aborted || client.isDisposed()) return;
              if (signal.aborted) {
                api.ui.toast({
                  title: "Push",
                  message: renderCancellation(results),
                  variant: "warning",
                });
                return;
              }
              api.ui.toast({
                title: "Push",
                message: error instanceof Error ? error.message : String(error),
                variant: "error",
              });
            } finally {
              client.finish(sessionID);
            }
          },
        },
      ],
    }),
    api.event.on("file.edited", (event) => {
      repositoryCache = undefined;
      client.cancelFile(event.properties.file);
    }),
    api.event.on("file.watcher.updated", (event) => {
      repositoryCache = undefined;
      client.cancelFile(event.properties.file);
    }),
  ];

  api.lifecycle.onDispose(() => {
    for (const dispose of unregister) dispose();
    client.dispose();
  });
  api.slots.register({
    order: 45,
    slots: {
      sidebar_content(_context, props) {
        return <View api={api} client={client} sessionID={props.session_id} />;
      },
    },
  });
}

const tui: TuiPlugin = async (api, options) => registerPushPlugin(api, options);

const plugin: TuiPluginModule & { id: string } = {
  id: PLUGIN_ID,
  tui,
};

export default plugin;
