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
socket_path=${HERDR_SOCKET_PATH:-"$HOME/.config/herdr/sessions/${HERDR_SESSION:-main}/herdr.sock"}

[ -n "$pane_id" ] || exit 0

socket_request() {
    method=$1
    params=$2

    if [ -S "$socket_path" ] && command -v nc >/dev/null 2>&1; then
        printf '{"id":"smart-pane-nav","method":"%s","params":%s}\n' "$method" "$params" |
            nc -U "$socket_path" |
            sed -n '1p'
        return 0
    fi

    return 1
}

# Prefer the raw Herdr socket API over the Herdr CLI. The CLI can be newer than
# a long-running server after upgrades, which makes command keybindings fail
# with protocol_mismatch until the whole Herdr server is restarted.
process_params=$(jq -cn --arg pane_id "$pane_id" '{pane_id: $pane_id}')
process_response=$(socket_request 'pane.process_info' "$process_params" 2>/dev/null || true)

if printf '%s\n' "$process_response" |
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
    send_params=$(jq -cn --arg pane_id "$pane_id" --arg key "$key" '{pane_id: $pane_id, keys: [$key]}')
    socket_request 'pane.send_keys' "$send_params" >/dev/null 2>&1 && exit 0
    exec "$herdr_bin" pane send-keys "$pane_id" "$key"
fi

focus_params=$(jq -cn --arg pane_id "$pane_id" --arg direction "$direction" '{pane_id: $pane_id, direction: $direction}')
socket_request 'pane.focus_direction' "$focus_params" >/dev/null 2>&1 && exit 0

exec "$herdr_bin" pane focus \
    --direction "$direction" \
    --pane "$pane_id"
