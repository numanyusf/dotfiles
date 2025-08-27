#!/usr/bin/env bash

# Source dir
SRC="$HOME/.dotfiles/kitty_themes"

# Destination dir
DEST="$HOME/.local/share/omarchy/themes"

# Loop over each theme folder
for theme in "$SRC"/*; do
    name=$(basename "$theme")
    src_conf="$theme/kitty.conf"
    dest_dir="$DEST/$name"
    dest_conf="$dest_dir/kitty.conf"

    # Make sure destination theme dir exists
    mkdir -p "$dest_dir"

    # Remove any existing kitty.conf
    rm -f "$dest_conf"

    # Create symlink
    ln -s "$src_conf" "$dest_conf"

    echo "Linked $name → $dest_conf"
done
