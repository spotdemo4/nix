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

WATCH=false
REBUILD=false
while getopts 'dwr' flag; do
    case "$flag" in
        w) WATCH=true ;;
        r) REBUILD=true ;;
        *) echo "Invalid flag: $flag" ;;
    esac
done

FIRST_RUN=true
RETRY_COUNT=0
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
    cd /etc/nixos || { echo "could not change directory to /etc/nixos"; exit 1; }
    if ! git fetch --all; then
        echo "could not fetch updates"
        continue
    fi

    REMOTE_CHANGES=false
    if ! git diff --quiet HEAD origin/main; then
        REMOTE_CHANGES=true
        REBUILD=true
    fi

    LOCAL_CHANGES=false
    if [ -n "$(git status --porcelain)" ]; then
        LOCAL_CHANGES=true
        REBUILD=true
    fi

    if [ "$RETRY_COUNT" -ge 1 ]; then
        REBUILD=true
    fi

    if [ "$REMOTE_CHANGES" = true ] && [ "$LOCAL_CHANGES" = true ]; then
        echo "local and remote changes found: stashing and pulling"
        git stash
        git reset --hard origin/main
        if ! git stash pop; then
            echo "could not apply local changes"
            continue
        fi
        git add .
        nix fmt .
    elif [ "$REMOTE_CHANGES" = true ]; then
        echo "remote changes found: pulling"
        git reset --hard origin/main
    elif [ "$LOCAL_CHANGES" = true ]; then
        echo "local changes found"
        git add .
        nix fmt .
    fi

    if [ "$REBUILD" = false ]; then
        continue
    fi

    gprint "Updating"
    if ! nixos-rebuild switch --flake "/etc/nixos#${HOSTNAME}" --accept-flake-config; then
        bprint "Update failed"

        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ "$RETRY_COUNT" -ge 3 ]; then
            bprint "Update failed 3 times, not retrying again"
            RETRY_COUNT=0
        fi

        continue
    fi
    
    RETRY_COUNT=0

    gprint "Update finished"
done