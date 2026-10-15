import type { Progress, Tally } from "../types";

// Activity and result types from nix's internal-json log format.
const ACT_COPY_PATHS = 103;
const ACT_BUILDS = 104;
const ACT_BUILD = 105;
const RES_PROGRESS = 105;

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
