#!/usr/bin/env bash
# Optional Limine UEFI helper for Debian 13.
# Not invoked by install.sh. Default is a dry-run plan.
#
# Usage:
#   ./scripts/limine-setup.sh                 # plan (no writes)
#   ./scripts/limine-setup.sh apply           # copy EFI + config + NVRAM (GRUB stays)
#   ./scripts/limine-setup.sh apply --make-default
#   ./scripts/limine-setup.sh update-config   # rewrite limine.conf only
#   ./scripts/limine-setup.sh status
#
# Upstream: https://github.com/Limine-Bootloader/Limine

set -euo pipefail

LIMINE_VERSION="${LIMINE_VERSION:-12.9.0}"
LIMINE_URL="${LIMINE_URL:-https://github.com/Limine-Bootloader/Limine/releases/download/v${LIMINE_VERSION}/limine-binary.tar.xz}"
ESP_MOUNT="${ESP_MOUNT:-/boot/efi}"
LIMINE_EFI_DIR="EFI/limine"
LIMINE_LABEL="${LIMINE_LABEL:-Limine}"
LIVE_CONF="${LIVE_CONF:-/boot/limine/limine.conf}"

log()  { printf '\033[1;35m[limine]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[fail]\033[0m %s\n' "$*" >&2; exit 1; }

cmd="${1:-plan}"
shift || true
MAKE_DEFAULT=0
for arg in "$@"; do
  case "$arg" in
    --make-default) MAKE_DEFAULT=1 ;;
    -h|--help)
      sed -n '2,16p' "$0"
      exit 0
      ;;
    *) die "Argumento desconocido: $arg" ;;
  esac
done

if [ "$(id -u)" -ne 0 ]; then
  SUDO=sudo
else
  SUDO=""
fi

need_root_write() {
  [ "$(id -u)" -eq 0 ] || [ -n "${SUDO}" ] || die "Se necesita root."
}

detect() {
  [ -d /sys/firmware/efi ] || die "Este helper es solo UEFI."
  [ -f /etc/os-release ] || die "No hay /etc/os-release."
  # shellcheck disable=SC1091
  . /etc/os-release
  [ "${ID:-}" = "debian" ] || die "Pensado para Debian (detectado: ${ID:-unknown})."

  if command -v mokutil >/dev/null 2>&1; then
    if mokutil --sb-state 2>/dev/null | grep -qi 'SecureBoot enabled'; then
      die "Secure Boot está activo. Limine no viene firmado para shim. Desactivalo o firmá el EFI vos."
    fi
  fi

  findmnt "$ESP_MOUNT" >/dev/null 2>&1 || die "ESP no montado en $ESP_MOUNT."

  ESP_SOURCE="$(findmnt -no SOURCE "$ESP_MOUNT")"
  [ -n "$ESP_SOURCE" ] || die "No pude resolver el dispositivo de $ESP_MOUNT."
  DISK="/dev/$(lsblk -no PKNAME "$ESP_SOURCE" | tr -d ' ')"
  PART="$(lsblk -no PARTN "$ESP_SOURCE" | tr -d ' ')"
  [ -n "$DISK" ] && [ -n "$PART" ] || die "No pude resolver disco/partición de $ESP_SOURCE."

  ROOT_UUID="$(findmnt -no UUID /)"
  [ -n "$ROOT_UUID" ] || die "No pude leer el UUID de /."

  CMDLINE="root=UUID=${ROOT_UUID} ro quiet"

  mapfile -t KERNELS < <(
    for k in /boot/vmlinuz-*; do
      [ -e "$k" ] || continue
      ver="${k#/boot/vmlinuz-}"
      [ -f "/boot/initrd.img-${ver}" ] || continue
      printf '%s\n' "$ver"
    done | sort -Vr
  )
  [ "${#KERNELS[@]}" -gt 0 ] || die "No hay pares vmlinuz/initrd en /boot."
}

owner_home() {
  local u="${SUDO_USER:-${USER:-}}"
  getent passwd "$u" 2>/dev/null | cut -d: -f6
}

render_entries() {
  local ver
  for ver in "${KERNELS[@]}"; do
    cat <<EOF
/Debian ${ver}
    comment: Debian GNU/Linux (Limine)
    protocol: linux
    path: guid(${ROOT_UUID}):/boot/vmlinuz-${ver}
    cmdline: ${CMDLINE}
    module_path: guid(${ROOT_UUID}):/boot/initrd.img-${ver}

EOF
  done
}

render_theme() {
  local tf
  tf="$(owner_home)/.config/zoi/themed/limine.conf"
  if [ -f "$tf" ]; then
    cat "$tf"
    return
  fi
  cat <<'EOF'
# Fallback until zoi-theme set <id> writes ~/.config/zoi/themed/limine.conf
interface_branding: ZOI
interface_branding_colour: 89b4fa
interface_help_colour: 6c7086
interface_help_colour_bright: 89b4fa
term_background: ff1e1e2e
term_foreground: cdd6f4
term_background_bright: 313244
term_foreground_bright: cdd6f4
term_palette: 11111b;f38ba8;a6e3a1;f9e2af;89b4fa;cba6f7;94e2d5;cdd6f4
term_palette_bright: 6c7086;f38ba8;a6e3a1;f9e2af;89b4fa;cba6f7;94e2d5;cdd6f4
EOF
}

assemble_conf() {
  echo "# Assembled by zoi-theme + limine-setup.sh. Theme: zoi-theme; entries: regenerated."
  echo "timeout: 5"
  echo "default_entry: 1"
  echo
  echo "# zoi-theme-begin"
  render_theme
  echo "# zoi-theme-end"
  echo
  echo "# zoi-entries-begin"
  render_entries
  echo "# zoi-entries-end"
}

write_live_conf() {
  local dir owner
  dir="$(dirname "$LIVE_CONF")"
  $SUDO mkdir -p "$dir"
  owner="${SUDO_USER:-${USER:-root}}"
  $SUDO chown "$owner:$owner" "$dir" 2>/dev/null || true
  $SUDO chmod 0755 "$dir"
  assemble_conf | $SUDO tee "$LIVE_CONF" >/dev/null
  $SUDO chown "$owner:$owner" "$LIVE_CONF" 2>/dev/null || true
}

print_plan() {
  log "Plan (sin escribir nada)."
  echo
  echo "  Debian:        ${PRETTY_NAME:-$ID}"
  echo "  Firmware:      UEFI (Secure Boot off / no comprobado como enabled)"
  echo "  ESP:           $ESP_SOURCE  ->  $ESP_MOUNT"
  echo "  Disk/part:     $DISK  partition $PART"
  echo "  Root UUID:     $ROOT_UUID"
  echo "  Cmdline:       $CMDLINE"
  echo "  Limine:        v$LIMINE_VERSION  (binary tarball, BOOTX64.EFI only)"
  echo "  EFI dest:      $ESP_MOUNT/$LIMINE_EFI_DIR/BOOTX64.EFI"
  echo "  Config dest:   $LIVE_CONF  (not on ESP, so zoi-theme can recolor it)"
  echo "  Theme snippet: $(owner_home)/.config/zoi/themed/limine.conf"
  echo "  NVRAM label:   $LIMINE_LABEL"
  echo "  Make default:  $MAKE_DEFAULT"
  echo "  Kernels:"
  local ver
  for ver in "${KERNELS[@]}"; do
    echo "    - $ver"
  done
  echo
  echo "  GRUB no se toca (paquetes ni EFI/debian)."
  echo "  install.sh no llama a este script."
  echo
  echo "limine.conf preview:"
  echo "----------------------------------------"
  assemble_conf
  echo "----------------------------------------"
}

download_efi() {
  local work
  work="$(mktemp -d)"
  trap 'rm -rf "$work"' RETURN
  log "Descargando Limine $LIMINE_VERSION (binary tarball)."
  curl -fsSL -o "$work/limine-binary.tar.xz" "$LIMINE_URL"
  tar -xJf "$work/limine-binary.tar.xz" -C "$work"
  local efi
  efi="$(find "$work" -name 'BOOTX64.EFI' | head -1)"
  [ -n "$efi" ] || die "El tarball no trae BOOTX64.EFI."
  printf '%s\n' "$efi"
}

apply_install() {
  need_root_write
  local efi_src dest conf
  efi_src="$(download_efi)"
  dest="$ESP_MOUNT/$LIMINE_EFI_DIR"

  log "Creando $dest"
  $SUDO mkdir -p "$dest"
  log "Copiando BOOTX64.EFI"
  $SUDO cp -a "$efi_src" "$dest/BOOTX64.EFI"
  # Do not place limine.conf next to the EFI app: that path shadows /boot/limine/limine.conf.
  if [ -f "$dest/limine.conf" ]; then
    log "Moviendo $dest/limine.conf fuera del ESP para no tapar el conf temeable."
    $SUDO mv "$dest/limine.conf" "$dest/limine.conf.bak"
  fi
  log "Escribiendo $LIVE_CONF (colores de zoi-theme + kernels)"
  write_live_conf

  if ! command -v efibootmgr >/dev/null 2>&1; then
    die "Falta efibootmgr. Instalalo: sudo apt install efibootmgr"
  fi

  if efibootmgr | grep -q " ${LIMINE_LABEL}\$"; then
    log "Ya existe una entrada NVRAM '$LIMINE_LABEL'."
  else
    log "Creando entrada NVRAM '$LIMINE_LABEL' (sin reordenar el BootOrder salvo --make-default)."
    $SUDO efibootmgr --create \
      --disk "$DISK" \
      --part "$PART" \
      --label "$LIMINE_LABEL" \
      --loader "\\EFI\\limine\\BOOTX64.EFI"
  fi

  if [ "$MAKE_DEFAULT" -eq 1 ]; then
    local limine_id current filtered
    limine_id="$(efibootmgr | awk -v l="$LIMINE_LABEL" 'index($0, l) { sub(/^Boot/,""); sub(/\*.*/,""); print; exit }')"
    [ -n "$limine_id" ] || die "No pude leer el id NVRAM de $LIMINE_LABEL."
    current="$(efibootmgr | awk '/^BootOrder:/{print $2}')"
    filtered="$(printf '%s\n' "${current//,/ }" | tr ' ' '\n' | grep -vx "$limine_id" | paste -sd, -)"
    log "BootOrder actual: $current"
    log "Poniendo $limine_id primero."
    $SUDO efibootmgr -o "${limine_id}${filtered:+,$filtered}"
  else
    warn "Limine está instalado pero GRUB sigue primero. Para usarlo: $0 apply --make-default"
  fi

  local hook self
  self="$(readlink -f "$0")"
  hook=/etc/kernel/postinst.d/zz-limine
  log "Instalando hook $hook"
  printf '%s\n' \
    '#!/bin/sh' \
    '# Regenerates Limine menu after a kernel install. Installed by zoi-debian limine-setup.sh.' \
    'set -e' \
    "[ -x \"$self\" ] || exit 0" \
    "\"$self\" update-config" \
    | $SUDO tee "$hook" >/dev/null
  $SUDO chmod 0755 "$hook"

  log "Listo. GRUB sigue instalado como fallback."
}

update_config() {
  need_root_write
  log "Reescribiendo $LIVE_CONF"
  write_live_conf
  log "Config actualizado."
}

print_status() {
  echo "ESP: $ESP_SOURCE -> $ESP_MOUNT"
  echo "Root UUID: $ROOT_UUID"
  if [ -f "$ESP_MOUNT/$LIMINE_EFI_DIR/BOOTX64.EFI" ]; then
    echo "EFI: presente $ESP_MOUNT/$LIMINE_EFI_DIR/BOOTX64.EFI"
  else
    echo "EFI: ausente"
  fi
  if [ -f "$LIVE_CONF" ]; then
    echo "conf: presente $LIVE_CONF"
  else
    echo "conf: ausente $LIVE_CONF"
  fi
  if command -v efibootmgr >/dev/null 2>&1; then
    efibootmgr | sed -n '1,3p'
    efibootmgr | grep -E 'debian|Limine|GRUB|shim' || true
  fi
}

detect
case "$cmd" in
  plan|"") print_plan ;;
  apply) apply_install ;;
  update-config) update_config ;;
  status) print_status ;;
  *) die "Comando desconocido: $cmd (plan|apply|update-config|status)" ;;
esac
