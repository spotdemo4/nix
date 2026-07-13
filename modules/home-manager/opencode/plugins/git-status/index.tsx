/** @jsxImportSource @opentui/solid */
import type {
  TuiPlugin,
  TuiPluginApi,
  TuiPluginModule,
  TuiThemeCurrent,
} from "@opencode-ai/plugin/tui";
import { createSignal, For, Match, onCleanup, Switch } from "solid-js";
import {
  discoverGitRepositories,
  gitStatusLabel,
  inspectGitRepository,
  refreshGitRepository,
  type GitRepository,
  type GitStatus,
  type RepositoryDiscoveryOptions,
} from "./core";

type PluginOptions = {
  discoveryMs?: number;
  fetchAllRepositories?: boolean;
  fetchMs?: number;
  gitBinary?: string;
  refreshMs?: number;
  scanExclusions?: {
    add?: string[];
    remove?: string[];
  };
  timeoutMs?: number;
};

type GitRepositoryState =
  | { status: "error"; repository: GitRepository }
  | { status: "ready"; repository: GitRepository; data: GitStatus; fetchFailed: boolean };

type GitStatusState =
  | { status: "loading" }
  | { status: "absent" }
  | { status: "error" }
  | { status: "ready"; repositories: GitRepositoryState[] };

const PLUGIN_ID = "trev.git-status";
const DEFAULT_REFRESH_MS = 5_000;
const DEFAULT_FETCH_MS = 60_000;
const DEFAULT_DISCOVERY_MS = 30_000;
const DEFAULT_TIMEOUT_MS = 15_000;
const MIN_REFRESH_MS = 1_000;
const MIN_FETCH_MS = 15_000;
const MIN_DISCOVERY_MS = 5_000;
const MIN_TIMEOUT_MS = 1_000;
const EVENT_DEBOUNCE_MS = 250;
const MAX_CONCURRENT_GIT_COMMANDS = 4;

function interval(value: number | undefined, fallback: number, minimum: number) {
  if (typeof value !== "number" || !Number.isFinite(value)) return fallback;
  return Math.max(minimum, Math.floor(value));
}

function statusColor(status: GitStatus, theme: TuiThemeCurrent) {
  if (status.ahead > 0 && status.behind > 0) return theme.error;
  if (status.dirty) return theme.warning;
  if (status.ahead > 0 || status.behind > 0) return theme.info;
  if (!status.upstream && !status.detached) return theme.warning;
  return theme.success;
}

async function mapConcurrent<Item, Result>(
  items: Item[],
  limit: number,
  transform: (item: Item) => Promise<Result>,
) {
  const results = new Array<Result>(items.length);
  let next = 0;
  const worker = async () => {
    while (next < items.length) {
      const index = next;
      next += 1;
      results[index] = await transform(items[index]);
    }
  };
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, () => worker()));
  return results;
}

class GitStatusClient {
  private readonly abortController = new AbortController();
  private state: GitStatusState = { status: "loading" };
  private repositories: GitRepository[] = [];
  private readonly options: RepositoryDiscoveryOptions;
  private readonly listeners = new Set<(state: GitStatusState) => void>();
  private readonly refreshTimer: ReturnType<typeof setInterval>;
  private readonly fetchTimer: ReturnType<typeof setInterval>;
  private readonly discoveryTimer: ReturnType<typeof setInterval>;
  private debounceTimer?: ReturnType<typeof setTimeout>;
  private running = false;
  private queued = false;
  private fetchQueued = false;
  private discoveryQueued = false;
  private disposed = false;

  constructor(
    private readonly workspace: string,
    options: RepositoryDiscoveryOptions,
    refreshMs: number,
    fetchMs: number,
    discoveryMs: number,
    private readonly fetchAllRepositories: boolean,
  ) {
    this.options = { ...options, signal: this.abortController.signal };
    void this.refresh(true, true);
    this.refreshTimer = setInterval(() => void this.refresh(false, false), refreshMs);
    this.fetchTimer = setInterval(() => void this.refresh(true, false), fetchMs);
    this.discoveryTimer = setInterval(() => void this.refresh(false, true), discoveryMs);
  }

  subscribe(listener: (state: GitStatusState) => void) {
    this.listeners.add(listener);
    listener(this.state);
    return () => this.listeners.delete(listener);
  }

  scheduleRefresh() {
    if (this.disposed || this.debounceTimer) return;
    this.debounceTimer = setTimeout(() => {
      this.debounceTimer = undefined;
      void this.refresh(false, false);
    }, EVENT_DEBOUNCE_MS);
  }

  dispose() {
    this.disposed = true;
    this.abortController.abort();
    clearInterval(this.refreshTimer);
    clearInterval(this.fetchTimer);
    clearInterval(this.discoveryTimer);
    if (this.debounceTimer) clearTimeout(this.debounceTimer);
    this.debounceTimer = undefined;
    this.listeners.clear();
  }

  private async refresh(fetchRemote: boolean, discoverRepositories: boolean) {
    if (this.disposed) return;
    if (this.running) {
      this.queued = true;
      this.fetchQueued ||= fetchRemote;
      this.discoveryQueued ||= discoverRepositories;
      return;
    }

    this.running = true;
    try {
      if (discoverRepositories) {
        try {
          this.repositories = await discoverGitRepositories(this.workspace, this.options);
        } catch {
          if (this.disposed) return;
          if (this.repositories.length === 0) {
            this.setState({ status: "error" });
            return;
          }
        }
      }
      if (this.disposed) return;

      if (this.repositories.length === 0) {
        this.setState({ status: "absent" });
        return;
      }

      const previousFailures = new Map<string, boolean>();
      if (this.state.status === "ready") {
        for (const repository of this.state.repositories) {
          if (repository.status === "ready") {
            previousFailures.set(repository.repository.gitDirectory, repository.fetchFailed);
          }
        }
      }
      const repositories = await mapConcurrent(
        this.repositories,
        MAX_CONCURRENT_GIT_COMMANDS,
        async (repository): Promise<GitRepositoryState> => {
          if (this.disposed) return { status: "error", repository };
          try {
            if (fetchRemote && (repository.primary || this.fetchAllRepositories)) {
              const result = await refreshGitRepository(repository.directory, this.options);
              if (!result.status) return { status: "error", repository };
              return {
                status: "ready",
                repository,
                data: result.status,
                fetchFailed: result.fetchFailed,
              };
            }

            const status = await inspectGitRepository(repository.directory, this.options);
            if (!status) return { status: "error", repository };
            return {
              status: "ready",
              repository,
              data: status,
              fetchFailed: previousFailures.get(repository.gitDirectory) ?? false,
            };
          } catch {
            return { status: "error", repository };
          }
        },
      );
      if (this.disposed) return;
      this.setState({ status: "ready", repositories });
    } catch {
      if (this.disposed) return;
      this.setState({ status: "error" });
    } finally {
      this.running = false;
      if (this.queued && !this.disposed) {
        const queuedFetch = this.fetchQueued;
        const queuedDiscovery = this.discoveryQueued;
        this.queued = false;
        this.fetchQueued = false;
        this.discoveryQueued = false;
        queueMicrotask(() => void this.refresh(queuedFetch, queuedDiscovery));
      }
    }
  }

  private setState(state: GitStatusState) {
    this.state = state;
    for (const listener of this.listeners) listener(state);
  }
}

function RepositoryRow(props: { api: TuiPluginApi; state: GitRepositoryState }) {
  const theme = () => props.api.theme.current;
  const indentation = () => "  ".repeat(props.state.repository.depth);

  if (props.state.status === "error") {
    return (
      <box flexDirection="row" justifyContent="space-between">
        <text fg={theme().textMuted}>
          {indentation()}
          {props.state.repository.label}
        </text>
        <text fg={theme().error}>Unavailable</text>
      </box>
    );
  }

  return (
    <box flexDirection="row" justifyContent="space-between">
      <text fg={theme().textMuted}>
        {indentation()}
        {props.state.repository.label} [{props.state.data.branch}]
      </text>
      <text fg={props.state.fetchFailed ? theme().warning : statusColor(props.state.data, theme())}>
        {gitStatusLabel(props.state.data)}
        {props.state.fetchFailed ? " | Fetch failed" : ""}
      </text>
    </box>
  );
}

function View(props: { api: TuiPluginApi; client: GitStatusClient }) {
  const [state, setState] = createSignal<GitStatusState>({ status: "loading" });
  const unsubscribe = props.client.subscribe(setState);
  const theme = () => props.api.theme.current;
  onCleanup(unsubscribe);

  return (
    <Switch>
      <Match when={state().status === "loading"}>
        <box>
          <text fg={theme().text}>
            <b>Git</b>
          </text>
          <box flexDirection="row" justifyContent="flex-end">
            <text fg={theme().textMuted}>Checking...</text>
          </box>
        </box>
      </Match>
      <Match when={state().status === "error"}>
        <box>
          <text fg={theme().text}>
            <b>Git</b>
          </text>
          <box flexDirection="row" justifyContent="flex-end">
            <text fg={theme().error}>Unavailable</text>
          </box>
        </box>
      </Match>
      <Match when={state().status === "absent"}>{null}</Match>
      <Match when={state().status === "ready" && state()}>
        {(current) => {
          const ready = () => current() as Extract<GitStatusState, { status: "ready" }>;
          return (
            <box>
              <text fg={theme().text}>
                <b>Git</b>
              </text>
              <For each={ready().repositories}>
                {(repository) => <RepositoryRow api={props.api} state={repository} />}
              </For>
            </box>
          );
        }}
      </Match>
    </Switch>
  );
}

const tui: TuiPlugin = async (api, rawOptions) => {
  const options = rawOptions as PluginOptions | undefined;
  const client = new GitStatusClient(
    api.state.path.worktree || api.state.path.directory,
    {
      gitBinary: options?.gitBinary,
      scanExclusions: options?.scanExclusions,
      timeoutMs: interval(options?.timeoutMs, DEFAULT_TIMEOUT_MS, MIN_TIMEOUT_MS),
    },
    interval(options?.refreshMs, DEFAULT_REFRESH_MS, MIN_REFRESH_MS),
    interval(options?.fetchMs, DEFAULT_FETCH_MS, MIN_FETCH_MS),
    interval(options?.discoveryMs, DEFAULT_DISCOVERY_MS, MIN_DISCOVERY_MS),
    options?.fetchAllRepositories === true,
  );

  const unsubscribe = [
    api.event.on("file.edited", () => client.scheduleRefresh()),
    api.event.on("file.watcher.updated", () => client.scheduleRefresh()),
    api.event.on("session.idle", () => client.scheduleRefresh()),
  ];
  api.lifecycle.onDispose(() => {
    for (const dispose of unsubscribe) dispose();
    client.dispose();
  });
  api.slots.register({
    order: 50,
    slots: {
      sidebar_content() {
        return <View api={api} client={client} />;
      },
    },
  });
};

const plugin: TuiPluginModule & { id: string } = {
  id: PLUGIN_ID,
  tui,
};

export default plugin;
