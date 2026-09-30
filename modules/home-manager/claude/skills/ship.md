---
name: ship
description: Commit the current changes on a branch, open a pull request with auto-merge, and follow it until it merges or CI fails
disable-model-invocation: true
argument-hint: "[optional notes for the commit or PR]"
---

Ship the current changes as a pull request and see it through to merge.

The repo's own instructions (`AGENTS.md`, `CLAUDE.md`, contributing guides) take precedence over the defaults below. Follow any rules they give for branch names, commit messages, commit trailers, merge methods, and checks that must pass before work is done.

For a `github.com` remote, use `gh`. For any other remote, assume Forgejo and use the forgejo MCP tools, plus `forgejo-pr-wait` for waiting on the PR.

1. Inspect the repo with `git status`, `git diff`, and `git log --oneline -10`. If there is nothing to commit and no unpushed commits, stop and say so.
2. If on the default branch, create a branch for the change. Otherwise stay on the current branch. Without repo rules, use a short, descriptive name.
3. Run any checks the repo requires before work is done, and fix failures before continuing.
4. Stage the changes that belong to this work and commit them. Without repo rules, match the commit message style from `git log`.
5. Push the branch with upstream tracking.
6. Open a pull request against the default branch, unless one is already open for this branch, in which case the push updates it. If the repo has a pull request template, follow it for the description. Share the PR URL.
7. Enable auto-merge on the PR. Without repo rules, use the repo's default merge method (`viewerDefaultMergeMethod` from `gh repo view`, or `default_merge_style` from the Forgejo repo).
   - GitHub: `gh pr merge <pr> --auto` with the matching `--squash`, `--merge`, or `--rebase` flag.
   - Forgejo: merge with `merge_when_checks_succeed` set. Forgejo schedules this without looking at the checks, and it only acts on the schedule when a check status changes. So if the schedule lands after the checks have finished, it never fires. Step 8 catches that case.
   - If the call errors or times out, it may still have worked. Don't retry blindly, and don't say auto-merge is on until you've confirmed it. Check whether the PR merged, then go on to step 8. On Forgejo, `forgejo-pr-wait` reports whether auto-merge got scheduled, and a retry rejected with 409 means a schedule already exists.
   - If auto-merge can't be enabled, stop and report why. Don't merge directly instead, except in the step 8 cases below.
8. Wait until the PR merges, closes, or a CI check fails. CI can outlast a foreground command's timeout, so wait in the background rather than blocking.
   - GitHub: `gh pr checks <pr> --watch --fail-fast`, then confirm the PR state with `gh pr view <pr> --json state,mergeStateStatus`.
   - Forgejo: `forgejo-pr-wait <pr>` (add `-R owner/repo` if `origin` isn't the PR's repo). It exits 0 once merged, 1 when a check fails, 2 when checks passed or none were reported but the PR still isn't merging, 3 when the PR closed without merging, and 4 when auto-merge was scheduled only after the checks settled, so it will never fire. It prints the details each time, including whether auto-merge is scheduled.
   - On Forgejo exit 4, or exit 2 with `auto-merge: not scheduled` after the step 7 call errored or timed out, merge directly with the same merge style and without `force_merge`. That's what a working auto-merge would have done, and Forgejo still refuses the merge if it needs a review or has conflicts. Don't stop to ask first. Then run `forgejo-pr-wait` again to confirm the merge.
   - If the checks pass but the PR still doesn't merge (for example it needs a review or has conflicts), stop and report what it is waiting on.
9. Once merged, switch to the default branch, run `git pull --ff-only`, and confirm the merged commit is present locally. Then delete the local PR branch with `git branch -d`. Squash and rebase merges make `-d` refuse, so in that case use `-D`, but only after confirming the local branch tip matches the PR's merged head commit, so no unshipped commits are lost.
10. If CI fails, investigate: read the failed job logs (`gh run view <run-id> --log-failed`, or the forgejo action job log tools), find the root cause, and report it with a suggested fix. Don't push a fix without the user's go-ahead, since auto-merge is still enabled and would merge it once CI passes.

Additional notes from the user: $ARGUMENTS
