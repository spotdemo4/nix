/** @jsxImportSource @opentui/solid */
import type { TuiPlugin, TuiPluginApi, TuiPluginModule } from "@opencode-ai/plugin/tui";
import { createSignal, onCleanup, Show } from "solid-js";
import { AUTO_COMMIT_SESSION_TITLE, AUTO_COMMIT_TRIGGER } from "./constants";

type SessionInfo = {
  id: string;
  parentID?: string;
  title?: string;
};

const PLUGIN_ID = "trev.auto-commit-status";

export class AutoCommitStatusClient {
  private readonly parentsByChild = new Map<string, string>();
  private readonly childCounts = new Map<string, number>();
  private readonly listeners = new Set<() => void>();

  subscribe(listener: () => void) {
    this.listeners.add(listener);
    listener();
    return () => this.listeners.delete(listener);
  }

  isGenerating(parentID: string) {
    return (this.childCounts.get(parentID) ?? 0) > 0;
  }

  sessionCreated(session: SessionInfo) {
    if (session.title !== AUTO_COMMIT_SESSION_TITLE || !session.parentID) return;
    if (this.parentsByChild.has(session.id)) return;

    this.parentsByChild.set(session.id, session.parentID);
    this.childCounts.set(session.parentID, (this.childCounts.get(session.parentID) ?? 0) + 1);
    this.emit();
  }

  sessionDeleted(session: Pick<SessionInfo, "id">) {
    this.sessionFinished(session.id);
  }

  sessionFinished(sessionID: string) {
    const parentID = this.parentsByChild.get(sessionID);
    if (!parentID) return;

    this.parentsByChild.delete(sessionID);
    const count = (this.childCounts.get(parentID) ?? 1) - 1;
    if (count > 0) this.childCounts.set(parentID, count);
    else this.childCounts.delete(parentID);
    this.emit();
  }

  dispose() {
    this.parentsByChild.clear();
    this.childCounts.clear();
    this.listeners.clear();
  }

  private emit() {
    for (const listener of this.listeners) listener();
  }
}

function View(props: { api: TuiPluginApi; client: AutoCommitStatusClient; sessionID: string }) {
  const [generating, setGenerating] = createSignal(false);
  const unsubscribe = props.client.subscribe(() => {
    setGenerating(props.client.isGenerating(props.sessionID));
  });
  const theme = () => props.api.theme.current;
  onCleanup(unsubscribe);

  return (
    <Show when={generating()}>
      <text>
        <span style={{ fg: theme().textMuted }}>Auto commit </span>
        <span style={{ fg: theme().info }}>Generating...</span>
      </text>
    </Show>
  );
}

const tui: TuiPlugin = async (api) => {
  const client = new AutoCommitStatusClient();
  const unsubscribe = [
    api.keymap.registerLayer({
      commands: [
        {
          category: "VCS",
          desc: "Create atomic commits for attributable working tree changes",
          name: "auto-commit.run",
          namespace: "palette",
          slashName: "commit",
          title: "Run auto commit",
          async run() {
            const sessionID =
              api.route.current.name === "session" && "params" in api.route.current
                ? api.route.current.params?.sessionID
                : undefined;
            if (typeof sessionID !== "string") {
              api.ui.toast({
                title: "Auto commit",
                message: "Open a session before running auto commit",
                variant: "warning",
              });
              return;
            }

            const session = api.state.session.get(sessionID);
            if (!session || session.parentID) {
              api.ui.toast({
                title: "Auto commit",
                message: "Auto commit can only run from a top-level session",
                variant: "warning",
              });
              return;
            }
            const status = api.state.session.status(sessionID);
            if (status && status.type !== "idle") {
              api.ui.toast({
                title: "Auto commit",
                message: "Wait for the session to become idle before running auto commit",
                variant: "warning",
              });
              return;
            }

            try {
              await api.client.session.promptAsync(
                {
                  sessionID,
                  directory: session.directory,
                  agent: session.agent,
                  model: session.model
                    ? { providerID: session.model.providerID, modelID: session.model.id }
                    : undefined,
                  variant: session.model?.variant,
                  noReply: true,
                  parts: [
                    {
                      type: "text",
                      text: AUTO_COMMIT_TRIGGER,
                      synthetic: true,
                      ignored: true,
                    },
                  ],
                },
                { throwOnError: true },
              );
              api.ui.toast({
                title: "Auto commit",
                message: "Automatic commit requested",
                variant: "info",
              });
            } catch (error) {
              api.ui.toast({
                title: "Auto commit",
                message: error instanceof Error ? error.message : String(error),
                variant: "error",
              });
            }
          },
        },
      ],
    }),
    api.event.on("session.created", (event) => client.sessionCreated(event.properties.info)),
    api.event.on("session.deleted", (event) => client.sessionDeleted(event.properties.info)),
    api.event.on("session.status", (event) => {
      if (event.properties.status.type === "idle") {
        client.sessionFinished(event.properties.sessionID);
      }
    }),
    api.event.on("session.error", (event) => {
      if (event.properties.sessionID) client.sessionFinished(event.properties.sessionID);
    }),
  ];

  api.lifecycle.onDispose(() => {
    for (const dispose of unsubscribe) dispose();
    client.dispose();
  });
  api.slots.register({
    order: 40,
    slots: {
      sidebar_content(_context, props) {
        return <View api={api} client={client} sessionID={props.session_id} />;
      },
    },
  });
};

const plugin: TuiPluginModule & { id: string } = {
  id: PLUGIN_ID,
  tui,
};

export default plugin;
