#!/usr/bin/env bash
# Renders this chezmoi source into a temporary home (without running scripts or
# touching the real home and chezmoi state) and validates the result:
# - agent skills: frontmatter, names and Claude Code symlinks
# - rendered JSON config files
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
cz init \
	--promptString 'Diretório do grafo do Logseq=~/Documents/Notes' \
	--promptString 'SONAR_TOKEN (Enter para pular)=' > /dev/null
cz apply --exclude scripts --force

echo "== Validating skills"
"${PYTHON:-python3}" "$SRC/.github/scripts/validate_skills.py" "$DEST" || failures=$((failures + 1))

echo "== Validating rendered JSON"
"${PYTHON:-python3}" -m json.tool "$DEST/.claude/settings.json" > /dev/null \
	&& echo "ok   .claude/settings.json" || fail ".claude/settings.json: invalid JSON"

echo "== Validating pinned mise tools and shell configuration"
"${PYTHON:-python3}" - "$DEST/.config/mise/config.toml" <<'PY'
import re
import sys
import tomllib

with open(sys.argv[1], "rb") as stream:
    config = tomllib.load(stream)
for tool, options in config["tools"].items():
    version = options["version"] if isinstance(options, dict) else options
    if not (re.fullmatch(r"\d+\.\d+\.\d+", version)
            or re.fullmatch(r"autobuild-\d{4}-\d{2}-\d{2}-\d{2}-\d{2}", version)):
        raise SystemExit(f"{tool}: expected pinned version, found {version}")
print("ok   pinned mise versions")
PY
bash -n "$DEST/.bash_aliases"
zsh -n "$DEST/.zshrc"

echo "== Exercising bootstrap failure and repeat-install paths"
"${PYTHON:-python3}" "$SRC/.github/scripts/test_bootstrap.py"

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
		'#!/usr/bin/env zsh')
			zsh -n "$out" || fail "$rel: zsh syntax error"
			;;
		'#!/usr/bin/env bash' | '#!/usr/bin/bash' | '#!/bin/bash' | '#!/bin/sh')
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
