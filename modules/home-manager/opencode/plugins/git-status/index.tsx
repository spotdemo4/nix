/** @jsxImportSource @opentui/solid */
import type {
  TuiPlugin,
  TuiPluginApi,
  TuiPluginModule,
  TuiThemeCurrent,
} from "@opencode-ai/plugin/tui";
import { createSignal, Match, onCleanup, Show, Switch } from "solid-js";
import {
  gitStatusLabel,
  inspectGitRepository,
  refreshGitRepository,
  type GitCommandOptions,
  type GitStatus,
} from "./core";

type PluginOptions = {
  fetchMs?: number;
  gitBinary?: string;
  refreshMs?: number;
  timeoutMs?: number;
};

type GitStatusState =
  | { status: "loading" }
  | { status: "absent" }
  | { status: "error" }
  | { status: "ready"; data: GitStatus; fetchFailed: boolean };

const PLUGIN_ID = "trev.git-status";
const DEFAULT_REFRESH_MS = 5_000;
const DEFAULT_FETCH_MS = 60_000;
const DEFAULT_TIMEOUT_MS = 15_000;
const MIN_REFRESH_MS = 1_000;
const MIN_FETCH_MS = 15_000;
const MIN_TIMEOUT_MS = 1_000;
const EVENT_DEBOUNCE_MS = 250;

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

class GitStatusClient {
  private state: GitStatusState = { status: "loading" };
  private readonly listeners = new Set<(state: GitStatusState) => void>();
  private readonly refreshTimer: ReturnType<typeof setInterval>;
  private readonly fetchTimer: ReturnType<typeof setInterval>;
  private debounceTimer?: ReturnType<typeof setTimeout>;
  private running = false;
  private queued = false;
  private fetchQueued = false;
  private disposed = false;

  constructor(
    private readonly directory: string,
    private readonly options: GitCommandOptions,
    refreshMs: number,
    fetchMs: number,
  ) {
    void this.refresh(true);
    this.refreshTimer = setInterval(() => void this.refresh(false), refreshMs);
    this.fetchTimer = setInterval(() => void this.refresh(true), fetchMs);
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
      void this.refresh(false);
    }, EVENT_DEBOUNCE_MS);
  }

  dispose() {
    this.disposed = true;
    clearInterval(this.refreshTimer);
    clearInterval(this.fetchTimer);
    if (this.debounceTimer) clearTimeout(this.debounceTimer);
    this.debounceTimer = undefined;
    this.listeners.clear();
  }

  private async refresh(fetchRemote: boolean) {
    if (this.disposed) return;
    if (this.running) {
      this.queued = true;
      this.fetchQueued ||= fetchRemote;
      return;
    }

    this.running = true;
    try {
      if (fetchRemote) {
        const result = await refreshGitRepository(this.directory, this.options);
        this.applyStatus(result.status, result.fetchFailed);
      } else {
        const status = await inspectGitRepository(this.directory, this.options);
        const fetchFailed = this.state.status === "ready" && this.state.fetchFailed;
        this.applyStatus(status, fetchFailed);
      }
    } catch {
      this.setState({ status: "error" });
    } finally {
      this.running = false;
      if (this.queued && !this.disposed) {
        const queuedFetch = this.fetchQueued;
        this.queued = false;
        this.fetchQueued = false;
        queueMicrotask(() => void this.refresh(queuedFetch));
      }
    }
  }

  private applyStatus(status: GitStatus | undefined, fetchFailed: boolean) {
    this.setState(status ? { status: "ready", data: status, fetchFailed } : { status: "absent" });
  }

  private setState(state: GitStatusState) {
    this.state = state;
    for (const listener of this.listeners) listener(state);
  }
}

function View(props: { api: TuiPluginApi; client: GitStatusClient }) {
  const [state, setState] = createSignal<GitStatusState>({ status: "loading" });
  const unsubscribe = props.client.subscribe(setState);
  const theme = () => props.api.theme.current;
  onCleanup(unsubscribe);

  return (
    <Switch>
      <Match when={state().status === "loading"}>
        <text fg={theme().textMuted}>Git Checking...</text>
      </Match>
      <Match when={state().status === "error"}>
        <text fg={theme().error}>Git unavailable</text>
      </Match>
      <Match when={state().status === "absent"}>{null}</Match>
      <Match when={state().status === "ready" && state()}>
        {(current) => {
          const ready = () => current() as Extract<GitStatusState, { status: "ready" }>;
          return (
            <box>
              <text>
                <span style={{ fg: theme().textMuted }}>Git </span>
                <span style={{ fg: theme().text }}>
                  <b>{ready().data.branch}</b>
                </span>
                <span style={{ fg: statusColor(ready().data, theme()) }}>
                  {` ${gitStatusLabel(ready().data)}`}
                </span>
              </text>
              <Show when={ready().fetchFailed}>
                <text fg={theme().warning}>Remote refresh failed; showing cached refs</text>
              </Show>
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
      timeoutMs: interval(options?.timeoutMs, DEFAULT_TIMEOUT_MS, MIN_TIMEOUT_MS),
    },
    interval(options?.refreshMs, DEFAULT_REFRESH_MS, MIN_REFRESH_MS),
    interval(options?.fetchMs, DEFAULT_FETCH_MS, MIN_FETCH_MS),
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
      sidebar_footer() {
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
