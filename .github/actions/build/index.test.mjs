import assert from "node:assert/strict";
import test from "node:test";

import { normalizeGraph, parseBuildPlan, pruneGraph, queryBuildPlan } from "./index.mjs";

test("normalizes versioned derivation JSON", () => {
  const graph = normalizeGraph({
    version: 4,
    derivations: {
      "aaaaaaaa-root.drv": {
        inputs: {
          drvs: {
            "bbbbbbbb-input.drv": { outputs: ["out"] },
          },
        },
      },
      "bbbbbbbb-input.drv": {
        inputs: { drvs: {} },
      },
    },
  });

  assert.deepEqual(Object.keys(graph), [
    "/nix/store/aaaaaaaa-root.drv",
    "/nix/store/bbbbbbbb-input.drv",
  ]);
  assert.deepEqual(Object.keys(graph["/nix/store/aaaaaaaa-root.drv"].inputDrvs), [
    "/nix/store/bbbbbbbb-input.drv",
  ]);
});

test("prunes assembly derivations and their dependents", () => {
  const graph = {
    "/store/root.drv": {
      inputDrvs: {
        "/store/system-path.drv": {},
        "/store/service.drv": {},
      },
    },
    "/store/wrapper.drv": {
      inputDrvs: {
        "/store/etc.drv": {},
      },
    },
    "/store/system-path.drv": {
      inputDrvs: {
        "/store/package.drv": {},
      },
    },
    "/store/etc.drv": {
      inputDrvs: {
        "/store/config-file.drv": {},
      },
    },
    "/store/service.drv": {
      inputDrvs: {
        "/store/package.drv": {},
      },
    },
    "/store/package.drv": { inputDrvs: {} },
    "/store/config-file.drv": { inputDrvs: {} },
  };

  const { candidates, excluded } = pruneGraph(graph, [
    "/store/root.drv",
    "/store/system-path.drv",
    "/store/etc.drv",
  ]);

  assert.deepEqual(candidates, [
    "/store/service.drv",
    "/store/package.drv",
    "/store/config-file.drv",
  ]);
  assert.deepEqual([...excluded].sort(), [
    "/store/etc.drv",
    "/store/root.drv",
    "/store/system-path.drv",
    "/store/wrapper.drv",
  ]);
});

test("parses build, fetch, and unknown paths", () => {
  const plan = parseBuildPlan(`warning: example warning
these 2 derivations will be built:
  /nix/store/aaaaaaaa-one.drv
  /nix/store/bbbbbbbb-two.drv
this path will be fetched (1.0 MiB download, 2.0 MiB unpacked):
  /nix/store/cccccccc-input
don't know how to build these paths (may be caused by read-only store access):
  /nix/store/dddddddd-unknown
`);

  assert.deepEqual(plan, {
    willBuild: ["/nix/store/aaaaaaaa-one.drv", "/nix/store/bbbbbbbb-two.drv"],
    willFetch: ["/nix/store/cccccccc-input"],
    unknown: ["/nix/store/dddddddd-unknown"],
    unparsed: [],
  });
});

test("parses singular build output and ignores unrelated lines", () => {
  const plan = parseBuildPlan(`this derivation will be built:
  /nix/store/aaaaaaaa-one.drv
copying path '/nix/store/unrelated' from cache
`);

  assert.deepEqual(plan, {
    willBuild: ["/nix/store/aaaaaaaa-one.drv"],
    willFetch: [],
    unknown: [],
    unparsed: [],
  });
});

test("reports paths under an unknown heading", () => {
  const plan = parseBuildPlan(`a future Nix heading:
  /nix/store/aaaaaaaa-one.drv
`);

  assert.deepEqual(plan.unparsed, ["/nix/store/aaaaaaaa-one.drv"]);
});

function fakePlan(unknown = []) {
  return { willBuild: [], willFetch: [], unknown, unparsed: [] };
}

test("retries unknown paths with fresh cache lookups until they resolve", async () => {
  const results = [fakePlan(["/nix/store/aaaaaaaa-missing"]), fakePlan()];
  const calls = [];
  const sleeps = [];

  const plan = await queryBuildPlan(
    async (options) => {
      calls.push(options);
      return results.shift();
    },
    { delays: [10, 20], sleep: async (ms) => sleeps.push(ms), log: () => {} },
  );

  assert.deepEqual(plan, fakePlan());
  assert.deepEqual(calls, [{ fresh: false }, { fresh: true }]);
  assert.deepEqual(sleeps, [10]);
});

test("returns unknown paths after exhausting retries", async () => {
  let calls = 0;
  const logs = [];

  const plan = await queryBuildPlan(
    async () => {
      calls += 1;
      return fakePlan(["/nix/store/aaaaaaaa-missing"]);
    },
    { delays: [10, 20], sleep: async () => {}, log: (message) => logs.push(message) },
  );

  assert.deepEqual(plan.unknown, ["/nix/store/aaaaaaaa-missing"]);
  assert.equal(calls, 3);
  assert.equal(logs.length, 2);
  assert.match(logs[0], /^::warning::/);
});

test("does not retry when every path is known", async () => {
  let calls = 0;

  await queryBuildPlan(
    async () => {
      calls += 1;
      return fakePlan();
    },
    {
      sleep: async () => assert.fail("should not sleep"),
      log: () => assert.fail("should not log"),
    },
  );

  assert.equal(calls, 1);
});
