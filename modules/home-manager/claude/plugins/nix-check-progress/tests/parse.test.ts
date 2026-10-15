import { expect, test } from "claude-code/testing";

import { Tracker } from "../hooks/parse";

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
