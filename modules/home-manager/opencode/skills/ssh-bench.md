---
name: ssh-bench
description: Use when the user asks for ssh bench, the benchmark server, benchmarking, performance comparisons, profiling runs, or timing results that must separate building from measurement.
---

# SSH Bench Server

Use `ssh bench` for benchmark and profiling measurements. Keep all build, dependency setup, and synchronization work outside the timed benchmark command.

## When To Use

- Benchmarks, profiling, timing comparisons, regression checks, or performance investigations.
- Work where local machine load, thermals, background tasks, or hardware differences would make results noisy.
- Requests that need build artifacts measured without including compile time in the benchmark.

## Principle

Separate the work into two phases:

1. Build or prepare artifacts before measuring. Use `ssh build` for expensive builds when appropriate.
2. Run only the benchmark command on `ssh bench`, after the artifact and inputs are already present.

## Workflow

1. Verify the benchmark host and record context:

   ```sh
   ssh bench 'hostname; nproc; uptime'
   ```

2. Check local and remote tree state before comparing results:

   ```sh
   git status --short
   remote_dir=$(printf '%q' "$PWD")
   ssh bench "test -d $remote_dir && git -C $remote_dir status --short"
   ```

3. Build outside the timed benchmark. For expensive builds, prefer the build host:

   ```sh
   remote_dir=$(printf '%q' "$PWD")
   ssh build "cd $remote_dir && nix build .#target"
   ```

4. Make the benchmark artifact available on `bench` before measuring. Use the project's normal artifact path, binary cache, Nix store copy, or a tightly scoped file sync. Do not copy secrets or unrelated files.

5. Run setup and warmup separately from the measured command:

   ```sh
   remote_dir=$(printf '%q' "$PWD")
   ssh bench "cd $remote_dir && ./result/bin/tool --version"
   ```

6. Run the measured benchmark on `bench` only after the build and setup are complete:

   ```sh
   remote_dir=$(printf '%q' "$PWD")
   ssh bench "cd $remote_dir && hyperfine './result/bin/tool input'"
   ```

7. Report benchmark context with the result: `bench` host, command, commit or tree state, artifact source, CPU count, warmup/setup notes, and whether the tree was dirty.

## Guardrails

- Do not include compilation, dependency installation, cache population, or file transfer in the measured command unless the user explicitly wants end-to-end timing.
- Do not benchmark on `build`; use it only for preparation work.
- Do not assume uncommitted local changes exist on `bench`. Check or sync intentionally.
- Prefer repeated runs with warmups for timing-sensitive comparisons.
- Keep the benchmark machine as idle as practical and mention obvious load or environmental noise in the result.
