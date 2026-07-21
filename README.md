# Dotfiles

Personal configuration files for my **Ubuntu (GNOME)** setup.

## Included configs

- `kitty` — Kitty terminal (font: CaskaydiaMono Nerd Font; theme included from `kitty_themes/`)
- `kitty_themes` — Self-contained kitty color themes (active: `tokyo-night`; also catppuccin, everforest, gruvbox, kanagawa, matte-black, nord, osaka-jade, ristretto, rose-pine, catppuccin-latte)
- `tmux` — tmux config with TPM plugins (prefix `C-a`)
- `nvim` — Neovim setup (LazyVim, plugins, keymaps, Lua configs)
- `starship.toml` — Starship prompt config

## Setup

Clone to `~/.dotfiles`, then symlink into `~/.config`:

```bash
ln -sfn ~/.dotfiles/kitty         ~/.config/kitty
ln -sfn ~/.dotfiles/kitty_themes  ~/.config/kitty_themes
ln -sfn ~/.dotfiles/tmux          ~/.config/tmux
ln -sfn ~/.dotfiles/nvim          ~/.config/nvim
ln -sfn ~/.dotfiles/starship.toml ~/.config/starship.toml
```

Prompt (bash): add `eval "$(starship init bash)"` to `~/.bashrc`.

tmux plugins: `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && ~/.tmux/plugins/tpm/bin/install_plugins`

To switch kitty theme: change the `include ../kitty_themes/<name>/kitty.conf` line in `kitty/kitty.conf`, then reload kitty (Ctrl+Shift+F5).
