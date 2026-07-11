---
description: Stage thread changes, then generate and confirm a Conventional Commit
---

Write a short, clear commit message following the Conventional Commits specification.

Before writing the message:

1. Inspect the Git status and both staged and unstaged changes, including untracked files.
2. Review the thread history to identify the files and hunks changed as part of the work performed in this thread.
3. Stage only those changes. Do not use `git add -A`, `git add .`, or another command that could stage unrelated changes. If a file contains both thread-related and unrelated changes, stage only the relevant hunks with a non-interactive patch.
4. Inspect the resulting staged Git diff and verify that every staged change belongs to this thread. Preserve unrelated worktree changes.
5. Use the thread history to understand the user's intent, relevant decisions, and why the staged changes were made.

Do not alter unrelated changes that were already staged before this command. If the existing staged diff contains unrelated changes, or if you cannot confidently distinguish thread-related changes from unrelated changes, use the question tool to ask the user how to proceed rather than guessing or modifying the index.

Treat the staged diff as the source of truth for what changed. Use the thread history only to improve the description and capture important rationale; do not describe changes that are not present in the staged diff.

Prefer a message containing only the subject line. Include a message body only when the staged diff or thread history contains important context that cannot fit clearly in the subject. Do not repeat information from the subject in the body.

Do not include meta-commentary or raw diff output in the commit message.

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

If there are no changes attributable to this thread, report `No changes from this thread to commit` and stop.

After generating the message:

1. Use the question tool to show the complete proposed commit message and ask the user to choose `Accept` or `Reject`.
2. If the user rejects it, do not create a commit or unstage the changes. Report that the commit was cancelled and stop.
3. If the user accepts it, check whether there are new or modified changes attributable to this thread since the message was generated. Ignore unrelated changes made concurrently by the user or another agent. Only if related changes appeared, repeat the thread-scoped staging process for those changes, generate a new message, and ask for confirmation again.
4. Commit the staged changes using the exact accepted message. Do not amend an existing commit, bypass hooks, or push.
5. Report whether the commit succeeded. If it failed, include the relevant Git error and do not retry with hooks disabled.
