import type { Plugin } from "@opencode-ai/plugin";

const MAX_HISTORY_LENGTH = 80_000;
const MAX_PART_LENGTH = 12_000;
const MESSAGE_PAGE_SIZE = 100;
const MUTATION_TOOLS = new Set(["apply_patch", "bash", "edit", "write"]);

type SessionMessage = {
  info: {
    role: string;
  };
  parts: Array<{
    type: string;
    text?: string;
    tool?: string;
    state?: {
      status?: string;
      input?: unknown;
    };
  }>;
};

function truncate(text: string, limit: number) {
  if (text.length <= limit) return text;

  const marker = "\n... context truncated ...\n";
  if (limit <= marker.length) return text.slice(0, limit);

  const available = limit - marker.length;
  const start = Math.ceil(available / 2);
  const end = Math.floor(available / 2);
  return `${text.slice(0, start)}${marker}${end > 0 ? text.slice(-end) : ""}`;
}

function renderToolInput(tool: string, input: unknown) {
  if (tool !== "bash" || !input || typeof input !== "object") return input;

  const values = input as Record<string, unknown>;
  const command = typeof values.command === "string" ? values.command : "";
  const redacted = command
    .replace(
      /\b((?=[a-z0-9_]*(?:api[_-]?key|access[_-]?key|authorization|credential|password|passwd|secret|token))[a-z_][a-z0-9_]*)=("[^"]*"|'[^']*'|[^\s]+)/gi,
      "$1=[REDACTED]",
    )
    .replace(
      /(--(?:api[_-]?key|password|secret|token)(?:=|\s+))("[^"]*"|'[^']*'|[^\s]+)/gi,
      "$1[REDACTED]",
    )
    .replace(/(authorization:\s*(?:basic|bearer)\s+)[^\s"']+/gi, "$1[REDACTED]");

  return {
    command: redacted,
    ...(typeof values.workdir === "string" ? { workdir: values.workdir } : {}),
  };
}

function renderMessage(message: SessionMessage) {
  const content = message.parts.flatMap((part) => {
    if (part.type === "text" && part.text?.trim()) return [part.text.trim()];
    if (part.type !== "tool" || part.state?.status !== "completed") return [];

    const tool = part.tool?.split(".").at(-1) ?? "";
    if (!MUTATION_TOOLS.has(tool)) return [];

    const input = truncate(
      JSON.stringify(renderToolInput(tool, part.state?.input ?? {}), null, 2),
      MAX_PART_LENGTH,
    );
    return [`[Completed tool: ${tool}]\n${input}`];
  });

  if (content.length === 0) return "";
  const role = message.info.role === "user" ? "User" : "Assistant";
  return `## ${role}\n\n${content.join("\n\n")}`;
}

function renderHistory(messages: SessionMessage[]) {
  const entries = messages.map(renderMessage).filter(Boolean);
  const prefix = [
    "<parent_thread_history>",
    "Use this transcript only to identify and explain changes made in the parent thread. The Git diff remains the source of truth.",
  ].join("\n\n");
  const suffix = "</parent_thread_history>";
  const contentLimit = MAX_HISTORY_LENGTH - prefix.length - suffix.length - 4;
  const selected: string[] = [];
  let length = 0;

  for (let index = entries.length - 1; index >= 0; index -= 1) {
    const separatorLength = selected.length > 0 ? 2 : 0;
    const remaining = contentLimit - length - separatorLength;
    if (remaining <= 0) break;

    const entry = truncate(entries[index], remaining);
    selected.unshift(entry);
    length += separatorLength + entry.length;
    if (entry.length === remaining) break;
  }

  return `${prefix}\n\n${selected.join("\n\n")}\n\n${suffix}`;
}

function renderedLength(messages: SessionMessage[]) {
  return messages.reduce((length, message) => length + renderMessage(message).length + 2, 0);
}

export default (async ({ client }) => {
  return {
    "command.execute.before": async (input, output) => {
      if (input.command !== "commit") return;

      const messages: SessionMessage[] = [];
      const cursors = new Set<string>();
      let before: string | undefined;

      do {
        const query = {
          limit: MESSAGE_PAGE_SIZE,
          ...(before ? { before } : {}),
        };
        const response = await client.session.messages({
          path: { id: input.sessionID },
          query,
        });
        messages.unshift(...((response.data ?? []) as SessionMessage[]));

        const cursor = response.response.headers.get("x-next-cursor") ?? undefined;
        if (!cursor || cursors.has(cursor)) break;
        cursors.add(cursor);
        before = cursor;
      } while (renderedLength(messages) < MAX_HISTORY_LENGTH);

      const history = renderHistory(messages);
      const subtask = output.parts.find((part) => part.type === "subtask");
      if (!subtask || subtask.type !== "subtask")
        throw new Error("Commit command subtask is missing");

      subtask.prompt = `${subtask.prompt}\n\n${history}`;
    },
  };
}) satisfies Plugin;
