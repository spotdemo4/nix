# shellcheck shell=bash
# Runs a command pinned to free, dedicated benchmark cores.
set -euo pipefail

# physical cores reserved for benchmarks
cores=(@cores@)
# CPU number of a core's second SMT thread, relative to the core
smt_offset="@smtOffset@"
lock_dir="@lockDir@"

usage() {
  cat <<EOF
Usage: bench-run [-c N] [--] COMMAND [ARGS...]
       bench-run --status

Runs COMMAND pinned to N dedicated physical cores (both SMT threads of each),
waiting until that many cores are free. The cores stay reserved until COMMAND
and every process that inherited them exit.

Options:
  -c, --cores N  number of physical cores to reserve (1-${#cores[@]}, default 1)
  -s, --status   show which cores are in use
  -h, --help     show this help
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

status() {
  local core lock fd
  lock_allocation
  for core in "${cores[@]}"; do
    lock=$(lock_file "$core")
    exec {fd}<"$lock"
    if flock -n "$fd"; then
      echo "core $core: free"
    else
      echo "core $core: $(cat "$lock")"
    fi
    exec {fd}<&-
  done
  unlock_allocation
}

count=1
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

held_cores=()
held_fds=()

# Locks `count` free cores. Releases everything on failure, so a waiting job
# never sits on a partial reservation.
acquire() {
  local core fd
  held_cores=()
  held_fds=()
  lock_allocation
  for core in "${cores[@]}"; do
    exec {fd}<>"$(lock_file "$core")"
    if flock -n "$fd"; then
      held_cores+=("$core")
      held_fds+=("$fd")
      if ((${#held_cores[@]} == count)); then
        unlock_allocation
        return 0
      fi
    else
      exec {fd}>&-
    fi
  done
  for fd in "${held_fds[@]}"; do
    exec {fd}>&-
  done
  unlock_allocation
  return 1
}

waiting=false
until acquire; do
  if ! $waiting; then
    echo "bench-run: waiting for $count free core(s)..." >&2
    waiting=true
  fi
  sleep 1
done

cpus=()
for core in "${held_cores[@]}"; do
  cpus+=("$core" "$((core + smt_offset))")
  # exec keeps this PID, so it ends up being COMMAND's
  echo "pid $$: $*" >"$(lock_file "$core")"
done
cpu_list=$(
  IFS=,
  echo "${cpus[*]}"
)

echo "bench-run: core(s) ${held_cores[*]} (CPUs $cpu_list)" >&2
export BENCH_RUN_CPUS=$cpu_list

# the lock fds are inherited, holding the reservation for COMMAND's lifetime
exec taskset --cpu-list "$cpu_list" "$@"
