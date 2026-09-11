#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$SCRIPT_DIR/install.sh"

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

run_script_with_env() {
  local env_var="$1"
  shift
  local output status
  set +e
  output="$(env "$env_var" "$SCRIPT" "$@" 2>&1)"
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

assert_failure_contains() {
  local name="$1"
  local needle="$2"
  shift 2
  local result status output
  result="$(run_script "$@")"
  status="$(printf '%s\n' "$result" | sed -n '1p')"
  output="$(printf '%s\n' "$result" | sed '1d')"

  if [ "$status" -eq 0 ]; then
    fail "$name unexpectedly succeeded with 0; output: $output"
    return
  fi
  if ! grep -qF -- "$needle" <<<"$output"; then
    fail "$name did not contain: $needle"
    echo "$output" >&2
    return
  fi
  pass "$name"
}

assert_env_success_contains() {
  local name="$1"
  local env_var="$2"
  local needle="$3"
  shift 3
  local result status output
  result="$(run_script_with_env "$env_var" "$@")"
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

assert_success_contains "help displays usage" "Usage: " --help
assert_success_contains "help documents skip-brew flag" "--skip-brew" --help
assert_success_contains "help documents no-brew flag" "--no-brew" --help
assert_success_contains "help documents dry-run flag" "--dry-run" --help
assert_success_contains "help documents inject-secrets flag" "--inject-secrets" --help

assert_success_contains "dry-run defaults to prompting for brew" "Would prompt to install Brewfile dependencies" --dry-run
assert_success_contains "dry-run with --skip-brew skips brew" "Skipping Brewfile installation (--skip-brew)" --dry-run --skip-brew
assert_success_contains "dry-run with --no-brew skips brew" "Skipping Brewfile installation (--skip-brew)" --dry-run --no-brew
assert_success_not_contains "--skip-brew suppresses prompt message" "Would prompt to install Brewfile dependencies" --dry-run --skip-brew

assert_env_success_contains "SKIP_BREW=1 environment variable skips brew" "SKIP_BREW=1" "Skipping Brewfile installation (--skip-brew)" --dry-run
assert_env_success_contains "SKIP_BREW=true environment variable skips brew" "SKIP_BREW=true" "Skipping Brewfile installation (--skip-brew)" --dry-run

assert_failure_contains "unknown option reports error" "Unknown argument: --unknown-flag" --unknown-flag

if [ "$failures" -gt 0 ]; then
  echo "$failures test(s) failed" >&2
  exit 1
fi

echo "all install tests passed"
