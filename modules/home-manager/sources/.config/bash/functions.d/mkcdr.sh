#!/usr/bin/env sh
mkcdr() { mkdir -p "$1" && cd "$1" || return; }
