# Portable oh-my-posh prompt — any Linux, any terminal, any shell

A standalone handout for replicating **just my oh-my-posh prompt**
(`emodipt-extend`) on a different machine — a different distro (Arch, Fedora, …)
and/or a different terminal. Nothing here depends on Ubuntu or Ptyxis.

The whole prompt is **3 pieces**:

1. the `oh-my-posh` **binary**
2. one **theme file** — `emodipt-extend.omp.json` (path-clean, drops in unchanged)
3. one **init line** in your shell rc

…plus a **Nerd Font** set in your terminal, which is the only per-terminal
manual step (fonts are a terminal setting, never part of the oh-my-posh config).

---

## 1. Install the oh-my-posh binary

**Universal (any distro)** — installs to `~/.local/bin`:
```bash
curl -s https://ohmyposh.dev/install.sh | bash -s
```
Make sure `~/.local/bin` is on your `PATH` (the install script usually adds it;
if not, add `export PATH="$HOME/.local/bin:$PATH"` to your shell rc).

**Per-distro package (optional alternative):**
```bash
# Arch / Manjaro (AUR)
yay -S oh-my-posh-bin           # or: paru -S oh-my-posh-bin

# Fedora
curl -s https://ohmyposh.dev/install.sh | bash -s   # no official repo pkg; use the installer

# Homebrew (if you use it on Linux)
brew install oh-my-posh
```

Check: `oh-my-posh --version`.

---

## 2. Get the theme file

```bash
mkdir -p ~/.config/oh-my-posh
git clone --depth 1 -b ubuntu https://github.com/numanyusf/dotfiles.git /tmp/df
cp /tmp/df/oh-my-posh/emodipt-extend.omp.json ~/.config/oh-my-posh/
rm -rf /tmp/df
```

(Or copy `emodipt-extend.omp.json` off a USB stick — it's a single self-contained
JSON file, no external references.)

---

## 3. Add the init line to your shell rc

**Syntax differs per shell** — use the one that matches your shell:

```bash
# bash  ->  ~/.bashrc
eval "$(oh-my-posh init bash --config ~/.config/oh-my-posh/emodipt-extend.omp.json)"
```
```zsh
# zsh   ->  ~/.zshrc
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/emodipt-extend.omp.json)"
```
```fish
# fish  ->  ~/.config/fish/config.fish
oh-my-posh init fish --config ~/.config/oh-my-posh/emodipt-extend.omp.json | source
```

Open a **new** terminal (or `source` the rc). The prompt should render — icons
may be missing until step 4.

---

## 4. Install a Nerd Font and set it in your terminal

The prompt's glyphs (git branch, node/language logos, battery, path arrows) need
a **Nerd Font**. This is set in the **terminal's own settings**, not oh-my-posh.

### Install the font

**Distro package (easiest where it exists):**
```bash
# Arch / Manjaro  (MesloLG family)
sudo pacman -S ttf-meslo-nerd
# Fedora
sudo dnf install fira-code-fonts    # or any Nerd Font pkg; Meslo not always packaged
```

**Universal manual install (any distro — this is what I use):**
```bash
mkdir -p ~/.local/share/fonts/Meslo
curl -sSL -o /tmp/Meslo.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip
unzip -q /tmp/Meslo.zip -d ~/.local/share/fonts/Meslo && rm /tmp/Meslo.zip
fc-cache -f ~/.local/share/fonts/Meslo
fc-list | grep -i meslo        # confirm it's registered
```
Any Nerd Font works (JetBrainsMono, FiraCode, CascadiaCode …) — swap the zip name.

### Point your terminal at it

Pick your terminal — each stores the font differently:

| Terminal | How to set the font |
|----------|---------------------|
| **Ptyxis** (GNOME) | `gsettings set org.gnome.Ptyxis use-system-font false` then `gsettings set org.gnome.Ptyxis font-name 'MesloLGM Nerd Font 13'` |
| **GNOME Terminal** | Preferences → Profile → Text → uncheck "Use system font" → pick "MesloLGM Nerd Font" |
| **Konsole** (KDE) | Settings → Edit Profile → Appearance → Font → "MesloLGM Nerd Font" |
| **Alacritty** | `~/.config/alacritty/alacritty.toml`: `[font] normal = { family = "MesloLGM Nerd Font" }` |
| **Kitty** | `~/.config/kitty/kitty.conf`: `font_family MesloLGM Nerd Font` |
| **WezTerm** | `~/.wezterm.lua`: `config.font = wezterm.font 'MesloLGM Nerd Font'` |
| **Foot** (Wayland) | `~/.config/foot/foot.ini`: `font=MesloLGM Nerd Font:size=12` |
| any other | look for "Font" in the terminal's Preferences/Profile |

> **Use the non-Mono variant** ("MesloLGM Nerd Font", not "…Nerd Font Mono").
> The Mono variant renders the prompt icons half-width so they look tiny. If TUI
> column alignment ever looks off, the Mono variant is the tradeoff.

Without a Nerd Font the prompt still works — you just get □ tofu boxes where the
glyphs should be.

---

## Notes / gotchas

- **After editing the `.omp.json`, run `oh-my-posh cache clear`** — oh-my-posh
  caches rendered segments in `~/.cache/oh-my-posh` and will otherwise show
  stale colors. (`oh-my-posh debug` bypasses the cache; `print primary` does not.)
- **Segments auto-hide** when the relevant tool/context is absent — the
  node/rust/go/java/python/battery/SSH segments only render when that runtime is
  installed (or you're on a laptop / over SSH). So the same theme looks right on
  a desktop, a laptop, and a server without edits.
- This is **only the prompt.** The `ls` colors (vivid `LS_COLORS`) and eza icon
  aliases from my dotfiles are separate — grab `ls_colors` and the eza aliases
  from `bashrc` if you want those too, but they're not required for the prompt.
- The theme's colors are One Dark (coral `#E06C75`, gold `#E5C07B`, green
  `#98C379`); they render the same in any terminal that supports truecolor
  (essentially all modern ones).
