---
name: ssh-build
description: Use when the user asks for ssh build, the build server, remote builds, CPU-intensive build tasks, large tests, compile-heavy work, or expensive Nix builds.
---

# SSH Build Server

Use `ssh build` to run CPU-intensive work on the build server instead of the local machine.

## When To Use

- Expensive builds, especially Nix builds, `nix flake check`, or `nix-fast-build`.
- Large test suites, compile-heavy tasks, code generation, compression, or indexing.

## Workflow

1. First verify that the server is reachable and record basic context:

   ```sh
   ssh build 'hostname; nproc; uptime'
   ```

2. Check that the target workspace exists on the server before assuming it does:

   ```sh
   remote_dir=$(printf '%q' "$PWD")
   ssh build "test -d $remote_dir && git -C $remote_dir status --short"
   ```

3. Run the expensive command from the remote workspace:

   ```sh
   remote_dir=$(printf '%q' "$PWD")
   ssh build "cd $remote_dir && nix flake check"
   ```

4. If the user asks for benchmarks or performance comparisons, use the `ssh-bench` skill instead. Keep builds and benchmark measurements separate.

## Guardrails

- Do not copy secrets, credentials, or unrelated private files to the build server.
- Do not assume local uncommitted changes are present remotely. Check `git status --short` locally and remotely when the exact tree matters.
- Prefer running commands in an existing remote checkout. If files must be synchronized, explain why and keep the transfer scoped to the minimum required paths.
- Keep short, interactive, or I/O-bound commands local unless the user explicitly asks to use the build server.
- Do not run timed benchmarks on `build`; use `ssh bench` for measurement work.
