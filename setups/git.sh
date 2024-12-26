#!/usr/bin/bash

# Create symlinks
mv -f ~/.gitconfig ~/.gitconfig.bak 2> /dev/null
ln -sf ${PWD}/.gitconfig ~/.gitconfig

