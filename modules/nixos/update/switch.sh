#!/usr/bin/env bash
# Switches to the configuration checked out in /etc/nixos, falling back to making it the
# boot entry when switching keeps failing

HOSTNAME=@hostname@
RETRY_FILE=@retryFile@
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
