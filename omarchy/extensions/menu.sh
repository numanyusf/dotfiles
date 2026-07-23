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

# ── Extended AI install menu ─────────────────────────────────────────
# Adds terminal AI coding agents + Cursor to Install → AI, installed as
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

  case $(menu "Install" "󱚤  Claude Code\n󱚤  OpenAI Codex\n  Gemini CLI\n󱚤  opencode\n  Copilot CLI\n󱚤  Cursor\n  Dictation\n󱚤  LM Studio\n󱚤  Ollama\n󱚤  Crush") in
  *"Claude Code"*) install "Claude Code" "claude-code" ;;
  *Codex*) install "OpenAI Codex" "openai-codex-bin" ;;
  *Gemini*) install "Gemini CLI" "gemini-cli" ;;
  *opencode*) install "opencode" "opencode" ;;
  *Copilot*) install "GitHub Copilot CLI" "copilot-cli" ;;
  *Cursor*) install "Cursor" "cursor-bin" ;;
  *Dictation*) present_terminal omarchy-voxtype-install ;;
  *Studio*) install "LM Studio" "lmstudio-bin" ;;
  *Ollama*) install "Ollama" $ollama_pkg ;;
  *Crush*) install "Crush" "crush-bin" ;;
  *) show_install_menu ;;
  esac
}
