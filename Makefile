#!/usr/bin/bash

.ONESHELL:

all:

install:
	@# Run scripts in /installers folder
	@for script in ./installers/*.sh; do
	    @sh "$$script"
	@done

i3-config:
	nvim ./.config/i3/config

i3blocks-config:
	nvim ./.config/i3blocks/config

