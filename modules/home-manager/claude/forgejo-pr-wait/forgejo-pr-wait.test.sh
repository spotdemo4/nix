# shellcheck shell=bash
# Regression tests for forgejo-pr-wait, run by the flake's forgejo-pr-wait check with the
# package on PATH. Forgejo's API is stubbed by stubs.sh.

set -euo pipefail

BASH_ENV="$PWD/stubs.sh"
export BASH_ENV

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0

# Starts a scenario: a PR whose checks passed and whose reviewer approved, so forgejo-pr-wait
# reads the timeline for an auto-merge schedule once the grace period passes.
scenario() {
  FIXTURES="$work/$1"
  export FIXTURES
  mkdir "$FIXTURES"
  fixture 'pulls/1' '{"head":{"sha":"abc"},"merged":false,"state":"open","mergeable":true}'
  fixture 'commits/abc/status?limit=50&page=1' \
    '{"total_count":1,"statuses":[{"context":"ci","status":"success","target_url":"/owner/repo/actions/runs/1","updated_at":"2026-11-21T10:00:00Z"}]}'
  fixture 'pulls/1/reviews?limit=50&page=1' \
    '[{"id":1,"user":{"id":1,"login":"pi"},"state":"APPROVED","commit_id":"abc","dismissed":false,"html_url":"https://trev.zip/owner/repo/pulls/1#issuecomment-1"}]'
  fixture 'pulls/1/reviews?limit=50&page=2' '[]'
}

# Sets the response to a request for $1, a path under the repo.
fixture() {
  printf '%s\n' "$2" >"$FIXTURES/${1//[\/?&=]/_}"
}

# Runs forgejo-pr-wait on the scenario's PR, expecting exit code $1 and output containing $2.
expect() {
  local want="$1" pattern="$2" output code=0
  output="$(timeout 60 forgejo-pr-wait -R owner/repo 1 2>&1)" || code=$?
  if ((code == want)) && [[ "$output" == *"$pattern"* ]]; then
    printf 'ok %s\n' "${FIXTURES##*/}"
  else
    printf 'FAIL %s: expected exit %s and output containing %q, got exit %s:\n%s\n' \
      "${FIXTURES##*/}" "$want" "$pattern" "$code" "$output" >&2
    failures=$((failures + 1))
  fi
}

# Forgejo answers a timeline page past the last one with null rather than [].
scenario null-page
fixture 'issues/1/timeline?limit=50&page=1' '[{"type":"comment","created_at":"2026-11-21T09:00:00Z"}]'
fixture 'issues/1/timeline?limit=50&page=2' 'null'
expect 2 'auto-merge: not scheduled'

# The timeline filters events after paging, so a short page isn't the last one.
scenario short-page
fixture 'issues/1/timeline?limit=50&page=1' '[{"type":"comment","created_at":"2026-11-21T09:00:00Z"}]'
fixture 'issues/1/timeline?limit=50&page=2' '[{"type":"pull_scheduled_merge","created_at":"2026-11-21T09:30:00Z"}]'
fixture 'issues/1/timeline?limit=50&page=3' 'null'
expect 2 'auto-merge: scheduled at 2026-11-21T09:30:00Z'

# Scheduled after the last check status, so nothing is left to trigger the merge.
scenario stale-schedule
fixture 'issues/1/timeline?limit=50&page=1' '[{"type":"pull_scheduled_merge","created_at":"2026-11-21T10:05:00Z"}]'
fixture 'issues/1/timeline?limit=50&page=2' 'null'
expect 4 'stale auto-merge'

((failures == 0))
