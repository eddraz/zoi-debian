#!/usr/bin/env bash
# zoi-debian uninstall
# Removes dotfiles from ~/.config and restores waybar as default bar.
# Idempotent. Does NOT remove apt packages.

set -euo pipefail

log()  { printf '\033[1;35m[zoi]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[fail]\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -ne 0 ] && SUDO=sudo || SUDO=""

log "Stopping qs."
pkill -f quickshell || true

log "Backing up ~/.config/quickshell to ~/.config/quickshell.bak.$(date +%s)"
if [ -d "$HOME/.config/quickshell" ]; then
  mv "$HOME/.config/quickshell" "$HOME/.config/quickshell.bak.$(date +%s)"
fi

log "Removing qs-* scripts from ~/.local/bin."
rm -f $HOME/.local/bin/qs-*

if grep -q "qs -n --daemonize" "$HOME/.config/sway/config" 2>/dev/null; then
  log "Restoring waybar as default bar in sway/config."
  $SUDO sed -i '/exec_always \/usr\/bin\/qs -n --daemonize/d' "$HOME/.config/sway/config"
fi

log "Done. Los paquetes apt NO se desinstalaron. Para hacerlo:"
log "  sudo apt remove quickshell swaybg swayidle wlsunset figlet python3-terminaltexteffects"
log "Restart Sway with: swaymsg reload"
