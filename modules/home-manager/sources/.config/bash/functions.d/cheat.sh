#!/usr/bin/env sh
cheat() { # Get manpage-like help for a command (e.g. cheat wget)
    curl cheat.sh/"$1"
}