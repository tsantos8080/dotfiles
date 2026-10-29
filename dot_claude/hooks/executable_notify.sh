#!/usr/bin/env bash
# Claude Code hook: notification when Claude waits for you, but only if the
# terminal running this session is not the focused window (X11) or the screen
# is locked. Inside tmux, the terminal is the one with the tmux client.
# Desktop via notify-send; phone/watch via Pushover's e-mail gateway when
# PUSHOVER_EMAIL is set (settings.json env, from the chezmoi config).
# Usage: notify.sh waiting   (hook input JSON on stdin)
set -uo pipefail
input=$(cat)
# CLAUDE_HOOKS_QUIET=1 skips it (e.g. for claude -p in scripts).
[[ -z ${CLAUDE_HOOKS_QUIET:-} ]] || exit 0
pushover=
[[ -n ${PUSHOVER_EMAIL:-} ]] && pushover=1
[[ -n ${DISPLAY:-} || -n $pushover ]] || exit 0

locked=
gdbus call --session --dest org.gnome.ScreenSaver --object-path /org/gnome/ScreenSaver \
  --method org.gnome.ScreenSaver.GetActive 2>/dev/null | grep -q true && locked=1

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
if [[ -n $active && -z $locked ]]; then
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
  waiting)
    # Permission prompts carry a message; AskUserQuestion carries the question.
    text=$(jq -r '.message // .tool_input.questions[0].question // empty' <<<"$input")
    title="Claude is waiting for you — $where"
    body=$(tail_text <<<"$text")
    if [[ -n ${DISPLAY:-} ]]; then
      notify-send -a "Claude Code" -i dialog-question "$title" "$body"
    fi
    if [[ -n $pushover ]]; then
      # Straight to the pomail.net MX, like adp-cli; the subject is the title.
      subject="=?UTF-8?B?$(printf '%s' "$title" | base64 -w0)?="
      printf 'From: claude-code@example.com\r\nTo: %s\r\nSubject: %s\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n%s\r\n' \
        "$PUSHOVER_EMAIL" "$subject" "${body:-$title}" |
        curl -sS --max-time 15 smtp://pomail.pushover.net:25 \
          --mail-from claude-code@example.com --mail-rcpt "$PUSHOVER_EMAIL" --upload-file - >/dev/null
    fi
    ;;
esac
