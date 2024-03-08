# Install neovim

```
sudo apt install libfuse2 ripgrep fd-find build-essential php-cli composer -y

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

nvm install --lts && nvm use --lts

curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage

chmod u+x nvim.appimage

sudo mv ./nvim.appimage /usr/bin/nvim
```

# Create config folder

```
mkdir ~/.config
mkdir ~/.config/nvim
cd ~/.config/nvim
```
