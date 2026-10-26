#!/usr/bin/env bash
# Asks Claude to explain the PR's failing checks and shows the answer in glow.
# Only reads: nothing is re-run or changed.
# Usage: ci-failures.sh <owner/repo> <pr-number>
set -euo pipefail
repo=$1 pr=$2
source "$(dirname "$0")/spinner.sh"

failed_checks() {
  gh pr checks "$pr" --repo "$repo" --json bucket,workflow,name,link \
    --jq '.[] | select(.bucket == "fail") | [.workflow, .name, .link] | @tsv'
}

read_logs() {
  while IFS=$'\t' read -r workflow name link; do
    echo "## $workflow / $name"
    echo "$link"
    # GitHub Actions links end in /job/<id>; other checks have no log here.
    if [[ $link =~ /actions/runs/[0-9]+/job/([0-9]+) ]]; then
      # The error is usually at the end; the cut keeps the prompt small.
      gh run view --repo "$repo" --job "${BASH_REMATCH[1]}" --log-failed | tail -c 60000
    else
      echo "(check fora do GitHub Actions: sem log disponível)"
    fi
    echo
  done <<<"$failed"
}

explain() {
  printf '%s\n' "$logs" | claude -p "Estes são os logs dos checks que falharam na PR #$pr ($repo). Explique em português do Brasil, em markdown curto:
1. O que falhou, em uma frase por check.
2. A causa provável, com arquivo:linha e a mensagem de erro relevante.
3. Se parece problema da PR ou do ambiente (teste instável, timeout, serviço fora). Diga se é certeza ou hipótese.
Não invente: se o log não mostrar a causa, diga isso."
}

# gh exits non-zero when checks fail, which is exactly the case we want.
failed=$(spin "Checking PR #$pr..." failed_checks || true)
if [[ -z $failed ]]; then
  echo "No failing checks on PR #$pr."
  read -rn1 -p "Press any key to go back."
  exit 0
fi

logs=$(spin "Reading the logs of the failing checks on PR #$pr..." read_logs)
answer=$(spin "Asking Claude about the failures..." explain)
printf '%s\n' "$answer" | "$(dirname "$0")/show-markdown.sh"
