#!/usr/bin/env bash
# ZOI + swaybar: Sway's built-in bar, Quickshell overlays (launcher, notifs, lock, OSD…).
#
#   ./scripts/install-swaybar.sh
#
# If the desktop is not installed yet, runs install.sh first (ZOI_SKIP_REBOOT=1).
# Does not replace install.sh — Quickshell bar stays the default path.
# swaybar is part of sway; no extra apt package (not waybar, not i3status).
set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:${PATH:-/usr/bin:/bin}"

log()  { printf '\033[1;35m[zoi-swaybar]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[fail]\033[0m %s\n' "$*" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ "$(id -u)" -eq 0 ]; then
  die "Corrélo como tu usuario, no como root."
fi

if [ ! -d "$REPO_ROOT/dotfiles/quickshell" ]; then
  die "No encuentro $REPO_ROOT/dotfiles/quickshell"
fi

if ! command -v qs >/dev/null 2>&1 || [ ! -f "$HOME/.config/sway/config" ]; then
  log "Desktop ZOI no está; corro install.sh primero."
  ZOI_SKIP_REBOOT=1 "$SCRIPT_DIR/install.sh"
fi

log "Dotfiles swaybar + shell Quickshell sin Bar.qml (overlays)."
mkdir -p "$HOME/.config/quickshell" "$HOME/.local/bin" \
  "$HOME/.local/state/quickshell"
cp "$REPO_ROOT/dotfiles/quickshell/shell-waybar.qml" "$HOME/.config/quickshell/shell.qml"
install -m 755 "$REPO_ROOT/dotfiles/local-bin/qs-swaybar-status" "$HOME/.local/bin/qs-swaybar-status"

printf 'swaybar\n' > "$HOME/.local/state/quickshell/bar-backend"

# Mutually exclusive with Waybar: stop it and drop its Sway exec leftovers.
pkill -x waybar >/dev/null 2>&1 || true

SWAY="$HOME/.config/sway/config"
if [ -f "$SWAY" ]; then
  sed -i \
    -e '/# zoi-debian quickshell:/d' \
    -e '/^[[:space:]]*exec\(_always\)\{0,1\}[[:space:]]*\/usr\/bin\/qs -p/d' \
    -e '/^[[:space:]]*exec\(_always\)\{0,1\}[[:space:]]*quickshell -p/d' \
    -e '/# zoi-debian waybar:/d' \
    -e '/qs-waybar/d' \
    -e '/exec_always[[:space:]]\+waybar/d' \
    "$SWAY" || true
  log "Sway: qs (overlays) + bar zoi (swaybar)."
  python3 - "$SWAY" <<'PY'
import json
import os
import re
import sys

sway_path = sys.argv[1]
home = os.environ.get("HOME", "")
colors_path = os.path.join(home, ".local/state/quickshell/colors.json")
pal = {}
try:
    with open(colors_path, encoding="utf-8") as fh:
        loaded = json.load(fh)
    if isinstance(loaded, dict):
        pal = loaded
except Exception:
    pal = {}


def color(key, fallback):
    raw = pal.get(key) if pal else None
    if not isinstance(raw, str):
        return fallback
    value = raw.strip()
    if not value:
        return fallback
    if not value.startswith("#"):
        value = "#" + value
    return value


background = color("background", "#1e1e2e")
foreground = color("foreground", "#cdd6f4")
accent = color("accent", "#89b4fa")
dark_background = color("dark_background", "#181825")
muted = color("muted", "#6c7086")
red = color("red", "#f38ba8")
lighter = color("lighter_background", "") or muted
status_bin = os.path.join(home, ".local/bin/qs-swaybar-status")

block = f"""# zoi-debian swaybar begin
bar zoi {{
    position top
    pango_markup disabled
    status_command {status_bin}
    tray_output primary
    font pango:DejaVu Sans 12
    colors {{
        statusline {foreground}
        background {background}
        separator {muted}
        focused_workspace {accent} {accent} {dark_background}
        active_workspace {lighter} {lighter} {foreground}
        inactive_workspace {background} {background} {muted}
        urgent_workspace {red} {red} {dark_background}
    }}
}}
# zoi-debian swaybar end
"""

with open(sway_path, encoding="utf-8") as fh:
    text = fh.read()

pattern = re.compile(
    r"^# zoi-debian swaybar begin\n.*?^# zoi-debian swaybar end\n?",
    re.M | re.S,
)
if pattern.search(text):
    text = pattern.sub(block, text, count=1)
else:
    if text and not text.endswith("\n"):
        text += "\n"
    text += "\n" + block
    if not text.endswith("\n"):
        text += "\n"

with open(sway_path, "w", encoding="utf-8") as fh:
    fh.write(text)
PY
else
  warn "No hay $SWAY"
fi

if [ -x "$HOME/.local/bin/zoi-theme" ]; then
  theme_id=""
  if [ -f "$HOME/.local/state/quickshell/theme" ]; then
    theme_id="$(tr -d '[:space:]' < "$HOME/.local/state/quickshell/theme")"
  fi
  if [ -n "$theme_id" ]; then
    log "Reaplicando tema $theme_id (pinta bar zoi)."
    "$HOME/.local/bin/zoi-theme" set "$theme_id" || warn "zoi-theme set falló."
  elif [ -f "$HOME/.local/state/quickshell/colors.json" ]; then
    "$HOME/.local/bin/zoi-theme" apply-json "$(cat "$HOME/.local/state/quickshell/colors.json")" || true
  fi
fi

log "Reiniciando qs (sin Bar) y swaybar (reload)."
pkill -x waybar >/dev/null 2>&1 || true
pkill -x qs >/dev/null 2>&1 || pkill -f quickshell >/dev/null 2>&1 || true
sleep 0.3
if [ -n "${WAYLAND_DISPLAY:-}" ]; then
  /usr/bin/qs -n --daemonize || warn "qs no arrancó."
  command -v swaymsg >/dev/null && swaymsg reload >/dev/null 2>&1 || true
else
  log "Sin sesión Wayland ahora. Al entrar a Sway: qs + swaybar."
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

log "Listo. Barra = swaybar. Overlays QML = Super+Space launcher, Super+V clipboard, Super+N notifs, OSD."
log "Volver al bar Quickshell: ./scripts/install.sh (restaura Bar.qml y corta swaybar/Waybar)."
