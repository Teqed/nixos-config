#!/usr/bin/env sh
for file in ~/.config/bash/functions.d/*; do # shellcheck disable=SC1090
    . "$file"
done