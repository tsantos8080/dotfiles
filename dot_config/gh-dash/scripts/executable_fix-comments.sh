#!/usr/bin/env bash
# Creates (or reuses) a git worktree on the PR branch and opens Claude Code
# there to address the pending review comments. Claude does not commit or push.
# Remove the worktree when done: git worktree remove <path>
# Usage: fix-comments.sh <repo-path> <owner/repo> <pr-number> <branch>
set -euo pipefail
repo_path=$1 repo=$2 pr=$3 branch=$4
wt=~/Projects/worktrees/$(basename "$repo")-pr-$pr

# If the branch is already checked out somewhere (usually the main folder),
# use that folder: git refuses a second checkout of the same branch.
existing=$(git -C "$repo_path" worktree list --porcelain |
  awk -v ref="branch refs/heads/$branch" '/^worktree /{p=substr($0,10)} $0==ref{print p}')
if [[ -n $existing ]]; then
  wt=$existing
elif [[ ! -d $wt ]]; then
  git -C "$repo_path" fetch origin "+refs/heads/$branch:refs/remotes/origin/$branch"
  if git -C "$repo_path" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$repo_path" worktree add "$wt" "$branch"
  else
    git -C "$repo_path" worktree add --track -b "$branch" "$wt" "origin/$branch"
  fi
fi

cd "$wt"
exec claude "Leia os comentários de revisão ainda não resolvidos da PR #$pr ($repo), usando gh (threads com isResolved=false via GraphQL). Para cada um, mostre o comentário e a correção que você propõe, e espere eu confirmar antes de alterar. Não faça commit nem push sem eu pedir."
