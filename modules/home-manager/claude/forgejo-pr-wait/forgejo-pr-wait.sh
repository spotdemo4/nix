# shellcheck shell=bash

# Waits until a Forgejo pull request merges, closes, fails a check, or stops progressing.
# FORGEJO_URL and FORGEJO_TOKEN_FILE are set by the Nix wrapper.
#
# Exit codes:
#   0  merged
#   1  a check failed
#   2  not merging: checks passed (or none were reported) but the PR stayed open
#   3  closed without merging
#   4  stale auto-merge: scheduled only after the checks settled, so it will never fire
#   64 usage error

usage() {
  printf 'usage: forgejo-pr-wait [-R owner/repo] <pr-number>\n' >&2
  exit 64
}

# Parsed by hand because getopts stops at the first operand, so `<pr> -R repo` would fail.
repo=""
pr=""
while (($#)); do
  case "$1" in
    -R)
      (($# >= 2)) || usage
      repo="$2"
      shift 2
      ;;
    -R?*)
      repo="${1#-R}"
      shift
      ;;
    --)
      shift
      break
      ;;
    -*) usage ;;
    *)
      [[ -z "$pr" ]] || usage
      pr="$1"
      shift
      ;;
  esac
done
if (($#)); then
  [[ -z "$pr" && $# -eq 1 ]] || usage
  pr="$1"
fi
[[ "$pr" =~ ^[0-9]+$ ]] || usage

if [[ -z "$repo" ]]; then
  # Handles https://host/owner/repo, git@host:owner/repo, and ssh://git@host/owner/repo.
  remote="$(git remote get-url origin)"
  remote="${remote%.git}"
  repo="$(sed -E 's#^.*[:/]([^/:]+/[^/]+)$#\1#' <<<"$remote")"
fi

token="$(<"$FORGEJO_TOKEN_FILE")"
if [[ -z "$token" || "$token" == *$'\n'* ]]; then
  printf 'Forgejo token must be a non-empty single line: %s\n' "$FORGEJO_TOKEN_FILE" >&2
  exit 1
fi

api() {
  curl --silent --show-error --fail --retry 3 \
    --header "Authorization: token $token" \
    --header "Accept: application/json" \
    "$FORGEJO_URL/api/v1/repos/$repo/$1"
}

# The combined status holds the latest status for each context, paginated.
statuses() {
  local sha="$1" page=1 all='[]' body
  while :; do
    body="$(api "commits/$sha/status?limit=50&page=$page")"
    all="$(jq --argjson all "$all" '$all + (.statuses // [])' <<<"$body")"
    if (($(jq length <<<"$all") >= $(jq '.total_count // 0' <<<"$body"))) ||
      [[ "$(jq '.statuses // [] | length' <<<"$body")" == 0 ]]; then
      break
    fi
    page=$((page + 1))
  done
  printf '%s\n' "$all"
}

# The last auto-merge schedule or cancellation in the PR timeline, or null, paginated.
last_schedule() {
  local page=1 last='null' body
  while :; do
    body="$(api "issues/$pr/timeline?limit=50&page=$page")"
    [[ "$(jq length <<<"$body")" != 0 ]] || break
    last="$(jq --argjson last "$last" \
      '[$last] + [.[] | select(.type == "pull_scheduled_merge" or .type == "pull_cancel_scheduled_merge")] | last' \
      <<<"$body")"
    page=$((page + 1))
  done
  printf '%s\n' "$last"
}

print_statuses() {
  jq -r --arg base "$FORGEJO_URL" \
    '.[] | "  \(.context): \(.status) \(if (.target_url // "") | startswith("/") then $base + .target_url else .target_url // "" end)"' \
    <<<"$1"
}

# After the checks settle, give auto-merge (or a late CI run) this long to act.
grace=120
interval=5
max_interval=30
settled_since=""

while :; do
  pr_json="$(api "pulls/$pr")"
  sha="$(jq -r .head.sha <<<"$pr_json")"

  if [[ "$(jq -r .merged <<<"$pr_json")" == true ]]; then
    printf 'merged: %s/%s/pulls/%s\n' "$FORGEJO_URL" "$repo" "$pr"
    printf 'head: %s\nmerge commit: %s\n' "$sha" "$(jq -r .merge_commit_sha <<<"$pr_json")"
    exit 0
  fi

  if [[ "$(jq -r .state <<<"$pr_json")" == closed ]]; then
    printf 'closed without merging: %s/%s/pulls/%s\n' "$FORGEJO_URL" "$repo" "$pr"
    exit 3
  fi

  checks="$(statuses "$sha")"
  failed="$(jq '[.[] | select(.status == "failure" or .status == "error")]' <<<"$checks")"
  if [[ "$(jq length <<<"$failed")" != 0 ]]; then
    printf 'check failed on %s:\n' "$sha"
    print_statuses "$failed"
    exit 1
  fi

  if [[ "$(jq '[.[] | select(.status == "pending")] | length' <<<"$checks")" == 0 ]]; then
    settled_since="${settled_since:-$SECONDS}"
    if ((SECONDS - settled_since >= grace)); then
      schedule="$(last_schedule)"
      scheduled="$(jq '.type == "pull_scheduled_merge"' <<<"$schedule")"
      code=2
      if [[ "$scheduled" == true ]]; then
        # Forgejo only tries a scheduled merge when a check status changes, so a schedule
        # recorded after the last status has nothing left to trigger it.
        scheduled_at="$(jq -r .created_at <<<"$schedule" | date -f - +%s)"
        checked_at="$(jq -r '.[].updated_at' <<<"$checks" | date -f - +%s | sort -n | tail -n 1)"
        if ((scheduled_at >= ${checked_at:-0})); then
          code=4
        fi
      fi

      if ((code == 4)); then
        printf 'stale auto-merge: scheduled after the checks settled on %s, so it will never fire\n' "$sha"
      elif [[ "$(jq length <<<"$checks")" == 0 ]]; then
        printf 'not merging: no checks reported on %s\n' "$sha"
      else
        printf 'not merging: checks passed on %s\n' "$sha"
      fi
      print_statuses "$checks"
      if [[ "$scheduled" == true ]]; then
        printf 'auto-merge: scheduled at %s\n' "$(jq -r .created_at <<<"$schedule")"
      else
        printf 'auto-merge: not scheduled\n'
      fi
      printf 'mergeable: %s\n' "$(jq -r .mergeable <<<"$pr_json")"
      exit "$code"
    fi
  else
    settled_since=""
  fi

  sleep "$interval"
  interval=$((interval * 2 > max_interval ? max_interval : interval * 2))
done
