#!/usr/bin/bash

if which kitty > /dev/null 2>&1; then
	echo "\e[32mkitty is already installed. skipping...\e[0m"
else
	sudo apt install kitty -y
fi

if ls ~/.fonts/JetBrainsMonoNerdFont* > /dev/null 2>&1; then
	echo "\e[32mfont is already installed. skipping...\e[0m"
else
	# Install nerd fonts
	mkdir -p ${HOME}/.fonts
	wget -O ${HOME}/.fonts/font.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip
	unzip -o ${HOME}/.fonts/font.zip -d ${HOME}/.fonts
	fc-cache -f -v
fi
