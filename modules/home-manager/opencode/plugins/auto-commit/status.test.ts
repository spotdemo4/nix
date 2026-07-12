import { expect, test } from "bun:test";
import { AUTO_COMMIT_SESSION_TITLE } from "./constants";
import { AutoCommitStatusClient } from "./status";

test("tracks auto-commit generation for its parent session", () => {
  const client = new AutoCommitStatusClient();

  client.sessionCreated({
    id: "child",
    parentID: "parent",
    title: AUTO_COMMIT_SESSION_TITLE,
  });
  expect(client.isGenerating("parent")).toBe(true);
  expect(client.isGenerating("other-parent")).toBe(false);

  client.sessionDeleted({ id: "child" });
  expect(client.isGenerating("parent")).toBe(false);
});

test("ignores unrelated and top-level sessions", () => {
  const client = new AutoCommitStatusClient();

  client.sessionCreated({ id: "unrelated", parentID: "parent", title: "Other work" });
  client.sessionCreated({ id: "top-level", title: AUTO_COMMIT_SESSION_TITLE });

  expect(client.isGenerating("parent")).toBe(false);
});

test("keeps each parent active until all of its auto-commit children finish", () => {
  const client = new AutoCommitStatusClient();

  client.sessionCreated({ id: "child-1", parentID: "parent-1", title: AUTO_COMMIT_SESSION_TITLE });
  client.sessionCreated({ id: "child-2", parentID: "parent-1", title: AUTO_COMMIT_SESSION_TITLE });
  client.sessionCreated({ id: "child-3", parentID: "parent-2", title: AUTO_COMMIT_SESSION_TITLE });

  client.sessionDeleted({ id: "child-1" });
  expect(client.isGenerating("parent-1")).toBe(true);
  expect(client.isGenerating("parent-2")).toBe(true);

  client.sessionDeleted({ id: "child-2" });
  expect(client.isGenerating("parent-1")).toBe(false);
  expect(client.isGenerating("parent-2")).toBe(true);

  client.sessionDeleted({ id: "child-3" });
  expect(client.isGenerating("parent-2")).toBe(false);
});

test("clears completed generation without requiring child deletion", () => {
  const client = new AutoCommitStatusClient();

  client.sessionCreated({ id: "child", parentID: "parent", title: AUTO_COMMIT_SESSION_TITLE });
  client.sessionFinished("child");

  expect(client.isGenerating("parent")).toBe(false);
  client.sessionDeleted({ id: "child" });
  expect(client.isGenerating("parent")).toBe(false);
});
