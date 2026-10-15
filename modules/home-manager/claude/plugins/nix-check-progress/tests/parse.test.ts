import { expect, test } from "claude-code/testing";

import { Tracker, findCheck, flakeKey } from "../hooks/parse";

const feed = (tracker: Tracker, records: object[]) => {
  for (const record of records) tracker.line(JSON.stringify(record));
};

test("a finished builds group counts as complete when nix overshot", () => {
  const tracker = new Tracker(null);
  feed(tracker, [
    { action: "start", id: 1, type: 104, text: "" },
    { action: "result", id: 1, type: 105, fields: [8, 9, 0, 0] },
  ]);
  expect(tracker.snapshot().builds).toEqual({ done: 8, expected: 9, running: 0, failed: 0 });

  feed(tracker, [{ action: "stop", id: 1 }]);
  expect(tracker.snapshot().builds).toEqual({ done: 8, expected: 8, running: 0, failed: 0 });
});

test("failed and cancelled outputs count as checked", () => {
  const tracker = new Tracker(null);
  feed(tracker, [
    { action: "msg", level: 2, msg: "❓ \u001b[1mchecks.x86_64-linux.slow\u001b[0m (cancelled)" },
    { action: "msg", level: 0, msg: "❌ \u001b[31;1mchecks.x86_64-linux.bad\u001b[0m" },
    { action: "msg", level: 0, msg: "\u001b[31;1merror:\u001b[0m Cannot build 'bad.drv'." },
  ]);
  expect(tracker.snapshot()).toMatchObject({ outputs: 2, failed: 1 });
  expect(tracker.isClean).toBe(false);
});

test("keys the total on the directory and flake the check runs in", () => {
  expect(flakeKey("/elsewhere", 'cd /repo && log=$(mktemp); nix flake check -L >"$log" 2>&1')).toBe(
    "/repo",
  );
  expect(flakeKey("/repo", "nix flake check")).toBe("/repo");
  expect(flakeKey("/repo", "cd sub && nix flake check")).toBe("/repo/sub");
  expect(flakeKey("/home", 'nix flake check --impure path:/tmp/demo >"$log"')).toBe(
    "/home path:/tmp/demo",
  );
});

const found = (command: string) => {
  const check = findCheck(command);
  return check === undefined ? undefined : command.slice(check.start, check.end);
};

test("finds the check where it runs as a command", () => {
  expect(found("nix flake check")).toBe("nix flake check");
  expect(found('cd /repo && log=$(mktemp); nix flake check -L >"$log" 2>&1')).toBe(
    "nix flake check",
  );
  expect(found("FOO=1 time nix  flake check")).toBe("nix  flake check");
  expect(found("if true; then nix flake check; fi")).toBe("nix flake check");
  expect(found("cat <<'EOF' >notes\nnix flake check\nEOF\nnix flake check -L")).toBe(
    "nix flake check",
  );
  expect(findCheck("cat <<'EOF' >notes\nnix flake check\nEOF\nnix flake check -L")?.start).toBe(39);
});

test("leaves commands that only mention the check alone", () => {
  expect(findCheck('git commit -m "run nix flake check first"')).toBeUndefined();
  expect(findCheck("git commit -m 'nix flake check'")).toBeUndefined();
  expect(findCheck("echo nix flake check")).toBeUndefined();
  expect(findCheck("cat <<EOF >AGENTS.md\nnix flake check\nEOF")).toBeUndefined();
  expect(findCheck("true # then nix flake check")).toBeUndefined();
  expect(findCheck("grep -rn nix flake check .")).toBeUndefined();
});
