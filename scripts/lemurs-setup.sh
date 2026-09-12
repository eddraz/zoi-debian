#!/usr/bin/env bash
# Optional Lemurs display-manager helper for Debian 13 + Sway.
# install.sh calls `apply` (enable, not start). Default CLI is a dry-run plan.
#
# Debian PAM (not `include login`): pam_loginuid optional.
# TTY colors: /etc/lemurs/vtrgb + setvtrgb (kbd). Hex is ignored on the kernel VT.
# Cache is a file at /var/cache/lemurs/state (do not mkdir that path as the cache).
#
# Usage:
#   ./scripts/lemurs-setup.sh              # plan
#   sudo ./scripts/lemurs-setup.sh apply   # install binary + unit (does not start now)
#   ./scripts/lemurs-setup.sh status
#
# Upstream: https://github.com/coastalwhite/lemurs

set -euo pipefail

# usermod y demás viven en /usr/sbin; un PATH de usuario no lo incluye.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:${PATH:-/usr/bin:/bin}"

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

# After `exec sudo -u <desktop>` from root, SUDO_USER is root. Never own
# greeter files as root or mkdir into /root from the desktop user.
desktop_user() {
  local u
  for u in "${TARGET_USER:-}" "${SUDO_USER:-}" "${USER:-}"; do
    if [ -n "$u" ] && [ "$u" != root ] && getent passwd "$u" >/dev/null 2>&1; then
      printf '%s\n' "$u"
      return 0
    fi
  done
  getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 && $1 != "nobody" {print $1; exit}'
}

owner_name() {
  local u
  u="$(desktop_user)"
  printf '%s\n' "${u:-root}"
}

owner_home() {
  local u h
  u="$(owner_name)"
  h="$(getent passwd "$u" 2>/dev/null | cut -d: -f6 || true)"
  printf '%s\n' "$h"
}

usermod_existing_groups() {
  local user="$1" g list=""
  shift
  [ -n "$user" ] && [ "$user" != root ] || return 0
  for g in "$@"; do
    getent group "$g" >/dev/null 2>&1 || continue
    list="${list:+$list,}$g"
  done
  [ -n "$list" ] || return 0
  $SUDO usermod -aG "$list" "$user" || true
}

need_root_write() {
  [ "$(id -u)" -eq 0 ] || [ -n "${SUDO}" ] || die "Se necesita root."
}

print_plan() {
  log "Plan (sin escribir nada)."
  echo "  Version:     v$LEMURS_VERSION (binary tarball)"
  echo "  Binary dest: /usr/local/bin/lemurs"
  echo "  Config:      /etc/lemurs/config.toml  (ANSI names; chown user)"
  echo "  Variables:   /etc/lemurs/variables.toml  (títulos)"
  echo "  VT colors:   /etc/lemurs/vtrgb  (setvtrgb, 16 slots del wallpaper)"
  echo "  Cache:       /var/cache/lemurs/state  (file, not a directory)"
  echo "  User layout: ~/.config/zoi/lemurs/config.toml  (optional override)"
  echo "  Overlay:     ~/.config/zoi/lemurs/variables.overlay.toml"
  echo "  Wayland:     /etc/lemurs/wayland/sway  (only greeter session)"
  echo "  Sessions:    /etc/lemurs/xsessions + wayland-sessions (empty; skip Debian Sway-as-X11)"
  echo "  Unit:        /etc/systemd/system/lemurs.service  (TTY2, alias display-manager)"
  echo "  PAM:         /etc/pam.d/lemurs  (common-auth, loginuid optional)"
  echo "  LightDM:     se deshabilita; el paquete queda como fallback"
  echo "  Start now:   no (enable para el próximo boot)"
}

install_binary() {
  if command -v lemurs >/dev/null 2>&1; then
    if lemurs --version 2>/dev/null | grep -q "$LEMURS_VERSION"; then
      log "Lemurs v$LEMURS_VERSION ya está instalado. Saltando descarga."
      return 0
    fi
  fi

  local work efi
  work="$(mktemp -d)"
  log "Descargando Lemurs $LEMURS_VERSION."
  curl -fsSL -o "$work/lemurs.tar.xz" "$LEMURS_URL"
  tar -xJf "$work/lemurs.tar.xz" -C "$work"
  efi="$(find "$work" -type f -name lemurs -perm /111 | head -1)"
  if [ -z "$efi" ]; then
    rm -rf "$work"
    die "El tarball no trae el binario lemurs."
  fi
  $SUDO install -m 0755 "$efi" /usr/local/bin/lemurs
  rm -rf "$work"
}

write_wallpaper_fallback_vars() {
  local vars="$1"
  $SUDO tee "$vars" >/dev/null <<'EOF_VARS'
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
EOF_VARS
}

apply_install() {
  need_root_write
  arch="$(dpkg --print-architecture)"
  if [ "$arch" != "amd64" ]; then
    die "Lemurs v$LEMURS_VERSION solo publica tarball x86_64 (esta máquina: $arch)."
  fi
  [ -d "$DOT_LEMURS" ] || die "No encuentro $DOT_LEMURS."
  command -v curl >/dev/null || die "Falta curl."
  command -v setvtrgb >/dev/null || die "Falta setvtrgb (paquete kbd)."

  install_binary

  log "Instalando y verificando archivos en /etc/lemurs."
  $SUDO mkdir -p /etc/lemurs/wayland /etc/lemurs/wms /etc/lemurs/xsessions /etc/lemurs/wayland-sessions /var/cache/lemurs

  # 16-color VT map (hex is ignored on TTY2). Prefer the themed file from zoi-theme.
  
  # PAM/unit must be root:root. `cp -a` from the repo would keep the desktop user.
  $SUDO install -m 0644 -o root -g root "$DOT_LEMURS/lemurs.pam" /etc/pam.d/lemurs
  $SUDO install -m 0755 "$DOT_LEMURS/wayland-sway" /etc/lemurs/wayland/sway
  $SUDO install -m 0644 -o root -g root "$DOT_LEMURS/lemurs.service" /etc/systemd/system/lemurs.service

  local owner home share user_cfg stock_cfg themed vars example target_cfg
  owner="$(owner_name)"
  home="$(owner_home)"
  share="${home:+$home/.local/share/zoi/lemurs}"
  user_cfg="${home:+$home/.config/zoi/lemurs/config.toml}"
  stock_cfg="$DOT_LEMURS/config.toml"
  example="$REPO_ROOT/dotfiles/config/zoi/lemurs/variables.overlay.toml.example"

  if [ -n "$home" ] && [ -d "$home" ]; then
    mkdir -p "$share" "$home/.config/zoi/lemurs" || warn "No pude crear $share (sigo con /etc/lemurs)."
    if [ -d "$share" ] && [ ! -f "$user_cfg" ]; then
      cp -a "$stock_cfg" "$share/config.toml" || true
    fi
    if [ -f "$example" ] && [ ! -f "$home/.config/zoi/lemurs/variables.overlay.toml.example" ]; then
      cp -a "$example" "$home/.config/zoi/lemurs/variables.overlay.toml.example" || true
    fi
  else
    warn "Home de $owner vacío; solo escribo /etc/lemurs."
  fi

  if [ -n "$user_cfg" ] && [ -f "$user_cfg" ]; then
    target_cfg="$user_cfg"
  else
    target_cfg="$stock_cfg"
  fi

  $SUDO install -m 0644 -o "$owner" -g "$owner" "$target_cfg" /etc/lemurs/config.toml

  themed="${home:+$home/.config/zoi/themed/lemurs-variables.toml}"
  vars=/etc/lemurs/variables.toml
  if [ -n "$themed" ] && [ -f "$themed" ]; then
    if [ -f "$vars" ] && cmp -s "$themed" "$vars"; then
      : # Sin cambios
    else
      log "Actualizando paleta desde wallpaper/tema: $themed"
      $SUDO cp -a "$themed" "$vars"
    fi
  else
    if [ ! -f "$vars" ]; then
      log "Sin themed aún: paleta del wallpaper default (Baby Yoda), no tokyo-night."
      write_wallpaper_fallback_vars "$vars"
    fi
  fi

  $SUDO chown "$owner:$owner" "$vars" /etc/lemurs/config.toml
  $SUDO chmod 0644 "$vars" /etc/lemurs/config.toml

  vtrgb_src="${home:+$home/.config/zoi/themed/lemurs.vtrgb}"
  [ -n "$vtrgb_src" ] && [ -f "$vtrgb_src" ] || vtrgb_src="$DOT_LEMURS/vtrgb"
  if [ -f "$vtrgb_src" ]; then
    $SUDO install -m 0644 -o "$owner" -g "$owner" "$vtrgb_src" /etc/lemurs/vtrgb
  else
    warn "No hay vtrgb (themed ni $DOT_LEMURS/vtrgb); TTY2 queda en VGA de fábrica."
  fi

  usermod_existing_groups "$owner" video render seat

  log "Verificando estado de los servicios."
  # disable, not --now: --now kills a live LightDM/Sway session mid-apply.
  $SUDO systemctl disable lightdm.service 2>/dev/null || true
  $SUDO systemctl disable getty@tty2.service 2>/dev/null || true
  $SUDO systemctl daemon-reload
  if ! systemctl is-enabled lemurs.service >/dev/null 2>&1; then
    log "Habilitando Lemurs para el próximo boot."
    $SUDO systemctl enable lemurs.service
  fi

  log "Listo. El script finalizó exitosamente. Reboot para entrar en TTY2."
}

print_status() {
  echo "binary: $(command -v lemurs 2>/dev/null || echo missing)"
  echo "config: $([ -f /etc/lemurs/config.toml ] && echo present || echo missing)"
  echo "vars:   $([ -f /etc/lemurs/variables.toml ] && echo present || echo missing)"
  echo "vtrgb:  $([ -f /etc/lemurs/vtrgb ] && echo present || echo missing)"
  echo "pam:    $([ -f /etc/pam.d/lemurs ] && echo present || echo missing)"
  echo "sway:   $([ -x /etc/lemurs/wayland/sway ] && echo present || echo missing)"
  echo "setvtrgb: $(command -v setvtrgb 2>/dev/null || echo missing)"
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
