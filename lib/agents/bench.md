## Benchmark host

`ssh bench` reaches a dedicated x86_64-linux benchmarking machine with isolated cores and fixed clocks. Use it for any performance measurement or comparison instead of timing things locally, where results are noisy. Before using it, read the output of `ssh bench bench-run --help`: it explains how to copy builds there with `nix copy` and how to run benchmarks without disturbing other jobs.
