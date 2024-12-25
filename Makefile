#!/usr/bin/bash

.ONESHELL:

all:

install:
	@# Run scripts in /setups folder
	@for script in ./setups/*.sh; do
	    @sh "$$script"
	@done

i3-config:
	nvim ./.config/i3/config

i3blocks-config:
	nvim ./.config/i3blocks/config

