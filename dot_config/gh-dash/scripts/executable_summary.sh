#!/usr/bin/env bash
# Asks Claude for a short summary of the PR and shows it in glow.
# Usage: summary.sh <owner/repo> <pr-number>
set -euo pipefail
repo=$1 pr=$2
source "$(dirname "$0")/spinner.sh"

summarize() {
  {
    gh pr view "$pr" --repo "$repo" --json title,author,body,files \
      --template '# {{.title}} (por {{.author.login}})
{{.body}}

Arquivos:
{{range .files}}- {{.path}} (+{{.additions}} -{{.deletions}})
{{end}}'
    echo
    echo "Diff (pode estar cortado):"
    # Large diffs are cut so the prompt stays small.
    gh pr diff "$pr" --repo "$repo" | head -c 150000
  } | CLAUDE_HOOKS_QUIET=1 claude -p "Resuma esta pull request em português do Brasil, em markdown curto:
1. O que muda e por quê (2-3 frases).
2. Onde está o risco (arquivo:linha quando der).
3. O que olhar primeiro na revisão.
Não invente: se algo não estiver no diff, diga que não dá para saber."
}

window_status loading
summary=$(spin "Summarizing PR #$pr..." summarize)
window_status clear
printf '%s\n' "$summary" | "$(dirname "$0")/show-markdown.sh"
