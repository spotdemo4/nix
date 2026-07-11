// Adapted from https://github.com/anaskhan96/opencode-plugin-codex-usage (MIT).
// See codex-usage.LICENSE in this directory.
/** @jsxImportSource @opentui/solid */
import type {
  TuiPlugin,
  TuiPluginApi,
  TuiPluginModule,
  TuiThemeCurrent,
} from "@opencode-ai/plugin/tui";
import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import { createSignal, For, Match, onCleanup, Show, Switch } from "solid-js";

type PluginOptions = {
  codexBinary?: string;
  refreshMs?: number;
};

type RateLimitWindow = {
  usedPercent?: number;
  windowDurationMins?: number | null;
  resetsAt?: number | null;
};

type RateLimitCredits = {
  hasCredits?: boolean;
  unlimited?: boolean;
  balance?: string | null;
};

type SpendLimit = {
  remainingPercent?: number;
  resetsAt?: number;
};

type RateLimitSnapshot = {
  limitId?: string | null;
  limitName?: string | null;
  primary?: RateLimitWindow | null;
  secondary?: RateLimitWindow | null;
  credits?: RateLimitCredits | null;
  individualLimit?: SpendLimit | null;
};

type RateLimitResponse = {
  rateLimits?: RateLimitSnapshot | null;
  rateLimitsByLimitId?: Record<string, RateLimitSnapshot> | null;
};

type RateLimitData = {
  snapshots: RateLimitSnapshot[];
};

type RateLimitState =
  | { status: "loading"; data?: RateLimitData }
  | { status: "ready"; data: RateLimitData }
  | { status: "error"; message: string; data?: RateLimitData };

type RpcMessage = {
  id?: number;
  method?: string;
  result?: RateLimitResponse;
  error?: { message?: string };
};

const PLUGIN_ID = "trev.codex-usage";
const DEFAULT_REFRESH_MS = 30_000;
const MIN_REFRESH_MS = 15_000;
const REQUEST_TIMEOUT_MS = 15_000;
const RESTART_DELAY_MS = 5_000;
const STDERR_LIMIT = 4_096;

function errorMessage(error: unknown) {
  const message = error instanceof Error ? error.message : String(error);

  if (/token_invalidated|invalidated|unauthorized|\b401\b/i.test(message)) {
    return "Codex login expired; run `codex login`.";
  }
  if (/ENOENT/.test(message)) return "Codex CLI not found.";
  return message;
}

function refreshInterval(options: PluginOptions | undefined) {
  const value = options?.refreshMs;
  if (typeof value !== "number" || !Number.isFinite(value)) return DEFAULT_REFRESH_MS;
  return Math.max(MIN_REFRESH_MS, Math.floor(value));
}

function snapshotName(snapshot: RateLimitSnapshot) {
  const raw = snapshot.limitName?.trim() || snapshot.limitId?.trim() || "Codex";
  if (raw.toLowerCase() === "codex") return "Codex";

  return raw
    .replace(/_/g, "-")
    .split("-")
    .map((part) => {
      if (/^gpt$/i.test(part)) return "GPT";
      if (/^codex$/i.test(part)) return "Codex";
      if (!part || /^[0-9.]+$/.test(part)) return part;
      return part[0].toUpperCase() + part.slice(1);
    })
    .join("-");
}

function normalizeSnapshots(result: RateLimitResponse) {
  const snapshots = Object.values(result.rateLimitsByLimitId ?? {});
  if (snapshots.length === 0 && result.rateLimits) snapshots.push(result.rateLimits);

  return snapshots.sort((left, right) => {
    const leftID = left.limitId?.toLowerCase() ?? "codex";
    const rightID = right.limitId?.toLowerCase() ?? "codex";
    if (leftID === "codex") return -1;
    if (rightID === "codex") return 1;
    return snapshotName(left).localeCompare(snapshotName(right));
  });
}

class CodexUsageClient {
  private state: RateLimitState = { status: "loading" };
  private readonly listeners = new Set<(state: RateLimitState) => void>();
  private child?: ChildProcessWithoutNullStreams;
  private stdout = "";
  private stderr = "";
  private initialized = false;
  private initializeID?: number;
  private readID?: number;
  private nextID = 1;
  private queued = false;
  private disposed = false;
  private requestTimer?: ReturnType<typeof setTimeout>;
  private restartTimer?: ReturnType<typeof setTimeout>;
  private readonly pollTimer: ReturnType<typeof setInterval>;

  constructor(
    private readonly binary: string,
    refreshMs: number,
  ) {
    this.start();
    this.pollTimer = setInterval(() => this.refresh(), refreshMs);
  }

  subscribe(listener: (state: RateLimitState) => void) {
    this.listeners.add(listener);
    listener(this.state);
    return () => {
      this.listeners.delete(listener);
    };
  }

  refresh() {
    if (this.disposed) return;
    if (!this.child || !this.initialized) {
      this.queued = true;
      this.start();
      return;
    }
    if (this.readID !== undefined) {
      this.queued = true;
      return;
    }

    const id = this.nextID++;
    this.readID = id;
    if (this.send({ method: "account/rateLimits/read", id })) {
      this.setRequestTimeout("Timed out while reading Codex usage.");
    }
  }

  dispose() {
    this.disposed = true;
    clearInterval(this.pollTimer);
    this.clearRequestTimeout();
    if (this.restartTimer) clearTimeout(this.restartTimer);
    this.restartTimer = undefined;

    const child = this.child;
    this.child = undefined;
    child?.kill();
    this.listeners.clear();
  }

  private start() {
    if (this.disposed || this.child || this.restartTimer) return;

    this.stdout = "";
    this.stderr = "";
    this.initialized = false;
    this.nextID = 1;

    const child = spawn(this.binary, ["app-server", "--listen", "stdio://"], {
      cwd: process.env.HOME,
      stdio: ["pipe", "pipe", "pipe"],
    });
    this.child = child;

    child.stdout.on("data", (chunk) => this.onStdout(child, chunk.toString()));
    child.stderr.on("data", (chunk) => {
      if (this.child !== child) return;
      this.stderr = `${this.stderr}${chunk.toString()}`.slice(-STDERR_LIMIT);
    });
    child.stdin.on("error", (error) => {
      if (this.child === child) this.restart(error);
    });
    child.on("error", (error) => {
      if (this.child === child) this.restart(error);
    });
    child.on("exit", (code, signal) => {
      if (this.child !== child || this.disposed) return;
      const detail =
        this.stderr.trim() || `Codex app-server exited (${signal ?? code ?? "unknown"}).`;
      this.restart(new Error(detail));
    });

    const id = this.nextID++;
    this.initializeID = id;
    if (
      this.send({
        method: "initialize",
        id,
        params: {
          clientInfo: {
            name: "opencode_codex_usage",
            title: "OpenCode Codex Usage",
            version: "1.0.0",
          },
        },
      })
    ) {
      this.setRequestTimeout("Timed out while starting Codex app-server.");
    }
  }

  private send(message: Record<string, unknown>) {
    const child = this.child;
    if (!child?.stdin.writable) {
      this.restart(new Error("Codex app-server is not available."));
      return false;
    }

    child.stdin.write(`${JSON.stringify(message)}\n`, (error) => {
      if (error && this.child === child) this.restart(error);
    });
    return true;
  }

  private onStdout(child: ChildProcessWithoutNullStreams, chunk: string) {
    if (this.child !== child) return;

    this.stdout += chunk;
    const lines = this.stdout.split(/\r?\n/);
    this.stdout = lines.pop() ?? "";

    for (const line of lines) {
      if (!line.trim()) continue;
      let message: RpcMessage;
      try {
        message = JSON.parse(line) as RpcMessage;
      } catch {
        // Ignore non-protocol output; stderr is reported if the process fails.
        continue;
      }

      try {
        this.onMessage(message);
      } catch (error) {
        this.restart(error);
        return;
      }
    }
  }

  private onMessage(message: RpcMessage) {
    if (message.id === this.initializeID) {
      this.clearRequestTimeout();
      this.initializeID = undefined;
      if (message.error?.message) {
        this.restart(new Error(message.error.message));
        return;
      }

      this.initialized = true;
      this.send({ method: "initialized", params: {} });
      this.queued = false;
      this.refresh();
      return;
    }

    if (message.id === this.readID) {
      this.clearRequestTimeout();
      this.readID = undefined;

      if (message.error?.message) {
        this.setError(new Error(message.error.message));
      } else {
        this.setState({
          status: "ready",
          data: {
            snapshots: normalizeSnapshots(message.result ?? {}),
          },
        });
      }

      if (this.queued) {
        this.queued = false;
        queueMicrotask(() => this.refresh());
      }
      return;
    }

    if (message.method === "account/rateLimits/updated") this.refresh();
  }

  private restart(error: unknown) {
    if (this.disposed) return;
    this.setError(error);
    this.clearRequestTimeout();
    this.initializeID = undefined;
    this.readID = undefined;
    this.initialized = false;
    this.queued = true;

    const child = this.child;
    this.child = undefined;
    child?.kill();

    if (!this.restartTimer) {
      this.restartTimer = setTimeout(() => {
        this.restartTimer = undefined;
        this.start();
      }, RESTART_DELAY_MS);
    }
  }

  private setRequestTimeout(message: string) {
    this.clearRequestTimeout();
    this.requestTimer = setTimeout(() => this.restart(new Error(message)), REQUEST_TIMEOUT_MS);
  }

  private clearRequestTimeout() {
    if (this.requestTimer) clearTimeout(this.requestTimer);
    this.requestTimer = undefined;
  }

  private setError(error: unknown) {
    const data = this.state.data;
    this.setState({
      status: "error",
      message: errorMessage(error),
      ...(data ? { data } : {}),
    });
  }

  private setState(state: RateLimitState) {
    this.state = state;
    for (const listener of this.listeners) listener(state);
  }
}

function durationLabel(window: RateLimitWindow | null | undefined, fallback: string) {
  const minutes = window?.windowDurationMins;
  if (!minutes) return fallback;
  if (minutes === 10_080) return "Weekly";
  if (minutes === 43_200) return "Monthly";
  if (minutes % 1_440 === 0) return `${minutes / 1_440}d`;
  if (minutes % 60 === 0) return `${minutes / 60}h`;
  return `${minutes}m`;
}

function percentLeft(value: number | undefined) {
  if (typeof value !== "number" || !Number.isFinite(value)) return undefined;
  return Math.round(Math.max(0, Math.min(100, 100 - value)));
}

function remainingColor(remaining: number, theme: TuiThemeCurrent) {
  if (remaining < 15) return theme.error;
  if (remaining < 50) return theme.warning;
  return theme.success;
}

function resetLabel(timestamp: number | null | undefined) {
  if (!timestamp) return "reset unavailable";
  const date = new Date(timestamp * 1_000);
  if (Number.isNaN(date.getTime())) return "reset unavailable";

  return `resets ${new Intl.DateTimeFormat(undefined, {
    weekday: "short",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).format(date)}`;
}

function WindowView(props: {
  label: string;
  window: RateLimitWindow;
  theme: () => TuiThemeCurrent;
}) {
  const remaining = () => percentLeft(props.window.usedPercent);
  const color = () => {
    const value = remaining();
    return value === undefined ? props.theme().textMuted : remainingColor(value, props.theme());
  };

  return (
    <box>
      <box flexDirection="row" justifyContent="space-between">
        <text fg={props.theme().textMuted}>{props.label}</text>
        <text fg={color()}>
          {remaining() === undefined ? "unavailable" : `${remaining()}% left`}
        </text>
      </box>
      <text fg={props.theme().textMuted}>{resetLabel(props.window.resetsAt)}</text>
    </box>
  );
}

function SnapshotView(props: {
  snapshot: RateLimitSnapshot;
  showName: boolean;
  theme: () => TuiThemeCurrent;
}) {
  const spend = () => props.snapshot.individualLimit;
  const spendRemaining = () => {
    const value = spend()?.remainingPercent;
    return typeof value === "number" && Number.isFinite(value)
      ? Math.round(Math.max(0, Math.min(100, value)))
      : undefined;
  };
  const spendColor = () => {
    const value = spendRemaining();
    return value === undefined ? props.theme().textMuted : remainingColor(value, props.theme());
  };
  const creditBalance = () => {
    const credits = props.snapshot.credits;
    if (!credits?.hasCredits) return undefined;
    if (credits.unlimited) return "Unlimited";
    const value = Number(credits.balance);
    return Number.isFinite(value) ? `${Math.round(value).toLocaleString()} credits` : undefined;
  };

  return (
    <box marginTop={props.showName ? 1 : 0}>
      <Show when={props.showName}>
        <text fg={props.theme().text}>
          <b>{snapshotName(props.snapshot)}</b>
        </text>
      </Show>
      <Show when={props.snapshot.primary}>
        {(window) => (
          <WindowView label={durationLabel(window(), "5h")} window={window()} theme={props.theme} />
        )}
      </Show>
      <Show when={props.snapshot.secondary}>
        {(window) => (
          <WindowView
            label={durationLabel(window(), "Weekly")}
            window={window()}
            theme={props.theme}
          />
        )}
      </Show>
      <Show when={creditBalance()}>
        {(balance) => (
          <box flexDirection="row" justifyContent="space-between">
            <text fg={props.theme().textMuted}>Credits</text>
            <text fg={props.theme().text}>{balance()}</text>
          </box>
        )}
      </Show>
      <Show when={spend()}>
        {(limit) => (
          <box>
            <box flexDirection="row" justifyContent="space-between">
              <text fg={props.theme().textMuted}>Monthly credits</text>
              <text fg={spendColor()}>
                {spendRemaining() === undefined ? "unavailable" : `${spendRemaining()}% left`}
              </text>
            </box>
            <text fg={props.theme().textMuted}>{resetLabel(limit().resetsAt)}</text>
          </box>
        )}
      </Show>
    </box>
  );
}

function View(props: { api: TuiPluginApi; client: CodexUsageClient }) {
  const [state, setState] = createSignal<RateLimitState>({ status: "loading" });
  const unsubscribe = props.client.subscribe(setState);
  const theme = () => props.api.theme.current;
  const snapshots = () => state().data?.snapshots ?? [];
  const error = () => {
    const value = state();
    return value.status === "error" ? value.message : "Unknown error";
  };
  onCleanup(unsubscribe);

  return (
    <box>
      <text fg={theme().text}>
        <b>Codex Usage</b>
      </text>
      <Switch>
        <Match when={state().status === "loading" && !state().data}>
          <text fg={theme().textMuted}>Loading usage limits...</text>
        </Match>
        <Match when={state().status === "error" && !state().data}>
          <text fg={theme().warning}>{error()}</text>
        </Match>
        <Match when={snapshots().length === 0}>
          <text fg={theme().textMuted}>No usage data available.</text>
        </Match>
        <Match when={snapshots().length > 0}>
          <For each={snapshots()}>
            {(snapshot) => (
              <SnapshotView
                snapshot={snapshot}
                showName={snapshots().length > 1 || snapshotName(snapshot) !== "Codex"}
                theme={theme}
              />
            )}
          </For>
        </Match>
      </Switch>
      <Show when={state().status === "error" && state().data}>
        <text fg={theme().warning}>Refresh failed; showing last update.</text>
      </Show>
    </box>
  );
}

const tui: TuiPlugin = async (api, rawOptions) => {
  const options = rawOptions as PluginOptions | undefined;
  const client = new CodexUsageClient(options?.codexBinary ?? "codex", refreshInterval(options));

  api.lifecycle.onDispose(() => client.dispose());
  api.event.on("session.idle", () => client.refresh());
  api.slots.register({
    order: 150,
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
