#!/bin/bash
# Center the LUKS/boot Plymouth screen on every monitor.
#
# Omarchy has one shared Plymouth script for ALL desktop themes; switching
# themes just recolors it, regenerating /usr/share from the default template
# at ~/.local/share/omarchy/default/plymouth/omarchy.script. So the fix lives
# in that template. omarchy update can restore the stock template, so this
# script re-applies our per-monitor version from the dotfiles copy.
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$DOTFILES/plymouth/omarchy.script"
TEMPLATE="$HOME/.local/share/omarchy/default/plymouth/omarchy.script"

cp "$SRC" "$TEMPLATE"
echo "Patched template: $TEMPLATE"

# Re-bake into /usr/share with the current theme's colors and rebuild initramfs.
theme=$(cat "$HOME/.config/omarchy/current/theme.name" 2>/dev/null || echo "")
if [[ -n $theme ]] && command -v omarchy-plymouth-set-by-theme &>/dev/null; then
  omarchy-plymouth-set-by-theme "$theme"
else
  # Fallback: copy uncolored template and rebuild directly.
  sudo cp "$TEMPLATE" /usr/share/plymouth/themes/omarchy/omarchy.script
  if command -v limine-mkinitcpio &>/dev/null; then
    sudo limine-mkinitcpio
  else
    sudo mkinitcpio -P
  fi
fi
