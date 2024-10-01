#!/usr/bin/env bash
set -h # Enable 'hash' builtin
shopt -s checkwinsize # check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s globstar # If set, the pattern "**" used in a pathname expansion context will match all files and zero or more directories and subdirectories.
shopt -s cdspell # If set, minor errors in the spelling of a directory component in a cd command will be corrected. The errors checked for are transposed characters, a missing character, and a character too many.
shopt -s dirspell # If set, Bash attempts spelling correction on directory names during word completion if the directory name initially supplied does not exist.
shopt -s dotglob # If set, Bash includes filenames beginning with a ‘.’ in the results of filename expansion.
shopt -s extglob # If set, the extended pattern matching features are enabled.
shopt -s nocaseglob # Use case-insensitive filename globbing
shopt -s histappend # Make bash append rather than overwrite the history on disk

# Umask - /etc/profile default sets 022, removing write perms to group + others.
# umask 027 # Sets a restrictive umask: i.e. no exec perms for others.
umask 077 # Sets a more restrictive umask: neither group nor others have any perms.

if hash lesspipe 2>/dev/null; then eval "$(SHELL=/bin/sh lesspipe)" ; fi # make less more friendly for non-text input files, see lesspipe(1)

# Ignore some controlling instructions
# HISTIGNORE is a colon-delimited list of patterns which should be excluded.
# The '&' is a special pattern which suppresses duplicate entries.
export HISTIGNORE=$'[ \t]*:&:[fb]g:exit'
if [[ -n "${XDG_STATE_HOME}" ]]; then export HISTFILE="$XDG_STATE_HOME/history/bash_history" ; fi
