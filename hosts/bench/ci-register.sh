# shellcheck shell=bash
# Registers the bench host's runner with each Forgejo scope, and declares its labels.
# STATE, URL, NAME, VERSION, LABELS (registration form) and CONNECTIONS (name=token-file pairs)
# are set by the Nix wrapper.

# writeShellApplication sets errexit, but command substitutions drop it without this.
shopt -s inherit_errexit

read -ra runner_labels <<<"$LABELS"
names=()
for label in "${runner_labels[@]}"; do
  names+=("${label%%:*}")
done

for entry in $CONNECTIONS; do
  conn="${entry%%=*}"
  secret="${entry#*=}"
  dir="$STATE/$conn"
  mkdir -p "$dir"

  if [[ ! -s $dir/.runner ]]; then
    echo "Registering $NAME with the $conn scope"
    token=$(sed -n 's/^TOKEN=//p' "$secret")
    [[ -n $token ]] || {
      echo "error: $secret has no TOKEN" >&2
      exit 1
    }
    (
      cd "$dir" || exit
      forgejo-runner register --no-interactive \
        --instance "$URL" \
        --token "$token" \
        --name "$NAME" \
        --labels "$(
          IFS=,
          echo "${runner_labels[*]}"
        )"
    )
  fi

  # The daemon declares labels when it starts, but `one-job` never does, so Forgejo would
  # otherwise not know which jobs this runner can take. Declaring on every start also keeps
  # them in sync with the Nix config.
  uuid=$(jq -er .uuid "$dir/.runner")
  jq -n --arg version "$VERSION" '{version: $version, labels: $ARGS.positional}' --args "${names[@]}" |
    curl -fsS --retry 5 --retry-all-errors -o /dev/null \
      -X POST "${URL}api/actions/runner.v1.RunnerService/Declare" \
      -H "Content-Type: application/json" \
      -H "x-runner-uuid: $uuid" \
      -H @<(jq -r '"x-runner-token: \(.token)"' "$dir/.runner") \
      --data-binary @-
  echo "Declared ${#names[@]} labels for the $conn scope ($uuid)"
done
