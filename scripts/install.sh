#!/usr/bin/env bash
# zoi-debian install script
# Usage: curl -fsSL https://raw.githubusercontent.com/<owner>/zoi-debian/main/scripts/install.sh | sh
# Idempotent: safe to re-run.

set -euo pipefail

ZOI_REPO="${ZOI_REPO:-https://github.com/<owner>/zoi-debian.git}"
ZOI_BRANCH="${ZOI_BRANCH:-main}"
ZOI_DIR="${ZOI_DIR:-$HOME/projects/zoi-debian}"
QS_DOT="$HOME/.config/quickshell"

log()  { printf '\033[1;35m[zoi]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[fail]\033[0m %s\n' "$*" >&2; exit 1; }

if [ "$(id -u)" -ne 0 ]; then
  SUDO=sudo
else
  SUDO=""
fi

# ---------------------------------------------------------------- distro guard
. /etc/os-release
if [ "${ID:-}" != "debian" ]; then
  die "Esto está pensado para Debian (detectado: ${ID:-unknown})."
fi
log "Debian ${VERSION_ID:-unknown} detectado."

# ---------------------------------------------------------------- apt
log "Asegurando apt sources + backports."
$SUDO apt-get update -y

if ! apt-cache policy quickshell 2>/dev/null | grep -q trixie-backports; then
  $SUDO tee /etc/apt/sources.list.d/backports.list >/dev/null <<EOF
deb http://deb.debian.org/debian trixie-backports main contrib non-free non-free-firmware
EOF
  $SUDO apt-get update -y
fi

# ---------------------------------------------------------------- packages
PKGS=(
  sway swaybg swaylock swayidle
  foot foot-themes
  quickshell
  pipewire wireplumber
  wlsunset wtype wl-clipboard grim slurp wf-recorder
  playerctl mpv mpv-mpris yt-dlp
  cliphist
  figlet python3-terminaltexteffects
  brightnessctl
  lightdm
  librewolf
  fish
  jq
  bc
  btop
  python3-gi gir1.2-gdkpixbuf-2.0
  libqrencode4 qrencode
  polkit
  fonts-noto fonts-noto-color-emoji fonts-noto-cjk
  network-manager
  bluez bluez-tools
  pulseaudio-utils
  xdg-utils xdg-user-dirs
  pavucontrol
)

# quickshell 0.3+ está en backports
BP_PKGS=(quickshell)

log "Instalando paquetes base (puede tardar 1-3 min)."
$SUDO apt-get install -y --no-install-recommends "${PKGS[@]}"
log "Asegurando paquetes de backports."
$SUDO apt-get install -y --no-install-recommends -t trixie-backports "${BP_PKGS[@]}"

# ---------------------------------------------------------------- user dirs
log "Inicializando xdg-user-dirs."
xdg-user-dirs-update || true

# ---------------------------------------------------------------- dotfiles
log "Clonando / actualizando zoi-debian a $ZOI_DIR."
if [ -d "$ZOI_DIR/.git" ]; then
  (cd "$ZOI_DIR" && git pull --ff-only) || warn "git pull falló; usando copia local."
else
  mkdir -p "$(dirname "$ZOI_DIR")"
  if git clone --depth 1 -b "$ZOI_BRANCH" "$ZOI_REPO" "$ZOI_DIR" 2>/dev/null; then
    log "Repo clonado."
  else
    warn "Sin red o repo aún no publicado; usando copia local si existe."
    [ -d "$ZOI_DIR" ] || die "No tengo repo ni copia local."
  fi
fi

# ---------------------------------------------------------------- quickshell dotfiles
log "Instalando dotfiles de Quickshell en $QS_DOT."
mkdir -p "$QS_DOT/panels" "$QS_DOT/widgets" "$QS_DOT/Commons" "$QS_DOT/Ui"
cp -r "$ZOI_DIR/dotfiles/quickshell/." "$QS_DOT/"
chmod -R u+rwX "$QS_DOT"

# ---------------------------------------------------------------- themes & templates
log "Instalando motor de temas y plantillas de ZOI en ~/.config/zoi y ~/.local/share/zoi."
mkdir -p "$HOME/.config/zoi/themes" "$HOME/.config/zoi/themed" "$HOME/.config/zoi/hooks/theme-set.d"
mkdir -p "$HOME/.local/share/zoi/themes" "$HOME/.local/share/zoi/templates"
if [ -d "$ZOI_DIR/dotfiles/themes" ]; then
  cp -r "$ZOI_DIR/dotfiles/themes/"* "$HOME/.local/share/zoi/themes/" 2>/dev/null || true
  cp -r "$ZOI_DIR/dotfiles/themes/templates/"* "$HOME/.local/share/zoi/templates/" 2>/dev/null || true
  cp -r "$ZOI_DIR/dotfiles/themes/templates/"* "$HOME/.config/zoi/themed/" 2>/dev/null || true
fi

# ---------------------------------------------------------------- sway
log "Instalando config de Sway."
mkdir -p "$HOME/.config/sway"
if [ -f "$HOME/.config/sway/config" ] && [ ! -L "$HOME/.config/sway/config" ]; then
  cp "$HOME/.config/sway/config" "$HOME/.config/sway/config.bak.$(date +%s)"
fi
cp "$ZOI_DIR/dotfiles/sway/config" "$HOME/.config/sway/config"

# ---------------------------------------------------------------- foot
log "Instalando config de foot."
mkdir -p "$HOME/.config/foot"
if [ -f "$ZOI_DIR/dotfiles/config/foot/foot.ini" ]; then
  cp "$ZOI_DIR/dotfiles/config/foot/foot.ini" "$HOME/.config/foot/foot.ini"
fi

# ---------------------------------------------------------------- local-bin
log "Instalando scripts auxiliares y CLI zoi-theme en ~/.local/bin."
mkdir -p "$HOME/.local/bin"
cp "$ZOI_DIR/dotfiles/local-bin/"* "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/"*

# ---------------------------------------------------------------- wallpaper
log "Poniendo wallpaper por defecto."
mkdir -p "$HOME/Imágenes"
cp "$ZOI_DIR/assets/default-wallpaper.jpg" "$HOME/Imágenes/baby-yoda-cartoon.jpg"
mkdir -p "$HOME/.local/state/quickshell"
[ -f "$HOME/.local/state/quickshell/wallpaper" ] || \
  printf '%s\n' "$HOME/Imágenes/baby-yoda-cartoon.jpg" > "$HOME/.local/state/quickshell/wallpaper"
mkdir -p "$HOME/.config/quickshell"
[ -f "$HOME/.config/quickshell/screensaver.txt" ] || \
  printf 'ZOI\n' > "$HOME/.config/quickshell/screensaver.txt"

# ---------------------------------------------------------------- shell.json
log "Inicializando ~/.config/quickshell/shell.json."
if [ ! -f "$HOME/.config/quickshell/shell.json" ]; then
  cp "$ZOI_DIR/dotfiles/quickshell/shell.json" "$HOME/.config/quickshell/shell.json"
fi

# ---------------------------------------------------------------- initialize theme
log "Aplicando tema base con zoi-theme."
"$HOME/.local/bin/zoi-theme" set tokyo-night || warn "No se pudo aplicar tema inicial; corré 'zoi-theme set tokyo-night' manualmente."

# ---------------------------------------------------------------- fish as default
if command -v fish >/dev/null && ! grep -qE "^/.*/fish$" /etc/shells 2>/dev/null; then
  $SUDO sh -c "command -v fish >> /etc/shells"
fi
if [ -n "${SUDO}" ] && [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v fish)" ]; then
  $SUDO chsh -s "$(command -v fish)" "$USER" || warn "Cambiar shell por defecto falló; hacelo a mano."
fi

# ---------------------------------------------------------------- exec_always in sway
log "Asegurando que sway ejecute qs + qs-idle."
if ! grep -q "qs -n --daemonize" "$HOME/.config/sway/config"; then
  cat >> "$HOME/.config/sway/config" <<'EOF'

# zoi-debian: arrancar qs (si no lo está)
exec_always /usr/bin/qs -n --daemonize
exec_always $HOME/.local/bin/qs-idle
EOF
fi

# ---------------------------------------------------------------- sanity
log "Verificando binarios clave."
MISSING=0
for b in sway qs swaymsg playerctl wlsunset foot cliphist wl-copy wtype grim slurp wf-recorder wireplumber btop bc zoi-theme; do
  command -v "$b" >/dev/null || { warn "Falta binario: $b"; MISSING=$((MISSING+1)); }
done

log "Listo."
if [ "$MISSING" -gt 0 ]; then
  warn "Faltan $MISSING binarios — instalá los paquetes correspondientes y corré de nuevo."
fi
log "Cerrá sesión y volvé a entrar (o corré: swaymsg reload && pkill qs && swaymsg exec /usr/bin/qs -n --daemonize)."
log "Atajos: ver docs/shortcuts.md"
log "Configuración y Temas: ver docs/configuration.md"
log "Si algo falla: docs/troubleshooting.md"
