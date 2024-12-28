#!/usr/bin/bash

if which flameshot > /dev/null 2>&1; then
	echo "\e[32mflameshot is already installed. skipping...\e[0m"
else
	sudo apt install -y flameshot
fi

