#!/usr/bin/env bash
# Optional Lemurs display-manager helper for Debian 13 + Sway.
# install.sh calls `apply` (enable, not start). Default CLI is a dry-run plan.
#
# Usage:
#   ./scripts/lemurs-setup.sh              # plan
#   sudo ./scripts/lemurs-setup.sh apply   # install binary + unit (does not start now)
#   ./scripts/lemurs-setup.sh status
#
# Upstream: https://github.com/coastalwhite/lemurs

set -euo pipefail

LEMURS_VERSION="${LEMURS_VERSION:-0.4.0}"
LEMURS_URL="${LEMURS_URL:-https://github.com/coastalwhite/lemurs/releases/download/v${LEMURS_VERSION}/lemurs-x86_64-unknown-linux-gnu.tar.xz}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOT_LEMURS="$REPO_ROOT/dotfiles/lemurs"

log()  { printf '\033[1;35m[lemurs]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[fail]\033[0m %s\n' "$*" >&2; exit 1; }

cmd="${1:-plan}"

if [ "$(id -u)" -ne 0 ]; then
  SUDO=sudo
else
  SUDO=""
fi

owner_home() {
  local u="${SUDO_USER:-${USER:-}}"
  getent passwd "$u" 2>/dev/null | cut -d: -f6
}

owner_name() {
  printf '%s\n' "${SUDO_USER:-${USER:-root}}"
}

need_root_write() {
  [ "$(id -u)" -eq 0 ] || [ -n "${SUDO}" ] || die "Se necesita root."
}

print_plan() {
  log "Plan (sin escribir nada)."
  echo "  Version:     v$LEMURS_VERSION (binary tarball)"
  echo "  Binary dest: /usr/local/bin/lemurs"
  echo "  Config:      /etc/lemurs/config.toml  (chown user; zoi-theme may refresh)"
  echo "  Variables:   /etc/lemurs/variables.toml  (paleta wallpaper/tema)"
  echo "  User layout: ~/.config/zoi/lemurs/config.toml  (optional override)"
  echo "  Overlay:     ~/.config/zoi/lemurs/variables.overlay.toml"
  echo "  Wayland:     /etc/lemurs/wayland/sway"
  echo "  Unit:        /etc/systemd/system/lemurs.service  (TTY2, alias display-manager)"
  echo "  PAM:         /etc/pam.d/lemurs"
  echo "  LightDM:     se deshabilita; el paquete queda como fallback"
  echo "  Start now:   no (enable para el próximo boot)"
}

install_binary() {
  local work efi
  work="$(mktemp -d)"
  trap 'rm -rf "$work"' RETURN
  log "Descargando Lemurs $LEMURS_VERSION."
  curl -fsSL -o "$work/lemurs.tar.xz" "$LEMURS_URL"
  tar -xJf "$work/lemurs.tar.xz" -C "$work"
  efi="$(find "$work" -type f -name lemurs -perm /111 | head -1)"
  [ -n "$efi" ] || die "El tarball no trae el binario lemurs."
  $SUDO install -m 0755 "$efi" /usr/local/bin/lemurs
}

write_wallpaper_fallback_vars() {
  local vars="$1"
  $SUDO tee "$vars" >/dev/null <<'EOF'
background = "#1c1c1c"
foreground = "#e6e6e6"
accent = "#fbad60"
muted = "#a6a6a6"
overlay = "#a6a6a6"
surface = "#2e2e2e"
mantle = "#141414"
crust = "#0d0d0d"
red = "#fb6060"
green = "#60fbfb"
peach = "#fbad60"
yellow = "#fbfb60"
login_title = "ZOI"
password_title = "password"
EOF
}

apply_install() {
  need_root_write
  arch="$(dpkg --print-architecture)"
  if [ "$arch" != "amd64" ]; then
    die "Lemurs v$LEMURS_VERSION solo publica tarball x86_64 (esta máquina: $arch)."
  fi
  [ -d "$DOT_LEMURS" ] || die "No encuentro $DOT_LEMURS."
  command -v curl >/dev/null || die "Falta curl."

  install_binary

  log "Instalando /etc/lemurs."
  $SUDO mkdir -p /etc/lemurs/wayland /etc/lemurs/wms /var/cache/lemurs
  $SUDO cp -a "$DOT_LEMURS/lemurs.pam" /etc/pam.d/lemurs
  $SUDO install -m 0755 "$DOT_LEMURS/wayland-sway" /etc/lemurs/wayland/sway
  $SUDO cp -a "$DOT_LEMURS/lemurs.service" /etc/systemd/system/lemurs.service

  local owner home share user_cfg stock_cfg themed vars example
  owner="$(owner_name)"
  home="$(owner_home)"
  share="$home/.local/share/zoi/lemurs"
  user_cfg="$home/.config/zoi/lemurs/config.toml"
  stock_cfg="$DOT_LEMURS/config.toml"
  example="$REPO_ROOT/dotfiles/config/zoi/lemurs/variables.overlay.toml.example"
  mkdir -p "$share" "$home/.config/zoi/lemurs"
  cp -a "$stock_cfg" "$share/config.toml"
  if [ -f "$example" ] && [ ! -f "$home/.config/zoi/lemurs/variables.overlay.toml.example" ]; then
    cp -a "$example" "$home/.config/zoi/lemurs/variables.overlay.toml.example"
  fi
  if [ -f "$user_cfg" ]; then
    log "Layout de usuario: $user_cfg"
    $SUDO cp -a "$user_cfg" /etc/lemurs/config.toml
  else
    $SUDO cp -a "$stock_cfg" /etc/lemurs/config.toml
  fi

  themed="$home/.config/zoi/themed/lemurs-variables.toml"
  vars=/etc/lemurs/variables.toml
  if [ -f "$themed" ]; then
    log "Paleta activa desde wallpaper/tema: $themed"
    $SUDO cp -a "$themed" "$vars"
  else
    log "Sin themed aún: paleta del wallpaper default (Baby Yoda), no tokyo-night."
    write_wallpaper_fallback_vars "$vars"
  fi
  $SUDO chown "$owner:$owner" "$vars" /etc/lemurs/config.toml
  $SUDO chmod 0644 "$vars" /etc/lemurs/config.toml

  if getent group seat >/dev/null 2>&1; then
    $SUDO usermod -aG seat "$owner" || true
  fi

  log "Deshabilitando LightDM / display-manager previo (el paquete no se borra)."
  $SUDO systemctl disable --now lightdm.service 2>/dev/null || true
  $SUDO systemctl disable display-manager.service 2>/dev/null || true
  $SUDO systemctl disable getty@tty2.service 2>/dev/null || true

  log "Enable Lemurs para el próximo boot (no se arranca ahora)."
  $SUDO systemctl daemon-reload
  $SUDO systemctl enable lemurs.service

  log "Listo. El login TUI aparece en TTY2 después de reboot."
}

print_status() {
  echo "binary: $(command -v lemurs 2>/dev/null || echo missing)"
  echo "config: $([ -f /etc/lemurs/config.toml ] && echo present || echo missing)"
  echo "vars:   $([ -f /etc/lemurs/variables.toml ] && echo present || echo missing)"
  echo "sway:   $([ -x /etc/lemurs/wayland/sway ] && echo present || echo missing)"
  systemctl is-enabled lemurs.service 2>/dev/null || echo "lemurs: not enabled"
  systemctl is-enabled lightdm.service 2>/dev/null || echo "lightdm: not enabled"
}

case "$cmd" in
  plan|"") print_plan ;;
  apply) apply_install ;;
  status) print_status ;;
  -h|--help)
    sed -n '2,12p' "$0"
    ;;
  *) die "Comando desconocido: $cmd (plan|apply|status)" ;;
esac
