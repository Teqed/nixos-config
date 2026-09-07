#!/usr/bin/env sh
if hash lf 2>/dev/null; then
    lfcd () {
        cd "$(command lf -print-last-dir "$@")" || return
    }
fi
