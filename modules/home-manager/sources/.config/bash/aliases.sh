#!/usr/bin/env sh
alias reload="source ~/.bash_profile" # Reload bash aliases

# enable color support of ls and also add handy aliases
if hash dircolors 2>/dev/null; then
    [ -f "$XDG_CONFIG_HOME"/dircolors/dircolors ] && eval "$(dircolors -b "$XDG_CONFIG_HOME"/dircolors/dircolors)" || eval "$(dircolors -b)"
    if hash eza 2>/dev/null; then
        alias ls='eza -@F --color=auto --icons --color-scale --group-directories-first'
    elif hash exa 2>/dev/null; then
        alias ls='exa -@F --color=auto --icons --color-scale --group-directories-first'
    else
        alias ls='ls -hF --color=auto --group-directories-first'
    fi
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='LC_ALL=C fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias ncdu='ncdu --color dark'
fi

# some more ls aliases
alias ll='ls -Al'
alias la='ls -A'
alias l='ls -x'

if hash bat 2>/dev/null; then alias bat='bat --paging=never --style=plain' ; fi # Use bat(1) like cat(1) by default

# Directory Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

# Force interactive operation
alias rm='rm -i'
# alias cp='cp -i'
# alias mv='mv -i'

# Default to human readable figures
alias df='df -h'
alias du='du -h'

# Misc
alias whence='type -a'  # where, of a sort

# Use 132x27 color display
alias 5250='tn5250 ssl:localhost env.TERM=IBM-3477-FC'

if hash grc 2>/dev/null; then # aliases for grc(1) - Generic Colouriser
    [ -f /etc/default/grc ] && . /etc/default/grc # If /etc/default/grc exists, source it
    GRC="$(which grc)" # Get the path to grc
    if tty -s && [ -n "$TERM" ] && [ "$TERM" != dumb ] && [ -n "$GRC" ]; then # If terminal is interactive and grc is available
        alias colourify='$GRC -es'
        alias blkid='colourify blkid'
        alias configure='colourify ./configure'
        alias df='colourify df -h'
        alias diff='colourify diff'
        alias docker='colourify docker'
        alias docker-compose='colourify docker-compose'
        alias docker-machine='colourify docker-machine'
        alias du='colourify du -h'
        alias env='colourify env'
        alias free='colourify free'
        alias fdisk='colourify fdisk'
        alias findmnt='colourify findmnt'
        alias make='colourify make'
        alias gcc='colourify gcc'
        alias g++='colourify g++'
        alias id='colourify id'
        alias ip='colourify ip'
        alias iptables='colourify iptables'
        alias as='colourify as'
        alias gas='colourify gas'
        alias journalctl='colourify journalctl'
        alias kubectl='colourify kubectl'
        alias ld='colourify ld'
        #alias ls='colourify ls'
        alias lsof='colourify lsof'
        alias lsblk='colourify lsblk'
        alias lspci='colourify lspci'
        alias netstat='colourify netstat'
        alias ping='colourify ping'
        alias ss='colourify ss'
        alias traceroute='colourify traceroute'
        alias traceroute6='colourify traceroute6'
        alias head='colourify head'
        alias tail='colourify tail'
        alias dig='colourify dig'
        alias mount='colourify mount'
        alias ps='colourify ps'
        alias mtr='colourify mtr'
        alias semanage='colourify semanage'
        alias getsebool='colourify getsebool'
        alias ifconfig='colourify ifconfig'
        alias sockstat='colourify sockstat'
    fi ; fi