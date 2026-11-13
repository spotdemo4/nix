# shellcheck shell=bash

# Waits until a Forgejo pull request merges, closes, fails a check, gets changes requested,
# or stops progressing.
# FORGEJO_URL and FORGEJO_TOKEN_FILE are set by the Nix wrapper.
#
# Exit codes:
#   0  merged
#   1  a check failed
#   2  not merging: checks passed (or none were reported) and no review is pending, but the
#      PR stayed open
#   3  closed without merging
#   4  stale auto-merge: scheduled only after the checks settled, so it will never fire
#   5  changes requested: a reviewer's latest verdict on the head commit requests changes
#   6  Forgejo API error: it stayed unreachable for 10 minutes, rejected a request (for example
#      an unknown PR or a bad token), or the token file is unusable
#   64 usage error

# writeShellApplication sets errexit, but command substitutions drop it without this.
shopt -s inherit_errexit

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
  exit 6
fi

# Prints the response to a GET request if it's a JSON value of the given type (object or
# array). Returns 2 when Forgejo rejects the request, and 1 on any other failure, which may
# clear up on its own: a timeout, a 408, 429, or 5xx response, or a body of the wrong type.
# Timeouts make a stalled connection fail, and --retry treats that failure as transient.
# --fail keeps error bodies out of the output, where a retry would append to them.
api() {
  local path="$1" type="$2" response status body code=0
  response="$(curl --silent --show-error --fail --retry 3 --connect-timeout 10 --max-time 30 \
    --header "Authorization: token $token" \
    --header "Accept: application/json" \
    --write-out '\n%{http_code}' \
    "$FORGEJO_URL/api/v1/repos/$repo/$path")" || code=$?
  status="${response##*$'\n'}"
  body="${response%$'\n'*}"
  if ((code != 0)); then
    if ((code == 22)) && [[ "$status" == 4?? && "$status" != 408 && "$status" != 429 ]]; then
      return 2
    fi
    return 1
  fi
  if ! jq -e --arg type "$type" 'type == $type' >/dev/null 2>&1 <<<"$body"; then
    printf 'forgejo-pr-wait: expected a JSON %s from %s\n' "$type" "$path" >&2
    return 1
  fi
  printf '%s\n' "$body"
}

# The combined status holds the latest status for each context, paginated.
statuses() {
  local sha="$1" page=1 all='[]' body
  while :; do
    body="$(api "commits/$sha/status?limit=50&page=$page" object)" || return
    all="$(jq --argjson all "$all" '$all + (.statuses // [])' <<<"$body")"
    if jq -e --argjson all "$all" \
      '($all | length) >= (.total_count // 0) or (.statuses // [] | length) == 0' \
      >/dev/null <<<"$body"; then
      break
    fi
    page=$((page + 1))
  done
  printf '%s\n' "$all"
}

# Every item from an endpoint that returns a paginated JSON array.
paginate() {
  local page=1 all='[]' body
  while :; do
    body="$(api "$1?limit=50&page=$page" array)" || return
    jq -e 'length > 0' >/dev/null <<<"$body" || break
    all="$(jq --argjson all "$all" '$all + .' <<<"$body")"
    page=$((page + 1))
  done
  printf '%s\n' "$all"
}

# The last auto-merge schedule or cancellation in the PR timeline, or null.
last_schedule() {
  local timeline
  timeline="$(paginate "issues/$pr/timeline")" || return
  jq '[.[] | select(.type == "pull_scheduled_merge" or .type == "pull_cancel_scheduled_merge")] | last' <<<"$timeline"
}

# Each user's latest verdict or review request. Comments, drafts, and dismissed reviews
# don't change it, and team requests are skipped because a member's review doesn't clear them.
latest_reviews() {
  local reviews
  reviews="$(paginate "pulls/$pr/reviews")" || return
  jq '[.[] | select((.dismissed | not) and .user != null and
    (.state == "APPROVED" or .state == "REQUEST_CHANGES" or .state == "REQUEST_REVIEW"))]
    | group_by(.user.id) | map(max_by(.id))' <<<"$reviews"
}

print_statuses() {
  jq -r --arg base "$FORGEJO_URL" \
    '.[] | "  \(.context): \(.status) \(if (.target_url // "") | startswith("/") then $base + .target_url else .target_url // "" end)"' \
    <<<"$1"
}

print_reviews() {
  jq -r '.[] | "  \(.user.login): \(.state) \(.html_url)"' <<<"$1"
}

# After the checks and reviews settle, give auto-merge (or a late CI run) this long to act.
grace=120
interval=5
max_interval=30
# Keep polling through a Forgejo outage up to this long.
outage=600
settled_since=""
failing_since=""

pause() {
  sleep "$interval"
  interval=$((interval * 2 > max_interval ? max_interval : interval * 2))
}

# Handles a helper that returned api's status $1: gives up if Forgejo rejected the request
# or has been failing for too long, and otherwise waits to try again at the next poll.
api_failed() {
  if (($1 == 2)); then
    printf 'Forgejo API rejected a request for %s/%s/pulls/%s\n' "$FORGEJO_URL" "$repo" "$pr"
    exit 6
  fi
  failing_since="${failing_since:-$SECONDS}"
  if ((SECONDS - failing_since >= outage)); then
    printf 'could not reach Forgejo for %s minutes: %s/%s/pulls/%s\n' \
      "$((outage / 60))" "$FORGEJO_URL" "$repo" "$pr"
    exit 6
  fi
  printf 'forgejo-pr-wait: Forgejo API request failed, retrying in %ss\n' "$interval" >&2
  pause
}

while :; do
  pr_json="$(api "pulls/$pr" object)" || {
    api_failed "$?"
    continue
  }
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

  checks="$(statuses "$sha")" || {
    api_failed "$?"
    continue
  }
  failed="$(jq '[.[] | select(.status == "failure" or .status == "error")]' <<<"$checks")"
  if jq -e 'length > 0' >/dev/null <<<"$failed"; then
    printf 'check failed on %s:\n' "$sha"
    print_statuses "$failed"
    exit 1
  fi

  reviews="$(latest_reviews)" || {
    api_failed "$?"
    continue
  }
  rejected="$(jq --arg sha "$sha" '[.[] | select(.state == "REQUEST_CHANGES" and .commit_id == $sha)]' <<<"$reviews")"
  if jq -e 'length > 0' >/dev/null <<<"$rejected"; then
    printf 'changes requested on %s:\n' "$sha"
    jq -r '.[] | "  \(.user.login) (review \(.id), \(.comments_count) inline comments): \(.html_url)",
      (.body // "" | select(. != "") | split("\n")[] | "    " + .)' <<<"$rejected"
    exit 5
  fi

  # A requested review, or a change request on an older commit, still needs a reviewer to act.
  # Strict tests, so an unexpected empty value counts as unsettled rather than settled.
  if jq -e 'all(.status != "pending")' >/dev/null <<<"$checks" &&
    jq -e 'all(.state == "APPROVED")' >/dev/null <<<"$reviews"; then
    settled_since="${settled_since:-$SECONDS}"
    if ((SECONDS - settled_since >= grace)); then
      schedule="$(last_schedule)" || {
        api_failed "$?"
        continue
      }
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
      elif jq -e 'length == 0' >/dev/null <<<"$checks"; then
        printf 'not merging: no checks reported on %s\n' "$sha"
      else
        printf 'not merging: checks passed on %s\n' "$sha"
      fi
      print_statuses "$checks"
      if jq -e 'length > 0' >/dev/null <<<"$reviews"; then
        printf 'reviews:\n'
        print_reviews "$reviews"
      fi
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

  failing_since=""
  pause
done
