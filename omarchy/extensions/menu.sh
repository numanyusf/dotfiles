# Overwrite parts of the omarchy-menu with user-specific submenus.
# See $OMARCHY_PATH/bin/omarchy-menu for functions that can be overwritten.
#
# WARNING: Overwritten functions will obviously not be updated when Omarchy changes.
#
# Example of minimal system menu:
#
# show_system_menu() {
#   case $(menu "System" "  Lock\n󰐥  Shutdown") in
#   *Lock*) omarchy-system-lock ;;
#   *Shutdown*) omarchy-system-shutdown ;;
#   *) back_to show_main_menu ;;
#   esac
# }
#
# Example of overriding just the about menu action: (Using zsh instead of bash (default))
#
# show_about() {
#   exec omarchy-launch-or-focus-tui "zsh -c 'fastfetch; read -k 1'"
# }

# ── About uses a smaller font ────────────────────────────────────────
# The fastfetch About layout is up to ~122 columns wide on this machine
# (long CPU/GPU strings) and is designed for Omarchy's default terminal
# font size (9). Our Alacritty font is 11, so in the fixed 875x600 About
# window the layout wraps/misaligns. Launch it with font size 9 (leaving
# the normal terminal at 11) and a dedicated class (org.omarchy.about) so
# our own float/center/size rules in ~/.config/hypr/hyprland.conf apply
# without competing with Omarchy's floating-window tag size (875x600).
show_about() {
  setsid uwsm-app -- alacritty --class org.omarchy.about -o font.size=9 \
    -o window.dynamic_padding=true \
    -e bash -c 'fastfetch; read -n 1 -s' >/dev/null 2>&1 &
}

# ── Extended AI install menu ─────────────────────────────────────────
# Adds terminal AI coding agents to Install → AI, installed as
# AUR/repo packages via Omarchy's own `install` helper (omarchy-pkg-add).
# Because they're real packages, they also show up in Remove → Package.
# Overrides the upstream show_install_ai_menu(); this file is sourced
# after it (see the tail of $OMARCHY_PATH/bin/omarchy-menu), so it wins.
show_install_ai_menu() {
  ollama_pkg=$(
    (omarchy-cmd-present nvidia-smi && echo ollama-cuda) ||
      (omarchy-cmd-present rocminfo && echo ollama-rocm) ||
      echo ollama
  )

  case $(menu "Install" "󱚤  Claude Code CLI\n󱚤  Cursor CLI\n󱚤  OpenAI Codex CLI\n  GitHub Copilot CLI\n  Gemini CLI\n󱚤  Opencode CLI\n󱚤  Crush CLI\n󱚤  LM Studio\n󱚤  Ollama\n  Voice Dictation") in
  *"Claude Code"*) install "Claude Code CLI" "claude-code" ;;
  *Cursor*) install "Cursor CLI" "cursor-cli" ;;
  *Codex*) install "OpenAI Codex CLI" "openai-codex-bin" ;;
  *Copilot*) install "GitHub Copilot CLI" "copilot-cli" ;;
  *Gemini*) install "Gemini CLI" "gemini-cli" ;;
  *Opencode*) install "Opencode CLI" "opencode" ;;
  *Crush*) install "Crush CLI" "crush-bin" ;;
  *Studio*) install "LM Studio" "lmstudio-bin" ;;
  *Ollama*) install "Ollama" $ollama_pkg ;;
  *Dictation*) present_terminal omarchy-voxtype-install ;;
  *) show_install_menu ;;
  esac
}
