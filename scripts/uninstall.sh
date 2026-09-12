#!/usr/bin/env bash
# zoi-debian uninstall
# Removes ZOI helpers and configs from the user home.
# Idempotent. Does NOT remove apt packages. Does not re-enable LightDM.

set -euo pipefail

# systemctl y helpers de sbin; un PATH de usuario a veces omite /usr/sbin.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:${PATH:-/usr/bin:/bin}"

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

log "Removing qs-*, zoi-theme and Inlyne from ~/.local/bin."
rm -f $HOME/.local/bin/qs-* $HOME/.local/bin/zoi-theme $HOME/.local/bin/inlyne
rm -f $HOME/.config/zoi/keys.json $HOME/.config/zoi/keys-apply.json
rm -f "$HOME/.local/share/applications/inlyne.desktop" \
     "$HOME/.local/share/applications/zoi-markdown.desktop"
rm -rf "$HOME/.config/inlyne"

log "Cleaning up state directories in ~/.local/state/zoi and ~/.local/state/quickshell."
rm -rf $HOME/.local/state/zoi $HOME/.local/state/quickshell

if [ -f "$HOME/.config/sway/config" ]; then
  log "Cleaning up quickshell autostart entries in sway/config."
  sed -i '/exec_always .*\/qs -n --daemonize/d' "$HOME/.config/sway/config"
  sed -i '/exec_always .*\/qs-idle/d' "$HOME/.config/sway/config"
  sed -i '/qs-keys-apply/d' "$HOME/.config/sway/config"
fi

log "Removing Lemurs unit/PAM/config (does not enable LightDM)."
$SUDO systemctl disable lemurs.service 2>/dev/null || true
$SUDO rm -f /etc/systemd/system/lemurs.service /etc/pam.d/lemurs /usr/local/bin/lemurs
$SUDO rm -rf /etc/lemurs /var/cache/lemurs
$SUDO systemctl daemon-reload 2>/dev/null || true
rm -rf "$HOME/.local/share/zoi/lemurs"
rm -f "$HOME/.config/zoi/themed/lemurs-variables.toml" \
     "$HOME/.config/zoi/themed/lemurs-config.toml" \
     "$HOME/.config/zoi/themed/lemurs.vtrgb"

log "Done. Los paquetes apt NO se desinstalaron. Para hacerlo:"
log "sudoers (/etc/sudoers.d/zoi-*) no se toca. Herdr, Pi e Inlyne son de usuario. Config: ~/.config/herdr ~/.config/inlyne ~/.config/yazi"
log "  sudo apt remove quickshell qt6-wayland swaybg swayidle wlsunset figlet python3-terminaltexteffects btop bc libqrencode4"
log "Restart Sway with: swaymsg reload"
