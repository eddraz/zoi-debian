#!/usr/bin/env bash
# zoi-debian install script
# Usage: curl -fsSL https://...install.sh | sh
# Idempotent: safe to re-run.

set -euo pipefail

ZOI_REPO="${ZOI_REPO:-https://github.com/<owner>/zoi-debian.git}"
ZOI_BRANCH="${ZOI_BRANCH:-main}"
ZOI_DIR="${ZOI_DIR:-$HOME/projects/zoi-debian}"
QS_DOT="$HOME/.config/quickshell"
ASSETS_DIR_DEFAULT="/usr/share/backgrounds/zoi-debian"

log()  { printf '\033[1;35m[zoi]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[fail]\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -ne 0 ] && SUDO=sudo || SUDO=""

# ---------------------------------------------------------------- distro guard
. /etc/os-release
if [ "${ID:-}" != "debian" ]; then
  die "Esto está pensado para Debian (detectado: ${ID:-unknown})."
fi
log "Debian ${VERSION_ID} detectado."

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
  sway swaybg swaylock swayidle sway-launcher
  foot foot-themes
  quickshell
  waybar                 # opcional, no se usa pero algunos lo esperan
  pipewire pipewire-audio-client-libraries wireplumber
  wlsunset wtype wl-clipboard grim slurp wf-recorder swaymsg
  playerctl mpv mpv-mpris yt-dlp
  cliphist
  figlet python3-terminaltexteffects
  brightnessctl light
  lightdm lightdm-gtk-greeter
  librewolf              # default browser
  libreoffice            # opcional
  fish
  jq
  polkit polkitd
  fonts-noto fonts-noto-color-emoji fonts-noto-cjk
  network-manager network-manager-gnome
  bluez bluez-tools
  pulseaudio-utils       # pactl
  xdg-utils xdg-user-dirs
  pavucontrol
)

# backports-only
BP_PKGS=(quickshell)

log "Instalando paquetes base (~300 MB)."
$SUDO apt-get install -y --no-install-recommends "${PKGS[@]}"
log "Instalando paquetes de backports."
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

# ---------------------------------------------------------------- sway
log "Instalando config de Sway."
mkdir -p "$HOME/.config/sway"
cp "$ZOI_DIR/dotfiles/sway/config" "$HOME/.config/sway/config"

# ---------------------------------------------------------------- foot
log "Instalando config de foot."
mkdir -p "$HOME/.config/foot"
[ -f "$ZOI_DIR/dotfiles/config/foot/foot.ini" ] && \
  cp "$ZOI_DIR/dotfiles/config/foot/foot.ini" "$HOME/.config/foot/foot.ini"

# ---------------------------------------------------------------- local-bin
log "Instalando scripts auxiliares en ~/.local/bin."
mkdir -p "$HOME/.local/bin"
cp "$ZOI_DIR/dotfiles/local-bin/"* "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/qs-"*

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

# ---------------------------------------------------------------- fish as default
if command -v fish >/dev/null && ! grep -q "$(command -v fish)$" /etc/shells; then
  $SUDO sh -c "command -v fish >> /etc/shells"
fi
if [ -n "${SUDO}" ] && [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v fish)" ]; then
  $SUDO chsh -s "$(command -v fish)" "$USER" || warn "Cambiar shell por defecto falló; hacelo a mano."
fi

# ---------------------------------------------------------------- qs as default bar
log "Asegurando que sway ejecute qs en lugar de waybar."
if ! grep -q "qs -n --daemonize" "$HOME/.config/sway/config"; then
  cat >> "$HOME/.config/sway/config" <<'EOF'

# zoi-debian: arrancar qs (si no lo está)
exec_always /usr/bin/qs -n --daemonize
EOF
fi

# ---------------------------------------------------------------- sway-launcher
log "Verificando sway-launcher para Super+Space."
if ! command -v $menu >/dev/null 2>&1; then
  cat > "$HOME/.local/bin/zoi-launcher" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/qs -p /usr/share/zoi-debian/launcher-loader.qml
EOF
  chmod +x "$HOME/.local/bin/zoi-launcher"
fi

# ---------------------------------------------------------------- sanity
log "Verificando binarios clave."
for b in sway qs swaymsg playerctl wlsunset foot cliphist wl-copy wtype grim slurp wf-recorder; do
  command -v "$b" >/dev/null || warn "Falta binario: $b"
done

log "Listo. Cerrá sesión y volvé a entrar (o reiniciá)."
log "Atajos: ver docs/shortcuts.md"
log "Si algo falla: docs/troubleshooting.md"
