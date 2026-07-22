# Dotfiles

Personal configuration files for my **Ubuntu (GNOME)** setup.

Theme across everything: **One Dark** (coral `#E06C75`, gold `#E5C07B`, green `#98C379`) with the GNOME/Yaru **orange** system accent.

## Included configs

- `bashrc` — Bash config: inits **oh-my-posh**, loads `dircolors`, and aliases `ls`→**eza** (with Nerd Font icons)
- `oh-my-posh/` — prompt theme `emodipt-extend.omp.json` (time, shell, git, node/language versions, project version, battery, python venv, SSH host, path, exec-time, status)
- `dircolors` — `LS_COLORS` for `ls`/eza (directories in gold `#E5C07B`)
- `ptyxis.dconf` — Ptyxis terminal settings (font, opacity, palette, copy toast)
- `nvim/` — Neovim (LazyVim) with the **One Dark** colorscheme (`navarasu/onedark.nvim`)
- `tmux/` — tmux config with TPM plugins (prefix `C-a`)

## Dependencies

- **Ptyxis** terminal (GNOME)
- **oh-my-posh** — `curl -s https://ohmyposh.dev/install.sh | bash -s` (installs to `~/.local/bin`)
- **eza** — `sudo apt install eza`
- **MesloLGM Nerd Font** — installed under `~/.local/share/fonts/Meslo/`
- **Neovim** ≥ 0.11

## Setup

Clone to `~/.dotfiles`, then symlink:

```bash
ln -sfn ~/.dotfiles/bashrc      ~/.bashrc
ln -sfn ~/.dotfiles/dircolors   ~/.dircolors
ln -sfn ~/.dotfiles/oh-my-posh  ~/.config/oh-my-posh
ln -sfn ~/.dotfiles/nvim        ~/.config/nvim
ln -sfn ~/.dotfiles/tmux        ~/.config/tmux
```

Restore Ptyxis settings:

```bash
dconf load /org/gnome/Ptyxis/ < ~/.dotfiles/ptyxis.dconf
```

tmux plugins:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
~/.tmux/plugins/tpm/bin/install_plugins
```

nvim plugins install automatically on first launch (LazyVim bootstraps `lazy.nvim`).

## Notes

- The terminal directory color, oh-my-posh path color, and `ls`/eza directory color are all kept in sync at gold `#E5C07B`.
- To change the nvim One Dark variant, edit `style` in `nvim/lua/plugins/colorscheme.lua` (`dark`, `darker`, `cool`, `deep`, `warm`, `warmer`).
