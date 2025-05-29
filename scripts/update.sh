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
REBUILD=false
while getopts 'dfwr' flag; do
    case "$flag" in
        d) DELETE=true ;;
        f) FLAKE=true ;;
        w) WATCH=true ;;
        r) REBUILD=true ;;
        *) echo "Invalid flag: $flag" ;;
    esac
done

FIRST_RUN=true
while true; do
    if [ "$FIRST_RUN" = false ]; then
        REBUILD=false

        if [ "$WATCH" = false ]; then
            break
        else
            sleep 1m
        fi
    fi
    FIRST_RUN=false
    
    echo "Checking for updates"
    cd /etc/nixos
    git fetch

    if ! git diff --quiet HEAD origin/main; then
        REBUILD=true
        echo "Remote changes found, pulling"
        git stash
        git pull origin main
        git stash pop
    fi

    LOCAL_CHANGES=false
    if [ -n "$(git status --porcelain)" ]; then
        LOCAL_CHANGES=true
        REBUILD=true
        echo "Local changes found, checking"
        git add .
        nix fmt .
        nix flake check
    fi

    if [ "$FLAKE" = true ]; then
        REBUILD=true
        echo "Updating flake"
        nix flake update
    fi

    if [ "$REBUILD" = false ]; then
        continue
    fi

    gprint "Updating"
    if ! nixos-rebuild switch --flake "/etc/nixos#${HOSTNAME}" --accept-flake-config; then
        bprint "Update failed"
        continue
    fi

    if [ "$LOCAL_CHANGES" = true ]; then
        echo "Waiting for network"
        until ping -c1 1.1.1.1 >/dev/null 2>&1; do :; done

        echo "Pushing to github"
        git commit -m "$(nixos-rebuild list-generations | grep current)"
        git push -u origin main
    fi

    if [ "$DELETE" = true ]; then
        echo "Deleting old generations"
        nix-collect-garbage --delete-older-than 7d
    fi

    gprint "Update finished"
done