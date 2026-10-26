#!/usr/bin/env bash
# Claude Code hook: desktop notification when Claude finishes or waits for
# you, but only if the terminal running this session is not the focused
# window (X11). Inside tmux, the terminal is the one with the tmux client.
# Usage: notify.sh done|waiting   (hook input JSON on stdin)
set -uo pipefail
input=$(cat)
# CLAUDE_HOOKS_QUIET=1 skips it (e.g. for claude -p in scripts).
[[ -n ${DISPLAY:-} && -z ${CLAUDE_HOOKS_QUIET:-} ]] || exit 0

# X window ids of the terminals showing this session.
windows=()
if [[ -n ${TMUX:-} && -n ${TMUX_PANE:-} ]]; then
  session=$(tmux display -p -t "$TMUX_PANE" '#{session_name}')
  for pid in $(tmux list-clients -t "$session" -F '#{client_pid}'); do
    id=$(tr '\0' '\n' <"/proc/$pid/environ" 2>/dev/null | sed -n 's/^WINDOWID=//p')
    [[ -n $id ]] && windows+=("$id")
  done
elif [[ -n ${WINDOWID:-} ]]; then
  windows+=("$WINDOWID")
fi

active=$(xprop -root _NET_ACTIVE_WINDOW 2>/dev/null | grep -oE '0x[0-9a-f]+$')
if [[ -n $active ]]; then
  for id in "${windows[@]}"; do
    ((id == active)) && exit 0
  done
fi

project=$(basename "$(jq -r '.cwd // empty' <<<"$input")")
where=${project:-Claude Code}
# Plain one-line text, cut to its last ~200 characters at a word boundary.
tail_text() {
  local text
  text=$(sed -E 's/[`*#>]//g' | tr -s '[:space:]' ' ' | sed -E 's/^ //; s/ $//')
  if ((${#text} > 200)); then
    text=${text: -200}
    text="…${text#* }"
  fi
  printf '%s' "$text"
}

case $1 in
  done)
    # Newer Claude Code versions send the reply; otherwise read the transcript.
    reply=$(jq -r '.last_assistant_message // empty' <<<"$input")
    transcript=$(jq -r '.transcript_path // empty' <<<"$input")
    if [[ -z $reply && -f $transcript ]]; then
      reply=$(tail -n 300 "$transcript" | jq -rs '[.[] | select(.type == "assistant")
        | .message.content[]? | select(.type == "text") | .text] | last // empty' 2>/dev/null)
    fi
    notify-send -a "Claude Code" -i dialog-information \
      "Claude finished — $where" "$(tail_text <<<"$reply")"
    ;;
  waiting)
    # Permission prompts carry a message; AskUserQuestion carries the question.
    text=$(jq -r '.message // .tool_input.questions[0].question // empty' <<<"$input")
    notify-send -a "Claude Code" -i dialog-question \
      "Claude is waiting for you — $where" "$(tail_text <<<"$text")"
    ;;
esac
