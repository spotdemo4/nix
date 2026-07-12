import { afterEach, describe, expect, test } from "bun:test";
import { chmod, mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import direnvPlugin from "./index";

const directories: string[] = [];

async function createHarness() {
  const root = await mkdtemp(join(tmpdir(), "opencode-direnv-test-"));
  directories.push(root);
  const binary = join(root, "direnv");
  const calls = join(root, "calls");
  const toasts: Array<{ message: string; variant: string }> = [];
  const logs: Array<{ level: string; message: string }> = [];

  await writeFile(
    binary,
    `#!/bin/sh
printf 'call\n' >> '${calls}'
cwd=$(pwd)
case "$cwd" in
  *blocked*)
    printf 'direnv: error %s/.envrc is blocked\n' "$cwd" >&2
    exit 1
    ;;
  *hanging*)
    sleep 60
    ;;
esac
if [ -n "\${FAKE_DIRENV_STATE:-}" ] && [ -f "$cwd/reload" ]; then
  printf '{"PROJECT_NAME":"reloaded"}\n'
elif [ -n "\${FAKE_DIRENV_STATE:-}" ]; then
  printf '{}\n'
else
  printf '{"DIRENV_FILE":"%s/.envrc","FAKE_DIRENV_STATE":"cached","PROJECT_NAME":"%s"}\n' "$cwd" "\${cwd##*/}"
fi
`,
  );
  await chmod(binary, 0o755);

  const client = {
    app: {
      log: async ({ body }: { body: { level: string; message: string } }) => {
        logs.push(body);
        return { data: true };
      },
    },
    tui: {
      showToast: async ({ body }: { body: { message: string; variant: string } }) => {
        toasts.push(body);
        return { data: true };
      },
    },
  };
  const hooks = await direnvPlugin(
    {
      client: client as never,
      directory: root,
      experimental_workspace: { register() {} },
      project: {} as never,
      serverUrl: new URL("http://localhost"),
      worktree: root,
      $: undefined as never,
    },
    { direnvBinary: binary },
  );

  return {
    calls,
    hooks,
    logs,
    root,
    toasts,
  };
}

async function shellEnv(
  hook: NonNullable<Awaited<ReturnType<typeof direnvPlugin>>["shell.env"]>,
  cwd: string,
) {
  const output = { env: {} as Record<string, string> };
  await hook({ cwd }, output);
  return output.env;
}

afterEach(async () => {
  await Promise.all(directories.splice(0).map((directory) => rm(directory, { recursive: true })));
});

describe("direnv shell environments", () => {
  test("keeps cached environments isolated by working directory", async () => {
    const harness = await createHarness();
    const one = join(harness.root, "one");
    const two = join(harness.root, "two");
    await Promise.all([mkdir(one), mkdir(two)]);

    const first = await shellEnv(harness.hooks["shell.env"]!, one);
    const second = await shellEnv(harness.hooks["shell.env"]!, two);
    const cached = await shellEnv(harness.hooks["shell.env"]!, one);

    expect(first.PROJECT_NAME).toBe("one");
    expect(second.PROJECT_NAME).toBe("two");
    expect(cached.PROJECT_NAME).toBe("one");
    expect((await readFile(harness.calls, "utf8")).trim().split("\n")).toHaveLength(3);
    expect(harness.toasts.filter((toast) => toast.variant === "info")).toHaveLength(2);
  });

  test("applies changes returned by direnv's watched-file refresh", async () => {
    const harness = await createHarness();
    const project = join(harness.root, "project");
    await mkdir(project);

    expect((await shellEnv(harness.hooks["shell.env"]!, project)).PROJECT_NAME).toBe("project");
    await writeFile(join(project, "reload"), "");
    expect((await shellEnv(harness.hooks["shell.env"]!, project)).PROJECT_NAME).toBe("reloaded");
  });

  test("warns once while an envrc remains blocked", async () => {
    const harness = await createHarness();
    const blocked = join(harness.root, "blocked");
    await mkdir(blocked);

    expect(await shellEnv(harness.hooks["shell.env"]!, blocked)).toEqual({});
    expect(await shellEnv(harness.hooks["shell.env"]!, blocked)).toEqual({});
    expect(harness.toasts).toEqual([
      expect.objectContaining({
        message: ".envrc is blocked; run `direnv allow` to enable it",
        variant: "warning",
      }),
    ]);
  });

  test("silently skips when direnv is unavailable", async () => {
    const harness = await createHarness();
    const hooks = await direnvPlugin(
      {
        client: {
          app: { log: async () => ({ data: true }) },
          tui: { showToast: async () => ({ data: true }) },
        } as never,
        directory: harness.root,
        experimental_workspace: { register() {} },
        project: {} as never,
        serverUrl: new URL("http://localhost"),
        worktree: harness.root,
        $: undefined as never,
      },
      { direnvBinary: join(harness.root, "missing-direnv") },
    );

    expect(await shellEnv(hooks["shell.env"]!, harness.root)).toEqual({});
  });

  test("terminates a hung direnv refresh", async () => {
    const harness = await createHarness();
    const hanging = join(harness.root, "hanging");
    await mkdir(hanging);
    const hooks = await direnvPlugin(
      {
        client: {
          app: {
            log: async ({ body }: { body: { level: string; message: string } }) => {
              harness.logs.push(body);
              return { data: true };
            },
          },
          tui: { showToast: async () => ({ data: true }) },
        } as never,
        directory: harness.root,
        experimental_workspace: { register() {} },
        project: {} as never,
        serverUrl: new URL("http://localhost"),
        worktree: harness.root,
        $: undefined as never,
      },
      { direnvBinary: join(harness.root, "direnv"), timeoutMs: 50 },
    );

    expect(await shellEnv(hooks["shell.env"]!, hanging)).toEqual({});
    expect(harness.logs.at(-1)?.message).toContain("timed out after 50 ms");
  });
});
