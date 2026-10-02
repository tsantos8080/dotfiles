#!/usr/bin/env bash
# Renders this chezmoi source into a temporary home (without running scripts or
# touching the real home and chezmoi state) and validates the result:
# - agent skills: frontmatter, names and Claude Code symlinks
# - run_once scripts: syntax (bash -n / zsh -n) and shellcheck when available
#
# Usage: .github/scripts/validate.sh   (PYTHON=<python with pyyaml> to override)
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

DEST="$WORK/home"
mkdir -p "$DEST"

cz() {
	chezmoi --source "$SRC" --config "$WORK/chezmoi.toml" \
		--persistent-state "$WORK/state.boltdb" --cache "$WORK/cache" \
		--destination "$DEST" --no-tty "$@"
}

failures=0
fail() {
	echo "::error::$*"
	failures=$((failures + 1))
}

echo "== Rendering source for $(uname -s)"
cz init --promptString 'Diretório do grafo do Logseq=~/Documents/Notes' > /dev/null
cz apply --exclude scripts --force

echo "== Validating skills"
"${PYTHON:-python3}" "$SRC/.github/scripts/validate_skills.py" "$DEST" || failures=$((failures + 1))

echo "== Validating scripts"
while IFS= read -r rel; do
	file="$SRC/$rel"
	out="$WORK/rendered/$rel"
	mkdir -p "$(dirname "$out")"
	if [[ "$rel" == *.tmpl ]]; then
		if ! cz execute-template < "$file" > "$out"; then
			fail "$rel: template failed to render"
			continue
		fi
	else
		cp "$file" "$out"
	fi

	before=$failures
	shebang="$(head -n 1 "$out")"
	case "$shebang" in
		*zsh*)
			zsh -n "$out" || fail "$rel: zsh syntax error"
			;;
		*bash* | *sh*)
			bash -n "$out" || fail "$rel: bash syntax error"
			if command -v shellcheck > /dev/null 2>&1; then
				# SC1090: scripts source ~/.bashrc and ~/.zshrc on purpose; shellcheck
				# can't follow those paths, which is expected in dotfiles.
				shellcheck --severity=warning --shell=bash --exclude=SC1090 "$out" || fail "$rel: shellcheck"
			fi
			;;
		*)
			fail "$rel: missing or unknown shebang: $shebang"
			;;
	esac
	((failures == before)) && echo "ok   $rel"
done < <(cz managed --include scripts --path-style source-relative)

if ((failures > 0)); then
	echo "== $failures check(s) failed"
	exit 1
fi
echo "== All checks passed"
