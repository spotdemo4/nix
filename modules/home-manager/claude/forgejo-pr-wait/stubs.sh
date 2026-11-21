# shellcheck shell=bash
# Sourced through BASH_ENV by forgejo-pr-wait.test.sh, so bash defines these functions before
# it runs forgejo-pr-wait, and they take precedence over the commands on its PATH.

# Answers a Forgejo API request with the file in $FIXTURES named after the request's path under
# the repo, with / ? & = replaced by _, or with a 404 when there is no such file.
curl() {
  local name="${!#}"
  name="${name#*/api/v1/repos/owner/repo/}"
  name="${name//[\/?&=]/_}"
  if [[ -f "$FIXTURES/$name" ]]; then
    printf '%s\n200' "$(<"$FIXTURES/$name")"
  else
    printf '\n404'
    return 22
  fi
}

# Advances SECONDS instead of waiting, so the grace period and the outage limit pass at once.
sleep() {
  SECONDS=$((SECONDS + $1))
}
