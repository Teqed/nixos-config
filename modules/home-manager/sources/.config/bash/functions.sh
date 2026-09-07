#!/usr/bin/env sh
for file in ~/.config/bash/functions.d/*; do
    . "$file"
done
