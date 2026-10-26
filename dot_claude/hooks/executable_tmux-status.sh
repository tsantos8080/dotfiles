#!/usr/bin/env bash
# Claude Code hook: shows the session state at the end of the tmux window
# name: "claude ◌" while working and "claude ?" when waiting for an answer or
# permission. "clear" removes the mark; "reset" also gives the window back to
# tmux's automatic naming.
# Set CLAUDE_HOOKS_QUIET=1 to skip it (e.g. for claude -p in scripts).
# Usage: tmux-status.sh <symbol>|clear|reset
cat >/dev/null # hook input on stdin is not needed
[[ -n ${TMUX:-} && -n ${TMUX_PANE:-} && -z ${CLAUDE_HOOKS_QUIET:-} ]] || exit 0

name=$(tmux display -p -t "$TMUX_PANE" '#{window_name}')
# Marks at the start of the name and ✓/✗ are from older versions of this hook.
base=$(sed -E 's/^(◌|\?) //; s/ (◌|✓|✗|\?)$//' <<<"$name")
case $1 in
  clear | reset) new=$base ;;
  *) new="$base $1" ;;
esac
[[ $new == "$name" ]] || tmux rename-window -t "$TMUX_PANE" "$new"
[[ $1 != reset ]] || tmux set-option -w -t "$TMUX_PANE" automatic-rename on
