import type { Register } from "claude-code";

import type { Progress } from "../types";
import { Lines, Tracker, bar, findCheck, flakeKey } from "./parse";

const RUNS = { plugin: "nix-check-progress", key: "runs" } as const;
const FLUSH_MS = 250;

const plural = (n: number, word: string) => `${n} ${word}${n === 1 ? "" : "s"}`;

const headline = (p: Progress): { ratio: number | null; label: string } => {
  if (p.total !== null && p.total > 0) {
    return { ratio: p.outputs / p.total, label: `${p.outputs}/${p.total} outputs` };
  }
  if (p.phase === "build" && p.builds.expected > 0) {
    return {
      ratio: p.builds.done / p.builds.expected,
      label: `${p.builds.done}/${p.builds.expected} builds`,
    };
  }
  return { ratio: null, label: `${plural(p.outputs, "output")} checked` };
};

const details = (p: Progress): string => {
  const parts: string[] = [];
  if (p.builds.expected > 0) {
    parts.push(
      `builds ${p.builds.done}/${p.builds.expected}` +
        (p.builds.running > 0 ? ` (${p.builds.running} running)` : ""),
    );
  }
  if (p.downloads.expected > 0) {
    parts.push(`downloads ${p.downloads.done}/${p.downloads.expected}`);
  }
  if (p.activity !== null) {
    parts.push(p.activity);
  }
  return parts.join(" · ");
};

export const register: Register = (on) => {
  on("tool.call", { tool: "Bash" }, async ($, e, next) => {
    const check = findCheck(e.command);
    if (
      check === undefined ||
      e.run_in_background === true ||
      e.command.includes("json-log-path")
    ) {
      return next(e);
    }

    const id = e.tool_use_id;
    const path = `${(await $.env.get("TMPDIR")) ?? "/tmp"}/nix-check-progress-${id}.jsonl`;
    // The last clean check of the same flake sets the bar's total.
    const totalKey = `total:${flakeKey(await $.session.cwd(), e.command)}`.slice(0, 256);
    const stored = await $.store.get(totalKey);
    const tracker = new Tracker(typeof stored === "number" ? stored : null);
    const ref = { ...RUNS, id };

    await $.fs.write(path, "");
    await $.state.set(ref, tracker.snapshot());

    let isDirty = false;
    let isStopped = false;
    const tail = $.process.spawn({ argv: ["tail", "-n", "+1", "-F", path] });
    void (async () => {
      const lines = new Lines();
      for await (const { stream, text } of tail) {
        // Removing the log makes tail complain on stderr, which ends the loop.
        if (isStopped) break;
        if (stream !== "stdout") continue;
        for (const line of lines.push(text)) tracker.line(line);
        isDirty = true;
      }
    })().catch((error) => $.ui.log(`tail failed: ${String(error)}`, { to: "debug" }));
    const tick = $.clock.every(FLUSH_MS, () => {
      if (isDirty) {
        isDirty = false;
        void $.state.set(ref, tracker.snapshot());
      }
    });

    try {
      const ran = await next({
        ...e,
        command:
          e.command.slice(0, check.end) +
          ` --option json-log-path '${path}'` +
          e.command.slice(check.end),
      });

      // Let tail deliver the last records before judging the run.
      await $.clock.sleep(FLUSH_MS);
      if (
        ran.deny === undefined &&
        ran.isError !== true &&
        tracker.isClean &&
        tracker.checked > 0
      ) {
        await $.store.set(totalKey, tracker.checked);
      }

      return ran;
    } finally {
      isStopped = true;
      tick.cancel();
      await $.process.run(["rm", "-f", path]);
      $.clock.after(2000, () => void tail.return({ code: null, signal: null }));
      await $.state.set(ref, null);
    }
  }).catch(($, e, next) => next(e));

  on("ui.render", { component: "ToolProgress" }, async ($, e, next) => {
    const { value: progress } = await $.state.get({ ...RUNS, id: e.props.tool_use_id });
    if (progress === undefined || progress === null) {
      return next(e);
    }

    const { Box, Text } = $.ui.resolve(e);
    const columns = e.viewport?.columns ?? 80;
    const { ratio, label } = headline(progress);
    const detail = details(progress);

    return (
      <Box flexDirection="column">
        <Text>
          <Text dimColor>nix flake check </Text>
          {ratio === null ? null : (
            <Text color="claude">{bar(ratio, Math.min(30, Math.max(10, columns - 50)))} </Text>
          )}
          {label}
          {progress.failed > 0 ? <Text color="error"> · {progress.failed} failed</Text> : null}
        </Text>
        {detail === "" ? null : (
          <Text dimColor wrap="truncate-end">
            {detail}
          </Text>
        )}
        {e.props.hint === "" ? null : <Text dimColor>{e.props.hint}</Text>}
      </Box>
    );
  });
};
