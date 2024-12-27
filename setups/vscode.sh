#!/usr/bin/bash

if which code > /dev/null 2>&1; then
	echo "\e[32mvscode is already installed. skipping...\e[0m"
else
	wget -O /tmp/vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
	sudo dpkg -i /tmp/vscode.deb
	rm -rf /tmp/vscode.deb
fi

# Extensions
code --install-extension github.copilot
code --install-extension github.copilot-chat
code --install-extension gruntfuggly.todo-tree
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-vscode-remote.remote-containers
code --install-extension ms-vscode.makefile-tools
code --install-extension namesmt.blade-php
code --install-extension nidu.copy-json-path
code --install-extension vscodevim.vim
code --install-extension waderyan.gitblame
code --install-extension xdebug.php-debug

# Keybindings
mv -f ~/.config/Code/User/keybindings.json ~/.config/Code/User/keybindings.json.bak 2> /dev/null
ln -sf ${PWD}/.config/Code/User/keybindings.json ~/.config/Code/User/keybindings.json

