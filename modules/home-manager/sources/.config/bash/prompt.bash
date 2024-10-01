#!/usr/bin/env bash
# https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Variables.html#index-PS1
# https://www.gnu.org/software/bash/manual/html_node/Controlling-the-Prompt.html
export GIT_PS1_SHOWDIRTYSTATE=1 # Show * if repo is dirty
_hostname=$(hostname) # Get hostname and remove www. prefix if present
[[ $_hostname == www.* ]] && _hostname=${_hostname:4} ; [[ $_hostname == WWW.* ]] && _hostname=${_hostname:4}
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then debian_chroot=$(cat /etc/debian_chroot) ; fi
__prompt_command() { # Function to generate PS1 after each command
    history -a # Append to history file
    local EXIT="$?" # Get exit code of last command
    shortpath=$(awk -F'/' '{if(NF>5) print $1"/"$2"/../"$(NF-1)"/"$(NF-0); else print $0;}' <<<"${PWD/#$HOME/\~}") # Shorten path to first and last 3 directories
    ttitle "${_hostname} ${shortpath}"
    IFS=';' read -r -sdR -p $'\E[6n' _ROW COL # Get cursor position
    [ "$COL" -ne 1 ] && echo '' # Add newline if cursor is not at 1st column
    PS1="${debian_chroot:+($debian_chroot)}\[\033[38;5;81m\]$_hostname \[\033[38;5;141m\]${shortpath}";
    if [ $EXIT != 0 ]; then PS1+=" \[\e[0;31m\]" # Add red if exit code non 0
    else PS1+=" \[\e[49;38;5;227m\]" ; fi # Add yellow if exit code 0
    PS1+="\$\[\e[0m\] " ; # Add prompt symbol and reset colors
}
PROMPT_COMMAND=__prompt_command
__prompt_command # Generate PS1 for first time