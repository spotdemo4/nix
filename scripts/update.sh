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
WATCH=false
REBUILD=false
while getopts 'dwr' flag; do
    case "$flag" in
        d) DELETE=true ;;
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
    
    echo "checking for updates"
    cd /etc/nixos
    if ! git fetch; then
        echo "could not fetch updates"
        continue
    fi

    REMOTE_CHANGES=false
    if ! git diff --quiet HEAD origin/production; then
        REMOTE_CHANGES=true
        REBUILD=true
    fi

    LOCAL_CHANGES=false
    if [ -n "$(git status --porcelain)" ]; then
        LOCAL_CHANGES=true
        REBUILD=true
    fi

    if [ "$REMOTE_CHANGES" = true ] && [ "$LOCAL_CHANGES" = true ]; then
        echo "local and remote changes found: stashing, pulling and checking"
        git stash
        git pull origin production
        git stash pop
        git add .
        nix fmt .
        nix flake check --accept-flake-config
    elif [ "$REMOTE_CHANGES" = true ]; then
        echo "remote changes found: pulling"
        git pull origin production
    elif [ "$LOCAL_CHANGES" = true ]; then
        echo "local changes found: checking"
        git add .
        nix fmt .
        nix flake check --accept-flake-config
    fi

    if [ "$REBUILD" = false ]; then
        continue
    fi

    gprint "Updating"
    if ! nixos-rebuild switch --flake "/etc/nixos#${HOSTNAME}" --accept-flake-config; then
        bprint "Update failed"
        continue
    fi

    if [ "$DELETE" = true ]; then
        echo "deleting old generations"
        nix-collect-garbage --delete-older-than 7d
    fi

    gprint "Update finished"
done