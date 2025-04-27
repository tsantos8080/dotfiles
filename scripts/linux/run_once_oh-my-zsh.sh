#!/usr/bin/bash

if grep -q "oh-my-zsh.sh" "$HOME/.zshrc"; then
	echo "\e[32moh-my-zsh is already installed. skipping...\e[0m"
else
	rm -rf ~/.oh-my-zsh
	sudo apt install -y zsh curl

	RUNZSH=no CHSH=no sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Set zsh as default shell
sudo chsh -s /usr/bin/zsh

# Plugins
if [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
	echo "\e[32moh-my-zsh autosuggestions plugin is already installed. skipping...\e[0m"
else
	git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi

if [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-you-should-use" ]; then
	echo "\e[32moh-my-zsh you-should-use plugin is already installed. skipping...\e[0m"
else
	git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use
fi

