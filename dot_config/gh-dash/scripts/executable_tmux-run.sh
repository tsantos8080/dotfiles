#!/usr/bin/env bash
# Runs a command in a new tmux window named "<label> #<pr>" so gh-dash stays
# free. If that window already exists, switches to it instead. Outside tmux,
# runs the command in place. Scripts can mark the window name with
# window_status (spinner.sh): "summary #123 ◌" while loading, ✓ when ready,
# and this wrapper sets ✗ on failure.
# Usage: tmux-run.sh <label> <pr-number> <command> [args...]
set -euo pipefail

if [[ ${1:-} == --inner ]]; then
  # Inside the new window: keep it open on failure so the error can be read.
  export GHDASH_WINDOW=$2
  shift 2
  status=0
  "$@" || status=$?
  if ((status != 0)); then
    tmux rename-window -t "$TMUX_PANE" "$GHDASH_WINDOW ✗"
    echo
    read -rn1 -p "Failed (exit code $status). Press any key to close."
  fi
  exit "$status"
fi

label=$1 pr=$2
shift 2
if [[ -z ${TMUX:-} ]]; then
  exec "$@"
fi

name="$label #$pr"
existing=$(tmux list-windows -F '#{window_id}	#{window_name}' |
  awk -F'\t' -v n="$name" '$2 == n || index($2, n " ") == 1 { print $1; exit }')
if [[ -n $existing ]]; then
  tmux select-window -t "$existing"
else
  tmux new-window -n "$name" -- "$0" --inner "$name" "$@"
fi
