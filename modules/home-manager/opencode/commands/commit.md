---
description: Create confirmed atomic commits for uncommitted thread changes
model: openai/gpt-5.3-codex-spark
subtask: true
---

Create one or more short, clear Git commits following the Conventional Commits specification.

## Discover And Classify

Before staging anything:

1. Inspect the Git status and both staged and unstaged changes, including untracked files.
2. Inspect the recent commit history and relevant commit diffs with `git log` and `git show`.
3. Review the parent thread history supplied at the end of this prompt to identify the files, hunks, intent, and prior commits associated with work performed in this thread.
4. Classify the thread-related work into changes already committed and reachable from `HEAD`, related changes that remain uncommitted, and unrelated concurrent changes.

Verify that any commit attributed to this thread is reachable from `HEAD` and that its diff matches the work described in the thread. Do not treat a commit as related based only on a similar message. If a prior commit was rebased or squashed, use its actual reachable replacement when it can be identified confidently.

Only current staged, unstaged, or untracked changes are candidates for new commits. Never recreate a change that is already committed. Treat the Git diffs as the source of truth for what remains uncommitted and use the thread history to determine attribution, intent, and rationale.

Do not alter unrelated changes that were already staged before this command. Git commits the entire index, so do not proceed while unrelated staged content remains. Use the question tool to identify the conflicting staged paths or hunks and ask the user whether to cancel or explicitly allow those changes to be unstaged without modifying the worktree. Never unstage them automatically. If attribution is ambiguous, ask the user rather than guessing.

If no thread-related changes remain uncommitted:

- If related work is already committed, report `All changes from this thread are already committed`, include the relevant commit hashes and subjects, and stop.
- Otherwise, report `No changes from this thread to commit` and stop.

## Plan Atomic Commits

Partition the uncommitted thread-related hunks into one or more atomic commit groups. Use a single commit when all changes serve one coherent purpose. Split changes when they have independent intent, different Conventional Commit types or scopes, or can be reviewed and reverted independently.

Keep directly coupled changes together:

- Keep tests with the implementation they verify.
- Keep required documentation, generated output, migrations, and formatting with the change that requires them.
- Keep mechanical or prerequisite changes with their dependent change unless they remain useful and valid independently.

Every related uncommitted hunk must belong to exactly one group. Do not include unrelated hunks. Order groups so prerequisites are committed before dependent changes.

Before changing the index, show the proposed sequence with a concise purpose, expected files or hunks, and proposed commit message for each group. The user will approve each commit individually during execution; do not ask for separate approval of the overall plan. If the pending groups change materially during execution, show the revised sequence before staging the next affected group.

## Commit Message Rules

Prefer a message containing only the subject line. Include a message body only when the staged diff or thread history contains important context that cannot fit clearly in the subject. Do not repeat information from the subject in the body. Do not include meta-commentary or raw diff output in the commit message.

Follow these Conventional Commit and Git style rules:

- Use the subject format `type[optional scope][!]: description`.
- Use one of these types:
  - `feat`: a new feature.
  - `fix`: a bug fix.
  - `refactor`: a code change that neither fixes a bug nor adds a feature.
  - `docs`: documentation-only changes.
  - `style`: changes that do not affect the meaning of the code, such as formatting or whitespace.
  - `test`: adding or correcting tests.
  - `perf`: a code change that improves performance.
  - `ci`: changes to CI configuration files and scripts.
  - `build`: changes that affect the build system or external dependencies.
  - `chore`: other changes that do not modify source or test files.
- Optionally include a scope in parentheses after the type, such as `feat(auth):` or `fix(api):`.
- Append `!` after the type or scope for a breaking change, such as `feat(api)!:` or `refactor!:`.
- Start the description after the colon with a lowercase letter.
- Use the imperative mood.
- Keep the subject line at 65 characters or fewer.
- Do not end the subject line with punctuation.
- Separate the subject from the body with a blank line.
- Keep the body short and concise, and do not hard-wrap it.
- For a breaking change, use `!` in the subject, a `BREAKING CHANGE:` footer, or both.

## Execute The Plan

Process the proposed groups in order. Before each group, refresh the status, relevant diffs, and recent history because another user or agent may have changed or committed work concurrently.

For each group:

1. Reclassify its remaining hunks. If they are already committed, skip the group, record the reachable commit, and continue. If they changed materially or no longer form the same atomic unit, update and show the pending plan before proceeding.
2. Stage only the exact files or hunks in this group. Do not use `git add -A`, `git add .`, or another command that could stage unrelated changes. Use a non-interactive patch when a file contains changes from multiple groups or unrelated work.
3. If thread-related changes were already staged and must be split across groups, unstage only the relevant hunks without modifying the worktree, then stage the current group. Never unstage or discard unrelated work without explicit user approval.
4. Inspect the complete staged diff and verify that every staged hunk belongs to this group and that every intended hunk in the group is staged. Record the proposed tree with `git write-tree` and the expected parent with `git rev-parse HEAD`.
5. Generate the exact commit message from this staged diff, using the thread history only for intent and important rationale.
6. Show the exact staged patch, proposed tree hash, expected parent hash, and complete proposed message, then use the question tool to ask the user to choose `Accept` or `Reject`. Acceptance applies only to that patch, tree, parent, and message.
7. If the user rejects it, do not create a commit or unstage the current group. Report that the sequence was cancelled, list any commits already created, and stop.
8. If the user accepts it, check for new or modified thread-related changes since the message was generated. If they belong to the current group, stage them and return to step 4 to regenerate and reconfirm the patch, tree, and message. If they belong to a later or new group, leave them unstaged and update the pending plan after the current commit. Ignore unrelated worktree changes.
9. Immediately before committing, inspect the complete staged diff again and verify that every staged change was part of the accepted proposal. Recompute `git write-tree` and `git rev-parse HEAD` and require both to equal the accepted tree and parent hashes. If either differs, do not commit. Reconfirm only when the difference is thread-related; if unrelated staged content or a concurrent commit appeared, reclassify the work and show the updated plan without repeating the staging process unnecessarily.
10. In one shell invocation, compare the current index tree and `HEAD` to the accepted hashes and, only if both still match, run `git commit` using the exact accepted message. This narrows the opportunity for concurrent index or history changes. Do not amend an existing commit, bypass hooks, or push.
11. After committing, verify that the new commit's tree, parent, and message equal the accepted values. If the commit fails or any value differs, report the relevant error or mismatch, do not amend or retry with hooks disabled, list any commits already created, and stop.
12. Record the new commit hash and subject, then continue with the next pending group.

After processing all groups, report the commits created, related commits that already existed, and any thread-related changes that remain uncommitted. Do not claim success for a group unless its commit was actually created.
