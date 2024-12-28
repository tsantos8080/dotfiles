#!/usr/bin/bash

if which mise > /dev/null 2>&1; then
	echo "\e[32mmise is already installed. skipping...\e[0m"
else
	curl https://mise.run | sh
fi

# PHP dependencies
sudo apt install -y bison re2c libxml2 libxml2-dev libssl-dev libsqlite3-dev \
	sqlite3 libcurl4-openssl-dev curl libgd-dev libonig-dev libpq-dev \
	libreadline-dev libzip-dev

# Configure
mise trust ${PWD}
mise install

echo -e "\033[33mPlease run 'source ~/.zshrc' manually for the changes to take effect.\033[0m"

