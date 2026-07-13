import type { PluginOptions } from "@opencode-ai/plugin";
import type { TuiPlugin, TuiPluginApi, TuiPluginModule } from "@opencode-ai/plugin/tui";
import { attemptPush, createGitRunner, renderFallbackPrompt, type GitRunner } from "./core";

const PLUGIN_ID = "push";

export async function registerPushPlugin(
  api: TuiPluginApi,
  options?: PluginOptions,
  runner?: GitRunner,
) {
  const binary = typeof options?.gitBinary === "string" ? options.gitBinary : "git";
  const runGit = runner ?? createGitRunner(binary);
  const running = new Set<string>();

  const unregister = api.keymap.registerLayer({
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
          const status = api.state.session.status(sessionID);
          if (status && status.type !== "idle") {
            api.ui.toast({
              title: "Push",
              message: "Wait for the session to become idle before pushing",
              variant: "warning",
            });
            return;
          }
          if (running.has(sessionID)) {
            api.ui.toast({
              title: "Push",
              message: "A push is already running",
              variant: "warning",
            });
            return;
          }

          running.add(sessionID);
          try {
            const outcome = await attemptPush(session.directory, runGit, api.lifecycle.signal);
            if (api.lifecycle.signal.aborted) return;
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

            const currentStatus = api.state.session.status(sessionID);
            if (currentStatus && currentStatus.type !== "idle") {
              api.ui.toast({
                title: "Push",
                message: `${outcome.reason}; retry when the session is idle`,
                variant: "warning",
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
            api.ui.toast({
              title: "Push",
              message: `${outcome.reason}; handed off to the build agent`,
              variant: "info",
            });
          } catch (error) {
            if (api.lifecycle.signal.aborted) return;
            api.ui.toast({
              title: "Push",
              message: error instanceof Error ? error.message : String(error),
              variant: "error",
            });
          } finally {
            running.delete(sessionID);
          }
        },
      },
    ],
  });

  api.lifecycle.onDispose(unregister);
}

const tui: TuiPlugin = async (api, options) => registerPushPlugin(api, options);

const plugin: TuiPluginModule & { id: string } = {
  id: PLUGIN_ID,
  tui,
};

export default plugin;
