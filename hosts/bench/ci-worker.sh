# shellcheck shell=bash
# Runs CI jobs on benchmark cores, one at a time, while no benchmark needs them.
# Each attempt reserves cores with `bench-run --ci` and asks one Forgejo scope for a job, so
# the cores are only held while a job runs (or for the moment it takes to ask).
# CONNECTIONS, CORES, INTERVAL, WORKERS and JOB are set by the Nix wrapper, and SLOT by the unit.

# Spread the workers out so they don't all ask Forgejo at the same moment
sleep $(((SLOT - 1) * INTERVAL / WORKERS))

read -ra scopes <<<"$CONNECTIONS"
while true; do
  ran=false
  for conn in "${scopes[@]}"; do
    status=0
    bench-run --ci --cores "$CORES" -- "$JOB" "$conn" || status=$?
    case $status in
    0)
      echo "Finished a $conn job"
      ran=true
      ;;
    2) ;; # no job waiting in this scope
    75)
      # a benchmark is waiting or running, or the cores are taken
      break
      ;;
    *)
      echo "forgejo-runner one-job for $conn exited with $status" >&2
      ;;
    esac
  done

  # Check again right away after a job, since more are likely queued
  $ran || sleep "$INTERVAL"
done
