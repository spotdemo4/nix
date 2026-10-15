export type Tally = { done: number; expected: number; running: number; failed: number };

export type Progress = {
  phase: "eval" | "build";
  // Outputs nix reported as checked (✅) or failed (❌).
  outputs: number;
  failed: number;
  // Outputs the last successful check of the same flake reported, if known.
  total: number | null;
  builds: Tally;
  downloads: Tally;
  // What nix is doing right now, e.g. "evaluating 'checks.x86_64-linux'".
  activity: string | null;
};

declare module "claude-code" {
  interface PluginState {
    "nix-check-progress": { runs: StateFamily<Progress | null> };
  }
}
