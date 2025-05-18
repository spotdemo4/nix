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
WATCH=false
while getopts 'df' flag; do
    case "$flag" in
        d) DELETE=true ;;
        f) FLAKE=true ;;
        w) WATCH=true ;;
        *) echo "Invalid flag: $flag" ;;
    esac
done

FIRST_RUN=true

while true; do
    if [ "$WATCH" = false && "$FIRST_RUN" = false ]; then
        break
    fi
    if [ "$WATCH" = true && "$FIRST_RUN" = false ]; then
        sleep 1m
    fi
    FIRST_RUN=false
    
    echo "Checking for updates"
    pushd /etc/nixos

    git fetch

    REMOTE_CHANGES=false
    if ! git diff --quiet HEAD origin/main; then
        REMOTE_CHANGES=true
        echo "Remote changes found, pulling"
        git pull origin main
    fi

    LOCAL_CHANGES=false
    if [ -n "$(git status --porcelain)" ]; then
        LOCAL_CHANGES=true
        echo "Local changes found, checking"
        git add .
        nix fmt .
        nix flake check
    fi

    if [ "$FLAKE" = true ]; then
        echo "Updating flake"
        nix flake update
    fi

    if [ "$FLAKE" = false && "$LOCAL_CHANGES" = false && "$REMOTE_CHANGES" = false ]; then
        echo "No changes found, skipping"
        continue
    fi

    gprint "Updating"
    if ! nixos-rebuild switch --flake "/etc/nixos#${HOSTNAME}"; then
        bprint "Update failed"
        continue
    fi

    if [ "$LOCAL_CHANGES" = true ]; then
        echo "Waiting for network"
        until ping -c1 www.google.com >/dev/null 2>&1; do :; done

        echo "Pushing to github"
        git commit -m "$(nixos-rebuild list-generations | grep current)"
        git push -u origin main
    fi

    if [ "$DELETE" = true ]; then
        echo "Deleting old generations"
        nix-collect-garbage --delete-older-than 7d
    fi

    gprint "Update finished"
    popd
done