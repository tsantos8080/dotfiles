#!/usr/bin/bash

if ! grep -q "GTK_IM_MODULE=cedilla" /etc/environment; then
	echo "GTK_IM_MODULE=cedilla" | sudo tee -a /etc/environment > /dev/null
fi

if ! grep -q "QT_IM_MODULE=cedilla" /etc/environment; then
	echo "QT_IM_MODULE=cedilla" | sudo tee -a /etc/environment > /dev/null
fi

