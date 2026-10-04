#!/usr/bin/env bash
# Run as a fresh unprivileged user in the Ubuntu container used by CI.
set -euo pipefail
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
source_dir=${DOTFILES_SOURCE:?Set DOTFILES_SOURCE to the checkout}

cz() { chezmoi --source "$source_dir" --no-tty "$@"; }

cz init --promptDefaults
# Apply files first to exercise preservation of a pre-existing managed .zshrc.
cz apply --exclude scripts
expected_zshrc=$(sha256sum "$HOME/.zshrc")
cz apply --verbose
test "$(sha256sum "$HOME/.zshrc")" = "$expected_zshrc"

# A second apply must succeed without changing the rendered configuration.
test -z "$(cz diff --exclude scripts --no-pager)"
cz apply --verbose
test -z "$(cz diff --exclude scripts --no-pager)"
test "$(getent passwd "$(id -un)" | cut -d: -f7)" = /usr/bin/zsh
test -f "$HOME/.oh-my-zsh/oh-my-zsh.sh"
test ! -d "$HOME/.nvm"

# Verify PATH activation in fresh shells, not only in the bootstrap's PATH.
env PATH=/usr/bin:/bin bash -ic 'set -e; command -v chezmoi; command -v mise; node --version; mise doctor'
env PATH=/usr/bin:/bin zsh -ic 'set -e; command -v chezmoi; command -v mise; node --version; mise doctor'
mise exec -- python -c 'import pynvim'
mise exec -- nvim --clean --headless "+lua if vim.fn.has('python3') ~= 1 then vim.cmd('cquit 1') end" '+quitall'
mise exec -- php -r '
foreach (["curl", "dom", "gd", "intl", "mbstring", "pdo_mysql", "pdo_sqlite", "zip"] as $ext) {
    if (!extension_loaded($ext)) { fwrite(STDERR, "Missing PHP extension: $ext\n"); exit(1); }
}'
mise exec -- composer --version
mise exec -- python --version
mise exec -- nvim --version
echo 'Ubuntu bootstrap and second apply passed.'
