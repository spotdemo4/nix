import type { Plugin, PluginOptions } from "@opencode-ai/plugin";
import { spawn } from "node:child_process";

const MAX_OUTPUT_BYTES = 10 * 1024 * 1024;
const DEFAULT_TIMEOUT_MS = 120_000;
const MAX_TIMEOUT_MS = 2_147_483_647;

type DirenvExport = Record<string, string | null>;

type DirenvState = {
  env: NodeJS.ProcessEnv;
  envrc?: string;
};

type RunResult = {
  code: number | null;
  error?: NodeJS.ErrnoException;
  stderr: string;
  stdout: string;
};

function runDirenv(
  binary: string,
  cwd: string,
  env: NodeJS.ProcessEnv,
  timeoutMs: number,
): Promise<RunResult> {
  return new Promise((resolve) => {
    const child = spawn(binary, ["export", "json"], {
      cwd,
      detached: process.platform !== "win32",
      env,
      stdio: ["ignore", "pipe", "pipe"],
    });
    const stdout: Buffer[] = [];
    const stderr: Buffer[] = [];
    let outputBytes = 0;
    let settled = false;
    let killTimeout: NodeJS.Timeout | undefined;

    const kill = (signal: NodeJS.Signals) => {
      if (child.pid && process.platform !== "win32") {
        try {
          process.kill(-child.pid, signal);
          return;
        } catch {
          // Fall back to the direct child if its process group already exited.
        }
      }
      child.kill(signal);
    };

    const finish = (result: RunResult) => {
      if (settled) return;
      settled = true;
      clearTimeout(timeout);
      if (killTimeout) clearTimeout(killTimeout);
      resolve(result);
    };
    const collect = (chunks: Buffer[], chunk: Buffer) => {
      outputBytes += chunk.length;
      if (outputBytes > MAX_OUTPUT_BYTES) {
        kill("SIGKILL");
        return;
      }
      chunks.push(chunk);
    };
    const timeout = setTimeout(() => {
      kill("SIGTERM");
      killTimeout = setTimeout(() => kill("SIGKILL"), 5000);
    }, timeoutMs);

    child.stdout.on("data", (chunk: Buffer) => collect(stdout, chunk));
    child.stderr.on("data", (chunk: Buffer) => collect(stderr, chunk));
    child.on("error", (error: NodeJS.ErrnoException) => {
      finish({ code: null, error, stderr: Buffer.concat(stderr).toString(), stdout: "" });
    });
    child.on("close", (code) => {
      const result = {
        code,
        stderr: Buffer.concat(stderr).toString(),
        stdout: Buffer.concat(stdout).toString(),
      };
      if (killTimeout) {
        finish({
          ...result,
          error: Object.assign(new Error(`direnv export timed out after ${timeoutMs} ms`), {
            code: "ETIMEDOUT",
          }),
        });
        return;
      }
      if (outputBytes > MAX_OUTPUT_BYTES) {
        finish({
          ...result,
          error: Object.assign(new Error("direnv output exceeded 10 MiB"), { code: "EOVERFLOW" }),
        });
        return;
      }
      finish(result);
    });
  });
}

function parseExport(stdout: string): DirenvExport | undefined {
  if (!stdout.trim()) return {};
  const value: unknown = JSON.parse(stdout);
  if (!value || typeof value !== "object" || Array.isArray(value)) return;

  const result: DirenvExport = {};
  for (const [key, entry] of Object.entries(value)) {
    if (typeof entry !== "string" && entry !== null) return;
    result[key] = entry;
  }
  return result;
}

export default (async ({ client, directory }, options?: PluginOptions) => {
  const binary = typeof options?.direnvBinary === "string" ? options.direnvBinary : "direnv";
  const timeoutMs =
    typeof options?.timeoutMs === "number" &&
    Number.isFinite(options.timeoutMs) &&
    options.timeoutMs > 0 &&
    options.timeoutMs <= MAX_TIMEOUT_MS
      ? options.timeoutMs
      : DEFAULT_TIMEOUT_MS;
  const states = new Map<string, DirenvState>();
  const refreshes = new Map<string, Promise<DirenvState | undefined>>();
  const notifiedBlocked = new Set<string>();
  const notifiedFailures = new Set<string>();
  const notifiedLoaded = new Set<string>();

  const log = async (level: "info" | "warn", message: string) => {
    await client.app.log({ body: { service: "direnv", level, message } }).catch(() => undefined);
  };
  const notify = async (variant: "info" | "warning", message: string) => {
    await client.tui
      .showToast({
        body: { title: "direnv", message, variant, duration: 6000 },
        query: { directory },
      })
      .catch(() => undefined);
  };

  const refresh = async (cwd: string) => {
    const previous = states.get(cwd);
    const env = { ...(previous?.env ?? process.env) };
    const result = await runDirenv(binary, cwd, env, timeoutMs);
    if (result.error?.code === "ENOENT") return previous;

    let exported: DirenvExport | undefined;
    try {
      exported = parseExport(result.stdout);
    } catch {
      exported = undefined;
    }

    if (exported) {
      for (const [key, value] of Object.entries(exported)) {
        if (value === null) delete env[key];
        else env[key] = value;
      }
    }

    const envrc = env.DIRENV_FILE;
    const state = { env, ...(envrc ? { envrc } : {}) };
    if (exported) states.set(cwd, state);

    if (result.code === 0 && exported) {
      notifiedBlocked.delete(cwd);
      notifiedFailures.delete(cwd);
      if (envrc && !notifiedLoaded.has(envrc)) {
        notifiedLoaded.add(envrc);
        await log("info", `Loaded ${envrc}`);
        await notify("info", "Environment loaded");
      }
      return state;
    }

    if (/\b(blocked|not allowed)\b/i.test(result.stderr)) {
      if (!notifiedBlocked.has(cwd)) {
        notifiedBlocked.add(cwd);
        await notify("warning", ".envrc is blocked; run `direnv allow` to enable it");
      }
      return exported ? state : previous;
    }

    if (!notifiedFailures.has(cwd)) {
      notifiedFailures.add(cwd);
      const detail = result.error?.message || `direnv export exited with ${result.code}`;
      await log("warn", `${detail} in ${cwd}`);
    }
    return exported ? state : previous;
  };

  const refreshOnce = async (cwd: string) => {
    const pending = refreshes.get(cwd);
    if (pending) return pending;

    const next = refresh(cwd).finally(() => {
      if (refreshes.get(cwd) === next) refreshes.delete(cwd);
    });
    refreshes.set(cwd, next);
    return next;
  };

  return {
    "shell.env": async ({ cwd }, output) => {
      const state = await refreshOnce(cwd);
      if (!state) return;

      for (const [key, value] of Object.entries(state.env)) {
        if (value !== undefined && value !== process.env[key]) output.env[key] = value;
      }
    },
  };
}) satisfies Plugin;
