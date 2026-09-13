#!/usr/bin/env bash
# ZOI + Waybar: native bar, Quickshell overlays (launcher, notifs, lock, OSD…).
#
#   ./scripts/install-waybar.sh
#
# If the desktop is not installed yet, runs install.sh first (ZOI_SKIP_REBOOT=1).
# Does not replace install.sh — Quickshell bar stays the default path.
set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:${PATH:-/usr/bin:/bin}"

log()  { printf '\033[1;35m[zoi-waybar]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[fail]\033[0m %s\n' "$*" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ "$(id -u)" -eq 0 ]; then
  die "Corrélo como tu usuario (hace falta sudo), no como root."
fi
SUDO=sudo

if [ ! -d "$REPO_ROOT/dotfiles/quickshell" ]; then
  die "No encuentro $REPO_ROOT/dotfiles/quickshell"
fi

if ! command -v qs >/dev/null 2>&1 || [ ! -f "$HOME/.config/sway/config" ]; then
  log "Desktop ZOI no está; corro install.sh primero."
  ZOI_SKIP_REBOOT=1 "$SCRIPT_DIR/install.sh"
fi

log "Instalando waybar."
$SUDO apt-get install -y --no-install-recommends waybar || die "No pude instalar waybar."

log "Dotfiles Waybar + shell Quickshell sin Bar.qml."
mkdir -p "$HOME/.config/waybar" "$HOME/.config/quickshell" "$HOME/.local/bin" \
  "$HOME/.local/state/quickshell"
cp "$REPO_ROOT/dotfiles/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"
cp "$REPO_ROOT/dotfiles/waybar/config.jsonc" "$HOME/.config/waybar/config"
if [ ! -f "$HOME/.config/waybar/style.css" ]; then
  cp "$REPO_ROOT/dotfiles/waybar/style.css" "$HOME/.config/waybar/style.css"
fi
cp "$REPO_ROOT/dotfiles/quickshell/shell-waybar.qml" "$HOME/.config/quickshell/shell.qml"
install -m 755 "$REPO_ROOT/dotfiles/local-bin/qs-waybar" "$HOME/.local/bin/qs-waybar"
install -m 755 "$REPO_ROOT/dotfiles/local-bin/qs-waybar-weather" "$HOME/.local/bin/qs-waybar-weather"
# Keep other qs-* from the main install.
if [ -d "$REPO_ROOT/dotfiles/local-bin" ]; then
  find "$REPO_ROOT/dotfiles/local-bin" -maxdepth 1 -type f ! -name '*.pyc' \
    -exec install -m 755 {} "$HOME/.local/bin/" \;
fi

printf 'waybar\n' > "$HOME/.local/state/quickshell/bar-backend"

SWAY="$HOME/.config/sway/config"
if [ -f "$SWAY" ]; then
  if grep -q 'qs-waybar\|exec_always waybar' "$SWAY"; then
    log "Sway ya arranca Waybar."
  else
    log "Sway: qs (overlays) + qs-waybar (barra)."
    cat >> "$SWAY" <<'EOF'

# zoi-debian waybar: barra nativa; qs sigue para launcher/notifs/lock/OSD
exec_always $HOME/.local/bin/qs-waybar
EOF
  fi
else
  warn "No hay $SWAY"
fi

if [ -x "$HOME/.local/bin/zoi-theme" ]; then
  theme_id=""
  if [ -f "$HOME/.local/state/quickshell/theme" ]; then
    theme_id="$(tr -d '[:space:]' < "$HOME/.local/state/quickshell/theme")"
  fi
  if [ -n "$theme_id" ]; then
    log "Reaplicando tema $theme_id (pinta waybar.css)."
    "$HOME/.local/bin/zoi-theme" set "$theme_id" || warn "zoi-theme set falló."
  elif [ -f "$HOME/.local/state/quickshell/colors.json" ]; then
    "$HOME/.local/bin/zoi-theme" apply-json "$(cat "$HOME/.local/state/quickshell/colors.json")" || true
  fi
fi

log "Reiniciando qs (sin Bar) y Waybar."
pkill -x waybar >/dev/null 2>&1 || true
pkill -x qs >/dev/null 2>&1 || pkill -f quickshell >/dev/null 2>&1 || true
sleep 0.3
if [ -n "${WAYLAND_DISPLAY:-}" ]; then
  /usr/bin/qs -n --daemonize || warn "qs no arrancó."
  "$HOME/.local/bin/qs-waybar" >/dev/null 2>&1 &
  command -v swaymsg >/dev/null && swaymsg reload >/dev/null 2>&1 || true
else
  log "Sin sesión Wayland ahora. Al entrar a Sway: qs + Waybar."
fi

if [ -f "$REPO_ROOT/scripts/lib-go-gentleman.sh" ]; then
  # shellcheck source=lib-go-gentleman.sh
  . "$REPO_ROOT/scripts/lib-go-gentleman.sh"
  install_go_and_gentleman
fi
if [ -f "$REPO_ROOT/scripts/lib-llama-k2.sh" ]; then
  # shellcheck source=lib-llama-k2.sh
  . "$REPO_ROOT/scripts/lib-llama-k2.sh"
  install_k2_horizon
fi

log "Listo. Barra = Waybar. Overlays QML = Super+Space launcher, Super+V clipboard, Super+N notifs, OSD."
log "Volver al bar Quickshell: ./scripts/install.sh (pisa shell.qml) y comentá exec qs-waybar en sway/config."
