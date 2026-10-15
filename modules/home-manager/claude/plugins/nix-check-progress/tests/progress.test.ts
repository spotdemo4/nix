import { expect, mock, test } from "claude-code/testing";

const record = (r: object) => `${JSON.stringify(r)}\n`;

// A shortened check: one output evaluated, two builds of which one is done.
const LOG = [
  record({ action: "start", id: 1, level: 3, text: "evaluating 'checks.x86_64-linux'", type: 0 }),
  record({
    action: "msg",
    level: 2,
    msg: "✅ \u001b[1mformatter.x86_64-linux\u001b[0m (build skipped)",
  }),
  record({ action: "start", id: 2, level: 3, text: "running 2 flake checks", type: 0 }),
  record({ action: "start", id: 3, level: 0, text: "", type: 104 }),
  record({
    action: "start",
    id: 4,
    level: 3,
    text: "building '/nix/store/abc123-check-format.drv'",
    type: 105,
  }),
  record({ action: "result", id: 3, type: 105, fields: [1, 2, 1, 0] }),
].join("");

const BASH_RESULT = { stdout: "exit: 0", stderr: "", interrupted: false };

test("draws progress under a running nix flake check and cleans up", async ($, on) => {
  mock.store(on, { "total:/repo": 4 });
  mock.env(on, { TMPDIR: "/tmp/t" });
  const clock = mock.clock(on);

  let removed: () => void = () => {};
  const isRemoved = new Promise<void>((resolve) => (removed = resolve));
  const written: string[] = [];
  const ran: string[][] = [];
  let command = "";
  let drawn = "";

  on("session.cwd", () => ({ value: "/repo" }));
  on("fs.write", (_, e) => {
    written.push(e.path);
    return { value: undefined };
  });
  on("process.run", (_, e) => {
    ran.push([...e.argv]);
    removed();
    return {
      value: {
        exitCode: 0,
        stdout: "",
        stderr: "",
        isStdoutTruncated: false,
        isStderrTruncated: false,
      },
    };
  });
  on("process.spawn", async function* () {
    yield { stream: "stdout" as const, text: LOG.slice(0, 200) };
    yield { stream: "stdout" as const, text: LOG.slice(200) };
    await isRemoved;
    yield { stream: "stderr" as const, text: "tail: file has become inaccessible\n" };
    return { value: { code: null, signal: "SIGTERM" } };
  });
  on("tool.call", { tool: "Bash" }, async (_, e) => {
    command = e.command;
    await clock.sleep(600);
    const ui = await $.ui.mount({
      plugin: "nix-check-progress",
      surface: "terminal",
      component: "ToolProgress",
      requestId: e.tool_use_id,
      props: {
        tool_use_id: e.tool_use_id,
        kind: "background_hint",
        hint: "(ctrl+b to run in background)",
      },
    });
    drawn = (await ui.findAll({ type: "Text" })).map((t) => t.text).join("\n");
    await ui.unmount();
    return { result: BASH_RESULT };
  });

  const call = $.tool.call({ tool: "Bash", command: "nix flake check -L" });
  await clock.advance(600);
  await clock.advance(3000);
  await call;

  const path = written[0] ?? "";
  expect(path).toMatch(/^\/tmp\/t\/nix-check-progress-.+\.jsonl$/);
  expect(command).toBe(`nix flake check --option json-log-path '${path}' -L`);
  expect(drawn).toContain("1/4 outputs");
  expect(drawn).toContain("builds 1/2 (1 running)");
  expect(drawn).toContain("building check-format");
  expect(drawn).toContain("(ctrl+b to run in background)");
  expect(ran).toEqual([["rm", "-f", path]]);
});

test("leaves other Bash commands alone", async ($, on) => {
  let command = "";
  on("tool.call", { tool: "Bash" }, (_, e) => {
    command = e.command;
    return { result: BASH_RESULT };
  });

  await $.tool.call({ tool: "Bash", command: "nix flake show" });
  await $.tool.call({ tool: "Bash", command: "nix flake check", run_in_background: true });

  expect(command).toBe("nix flake check");
});
