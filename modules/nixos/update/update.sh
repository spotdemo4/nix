#!/usr/bin/env bash
# Usage: update [--now] [REVISION]
#
# Updates /etc/nixos to origin/main and switches to it. Unless --now is given, it waits
# until the host has been idle (trev.update.idle) before switching.

STATE_DIRECTORY=@stateDirectory@
RETRY_FILE=@retryFile@
WAIT_FOR_IDLE=@waitForIdle@
IDLE_MINUTES=@idleMinutes@
IDLE_CHECK=(@idleCheck@)
WRAPPER=(@wrapper@)
SWITCH=@switch@

if [ "${1:-}" = "--now" ]; then
    WAIT_FOR_IDLE=false
    shift
fi

REVISION="${1:-}"
if [ -n "$REVISION" ] && [[ ! "$REVISION" =~ ^[0-9a-f]{40}$ ]]; then
    echo "invalid revision: $REVISION" >&2
    exit 1
fi

# Fetches origin and sets TARGET_REVISION, or exits when there's nothing to update to
function find_update() {
    echo "checking for updates"
    if ! git fetch origin; then
        echo "could not fetch updates"
        exit 1
    fi

    TARGET_REVISION="$(git rev-parse --verify origin/main)"
    if [ -n "$REVISION" ]; then
        if [ "$REVISION" != "$TARGET_REVISION" ]; then
            echo "ignoring revision that is not the current origin/main: $REVISION" >&2
            exit 0
        fi

        if ! git merge-base --is-ancestor HEAD "$REVISION"; then
            echo "ignoring revision that is not a descendant of HEAD: $REVISION" >&2
            exit 0
        fi
    fi

    if [ "$(git rev-parse HEAD)" = "$TARGET_REVISION" ] && [ ! -e "$RETRY_FILE" ]; then
        exit 0
    fi
}

# Returns once every check over the last IDLE_MINUTES found the host idle
function wait_for_idle() {
    echo "waiting until the host has been idle for $IDLE_MINUTES minutes"
    local idle_since=$SECONDS
    while ((SECONDS - idle_since < IDLE_MINUTES * 60)); do
        sleep 1m
        if ! "${IDLE_CHECK[@]}"; then
            idle_since=$SECONDS
        fi
    done
    echo "host is idle"
}

exec 9>"$STATE_DIRECTORY/lock"
flock 9

cd /etc/nixos || { echo "could not change directory to /etc/nixos"; exit 1; }
find_update

if $WAIT_FOR_IDLE; then
    # let other updates (e.g. the update command) run while this one waits
    flock --unlock 9
    wait_for_idle
    flock 9

    # origin/main may have moved on, or another update applied it, while this one waited
    find_update
fi

echo "updating to $TARGET_REVISION"
git reset --hard "$TARGET_REVISION"

# the lock stays held through the switch, since the switch inherits fd 9
exec systemd-inhibit --what=sleep:shutdown --who=update --why="Updating NixOS" \
    "${WRAPPER[@]}" "$SWITCH"
