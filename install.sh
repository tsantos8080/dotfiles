#!/usr/bin/bash

# Run scripts in /setups folder
for script in ./setups/*.sh; do
    sh "$script"
done

