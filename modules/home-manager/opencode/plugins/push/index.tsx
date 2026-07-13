/** @jsxImportSource @opentui/solid */
import type { PluginOptions } from "@opencode-ai/plugin";
import type { TuiPlugin, TuiPluginApi, TuiPluginModule } from "@opencode-ai/plugin/tui";
import { isAbsolute, relative, resolve, sep } from "node:path";
import { createSignal, onCleanup, Show } from "solid-js";
import { attemptPush, createGitRunner, renderFallbackPrompt, type GitRunner } from "./core";

const PLUGIN_ID = "push";

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

export async function registerPushPlugin(
  api: TuiPluginApi,
  options?: PluginOptions,
  runner?: GitRunner,
) {
  const binary = typeof options?.gitBinary === "string" ? options.gitBinary : "git";
  const runGit = runner ?? createGitRunner(binary);
  const client = new PushStatusClient();

  const unregister = [
    api.keymap.registerLayer({
      commands: [
        {
          category: "VCS",
          desc: "Push the current branch, using an agent only when Git needs intervention",
          name: "push.run",
          namespace: "palette",
          slashName: "push",
          title: "Push current branch",
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
            if (!client.start(sessionID, session.directory)) {
              api.ui.toast({
                title: "Push",
                message: "A push is already running",
                variant: "warning",
              });
              return;
            }

            const signal = AbortSignal.any([api.lifecycle.signal, client.signal(sessionID)!]);
            try {
              const outcome = await attemptPush(session.directory, runGit, signal);
              if (api.lifecycle.signal.aborted || client.isDisposed()) return;
              if (signal.aborted) {
                api.ui.toast({
                  title: "Push",
                  message: "Push cancelled because workspace files changed",
                  variant: "warning",
                });
                return;
              }
              if (outcome.type === "pushed") {
                api.ui.toast({
                  title: "Push",
                  message: outcome.output.includes("[up to date]")
                    ? "Everything up-to-date"
                    : `Pushed ${outcome.branch} to ${outcome.upstream}`,
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
                      description: "Rebase and push current branch",
                      prompt: renderFallbackPrompt(outcome),
                    },
                  ],
                },
                { throwOnError: true },
              );
              if (api.lifecycle.signal.aborted || client.isDisposed()) return;
              if (signal.aborted) {
                api.ui.toast({
                  title: "Push",
                  message: "Push cancelled because workspace files changed",
                  variant: "warning",
                });
                return;
              }
              api.ui.toast({
                title: "Push",
                message: `${outcome.reason}; handed off to the build agent`,
                variant: "info",
              });
            } catch (error) {
              if (api.lifecycle.signal.aborted || client.isDisposed()) return;
              if (signal.aborted) {
                api.ui.toast({
                  title: "Push",
                  message: "Push cancelled because workspace files changed",
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
    api.event.on("file.edited", (event) => client.cancelFile(event.properties.file)),
    api.event.on("file.watcher.updated", (event) => client.cancelFile(event.properties.file)),
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
