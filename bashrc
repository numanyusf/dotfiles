# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

# Silence starship's harmless "git timed out" warning on the first prompt
# after boot (cold FS cache makes the first git call exceed command_timeout).
export STARSHIP_LOG=error

export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"

. "$HOME/.local/share/../bin/env"
