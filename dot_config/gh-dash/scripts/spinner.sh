# Sourced by the gh-dash scripts. Runs a slow command while a spinner with the
# elapsed seconds shows on stderr. The command's stderr is held back until the
# spinner stops, so errors don't mix with it:
#   result=$(spin "Summarizing PR #123..." some_function args)

spin() {
  local msg=$1 err status=0 pid
  shift
  err=$(mktemp)
  tput civis >&2 2>/dev/null || true
  (
    frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
    i=0 SECONDS=0
    while :; do
      printf '\r\033[K%s %s %ds' "${frames[i++ % ${#frames[@]}]}" "$msg" "$SECONDS" >&2
      sleep 0.1
    done
  ) >/dev/null &
  pid=$!
  "$@" 2>"$err" || status=$?
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  printf '\r\033[K' >&2
  tput cnorm >&2 2>/dev/null || true
  cat "$err" >&2
  rm -f "$err"
  return "$status"
}

# Marks the tmux window opened by tmux-run.sh, e.g. "summary #123 ✓", so the
# state shows in the status bar. Does nothing outside such a window.
window_status() {
  [[ -n ${TMUX:-} && -n ${GHDASH_WINDOW:-} ]] || return 0
  tmux rename-window -t "$TMUX_PANE" "$GHDASH_WINDOW $1"
}
