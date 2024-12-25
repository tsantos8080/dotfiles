#!/usr/bin/bash

if which i3 > /dev/null 2>&1; then
	echo "\e[32mi3 is already installed. skipping...\e[0m"
else
	# Install i3
	/usr/lib/apt/apt-helper download-file https://debian.sur5r.net/i3/pool/main/s/sur5r-keyring/sur5r-keyring_2024.03.04_all.deb keyring.deb SHA256:f9bb4340b5ce0ded29b7e014ee9ce788006e9bbfe31e96c09b2118ab91fca734;
	sudo apt install ./keyring.deb;
	echo "deb http://debian.sur5r.net/i3/ $(grep '^DISTRIB_CODENAME=' /etc/lsb-release | cut -f2 -d=) universe" | sudo tee /etc/apt/sources.list.d/sur5r-i3.list
	sudo apt update -y
	sudo apt install i3 -y
	rm -rf ./keyring.deb

	# Install used packages for this i3 config
	sudo apt install kitty feh -y

	# Install i3blocks
	sudo apt install -y autoconf
	sudo rm -rf /tmp/i3blocks
	git clone https://github.com/vivien/i3blocks /tmp/i3blocks
	cd /tmp/i3blocks
	./autogen.sh
	./configure
	make
	sudo make install
	sudo rm -rf /tmp/i3blocks

	# Setup i3blocks scripts
	cd .config/i3blocks/scripts/memory2
	make
	cd ../../../..

	# i3blocks mediaplayer dependency
	sudo apt install -y playerctl
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

# If picom is not installed
if which picom > /dev/null 2>&1; then
	echo "\e[32mpicom is already installed. skipping...\e[0m"
else
	# Install picom
	sudo apt install -y libconfig-dev libdbus-1-dev libegl-dev libev-dev libgl-dev libepoxy-dev libpcre2-dev libpixman-1-dev libx11-xcb-dev libxcb1-dev libxcb-composite0-dev libxcb-damage0-dev libxcb-glx0-dev libxcb-image0-dev libxcb-present-dev libxcb-randr0-dev libxcb-render0-dev libxcb-render-util0-dev libxcb-shape0-dev libxcb-util-dev libxcb-xfixes0-dev meson ninja-build uthash-dev cmake
	rm -rf /tmp/picom
	git clone https://github.com/yshui/picom /tmp/picom
	cd /tmp/picom
	meson setup --buildtype=release build
	ninja -C build
	sudo ninja -C build install
	rm -rf /tmp/picom
fi

# Create symlinks
rm -rf ~/.config/i3
ln -sf ${PWD}/.config/i3/ ~/.config/i3

rm -rf ~/.config/i3blocks
ln -sf ${PWD}/.config/i3blocks/ ~/.config/i3blocks

rm -rf ~/.config/picom
ln -sf ${PWD}/.config/picom/ ~/.config/picom
