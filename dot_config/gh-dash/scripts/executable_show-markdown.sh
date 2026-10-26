#!/usr/bin/env bash
# Renders markdown from stdin with glow at the terminal's full width and opens
# it in less with mouse-wheel scrolling (q quits, / searches).
set -euo pipefail
width=$(($(tput cols) - 2))
# glow drops colors when not writing to a terminal, so the style is fixed.
glow --style dark --width "$width" - | less -R --mouse --wheel-lines=3
