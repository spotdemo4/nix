#!/usr/bin/env bash

NTFY_URL=@ntfyUrl@

if [[ "${1:-}" == "--trigger" ]]; then
    revision="${NTFY_MESSAGE:-}"

    if [[ ! "$revision" =~ ^[0-9a-f]{40}$ ]]; then
        echo "ignoring invalid revision: $revision" >&2
        exit 0
    fi

    exec systemctl start "update@$revision.service"
fi

exec ntfy subscribe "$NTFY_URL" "$0 --trigger"
