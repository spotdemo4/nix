# shellcheck shell=bash
# Runs at most one CI job from a Forgejo scope, in containers pinned to the cores bench-run
# reserved. Exits 0 when a job ran, 2 when none was waiting, and 1 on errors.
# STATE and BASE_CONFIG are set by the Nix wrapper, BENCH_RUN_CPUS by bench-run, and
# RUNTIME_DIRECTORY by systemd.

# writeShellApplication sets errexit, but command substitutions drop it without this.
shopt -s inherit_errexit

conn=$1
config="$RUNTIME_DIRECTORY/config.yaml"

# JSON is valid YAML. Each worker gets its own cache, since the cache server keeps its
# database locked while the job runs.
jq \
  --arg file "$STATE/$conn/.runner" \
  --arg cache "$STATE/cache/$(basename "$RUNTIME_DIRECTORY")" \
  --arg options "--cpuset-cpus=$BENCH_RUN_CPUS" \
  '.runner.file = $file | .cache.dir = $cache | .container.options = $options' \
  "$BASE_CONFIG" >"$config"

cd "$RUNTIME_DIRECTORY" || exit
# Asking for a job when none is waiting is the common case, so drop its error message
exec forgejo-runner one-job --config "$config" \
  2> >(grep --line-buffered -vx "Error: no task received" >&2)
