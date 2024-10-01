#!/usr/bin/env bash
if [ -n "${COLORTERM}" ]; then
    export CLICOLOR=1
    # LSCOLORS=exgxfxDacxBaBaCaCaeaEa # For BSD
    #   foreground = "#ededed",
    #   background = "#000000", -- old 141619
    #   ansi
    export COLOR_0_BLACK=";30" #     '#000000', -- 'black', color0 -- old 313131
    export COLOR_1_MAROON=";31" #     '#cb150a', -- 'maroon', color1
    export COLOR_2_GREEN=";32" #     '#0ca948', -- 'green', color2
    export COLOR_3_OLIVE=";33" #     '#ff9e00', -- 'olive', color3
    export COLOR_4_NAVY=";34" #     '#2c77ea', -- 'navy', color4
    export COLOR_5_PURPLE=";35" #     '#ad2bd0', -- 'purple', color5
    export COLOR_6_TEAL=";36" #     '#10cec6', -- 'teal', color6
    export COLOR_7_SILVER=";37" #     '#758989', -- 'silver', color7
    #   brights
    export COLOR_8_GREY=";90" #     '#838383', -- 'grey', color8
    export COLOR_9_RED=";91" #     '#f24c32', -- 'red', color9
    export COLOR_10_LIME=";92" #     '#2cf083', -- 'lime', color10
    export COLOR_11_YELLOW=";93" #     '#ffd361', -- 'yellow', color11
    export COLOR_12_BLUE=";94" #     '#a5b7f4', -- 'blue', color12
    export COLOR_13_FUSCHIA=";95" #     '#bf89e0', -- 'fuchsia', color13
    export COLOR_14_AQUA=";96" #     '#96eaf9', -- 'aqua', color14
    export COLOR_15_WHITE=";97" #     '#ffffff', -- 'white', color15 -- old c4dfdf
    export COLOR_RESET='\e[0m' # Reset text

    # export COLOR_BLACK='\e[0;30m'
    # export COLOR_GRAY='\e[1;30m'
    # export COLOR_RED='\e[0;31m'
    # export COLOR_LIGHT_RED='\e[1;31m'
    # export COLOR_GREEN='\e[0;32m'
    # export COLOR_LIGHT_GREEN='\e[1;32m'
    # export COLOR_BROWN='\e[0;33m'
    # export COLOR_YELLOW='\e[1;33m'
    # export COLOR_BLUE='\e[0;34m'
    # export COLOR_LIGHT_BLUE='\e[1;34m'
    # export COLOR_PURPLE='\e[0;35m'
    # export COLOR_LIGHT_PURPLE='\e[1;35m'
    # export COLOR_CYAN='\e[0;36m'
    # export COLOR_LIGHT_CYAN='\e[1;36m'
    # export COLOR_LIGHT_GRAY='\e[0;37m'
    # export COLOR_WHITE='\e[1;37m'

    export LESS_TERMCAP_mb=$'\e[01${COLOR_1_MAROON}m'   # begin bold
    export LESS_TERMCAP_md=$'\e[01;38;5;74m'  # begin blink
    export LESS_TERMCAP_me=$COLOR_RESET       # reset bold/blink
    export LESS_TERMCAP_se=$COLOR_RESET       # reset reverse video
    export LESS_TERMCAP_so=$'\e[38;5;246m' # begin reverse video
    export LESS_TERMCAP_ue=$COLOR_RESET       # reset underline
    export LESS_TERMCAP_us=$'\e[04;38;5;146m' # begin underline

    export GREP_COLORS="ms=1;32:mc=1;32:ln=33" # (new) Matching text in Selected line = green, line numbers dark yellow

    # ANSI colouring functions
    ERROR_COLOR="${COLOR_1_MAROON}" # Red
    WARNING_COLOR="${COLOR_5_PURPLE}" # Magenta
    INFO_COLOR="${COLOR_6_TEAL}" # Cyan
    VERBOSE_COLOR="${COLOR_2_GREEN}" # Green
    DEBUG_COLOR="${COLOR_4_NAVY}" # Blue

    # colored GCC warnings and errors
    export GCC_COLORS="error=01${COLOR_1_MAROON}:warning=01${COLOR_5_PURPLE}:note=01${COLOR_6_TEAL}:caret=01${COLOR_2_GREEN}:locus=01:quote=01"

    error()   { local opts ; [[ $1 = "-n" ]] && { opts=$1 ; shift ; } ; echo "$opts" "[1m[1${ERROR_COLOR}m$*[0m" ; }
    warning() { local opts ; [[ $1 = "-n" ]] && { opts=$1 ; shift ; } ; echo "$opts" "[1m[1${WARNING_COLOR}m$*[0m" ; }
    info()    { local opts ; [[ $1 = "-n" ]] && { opts=$1 ; shift ; } ; echo "$opts" "[1m[1${INFO_COLOR}m$*[0m" ; }
    verbose() { local opts ; [[ $1 = "-n" ]] && { opts=$1 ; shift ; } ; echo "$opts" "[1m[1${VERBOSE_COLOR}m$*[0m" ; }
    debug()   { local opts ; [[ $1 = "-n" ]] && { opts=$1 ; shift ; } ; echo "$opts" "[1m[1${DEBUG_COLOR}m$*[0m" ; }

    highlight() { local opts ; [[ $1 = "-n" ]] && { opts=$1 ; shift ; } ; echo "$opts" "[1m[1${COLOR_7_SILVER}m$*[0m" ; }
    danger()    { local opts ; [[ $1 = "-n" ]] && { opts=$1 ; shift ; } ; echo "$opts" "[47m[1;5${COLOR_1_MAROON}m$*[0m" ; }

fi