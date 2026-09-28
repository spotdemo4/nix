---
name: ship
description: Commit the current changes on a branch, open a pull request with auto-merge, and follow it until it merges or CI fails
disable-model-invocation: true
argument-hint: "[optional notes for the commit or PR]"
---

Ship the current changes as a pull request and see it through to merge.

The repo's own instructions (`AGENTS.md`, `CLAUDE.md`, contributing guides) take precedence over the defaults below. Follow any rules they give for branch names, commit messages, commit trailers, merge methods, and checks that must pass before work is done.

For a `github.com` remote, use `gh`. For any other remote, assume Forgejo and use the forgejo MCP tools.

1. Inspect the repo with `git status`, `git diff`, and `git log --oneline -10`. If there is nothing to commit and no unpushed commits, stop and say so.
2. If on the default branch, create a branch for the change. Otherwise stay on the current branch. Without repo rules, use a short, descriptive name.
3. Run any checks the repo requires before work is done, and fix failures before continuing.
4. Stage the changes that belong to this work and commit them. Without repo rules, match the commit message style from `git log`.
5. Push the branch with upstream tracking.
6. Open a pull request against the default branch, unless one is already open for this branch, in which case the push updates it. If the repo has a pull request template, follow it for the description. Share the PR URL.
7. Enable auto-merge on the PR. Without repo rules, use the repo's default merge method (`viewerDefaultMergeMethod` from `gh repo view`, or `default_merge_style` from the Forgejo repo).
   - GitHub: `gh pr merge <pr> --auto` with the matching `--squash`, `--merge`, or `--rebase` flag.
   - Forgejo: merge with `merge_when_checks_succeed` set.
   - If auto-merge can't be enabled, stop and report why. Don't merge directly instead.
8. Wait until the PR merges, closes, or a CI check fails. CI can outlast a foreground command's timeout, so wait in the background rather than blocking.
   - GitHub: `gh pr checks <pr> --watch --fail-fast`, then confirm the PR state with `gh pr view <pr> --json state,mergeStateStatus`.
   - Forgejo: check the PR and its workflow runs with the forgejo MCP tools.
   - If the checks pass but the PR still doesn't merge (for example it needs a review or has conflicts), stop and report what it is waiting on.
9. Once merged, switch to the default branch, run `git pull --ff-only`, and confirm the merged commit is present locally. Then delete the local PR branch with `git branch -d`. Squash and rebase merges make `-d` refuse, so in that case use `-D`, but only after confirming the local branch tip matches the PR's merged head commit, so no unshipped commits are lost.
10. If CI fails, investigate: read the failed job logs (`gh run view <run-id> --log-failed`, or the forgejo action job log tools), find the root cause, and report it with a suggested fix. Don't push a fix without the user's go-ahead, since auto-merge is still enabled and would merge it once CI passes.

Additional notes from the user: $ARGUMENTS
