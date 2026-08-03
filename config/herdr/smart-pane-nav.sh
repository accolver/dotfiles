#!/bin/sh

set -u

direction=${1:-}

case "$direction" in
    left)
        key="ctrl+h"
        ;;
    right)
        key="ctrl+l"
        ;;
    *)
        printf 'usage: %s left|right\n' "$0" >&2
        exit 2
        ;;
esac

pane_id=${HERDR_ACTIVE_PANE_ID:-${HERDR_PANE_ID:-}}
herdr_bin=${HERDR_BIN_PATH:-herdr}

[ -n "$pane_id" ] || exit 0

if "$herdr_bin" pane process-info --pane "$pane_id" 2>/dev/null |
    jq -e '
        any(
            .result.process_info.foreground_processes[]?;
            (
                [.name, .argv0]
                | map(select(type == "string") | split("/")[-1])
                | any(.[]; test("^(n?vim(diff)?|view)$"))
            )
        )
    ' >/dev/null 2>&1; then
    exec "$herdr_bin" pane send-keys "$pane_id" "$key"
fi

exec "$herdr_bin" pane focus \
    --direction "$direction" \
    --pane "$pane_id"
