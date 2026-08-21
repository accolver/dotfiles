#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$SCRIPT_DIR/unraid_install.sh"

failures=0

fail() {
  echo "not ok - $1" >&2
  failures=$((failures + 1))
}

pass() {
  echo "ok - $1"
}

run_script() {
  local output status
  set +e
  output="$($SCRIPT "$@" 2>&1)"
  status=$?
  set -e
  printf '%s\n' "$status"
  printf '%s\n' "$output"
}

assert_success_contains() {
  local name="$1"
  local needle="$2"
  shift 2
  local result status output
  result="$(run_script "$@")"
  status="$(printf '%s\n' "$result" | sed -n '1p')"
  output="$(printf '%s\n' "$result" | sed '1d')"

  if [ "$status" -ne 0 ]; then
    fail "$name exited with $status; output: $output"
    return
  fi
  if ! grep -qF -- "$needle" <<<"$output"; then
    fail "$name did not contain: $needle"
    echo "$output" >&2
    return
  fi
  pass "$name"
}

assert_success_not_contains() {
  local name="$1"
  local needle="$2"
  shift 2
  local result status output
  result="$(run_script "$@")"
  status="$(printf '%s\n' "$result" | sed -n '1p')"
  output="$(printf '%s\n' "$result" | sed '1d')"

  if [ "$status" -ne 0 ]; then
    fail "$name exited with $status; output: $output"
    return
  fi
  if grep -qF -- "$needle" <<<"$output"; then
    fail "$name unexpectedly contained: $needle"
    echo "$output" >&2
    return
  fi
  pass "$name"
}

assert_success_contains "help documents upgrade flag" "--upgrade" --help
assert_success_contains "help documents no git pull flag" "--no-git-pull" --help
assert_success_contains "help documents no pi update flag" "--no-pi-update" --help

assert_success_contains "manual dry-run pulls dotfiles" "[DRY RUN] git -C" --dry-run --no-nvim-sync
assert_success_contains "manual dry-run updates Pi packages" "[DRY RUN] pi update" --dry-run --no-nvim-sync
assert_success_contains "explicit upgrade mode is accepted" "Mode: upgrade" --dry-run --upgrade --no-nvim-sync
assert_success_contains "explicit upgrade pulls dotfiles" "[DRY RUN] git -C" --dry-run --upgrade --no-nvim-sync

assert_success_contains "startup mode skips git pull" "Startup mode: skipping dotfiles git pull" --dry-run --startup
assert_success_contains "startup mode skips Pi updates" "Startup mode: skipping network Pi package installs and updates" --dry-run --startup
assert_success_contains "startup mode skips Neovim" "Skipping Neovim sync" --dry-run --startup

assert_success_not_contains "no-git-pull suppresses git pull" "pull --ff-only" --dry-run --no-git-pull --no-nvim-sync
assert_success_not_contains "no-pi-update suppresses pi update" "pi update" --dry-run --no-pi-update --no-nvim-sync

if [ "$failures" -gt 0 ]; then
  echo "$failures test(s) failed" >&2
  exit 1
fi

echo "all unraid_install tests passed"
