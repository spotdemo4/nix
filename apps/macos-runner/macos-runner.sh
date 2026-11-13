# shellcheck shell=bash

# Installs a Forgejo runner on an Intel Mac over SSH, as a launchd agent that runs jobs directly
# on the host. One daemon serves every connection in CONNECTIONS and they share one job slot,
# since the Mac is too small to run jobs in parallel.
# FORGEJO_URL, RUNNER_BIN, RUNNER_VERSION, NODE_TARBALL, NODE_VERSION and CONNECTIONS are set by
# the Nix wrapper.
#
# Usage: macos-runner [ssh-host] [runner-name]
#
# Re-running is safe: existing registrations are kept, and the binary, node, config and agent are
# replaced (which restarts the runner and cancels a running job). Registration tokens are
# decrypted here with AGE_IDENTITY (default ~/.ssh/id_ed25519) and never reach the Mac; only the
# per-runner tokens Forgejo hands back are copied over.

# writeShellApplication sets errexit, but command substitutions drop it without this.
shopt -s inherit_errexit

host="${1:-madysens-macbook-air}"
name="${2:-macbook-air}"
identity="${AGE_IDENTITY:-$HOME/.ssh/id_ed25519}"
label="zip.trev.forgejo-runner"

tmp=$(mktemp -d)
ssh_opts=(-o ControlMaster=auto -o "ControlPath=$tmp/ssh" -o ControlPersist=60)
cleanup() {
  ssh "${ssh_opts[@]}" -O exit "$host" 2>/dev/null || true
  rm -rf "$tmp"
}
trap cleanup EXIT

# Callers build commands for the remote shell, quoting values with q
remote() {
  # shellcheck disable=SC2029
  ssh "${ssh_opts[@]}" "$host" "$@"
}

# Quotes a value for the remote shell
q() {
  printf '%q' "$1"
}

die() {
  echo "error: $*" >&2
  exit 1
}

# shellcheck disable=SC2016 # expands on the Mac
facts=$(remote 'printf "%s\n" "$HOME" "$(id -u)" "$(id -un)" "$(stat -f %Su /dev/console)" "$(uname -m)" "$(sw_vers -productVersion)"')
mapfile -t facts <<<"$facts"
home="${facts[0]}"
uid="${facts[1]}"
user="${facts[2]}"
console="${facts[3]}"
arch="${facts[4]}"
version="${facts[5]}"

[[ $arch == x86_64 ]] || die "$host is $arch, but this installs an x86_64 runner"

# launchd agents only run inside the user's GUI session
[[ $console == "$user" ]] ||
  die "$user must be logged in at the console of $host (currently $console); turn on automatic login for $user"

if ! remote 'xcode-select -p >/dev/null 2>&1'; then
  die "the Command Line Tools (git, clang, make) are missing on $host. Install them, then re-run:
  ssh -t $host 'touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress && softwareupdate --list'
  ssh -t $host 'sudo softwareupdate --install \"Command Line Tools for Xcode-<version from the list>\"'"
fi

# Idle sleep can be turned off in settings, but closing the lid always sleeps without this
if ! remote 'pmset -g | grep -Eq "^[[:space:]]*SleepDisabled[[:space:]]+1"'; then
  echo "warning: $host sleeps when its lid is closed, which pauses the runner. Prevent that with:
  ssh -t $host 'sudo pmset -a disablesleep 1'" >&2
fi

labels=("macos-${version%%.*}-intel:host" "macos-intel:host")
root="$home/.local/share/forgejo-runner"
state="$root/state"
logs="$home/Library/Logs/forgejo-runner"
plist="$home/Library/LaunchAgents/$label.plist"

echo "Installing forgejo-runner $RUNNER_VERSION on $host (macOS $version)"
remote "mkdir -p $(q "$root/bin") $(q "$logs") $(q "$home/Library/LaunchAgents") &&
  cat > $(q "$root/bin/forgejo-runner.new") &&
  chmod 755 $(q "$root/bin/forgejo-runner.new") &&
  mv $(q "$root/bin/forgejo-runner.new") $(q "$root/bin/forgejo-runner")" <"$RUNNER_BIN"

installed_node=$(remote "$(q "$root/node/bin/node") --version 2>/dev/null || true")
if [[ $installed_node != "v$NODE_VERSION" ]]; then
  echo "Installing node $NODE_VERSION"
  remote "rm -rf $(q "$root/node.new") && mkdir -p $(q "$root/node.new") &&
    tar -xzf - -C $(q "$root/node.new") --strip-components 1 &&
    rm -rf $(q "$root/node") && mv $(q "$root/node.new") $(q "$root/node")" <"$NODE_TARBALL"
fi

connection_config=""
for entry in $CONNECTIONS; do
  conn="${entry%%=*}"
  secret="${entry#*=}"
  dir="$state/$conn"

  if uuid=$(remote "test -s $(q "$dir/token") && cat $(q "$dir/uuid") 2>/dev/null") && [[ -n $uuid ]]; then
    echo "Keeping the $conn registration ($uuid)"
  else
    echo "Registering $name with the $conn scope"
    token=$(age --decrypt --identity "$identity" "$secret" | sed -n 's/^TOKEN=//p')
    [[ -n $token ]] || die "$secret has no TOKEN"

    mkdir "$tmp/$conn"
    (
      cd "$tmp/$conn" || exit
      forgejo-runner register --no-interactive \
        --instance "$FORGEJO_URL" \
        --token "$token" \
        --name "$name" \
        --labels "$(
          IFS=,
          echo "${labels[*]}"
        )"
    )
    uuid=$(jq -er .uuid "$tmp/$conn/.runner")

    # The runner reads token files verbatim, so write it without a trailing newline
    jq -j .token "$tmp/$conn/.runner" | remote "umask 077 && mkdir -p $(q "$dir") &&
      cat > $(q "$dir/token.new") && mv $(q "$dir/token.new") $(q "$dir/token") &&
      printf %s $(q "$uuid") > $(q "$dir/uuid")"
  fi

  connection_config+="    $conn:
      url: $FORGEJO_URL
      uuid: $uuid
      token_url: file://$dir/token
"
done

remote "cat > $(q "$root/config.yaml")" <<EOF
# Generated by macos-runner; changes are overwritten on the next run
log:
  level: info
runner:
  file: $root/.runner
  capacity: 1
  labels:
$(printf '    - %s\n' "${labels[@]}")
cache:
  enabled: true
  dir: $root/cache
host:
  workdir_parent: $root/work
server:
  connections:
${connection_config}
EOF

remote "cat > $(q "$plist")" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>$root/bin/forgejo-runner</string>
    <string>daemon</string>
    <string>--config</string>
    <string>$root/config.yaml</string>
  </array>
  <key>WorkingDirectory</key>
  <string>$root</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>$root/node/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$logs/runner.log</string>
  <key>StandardErrorPath</key>
  <string>$logs/runner.log</string>
</dict>
</plist>
EOF

echo "Restarting the $label agent"
remote "launchctl bootout gui/$uid/$label 2>/dev/null || true
  for _ in \$(seq 40); do launchctl print gui/$uid/$label >/dev/null 2>&1 || break; sleep 0.5; done
  launchctl bootstrap gui/$uid $(q "$plist")"

sleep 5
remote "launchctl print gui/$uid/$label | grep -E '^[[:space:]]+(state|pid|last exit code) ='
  echo '--- $logs/runner.log'
  tail -n 15 $(q "$logs/runner.log")"
