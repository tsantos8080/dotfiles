#!/bin/bash

if which mise > /dev/null 2>&1; then
	echo "\e[32mmise is already installed. skipping...\e[0m"
else
	brew install mise
fi

# Configure
mise trust ${PWD}
mise install

echo -e "\033[33mPlease run 'source ~/.zshrc' manually for the changes to take effect.\033[0m"

