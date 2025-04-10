#!/usr/bin/bash

if hostnamectl | grep -q "Chassis: desktop"; then
	setxkbmap -layout us -variant intl
else
	setxkbmap -layout us,br -variant intl,thinkpad -model thinkpad -option 'grp:win_space_toggle'

	xrandr --output HDMI-1 --mode 1920x1080 --rate 120
fi

