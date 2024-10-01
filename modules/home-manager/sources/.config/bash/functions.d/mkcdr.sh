#!/usr/bin/env sh
# Make directory and move to it
mkcdr() { mkdir -p "$1" && cd "$1" || return; }