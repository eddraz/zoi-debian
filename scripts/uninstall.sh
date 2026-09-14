#!/usr/bin/env bash
# zoi-debian uninstall
# Removes ZOI helpers and configs from the user home.
# Idempotent. Does NOT remove apt packages. Re-enables LightDM if Lemurs leftovers exist.

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
log "Removing herdr agent skill for Pi (~/.pi/agent/skills/herdr)."
rm -rf "$HOME/.pi/agent/skills/herdr"
log "Removing MCP config for Pi (~/.config/mcp/mcp.json)."
# Solo borramos si el archivo contiene exactamente los servers que sembramos. Si el
# usuario agregó otros MCPs propios (gitignored, otros tools), respetamos el archivo.
if [ -f "$HOME/.config/mcp/mcp.json" ] \
  && grep -q '"chrome-devtools"' "$HOME/.config/mcp/mcp.json" \
  && grep -q '"cloudflare-api"' "$HOME/.config/mcp/mcp.json" \
  && grep -q '"cloudflare-docs"' "$HOME/.config/mcp/mcp.json"; then
  rm -f "$HOME/.config/mcp/mcp.json"
  log "Quitado ~/.config/mcp/mcp.json."
else
  log "~/.config/mcp/mcp.json no es solo nuestro, lo dejo."
fi
rm -f $HOME/.config/zoi/keys.json $HOME/.config/zoi/keys-apply.json
rm -f "$HOME/.local/share/applications/inlyne.desktop" \
     "$HOME/.local/share/applications/zoi-markdown.desktop"
rm -rf "$HOME/.config/inlyne"

log "Cleaning up state directories in ~/.local/state/zoi, ~/.local/state/quickshell and weather cache."
rm -rf $HOME/.local/state/zoi $HOME/.local/state/quickshell
rm -f "$HOME/.cache/quickshell/weather.json" "$HOME/.cache/quickshell/weather.json.tmp"

if [ -f "$HOME/.config/sway/config" ]; then
  log "Cleaning up quickshell autostart entries in sway/config."
  sed -i '/exec_always .*\/qs -n --daemonize/d' "$HOME/.config/sway/config"
  sed -i '/exec_always .*\/qs-idle/d' "$HOME/.config/sway/config"
  sed -i '/qs-keys-apply/d' "$HOME/.config/sway/config"
fi

log "Removing leftover Lemurs unit/PAM/config and enabling LightDM."
$SUDO systemctl disable lemurs.service 2>/dev/null || true
$SUDO rm -f /etc/systemd/system/lemurs.service /etc/pam.d/lemurs /usr/local/bin/lemurs
$SUDO rm -rf /etc/lemurs /var/cache/lemurs
rm -rf "$HOME/.local/share/zoi/lemurs" "$HOME/.config/zoi/lemurs"
rm -f "$HOME/.config/zoi/themed/lemurs-variables.toml" \
     "$HOME/.config/zoi/themed/lemurs-config.toml" \
     "$HOME/.config/zoi/themed/lemurs.vtrgb"
$SUDO systemctl enable lightdm.service 2>/dev/null || true
$SUDO systemctl daemon-reload 2>/dev/null || true

log "Done. Los paquetes apt NO se desinstalaron. Para hacerlo:"
log "sudoers (/etc/sudoers.d/zoi-*) no se toca. Herdr, Pi e Inlyne son de usuario. Config: ~/.config/herdr ~/.config/inlyne ~/.config/yazi"
log "  sudo apt remove quickshell qt6-wayland swaybg swayidle wlsunset figlet python3-terminaltexteffects btop bc libqrencode4"
log "Restart Sway with: swaymsg reload"
