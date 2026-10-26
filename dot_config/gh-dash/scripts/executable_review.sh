#!/usr/bin/env bash
# Opens Claude Code in the repo and reviews the PR. Findings stay in the
# terminal: /code-review only posts to GitHub with --comment.
# Usage: review.sh <repo-path> <pr-number>
set -euo pipefail
cd "$1"
exec claude "/code-review $2"
