# shellcheck shell=bash

# Waits until a Forgejo pull request merges, closes, fails a check, or stops progressing.
# FORGEJO_URL and FORGEJO_TOKEN_FILE are set by the Nix wrapper.
#
# Exit codes:
#   0  merged
#   1  a check failed
#   2  not merging: checks passed (or none were reported) but the PR stayed open
#   3  closed without merging
#   64 usage error

usage() {
  printf 'usage: forgejo-pr-wait [-R owner/repo] <pr-number>\n' >&2
  exit 64
}

repo=""
while getopts "R:h" opt; do
  case "$opt" in
    R) repo="$OPTARG" ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
[[ $# -eq 1 && "$1" =~ ^[0-9]+$ ]] || usage
pr="$1"

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
      if [[ "$(jq length <<<"$checks")" == 0 ]]; then
        printf 'not merging: no checks reported on %s\n' "$sha"
      else
        printf 'not merging: checks passed on %s\n' "$sha"
        print_statuses "$checks"
      fi
      printf 'mergeable: %s\n' "$(jq -r .mergeable <<<"$pr_json")"
      exit 2
    fi
  else
    settled_since=""
  fi

  sleep "$interval"
  interval=$((interval * 2 > max_interval ? max_interval : interval * 2))
done
