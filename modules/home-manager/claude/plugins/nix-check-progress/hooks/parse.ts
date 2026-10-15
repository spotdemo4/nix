import type { Progress, Tally } from "../types";

// Activity and result types from nix's internal-json log format.
const ACT_COPY_PATHS = 103;
const ACT_BUILDS = 104;
const ACT_BUILD = 105;
const RES_PROGRESS = 105;

const CHECK = /^nix\s+flake\s+check\b/;
const SEPARATORS = ";&|(){}`\n";
// Words after which the next word still starts a command.
const PREFIXES = new Set([
  "!",
  "command",
  "do",
  "else",
  "env",
  "exec",
  "if",
  "then",
  "time",
  "until",
  "while",
]);

export type Span = { start: number; end: number };

// Finds the first `nix flake check` that runs as a command: at the start of a
// command, outside quotes, comments and heredoc bodies. Commands that only
// mention it (a commit message, a file written through a heredoc) are left alone.
export const findCheck = (command: string): Span | undefined => {
  const heredocs: string[] = [];
  let isCommandStart = true;
  let i = 0;

  while (i < command.length) {
    const c = command[i] ?? "";
    const rest = command.slice(i);

    if (c === "'" || c === '"') {
      const quoted = c === "'" ? /^'[^']*'?/.exec(rest) : /^"(?:\\.|[^"\\])*"?/.exec(rest);
      i += quoted?.[0].length ?? 1;
      isCommandStart = false;
    } else if (c === "\\") {
      i += 2;
      isCommandStart = false;
    } else if (c === "#" && (i === 0 || /\s/.test(command[i - 1] ?? ""))) {
      const newline = command.indexOf("\n", i);
      i = newline < 0 ? command.length : newline;
    } else if (c === "\n") {
      i += 1;
      // Skip the bodies of heredocs opened on the line that just ended.
      for (const word of heredocs.splice(0)) {
        const end = new RegExp(`^\\t*${word}$`, "m").exec(command.slice(i));
        i = end === null ? command.length : i + end.index + end[0].length;
      }
      isCommandStart = true;
    } else if (SEPARATORS.includes(c)) {
      i += 1;
      isCommandStart = true;
    } else if (/\s/.test(c)) {
      i += 1;
    } else if (rest.startsWith("<<") && !rest.startsWith("<<<")) {
      const heredoc = /^<<-?\s*(['"]?)(\w+)\1/.exec(rest);
      if (heredoc?.[2] !== undefined) heredocs.push(heredoc[2]);
      i += heredoc?.[0].length ?? 2;
      isCommandStart = false;
    } else {
      const check = isCommandStart ? CHECK.exec(rest) : null;
      if (check !== null) {
        return { start: i, end: i + check[0].length };
      }
      const word = /^[^\s;&|(){}`'"\\]+/.exec(rest)?.[0] ?? c;
      // Assignments and prefixes such as `time` keep the command position.
      isCommandStart = isCommandStart && (/^\w+=/.test(word) || PREFIXES.has(word));
      i += word.length;
    }
  }

  return undefined;
};

const ANSI = /\u001b\[[0-9;]*m/g;

type LogRecord = {
  action?: string;
  id?: number;
  type?: number;
  text?: string;
  level?: number;
  msg?: string;
  fields?: unknown[];
};

const sum = (tallies: Iterable<number[]>): Tally => {
  const total = { done: 0, expected: 0, running: 0, failed: 0 };
  for (const [done = 0, expected = 0, running = 0, failed = 0] of tallies) {
    total.done += done;
    total.expected += expected;
    total.running += running;
    total.failed += failed;
  }
  return total;
};

// Folds the records of one `json-log-path` file into a Progress snapshot.
export class Tracker {
  private phase: Progress["phase"] = "eval";
  private outputs = 0;
  private failed = 0;
  private hasError = false;
  private evaluating: string | null = null;
  private readonly types = new Map<number, number>();
  private readonly builds = new Map<number, number[]>();
  private readonly downloads = new Map<number, number[]>();
  private readonly building = new Map<number, string>();

  constructor(private readonly total: number | null) {}

  get checked(): number {
    return this.outputs;
  }

  // Whether every output checked so far passed and nix reported no error.
  get isClean(): boolean {
    return this.failed === 0 && !this.hasError;
  }

  line(text: string): void {
    let record: LogRecord;
    try {
      record = JSON.parse(text);
    } catch {
      return;
    }
    const id = record.id ?? -1;

    switch (record.action) {
      case "start": {
        this.types.set(id, record.type ?? 0);
        const what = record.text ?? "";
        if (record.type === ACT_BUILD) {
          const name = /^building '\/nix\/store\/[a-z0-9]+-(.+)\.drv'/.exec(what)?.[1];
          this.building.set(id, name ?? what);
        } else if (what.startsWith("evaluating ")) {
          this.evaluating = what;
        } else if (/^running \d+ flake checks?$/.test(what)) {
          this.phase = "build";
        }
        break;
      }
      case "stop": {
        this.building.delete(id);
        // Nix's expected count can overshoot (8 checks reported as x/9), so a
        // finished group counts as complete.
        const tallies = this.types.get(id) === ACT_BUILDS ? this.builds : this.downloads;
        const [done = 0, , , failed = 0] = tallies.get(id) ?? [];
        if (tallies.has(id)) tallies.set(id, [done, done + failed, 0, failed]);
        break;
      }
      case "result": {
        if (record.type !== RES_PROGRESS || !Array.isArray(record.fields)) {
          break;
        }
        const fields = record.fields.map(Number);
        const type = this.types.get(id);
        if (type === ACT_BUILDS) this.builds.set(id, fields);
        if (type === ACT_COPY_PATHS) this.downloads.set(id, fields);
        break;
      }
      case "msg": {
        const msg = (record.msg ?? "").replace(ANSI, "");
        if (msg.startsWith("✅") || msg.startsWith("❓")) this.outputs += 1;
        if (msg.startsWith("❌")) {
          this.outputs += 1;
          this.failed += 1;
        }
        if (record.level === 0 && msg.startsWith("error")) this.hasError = true;
        break;
      }
    }
  }

  snapshot(): Progress {
    const [current, ...others] = this.building.values();
    const activity =
      current === undefined
        ? this.phase === "eval"
          ? this.evaluating
          : null
        : others.length > 0
          ? `building ${current} (+${others.length} more)`
          : `building ${current}`;

    return {
      phase: this.phase,
      outputs: this.outputs,
      failed: this.failed,
      total: this.total,
      builds: sum(this.builds.values()),
      downloads: sum(this.downloads.values()),
      activity,
    };
  }
}

// Splits streamed text into whole lines, holding a partial last line back.
export class Lines {
  private rest = "";

  push(text: string): string[] {
    const lines = (this.rest + text).split("\n");
    this.rest = lines.pop() ?? "";
    return lines;
  }
}

export const bar = (ratio: number, width: number): string => {
  const filled = Math.round(Math.min(Math.max(ratio, 0), 1) * width);
  return "█".repeat(filled) + "░".repeat(width - filled);
};

const unquote = (word: string) => word.replace(/^(['"])(.*)\1$/, "$2");

// Names the flake a command checks: the directory a `cd` before the check
// moves to (else `cwd`), plus the flake argument when one is given.
export const flakeKey = (cwd: string, command: string): string => {
  const check = findCheck(command);
  if (check === undefined) {
    return cwd;
  }

  let dir = cwd;
  const before = command.slice(0, check.start);
  for (const [, target = ""] of before.matchAll(
    /(?:^|[;&|(])\s*cd\s+("[^"]*"|'[^']*'|[^\s;&|)]+)/g,
  )) {
    const path = unquote(target);
    dir = path.startsWith("/") ? path : `${dir}/${path}`;
  }

  const args = command.slice(check.end).split(/[;&|<>\n]/, 1)[0] ?? "";
  const ref = args
    .trim()
    .split(/\s+/)
    .map(unquote)
    .find((word) => /^(\.|\/|~|[a-z+]+:)/.test(word));
  return ref === undefined ? dir : `${dir} ${ref}`;
};
