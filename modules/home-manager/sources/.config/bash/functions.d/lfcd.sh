#!/usr/bin/env sh
if hash lf 2>/dev/null; then
    lfcd () { # If using lf, add the following so that when you exit lf, you are in the directory you were in when you finished using lf
        cd "$(command lf -print-last-dir "$@")" || return # `command` is needed in case `lfcd` is aliased to `lf`
    }
    # alias lf='lfcd' # Uncomment this line to make lfcd the default behavior of lf
fi