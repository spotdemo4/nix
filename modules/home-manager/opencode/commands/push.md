---
description: Push the current branch, rebasing and resolving conflicts if needed.
agent: build
subtask: true
---

Push the current Git branch to its configured upstream.

1. Inspect the current branch, status, configured upstream, and recent commits.
2. Run `git push` without force options.
3. If the push is rejected because the remote branch has commits that are not local, fetch the upstream and rebase the current branch onto it. Do not merge.
4. If the rebase has conflicts, inspect each conflict and the relevant surrounding changes, resolve it while preserving both sides' intent, stage the resolved files, and continue the rebase. Repeat until the rebase completes.
5. Run relevant lightweight checks when conflict resolution changed files, then retry `git push` without force options.

Never use `--force`, `--force-with-lease`, destructive reset commands, or discard unrelated working-tree changes. Use `--autostash` when a rebase is blocked by pre-existing tracked changes. If the upstream is missing or checks fail after resolution, report the blocker instead of guessing or pushing broken changes. If a conflict cannot be resolved confidently, abort the rebase before reporting the blocker.
