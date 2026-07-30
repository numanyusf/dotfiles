#!/usr/bin/env bash
#
# bootstrap.sh — restore this Ubuntu (GNOME) setup on a fresh install.
#
# Run AFTER a clean Ubuntu install, as the normal user (it calls sudo itself):
#   git clone https://github.com/numanyusf/dotfiles.git ~/.dotfiles
#   cd ~/.dotfiles && git checkout ubuntu
#   ./bootstrap.sh
#
# Idempotent: safe to re-run. It installs apt repos + packages, lays the
# config symlinks, and installs oh-my-posh + the Nerd Font.
#
# It does NOT do the system-level security setup (LUKS/TPM2 unlock, YubiKey
# PAM) — those touch /etc, need physical touches / secrets, and are documented
# step-by-step in docs/system-setup.md. This script prints a reminder at the end.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log()  { printf '\033[1;33m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;31m!!\033[0m  %s\n' "$*"; }

# ---------------------------------------------------------------------------
# 0. Preflight — sanity-check the target machine before changing anything
# ---------------------------------------------------------------------------
preflight() {
  log "Preflight checks"
  local warned=0

  # OS: expect Ubuntu (the apt repos + package names assume it)
  local id="" codename="" ver=""
  if [ -r /etc/os-release ]; then
    id=$(. /etc/os-release; echo "${ID:-}")
    codename=$(. /etc/os-release; echo "${VERSION_CODENAME:-}")
    ver=$(. /etc/os-release; echo "${VERSION_ID:-}")
  fi
  if [ "$id" != "ubuntu" ]; then
    warn "OS is '${id:-unknown}', not ubuntu — apt repos/package names may not match."
    warned=1
  else
    log "  Ubuntu $ver ($codename)"
  fi

  # Ubuntu >= 24.04 needed for eza/vivid in the archive
  # (numeric compare: 24.04 -> 2404)
  local vernum="${ver//./}"
  if [ -n "$vernum" ] && [ "$vernum" -lt 2404 ] 2>/dev/null; then
    warn "Ubuntu $ver < 24.04: 'eza' and 'vivid' aren't in the archive — install them"
    warn "   another way (cargo/binary) or drop them from packages.txt."
    warned=1
  fi

  # GNOME desktop (Ptyxis dconf + oh-my-posh assume it)
  if [ "${XDG_CURRENT_DESKTOP:-}" != "" ] && ! echo "${XDG_CURRENT_DESKTOP}" | grep -qi gnome; then
    warn "Desktop is '${XDG_CURRENT_DESKTOP}', not GNOME — Ptyxis dconf restore may be a no-op."
    warned=1
  fi
  # Ptyxis is the default terminal only on newer Ubuntu; note it if absent
  if [ -n "$vernum" ] && [ "$vernum" -lt 2510 ] 2>/dev/null; then
    warn "On Ubuntu < 25.10 the default terminal is gnome-terminal, not Ptyxis —"
    warn "   the ptyxis.dconf restore only matters if you install Ptyxis yourself."
  fi

  # Username: gitconfig hardcodes an absolute /home/numan/.ssh signers path
  if [ "$(id -un)" != "numan" ]; then
    warn "You are '$(id -un)', not 'numan'. gitconfig's allowedSignersFile is the"
    warn "   absolute path /home/numan/.ssh/allowed_signers. After bootstrap, run:"
    warn "     git config --global gpg.ssh.allowedSignersFile \"\$HOME/.ssh/allowed_signers\""
    warned=1
  fi
  if [ "$HOME" != "/home/numan" ]; then
    warn "\$HOME is '$HOME' (not /home/numan) — double-check the gitconfig signers path above."
    warned=1
  fi

  if [ "$warned" = 1 ]; then
    printf '\n'
    read -r -p "Warnings above. Continue anyway? [y/N] " reply
    case "$reply" in [yY]*) ;; *) echo "Aborted."; exit 1 ;; esac
  fi
}

# ---------------------------------------------------------------------------
# 1. Third-party apt repositories + keys
# ---------------------------------------------------------------------------
add_repos() {
  log "Adding third-party apt repositories"
  sudo install -d -m 0755 /etc/apt/keyrings /usr/share/keyrings

  # 1Password (desktop app + op CLI)
  if [ ! -f /etc/apt/sources.list.d/1password.sources ]; then
    log "  1Password"
    curl -sS https://downloads.1password.com/linux/keys/1password.asc \
      | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
    echo 'Types: deb
URIs: https://downloads.1password.com/linux/debian/amd64
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/1password-archive-keyring.gpg' \
      | sudo tee /etc/apt/sources.list.d/1password.sources >/dev/null
    # debsig verification policy required by the 1Password package
    sudo install -d -m 0755 /etc/debsig/policies/AC2D62742012EA22
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol \
      | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol >/dev/null
    sudo install -d -m 0755 /usr/share/debsig/keyrings/AC2D62742012EA22
    curl -sS https://downloads.1password.com/linux/keys/1password.asc \
      | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
  fi

  # VS Code (Microsoft)
  if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then
    log "  VS Code"
    curl -sS https://packages.microsoft.com/keys/microsoft.asc \
      | sudo gpg --dearmor --output /etc/apt/keyrings/packages.microsoft.gpg
    echo 'deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main' \
      | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
  fi

  # Firefox from Mozilla (NOT the snap — snap can't reach the 1Password app)
  if [ ! -f /etc/apt/sources.list.d/mozilla.list ]; then
    log "  Firefox (Mozilla .deb)"
    curl -sS https://packages.mozilla.org/apt/repo-signing-key.gpg \
      | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc >/dev/null
    echo 'deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main' \
      | sudo tee /etc/apt/sources.list.d/mozilla.list >/dev/null
    # pin so the .deb always wins over the snap/transitional package
    echo 'Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000' | sudo tee /etc/apt/preferences.d/mozilla >/dev/null
  fi

  # eduVPN (Tampere University / CSC access)
  if [ ! -f /etc/apt/sources.list.d/eduvpn-v4.list ]; then
    log "  eduVPN"
    curl -sS https://app.eduvpn.org/linux/v4/deb/app+linux@eduvpn.org.asc \
      | sudo gpg --dearmor --output /usr/share/keyrings/eduvpn-v4.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/eduvpn-v4.gpg] https://app.eduvpn.org/linux/v4/deb/ $(lsb_release -cs) main" \
      | sudo tee /etc/apt/sources.list.d/eduvpn-v4.list >/dev/null
  fi
}

# ---------------------------------------------------------------------------
# 2. Install packages
# ---------------------------------------------------------------------------
install_packages() {
  log "apt update"
  sudo apt-get update -y

  log "Installing packages from packages.txt"
  # strip comments/blank lines/inline comments
  mapfile -t pkgs < <(sed -E 's/#.*//; s/[[:space:]]+$//; /^$/d' "$DOTFILES/packages.txt")
  sudo apt-get install -y "${pkgs[@]}"

  log "Installing third-party-repo apps"
  sudo apt-get install -y 1password 1password-cli code firefox eduvpn-client

  # fd-find installs the binary as fdfind; most tools expect it as `fd`
  mkdir -p "$HOME/.local/bin"
  [ -e "$HOME/.local/bin/fd" ] || ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"

  log "Suggest: sudo ubuntu-drivers install   # NVIDIA driver (RTX 3060 Mobile)"
}

# ---------------------------------------------------------------------------
# 3. oh-my-posh + Nerd Font
# ---------------------------------------------------------------------------
install_prompt_and_font() {
  if ! command -v oh-my-posh >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/oh-my-posh" ]; then
    log "Installing oh-my-posh to ~/.local/bin"
    curl -s https://ohmyposh.dev/install.sh | bash -s
  fi

  local fdir="$HOME/.local/share/fonts/Meslo"
  if [ ! -d "$fdir" ]; then
    log "Installing MesloLGM Nerd Font"
    mkdir -p "$fdir"
    tmp="$(mktemp -d)"
    curl -sSL -o "$tmp/Meslo.zip" \
      https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip
    unzip -q "$tmp/Meslo.zip" -d "$fdir"
    rm -rf "$tmp"
    fc-cache -f "$fdir" >/dev/null 2>&1 || true
    # NOTE: use the non-Mono "MesloLGM Nerd Font" in Ptyxis — the Mono variant
    # shrinks the prompt icons. (see docs/system-setup.md / dotfiles README)
  fi
}

# ---------------------------------------------------------------------------
# 4. uv (Python package/venv manager)
# ---------------------------------------------------------------------------
install_uv() {
  if ! command -v uv >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/uv" ]; then
    log "Installing uv to ~/.local/bin"
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
}

# ---------------------------------------------------------------------------
# 4b. Graphify (codebase knowledge-graph CLI, used per-project via `/graphify`)
# ---------------------------------------------------------------------------
install_graphify() {
  if command -v uv >/dev/null 2>&1 && ! command -v graphify >/dev/null 2>&1; then
    log "Installing Graphify CLI"
    uv tool install graphifyy
  fi
}

# ---------------------------------------------------------------------------
# 5. Symlinks
# ---------------------------------------------------------------------------
link() {  # link <repo-relative-src> <dest>
  local src="$DOTFILES/$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest"
  printf '   %s -> %s\n' "$dest" "$src"
}

make_symlinks() {
  log "Linking config into place"
  link bashrc              "$HOME/.bashrc"
  link gitconfig           "$HOME/.gitconfig"
  link oh-my-posh          "$HOME/.config/oh-my-posh"
  link nvim                "$HOME/.config/nvim"
  link tmux/tmux.conf      "$HOME/.tmux.conf"
  link vscode/settings.json "$HOME/.config/Code/User/settings.json"
  link 1password/agent.toml "$HOME/.config/1Password/ssh/agent.toml"
  mkdir -p "$HOME/.cursor/rules" "$HOME/.cursor/hooks" "$HOME/.claude/hooks"
  link agents/AGENTS.md          "$HOME/.claude/CLAUDE.md"
  link agents/claude-settings.json "$HOME/.claude/settings.json"
  link agents/cursor-general.mdc "$HOME/.cursor/rules/general.mdc"
  link agents/cursor-graphify.mdc "$HOME/.cursor/rules/graphify.mdc"
  link agents/cursor-mcp.json    "$HOME/.cursor/mcp.json"
  link agents/cursor-hooks.json  "$HOME/.cursor/hooks.json"
  link agents/hooks/block-dangerous-git.sh "$HOME/.claude/hooks/block-dangerous-git.sh"
  link agents/hooks/block-dangerous-git.sh "$HOME/.cursor/hooks/block-dangerous-git.sh"
  link agents/hooks/cursor-caveman-session.sh "$HOME/.cursor/hooks/cursor-caveman-session.sh"

  # ssh needs strict perms; symlink the individual files, not the dir
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  link ssh/config          "$HOME/.ssh/config"
  link ssh/allowed_signers "$HOME/.ssh/allowed_signers"

  # ls_colors is read by bashrc directly (no symlink needed)
}

# ---------------------------------------------------------------------------
# 5b. VS Code extensions (theme referenced by vscode/settings.json)
# ---------------------------------------------------------------------------
install_vscode_extensions() {
  if command -v code >/dev/null 2>&1; then
    log "Installing VS Code extensions (One Dark Pro theme + Material Icon Theme)"
    code --install-extension zhuangtongfa.material-theme --force >/dev/null
    code --install-extension pkief.material-icon-theme --force >/dev/null
  fi
}

# ---------------------------------------------------------------------------
# 6. Ptyxis terminal settings
# ---------------------------------------------------------------------------
restore_ptyxis() {
  # The custom palette MUST be installed before the dconf load, otherwise the
  # profile points at a palette id that does not resolve and Ptyxis silently
  # falls back to the built-in "One" (whose accent colour is blue).
  log "Installing Ptyxis palettes"
  mkdir -p "$HOME/.local/share/org.gnome.Ptyxis/palettes"
  cp -f "$DOTFILES"/ptyxis/*.palette "$HOME/.local/share/org.gnome.Ptyxis/palettes/"

  if command -v dconf >/dev/null 2>&1; then
    log "Restoring Ptyxis settings"
    dconf load /org/gnome/Ptyxis/ < "$DOTFILES/ptyxis.dconf"
  fi
}

main() {
  preflight
  add_repos
  install_packages
  install_prompt_and_font
  install_uv
  install_graphify
  make_symlinks
  install_vscode_extensions
  restore_ptyxis

  cat <<'EOF'

============================================================================
 Dotfiles bootstrap complete.

 STILL MANUAL (see docs/system-setup.md — these can't be scripted safely):
   1. gh auth login                     (GitHub HTTPS credential helper)
   2. Sign in to the 1Password app + enable the SSH agent, CLI, and the
      Firefox extension (native-messaging). SSH signing needs this.
   3. LUKS + TPM2 auto-unlock            (systemd-cryptenroll — needs the
                                          disk passphrase, run by you)
   4. YubiKey FIDO2 enrollment for LUKS + tap-to-sudo (login stays password
                                          — see docs/system-setup.md §3)
   5. Node via nvm, Docker              (optional dev toolchains)
   6. ./agents/mcp-servers.sh, then `claude` -> /mcp to finish OAuth login
                                          for figma-remote-mcp and vercel
      (Cursor MCP is agents/cursor-mcp.json → ~/.cursor/mcp.json; for a
       project that needs `cursor-agent mcp enable`, also symlink that
       file to <project>/.cursor/mcp.json — enable is flaky with global-only)
   7. Paste agents/cursor-general.mdc's body into Cursor's Settings > Rules
                                          > User Rules (filesystem rules also
                                          live at ~/.cursor/rules/general.mdc)
   8. `graphify update .` (or extract) per project you want a knowledge
                                          graph in — CLI is global; graphs are
                                          per-repo. Agent rule is already
                                          global (cursor-graphify.mdc).
                                          Optional: `graphify install --platform cursor`
   9. ./agents/caveman-install.sh        (output-compression skill for
                                          Claude Code/Cursor/Continue —
                                          on by default on Claude Code)
  10. ./agents/mattpocock-skills-install.sh (curated engineering skills:
                                          grill-with-docs, tdd, implement,
                                          research, diagnosing-bugs,
                                          code-review, git-guardrails)

 Then open a new terminal (oh-my-posh + eza) and confirm
 `git log --show-signature` verifies.

 Neovim is set up fresh (LazyVim starter) — first launch installs plugins.
 tmux is set up fresh too, themed to match the Ptyxis terminal palette.
============================================================================
EOF
}

main "$@"
