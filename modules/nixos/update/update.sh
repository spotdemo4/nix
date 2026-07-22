#!/usr/bin/env bash

HOSTNAME=@hostname@
STATE_DIRECTORY=@stateDirectory@
USER=@user@
USER_ID=$(id -u "${USER}")

function notify() {
    runuser -u "${USER}" -- env DISPLAY=:0 "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus" notify-send "$@" > /dev/null 2>&1 || true
}

function gprint() {
    printf "\033[0;36m%s\n\033[0m" "$1"
    notify --urgency=normal "Updater" "$1"
}

function bprint() {
    printf "\033[0;31m%s\n\033[0m" "$1"
    notify --urgency=critical "Updater" "$1"
}

REVISION="${1:-}"
if [ -n "$REVISION" ] && [[ ! "$REVISION" =~ ^[0-9a-f]{40}$ ]]; then
    echo "invalid revision: $REVISION" >&2
    exit 1
fi

exec 9>"$STATE_DIRECTORY/lock"
flock 9

RETRY_FILE="$STATE_DIRECTORY/retry"

echo "checking for updates"
cd /etc/nixos || { echo "could not change directory to /etc/nixos"; exit 1; }
if ! git fetch origin; then
    echo "could not fetch updates"
    exit 1
fi

TARGET_REVISION=origin/main
if [ -n "$REVISION" ]; then
    REMOTE_REVISION="$(git rev-parse --verify origin/main)"
    if [ "$REVISION" != "$REMOTE_REVISION" ]; then
        echo "ignoring revision that is not the current origin/main: $REVISION" >&2
        exit 0
    fi

    if ! git merge-base --is-ancestor HEAD "$REVISION"; then
        echo "ignoring revision that is not a descendant of HEAD: $REVISION" >&2
        exit 0
    fi

    TARGET_REVISION="$REVISION"
fi

CURRENT_REVISION="$(git rev-parse HEAD)"
RESOLVED_TARGET_REVISION="$(git rev-parse "$TARGET_REVISION")"
if [ "$CURRENT_REVISION" = "$RESOLVED_TARGET_REVISION" ] && [ ! -e "$RETRY_FILE" ]; then
    exit 0
fi

echo "updating to $RESOLVED_TARGET_REVISION"
git reset --hard "$RESOLVED_TARGET_REVISION"

gprint "Updating"
touch "$RETRY_FILE"
for attempt in 1 2; do
    if nixos-rebuild switch --flake "/etc/nixos#${HOSTNAME}" --accept-flake-config; then
        rm -f "$RETRY_FILE"
        gprint "Update successful"
        exit 0
    fi

    if [ "$attempt" -lt 2 ]; then
        sleep 1m
    fi
done

if nixos-rebuild boot --flake "/etc/nixos#${HOSTNAME}" --accept-flake-config; then
    bprint "Update failed, reboot required"
else
    bprint "Update failed"
fi

exit 1
