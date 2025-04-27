#!/usr/bin/env bash

# Escalate to root if not root
[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

HOSTNAME=@hostname@
USER=@user@
USER_ID=$(id -u ${USER})

function notify() {
    sudo -u ${USER} DISPLAY=:0 "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus" notify-send "$@" > /dev/null 2>&1 || true
}

function gprint() {
    printf "\033[0;36m%s\n\033[0m" "$1"
    notify --urgency=normal "Updater" "$1"
}

function bprint() {
    printf "\033[0;31m%s\n\033[0m" "$1"
    notify --urgency=critical "Updater" "$1"
}

DELETE=false
FLAKE=false
while getopts 'df' flag; do
    case "$flag" in
        d) DELETE=true ;;
        f) FLAKE=true ;;
        *) echo "Invalid flag: $flag" ;;
    esac
done

gprint "Updating"
pushd /etc/nixos
git add .

LOCAL_CHANGES=false
git fetch
if ! git diff --quiet HEAD origin/main; then
    echo "Remote changes found, pulling"
    git pull origin main
fi

if ! git diff --quiet; then
    gprint "Checking"
    LOCAL_CHANGES=true
    nix fmt .
    nix flake check
fi

if [ "$FLAKE" = true ]; then
    gprint "Updating flake"
    nix flake update
fi

gprint "Rebuilding"
if ! nixos-rebuild switch --flake "/etc/nixos#${HOSTNAME}"; then
    bprint "Rebuild failed"
    exit 1
fi

echo "Waiting for network"
until ping -c1 www.google.com >/dev/null 2>&1; do :; done

if [ "$LOCAL_CHANGES" = true ]; then
    echo "Pushing to github"
    git commit -m "$(nixos-rebuild list-generations | grep current)"
    git push -u origin main
fi

if [ "$DELETE" = true ]; then
    gprint "Deleting old generations"
    nix-collect-garbage --delete-older-than 7d
fi

gprint "Finished update"
popd