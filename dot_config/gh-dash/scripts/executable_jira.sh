#!/usr/bin/env bash
# Opens the Jira issue named in the PR branch (e.g. fix/PTB-6532-...).
# Usage: jira.sh <branch>
set -euo pipefail
key=$(grep -oiE '[a-z]+-[0-9]+' <<<"$1" | head -1 | tr '[:lower:]' '[:upper:]' || true)
if [[ -z $key ]]; then
  echo "No Jira issue in the branch name: $1"
  read -rn1 -p "Press any key to go back."
  exit 0
fi
xdg-open "https://melhorenvio.atlassian.net/browse/$key" >/dev/null 2>&1 &
