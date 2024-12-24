.ONESHELL:
SHELL := /bin/zsh

all:

install:
	@# Install Window Tilling Manager
	@/usr/lib/apt/apt-helper download-file https://debian.sur5r.net/i3/pool/main/s/sur5r-keyring/sur5r-keyring_2024.03.04_all.deb keyring.deb SHA256:f9bb4340b5ce0ded29b7e014ee9ce788006e9bbfe31e96c09b2118ab91fca734;
	@sudo apt install ./keyring.deb;
	@echo "deb http://debian.sur5r.net/i3/ $$(grep '^DISTRIB_CODENAME=' /etc/lsb-release | cut -f2 -d=) universe" | sudo tee /etc/apt/sources.list.d/sur5r-i3.list
	@sudo apt update -y
	@sudo apt install i3 i3blocks -y
	@rm -rf ./keyring.deb

	@# Install kitty, feh, flameshot
	@sudo apt install kitty feh -y

	@# Install nerd fonts
	@mkdir -p ${HOME}/.fonts
	@wget -O ${HOME}/.fonts/font.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip
	@unzip -o ${HOME}/.fonts/font.zip -d ${HOME}/.fonts
	@fc-cache -f -v

	@# Install neovim
	@curl -LO https://github.com/neovim/neovim/releases/download/v0.10.0/nvim.appimage
	@chmod u+x nvim.appimage
	@sudo mv ./nvim.appimage /usr/bin/nvim

	@# Install dependencies
	@sudo apt install libfuse2 ripgrep fd-find build-essential php-cli composer python3 python3-pip python3-pynvim -y
	@curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
	@source ~/.bashrc
	@source ~/.zshrc
	@nvm install --lts && nvm use --lts
			
	@# Link nvim
	@rm -rf ~/.config/nvim
	@ln -sf ${PWD}/.config/nvim ~/.config/nvim

	@# Link i3
	@rm -rf ~/.config/i3
	@ln -sf ${PWD}/.config/i3/ ~/.config/i3

	@# Link i3blocks
	@rm -rf ~/.config/i3blocks
	@ln -sf ${PWD}/.config/i3blocks/ ~/.config/i3blocks

	@# Link picom
	@rm -rf ~/.config/picom
	@ln -sf ${PWD}/.config/picom/ ~/.config/picom

	@# Link flameshot
	@rm -rf ~/.config/flameshot
	@ln -sf ${PWD}/.config/flameshot/ ~/.config/flameshot

	@#Install picom
	@sudo apt install -y libconfig-dev libdbus-1-dev libegl-dev libev-dev libgl-dev libepoxy-dev libpcre2-dev libpixman-1-dev libx11-xcb-dev libxcb1-dev libxcb-composite0-dev libxcb-damage0-dev libxcb-glx0-dev libxcb-image0-dev libxcb-present-dev libxcb-randr0-dev libxcb-render0-dev libxcb-render-util0-dev libxcb-shape0-dev libxcb-util-dev libxcb-xfixes0-dev meson ninja-build uthash-dev cmake
	@rm -rf /tmp/picom
	@git clone https://github.com/yshui/picom /tmp/picom
	@cd /tmp/picom
	@meson setup --buildtype=release build
	@ninja -C build
	@sudo ninja -C build install
	@rm -rf /tmp/picom

	@#Install i3blocks
	@sudo apt install -y autoconf
	@sudo rm -rf /tmp/i3blocks
	@git clone https://github.com/vivien/i3blocks /tmp/i3blocks
	@cd /tmp/i3blocks
	@./autogen.sh
	@./configure
	@make
	@sudo make install
	@sudo rm -rf /tmp/i3blocks

	@#Setup i3blocks scripts
	@cd .config/i3blocks/scripts/memory2
	@make
	@cd ../../../..

	@# Install oh-my-zsh
	@rm -rf ~/.oh-my-zsh
	@sudo apt install -y zsh curl
	@RUNZSH=no CHSH=no sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

	@# Set zsh as default shell
	@sudo chsh -s /bin/zsh

	@# Plugins
	@git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

	@# Link .zshrc
	@rm -rf ~/.config/.zshrc
	@ln -sf ${PWD}/.zshrc ~/.zshrc


i3-config:
	nvim ./.config/i3/config

i3blocks-config:
	nvim ./.config/i3blocks/config

