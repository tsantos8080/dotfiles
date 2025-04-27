#!/bin/bash

if which mise > /dev/null 2>&1; then
	echo "\e[32mmise is already installed. skipping...\e[0m"
else
	brew install mise

	# PHP dependencies
	brew install autoconf gmp libsodium bison re2c libxml2 pkgconf libgd libiconv libzip
fi

# Configure
mise trust ${PWD}

PHP_CONFIGURE_OPTIONS="--with-iconv=$(brew --prefix libiconv) --with-openssl=$(brew --prefix openssl)" \
	mise install

echo -e "\033[33mPlease run 'source ~/.zshrc' manually for the changes to take effect.\033[0m"
