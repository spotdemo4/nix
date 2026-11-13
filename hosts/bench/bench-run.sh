# shellcheck shell=bash
# Runs a command pinned to free, dedicated benchmark cores.
#
# CI workers share the cores through --ci, and never at the same time as a benchmark:
# - A benchmark holds a shared lock on demand.lock from the moment it starts waiting until
#   it exits. CI only reserves cores while nobody holds it, so CI starts no new jobs once a
#   benchmark is waiting.
# - A benchmark only starts once no core is held by CI, so it waits for running CI jobs.
set -euo pipefail

# physical cores reserved for benchmarks
cores=(@cores@)
# CPU number of a core's second SMT thread, relative to the core
smt_offset="@smtOffset@"
lock_dir="@lockDir@"

# exit status when cores weren't reserved (--ci) or not in time (--timeout)
not_reserved=75

usage() {
  cat <<EOF
Usage: bench-run [-c N] [-t TIME] [--] COMMAND [ARGS...]
       bench-run --status

Runs COMMAND pinned to N dedicated physical cores (both SMT threads of each),
waiting until that many cores are free. The cores stay reserved until COMMAND
and every process that inherited them exit.

CI jobs use the cores while no benchmark needs them. Once a benchmark is
waiting, CI starts no new jobs, and the benchmark starts when the running CI
jobs finish. CI stays paused until every benchmark has exited.

Options:
  -c, --cores N     number of physical cores to reserve (1-${#cores[@]}, default 1)
  -t, --timeout T   give up after T (e.g. 90, 30m, 2h) and exit ${not_reserved}
  -s, --status      show which cores are in use
      --ci          for CI workers: reserve cores only while no benchmark is
                    waiting or running, without waiting; exit ${not_reserved} otherwise
  -h, --help        show this help
EOF
}

lock_file() {
  echo "$lock_dir/core$1.lock"
}

# Serializes reservation attempts, so concurrent attempts don't see each
# other's partial reservations as busy cores.
lock_allocation() {
  exec {allocation_fd}<>"$lock_dir/allocation.lock"
  flock "$allocation_fd"
}

unlock_allocation() {
  exec {allocation_fd}>&-
}

# Succeeds when no benchmark is waiting or running
benchmarks_idle() {
  local fd idle=false
  exec {fd}<>"$lock_dir/demand.lock"
  if flock -n -x "$fd"; then
    idle=true
  fi
  exec {fd}>&-
  $idle
}

# Describes who holds a core, from its lock file and when it was written
holder() {
  local lock
  lock=$(lock_file "$1")
  echo "$(<"$lock") (since $(date -r "$lock" +%H:%M))"
}

status() {
  local core fd
  lock_allocation
  for core in "${cores[@]}"; do
    exec {fd}<"$(lock_file "$core")"
    if flock -n "$fd"; then
      echo "core $core: free"
    else
      echo "core $core: $(holder "$core")"
    fi
    exec {fd}<&-
  done
  if benchmarks_idle; then
    echo "CI: may use free cores"
  else
    echo "CI: paused, a benchmark is waiting or running"
  fi
  unlock_allocation
}

# Converts 90, 90s, 30m or 2h to seconds
parse_duration() {
  [[ $1 =~ ^([0-9]+)([smh]?)$ ]] || return 1
  local n=${BASH_REMATCH[1]}
  case ${BASH_REMATCH[2]} in
  m) n=$((n * 60)) ;;
  h) n=$((n * 3600)) ;;
  esac
  echo "$n"
}

count=1
timeout=
ci=false
while (($#)); do
  case $1 in
  -c | --cores)
    if (($# < 2)); then
      usage >&2
      exit 2
    fi
    count=$2
    shift 2
    ;;
  --cores=*)
    count=${1#*=}
    shift
    ;;
  -t | --timeout)
    if (($# < 2)); then
      usage >&2
      exit 2
    fi
    timeout=$2
    shift 2
    ;;
  --timeout=*)
    timeout=${1#*=}
    shift
    ;;
  --ci)
    ci=true
    shift
    ;;
  -s | --status)
    status
    exit 0
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  --)
    shift
    break
    ;;
  -*)
    echo "bench-run: unknown option: $1" >&2
    usage >&2
    exit 2
    ;;
  *)
    break
    ;;
  esac
done

if (($# == 0)); then
  usage >&2
  exit 2
fi

if [[ ! $count =~ ^[1-9][0-9]*$ ]] || ((count > ${#cores[@]})); then
  echo "bench-run: core count must be between 1 and ${#cores[@]}" >&2
  exit 2
fi

if [[ -n $timeout ]] && ! timeout=$(parse_duration "$timeout"); then
  echo "bench-run: timeout must look like 90, 90s, 30m or 2h" >&2
  exit 2
fi

held_cores=()
held_fds=()
# CI jobs holding cores, which a benchmark has to wait for
ci_jobs=()

# Locks `count` free cores. Releases everything on failure, so a waiting job
# never sits on a partial reservation.
acquire() {
  local core fd lock
  held_cores=()
  held_fds=()
  ci_jobs=()
  lock_allocation

  if $ci && ! benchmarks_idle; then
    unlock_allocation
    return 1
  fi

  for core in "${cores[@]}"; do
    lock=$(lock_file "$core")
    exec {fd}<>"$lock"
    if flock -n "$fd"; then
      if ((${#held_cores[@]} < count)); then
        held_cores+=("$core")
        held_fds+=("$fd")
        continue
      fi
    elif [[ $(<"$lock") == "ci "* ]]; then
      ci_jobs+=("core $core: $(holder "$core")")
    fi
    exec {fd}>&-
  done

  if ((${#held_cores[@]} == count)) && { $ci || ((${#ci_jobs[@]} == 0)); }; then
    # Written before unlocking, so other attempts never see a stale holder
    for core in "${held_cores[@]}"; do
      # exec keeps this PID, so it ends up being COMMAND's
      if $ci; then
        echo "ci pid $$: $*" >"$(lock_file "$core")"
      else
        echo "pid $$: $*" >"$(lock_file "$core")"
      fi
    done
    unlock_allocation
    return 0
  fi

  for fd in "${held_fds[@]}"; do
    exec {fd}>&-
  done
  held_cores=()
  held_fds=()
  unlock_allocation
  return 1
}

if $ci; then
  acquire "$@" || exit "$not_reserved"
else
  # Held until COMMAND exits, which keeps CI from starting jobs while this waits and runs
  exec {demand_fd}<>"$lock_dir/demand.lock"
  flock -s "$demand_fd"

  reason=
  until acquire "$@"; do
    if ((${#ci_jobs[@]})); then
      next="waiting for CI to finish (it starts no new jobs meanwhile):$(printf '\n  %s' "${ci_jobs[@]}")"
    else
      next="waiting for $count free core(s)..."
    fi
    if [[ $next != "$reason" ]]; then
      echo "bench-run: $next" >&2
      reason=$next
    fi
    if [[ -n $timeout ]] && ((SECONDS >= timeout)); then
      echo "bench-run: gave up after ${timeout}s" >&2
      exit "$not_reserved"
    fi
    sleep 1
  done
fi

cpus=()
for core in "${held_cores[@]}"; do
  cpus+=("$core" "$((core + smt_offset))")
done
cpu_list=$(
  IFS=,
  echo "${cpus[*]}"
)

if ! $ci; then
  echo "bench-run: core(s) ${held_cores[*]} (CPUs $cpu_list)" >&2
fi
export BENCH_RUN_CPUS=$cpu_list

# the lock fds are inherited, holding the reservation for COMMAND's lifetime
exec taskset --cpu-list "$cpu_list" "$@"
