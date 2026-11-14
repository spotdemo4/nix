#!/usr/bin/env bash
# Usage: update [--now] [REVISION]
#
# Updates /etc/nixos to origin/main and switches to it. Automatic updates also collect
# garbage when it's due (trev.update.gc), after waiting until the host has been idle
# (trev.update.idle). --now updates right away, and leaves garbage collection to them.

STATE_DIRECTORY=@stateDirectory@
RETRY_FILE=@retryFile@
WAIT_FOR_IDLE=@waitForIdle@
IDLE_MINUTES=@idleMinutes@
IDLE_CHECK=(@idleCheck@)
WRAPPER=(@wrapper@)
SWITCH=@switch@
GC_ENABLE=@gcEnable@
GC_INTERVAL_DAYS=@gcIntervalDays@
GC=@gc@
# modified when garbage was last collected
GC_STAMP="$STATE_DIRECTORY/gc"

AUTOMATIC=true
if [ "${1:-}" = "--now" ]; then
    AUTOMATIC=false
    WAIT_FOR_IDLE=false
    shift
fi

REVISION="${1:-}"
if [ -n "$REVISION" ] && [[ ! "$REVISION" =~ ^[0-9a-f]{40}$ ]]; then
    echo "invalid revision: $REVISION" >&2
    exit 1
fi

# Fetches origin, and sets UPDATE and TARGET_REVISION to whether and what to update to
function find_update() {
    echo "checking for updates"
    if ! git fetch origin; then
        echo "could not fetch updates"
        exit 1
    fi

    UPDATE=false
    TARGET_REVISION="$(git rev-parse --verify origin/main)"
    if [ -n "$REVISION" ]; then
        if [ "$REVISION" != "$TARGET_REVISION" ]; then
            echo "ignoring revision that is not the current origin/main: $REVISION" >&2
            return
        fi

        if ! git merge-base --is-ancestor HEAD "$REVISION"; then
            echo "ignoring revision that is not a descendant of HEAD: $REVISION" >&2
            return
        fi
    fi

    if [ "$(git rev-parse HEAD)" != "$TARGET_REVISION" ] || [ -e "$RETRY_FILE" ]; then
        UPDATE=true
    fi
}

# Sets GC_DUE to whether this run should collect garbage
function find_gc() {
    GC_DUE=false
    if ! $AUTOMATIC || ! $GC_ENABLE; then
        return
    fi

    if [ ! -e "$GC_STAMP" ] ||
        (($(date +%s) - $(stat -c %Y "$GC_STAMP") >= GC_INTERVAL_DAYS * 86400)); then
        GC_DUE=true
    fi
}

# Finds what to do, or exits when there's nothing
function plan() {
    find_update
    find_gc
    if ! $UPDATE && ! $GC_DUE; then
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
plan

if $WAIT_FOR_IDLE; then
    # let other updates (e.g. the update command) run while this one waits
    flock --unlock 9
    wait_for_idle
    flock 9

    # origin/main may have moved on, or another run may have done the work, while this one waited
    plan
fi

if $GC_DUE; then
    # claimed while locked, so concurrent runs don't collect garbage too
    touch "$GC_STAMP"
fi

if $UPDATE; then
    echo "updating to $TARGET_REVISION"
    git reset --hard "$TARGET_REVISION"

    if ! systemd-inhibit --what=sleep:shutdown --who=update --why="Updating NixOS" \
        "${WRAPPER[@]}" "$SWITCH"; then
        # keep older generations to roll back to while the switch fails
        if $GC_DUE; then
            rm -f "$GC_STAMP"
        fi
        exit 1
    fi
fi

# garbage collection doesn't touch the checkout, so the update command can run meanwhile
flock --unlock 9

if $GC_DUE; then
    echo "collecting garbage"
    if ! "${WRAPPER[@]}" "$GC"; then
        rm -f "$GC_STAMP"
        exit 1
    fi
fi
