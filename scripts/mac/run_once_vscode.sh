#!/bin/bash

if which code > /dev/null 2>&1; then
	echo "\e[32mvscode is already installed. skipping...\e[0m"
else
	brew install --cask visual-studio-code
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
code --install-extension teabyii.ayu

