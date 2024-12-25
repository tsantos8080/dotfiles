#!/usr/bin/bash

if which nvim > /dev/null 2>&1; then
	echo "\e[32mneovim is already installed. skipping...\e[0m"
else
	# Install neovim
	curl -LO https://github.com/neovim/neovim/releases/download/v0.10.0/nvim.appimage
	chmod u+x nvim.appimage
	sudo mv ./nvim.appimage /usr/bin/nvim
fi

# Install dependencies
sudo apt install -y libfuse2 ripgrep fd-find build-essential php-cli composer python3 python3-pip python3-pynvim

if ! nvm --version > /dev/null 2>&1; then
	echo "\e[32mnvm is already installed. skipping...\e[0m"
else
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

	nvm install v22 && nvm use v22

	source ~/.bashrc
	source ~/.zshrc
fi

# Create symlinks
rm -rf ~/.config/nvim
ln -sf ${PWD}/.config/nvim ~/.config/nvim

