#!/usr/bin/env bash
if [ -n "${COLORTERM}" ]; then
    export CLICOLOR=1
    error()   { local opts ; [[ $1 = "-n" ]] && { opts=$1 ; shift ; } ; echo "$opts" "[1m[1${ERROR_COLOR}m$*[0m" ; }
    warning() { local opts ; [[ $1 = "-n" ]] && { opts=$1 ; shift ; } ; echo "$opts" "[1m[1${WARNING_COLOR}m$*[0m" ; }
    info()    { local opts ; [[ $1 = "-n" ]] && { opts=$1 ; shift ; } ; echo "$opts" "[1m[1${INFO_COLOR}m$*[0m" ; }
    verbose() { local opts ; [[ $1 = "-n" ]] && { opts=$1 ; shift ; } ; echo "$opts" "[1m[1${VERBOSE_COLOR}m$*[0m" ; }
    debug()   { local opts ; [[ $1 = "-n" ]] && { opts=$1 ; shift ; } ; echo "$opts" "[1m[1${DEBUG_COLOR}m$*[0m" ; }

    highlight() { local opts ; [[ $1 = "-n" ]] && { opts=$1 ; shift ; } ; echo "$opts" "[1m[1${COLOR_7_SILVER}m$*[0m" ; }
    danger()    { local opts ; [[ $1 = "-n" ]] && { opts=$1 ; shift ; } ; echo "$opts" "[47m[1;5${COLOR_1_MAROON}m$*[0m" ; }

fi