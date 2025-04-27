#!/bin/bash

if which nvim > /dev/null 2>&1; then
	echo "\e[32mnvim is already installed. skipping...\e[0m"
else
	brew install nvim pyvim ripgrep
fi

