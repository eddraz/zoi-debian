#!/usr/bin/env bash
# zoi-debian installer for a Debian 13 terminal/minimal install.
#
# From a clone:
#   apt-get update && apt-get install -y curl git
#   git clone https://github.com/<you>/zoi-debian.git
#   cd zoi-debian && sudo ./scripts/install.sh
#
# Or one-liner (needs network already, pipe to bash not sh):
#   curl -fsSL https://raw.githubusercontent.com/<you>/zoi-debian/main/scripts/install.sh \
#     | sudo ZOI_REPO=https://github.com/<you>/zoi-debian.git bash
#
# Prompts only what is missing: Wi-Fi if offline; locale/keyboard/timezone if unset;
# sudoers for the login user (confirm). Uses the existing OS login user. Does not ask
# for name, email, username, or password, and does not create users or set git identity.
# Then Pi + desktop. Idempotent. Re-run does not re-ask or re-theme an existing desktop.
#
# Env: ZOI_REPO ZOI_BRANCH ZOI_DIR ZOI_NONINTERACTIVE=1 ZOI_SKIP_REBOOT=1
#      ZOI_LANG ZOI_XKB ZOI_TZ TARGET_USER ZOI_SUDOERS=0|1

set -euo pipefail

# usermod, locale-gen, update-locale viven en /usr/sbin. Un PATH de usuario
# (sudo -E, su sin '-', agentes) no lo incluye y el script muere con 127.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:${PATH:-/usr/bin:/bin}"

ZOI_REPO="${ZOI_REPO:-https://github.com/<owner>/zoi-debian.git}"
ZOI_BRANCH="${ZOI_BRANCH:-main}"

log()  { printf '\033[1;35m[zoi]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[fail]\033[0m %s\n' "$*" >&2; exit 1; }


dpkg_arch() { dpkg --print-architecture; }

arch_in() {
  local want="$1"
  shift
  local a
  for a in "$@"; do
    [ "$a" = "$want" ] && return 0
  done
  return 1
}

tty_in() {
  if [ -r /dev/tty ]; then
    cat - </dev/tty
  else
    cat -
  fi
}

ask() {
  local prompt="$1"
  local __out
  if [ -r /dev/tty ]; then
    printf '%s' "$prompt" >/dev/tty
    IFS= read -r __out </dev/tty
  else
    printf '%s' "$prompt"
    IFS= read -r __out
  fi
  printf '%s' "$__out"
}

ask_secret() {
  local prompt="$1"
  local __out
  if [ -r /dev/tty ]; then
    printf '%s' "$prompt" >/dev/tty
    IFS= read -rs __out </dev/tty
    printf '\n' >/dev/tty
  else
    printf '%s' "$prompt"
    IFS= read -rs __out
    printf '\n'
  fi
  printf '%s' "$__out"
}

have_net() {
  ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 || ping -c 1 -W 2 9.9.9.9 >/dev/null 2>&1
}

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
ARCH="$(dpkg_arch)"
export ARCH
FOREIGN="$(dpkg --print-foreign-architectures 2>/dev/null | tr '\n' ' ')"
log "Debian ${VERSION_ID:-unknown} · arquitectura nativa: $ARCH${FOREIGN:+ (foreign: $FOREIGN)}"
if ! arch_in "$ARCH" amd64 arm64; then
  warn "ZOI está testeado en amd64 y arm64. En $ARCH se instalan paquetes Debian; Yazi/Mullvad/Lemurs/Inlyne pueden saltearse."
fi

# Locate this repo if launched from a clone. curl|bash sets BASH_SOURCE to
# /dev/fd/N — that is not the git tree.
SCRIPT_PATH="${BASH_SOURCE[0]:-}"
SCRIPT_DIR=""
REPO_FROM_SCRIPT=""
case "$SCRIPT_PATH" in
  ""|/dev/fd/*|/proc/*/fd/*) ;;
  *)
    if [ -f "$SCRIPT_PATH" ]; then
      SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
      if [ -d "$SCRIPT_DIR/../dotfiles" ]; then
        REPO_FROM_SCRIPT="$(cd "$SCRIPT_DIR/.." && pwd)"
      fi
    fi
    ;;
esac

# ================================================================= bootstrap
if [ "${ZOI_BOOTSTRAPPED:-}" != "1" ]; then
  log "Fase 1: red, locale si falta, y re-lanzar como el usuario del sistema."

  if ! have_net; then
    log "No hay internet. Configurá Wi‑Fi."
        if ! command -v nmcli >/dev/null 2>&1; then
          log "Instalando NetworkManager (hace falta algo de red, p. ej. ethernet)."
          $SUDO apt-get update -y
          $SUDO apt-get install -y --no-install-recommends network-manager iw wpasupplicant rfkill || \
            die "Sin red y sin NetworkManager. Conectá ethernet o configurá Wi‑Fi en el instalador de Debian."
        fi
    $SUDO systemctl enable --now NetworkManager >/dev/null 2>&1 || true
    $SUDO rfkill unblock wifi >/dev/null 2>&1 || true
    $SUDO nmcli radio wifi on >/dev/null 2>&1 || true
    sleep 2
    if command -v nmcli >/dev/null; then
      log "Redes visibles:"
      $SUDO nmcli -f SSID,SIGNAL,SECURITY dev wifi list | head -20 || true
      SSID="$(ask "SSID: ")"
      [ -n "$SSID" ] || die "SSID vacío."
      WIFIPASS="$(ask_secret "Contraseña Wi‑Fi: ")"
      $SUDO nmcli dev wifi connect "$SSID" password "$WIFIPASS" || die "No pude conectar a $SSID."
    else
      die "Sin NetworkManager y sin red. Conectá ethernet y reintentá."
    fi
    have_net || die "Sigue sin internet después del Wi‑Fi."
    log "Wi‑Fi OK."
  else
    log "Internet OK."
  fi

  $SUDO apt-get update -y
  $SUDO apt-get install -y --no-install-recommends \
    ca-certificates curl git sudo xz-utils \
    network-manager iw wpasupplicant rfkill \
    locales tzdata keyboard-configuration console-setup

  if [ -z "${TARGET_USER:-}" ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    TARGET_USER="$SUDO_USER"
  fi
  if [ -z "${TARGET_USER:-}" ] && [ "$(id -u)" -ne 0 ]; then
    TARGET_USER="${USER}"
  fi
  if [ -z "${TARGET_USER:-}" ] || [ "$TARGET_USER" = "root" ]; then
    TARGET_USER="$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 && $1 != "nobody" {print $1; exit}')"
  fi
  [ -n "${TARGET_USER:-}" ] && [ "$TARGET_USER" != "root" ] || \
    die "No hay usuario de escritorio. El instalador no crea cuentas ni pide contraseña: corré el script con sudo desde tu usuario."
  id "$TARGET_USER" >/dev/null 2>&1 || die "El usuario $TARGET_USER no existe."
  log "Usuario del sistema: $TARGET_USER (no pido nombre, correo ni contraseña)."

  if [ "${ZOI_NONINTERACTIVE:-}" = "1" ]; then
        ZOI_LANG="${ZOI_LANG:-es_CO.UTF-8}"
        ZOI_XKB="${ZOI_XKB:-latam,us}"
        ZOI_TZ="${ZOI_TZ:-America/Bogota}"
  else
    read_kv() {
      local file="$1" key="$2"
      [ -r "$file" ] || return 0
      awk -F= -v k="$key" '
        $1 == k {
          v=$2
          gsub(/^[ 	"]+|[ 	"]+$/, "", v)
          print v
          exit
        }
      ' "$file"
    }
    _cur_lang="$(read_kv /etc/default/locale LANG)"
    _cur_xkb="$(read_kv /etc/default/keyboard XKBLAYOUT)"
    _cur_tz=""
    if [ -r /etc/timezone ]; then
      _cur_tz="$(tr -d "[:space:]" < /etc/timezone)"
    elif command -v timedatectl >/dev/null; then
      _cur_tz="$(timedatectl show -p Timezone --value 2>/dev/null || true)"
    fi
    if [ -z "${ZOI_LANG:-}" ]; then
      if [ -n "$_cur_lang" ]; then
        ZOI_LANG="$_cur_lang"
      else
        _lang="$(ask "Locale [es_CO.UTF-8]: ")"
        ZOI_LANG="${_lang:-es_CO.UTF-8}"
      fi
    fi
    if [ -z "${ZOI_XKB:-}" ]; then
      if [ -n "$_cur_xkb" ]; then
        ZOI_XKB="$_cur_xkb"
      else
        _xkb="$(ask "Teclado XKB [latam,us]: ")"
        ZOI_XKB="${_xkb:-latam,us}"
      fi
    fi
    if [ -z "${ZOI_TZ:-}" ]; then
      if [ -n "$_cur_tz" ]; then
        ZOI_TZ="$_cur_tz"
      else
        _tz="$(ask "Timezone [America/Bogota]: ")"
        ZOI_TZ="${_tz:-America/Bogota}"
      fi
    fi
    log "Locale=$ZOI_LANG  teclado=$ZOI_XKB  tz=$ZOI_TZ"
  fi

  _glist=""
  for _g in video render audio netdev plugdev seat; do
    getent group "$_g" >/dev/null 2>&1 || continue
    _glist="${_glist:+$_glist,}$_g"
  done
  if [ -n "$_glist" ]; then
    if [ "$(id -u)" -eq 0 ]; then
      usermod -aG "$_glist" "$TARGET_USER" || true
    else
      $SUDO usermod -aG "$_glist" "$TARGET_USER" || true
    fi
  fi

  sudoers_tag="$(printf '%s' "$TARGET_USER" | tr -c 'A-Za-z0-9_-' '_')"
  sudoers_file="/etc/sudoers.d/zoi-${sudoers_tag}"
  want_sudoers=0
  if [ -f "$sudoers_file" ]; then
    log "sudoers ya tiene a $TARGET_USER ($sudoers_file); no pregunto."
  else
    if [ "${ZOI_NONINTERACTIVE:-}" = "1" ]; then
      case "${ZOI_SUDOERS:-1}" in
        0|n|N|no|false) want_sudoers=0 ;;
        *) want_sudoers=1 ;;
      esac
    else
      log "Puedo escribir $sudoers_file con: $TARGET_USER ALL=(ALL:ALL) ALL"
      _ans="$(ask "¿Agregar a $TARGET_USER en sudoers? [Y/n] ")"
      case "$_ans" in
        ""|Y|y|S|s) want_sudoers=1 ;;
        *) want_sudoers=0 ;;
      esac
    fi
    if [ "$want_sudoers" = 1 ]; then
      _sudoers_tmp="$(mktemp)"
      printf '%s ALL=(ALL:ALL) ALL\n' "$TARGET_USER" >"$_sudoers_tmp"
      chmod 440 "$_sudoers_tmp"
      if visudo -cf "$_sudoers_tmp" >/dev/null 2>&1 \
        && $SUDO install -m 440 -o root -g root "$_sudoers_tmp" "$sudoers_file"; then
        rm -f "$_sudoers_tmp"
        if [ "$(id -u)" -eq 0 ]; then
          usermod -aG sudo "$TARGET_USER" 2>/dev/null || true
        else
          $SUDO usermod -aG sudo "$TARGET_USER" 2>/dev/null || true
        fi
        log "Agregué a $TARGET_USER en $sudoers_file y al grupo sudo."
      else
        rm -f "$_sudoers_tmp"
        warn "No pude escribir $sudoers_file (hace falta root/sudo, o visudo rechazó el fragmento)."
      fi
    else
      log "No agrego a $TARGET_USER en sudoers."
    fi
  fi

      _now_lang="$(awk -F= '/^LANG=/ {gsub(/"/,"",$2); print $2; exit}' /etc/default/locale 2>/dev/null || true)"
      _now_xkb="$(awk -F= '/^XKBLAYOUT=/ {gsub(/"/,"",$2); print $2; exit}' /etc/default/keyboard 2>/dev/null || true)"
      _now_tz=""
      if [ -r /etc/timezone ]; then
        _now_tz="$(tr -d "[:space:]" < /etc/timezone)"
      fi
      if [ "$_now_lang" = "$ZOI_LANG" ] && [ "$_now_xkb" = "$ZOI_XKB" ] && [ "$_now_tz" = "$ZOI_TZ" ]; then
        log "Locale/teclado/tz ya están así; no reescribo."
      else
      log "Aplicando locale=$ZOI_LANG  teclado=$ZOI_XKB  tz=$ZOI_TZ"
      if [ ! -f "/usr/share/zoneinfo/$ZOI_TZ" ]; then
        die "Timezone inexistente: $ZOI_TZ"
      fi
      $SUDO timedatectl set-timezone "$ZOI_TZ" 2>/dev/null || $SUDO ln -sf "/usr/share/zoneinfo/$ZOI_TZ" /etc/localtime
      if [ -f /etc/locale.gen ] && ! grep -qE "^${ZOI_LANG}[[:space:]]+UTF-8" /etc/locale.gen; then
        printf '%s\n' "${ZOI_LANG} UTF-8" | $SUDO tee -a /etc/locale.gen >/dev/null
      fi
      $SUDO locale-gen "$ZOI_LANG" >/dev/null
      $SUDO update-locale LANG="$ZOI_LANG" LANGUAGE="${ZOI_LANG%%.*}" LC_ALL="$ZOI_LANG"
      $SUDO tee /etc/default/keyboard >/dev/null <<EOF
XKBMODEL="pc105"
XKBLAYOUT="${ZOI_XKB}"
XKBVARIANT=""
XKBOPTIONS="grp:alt_shift_toggle"
BACKSPACE="guess"
EOF
      $SUDO setupcon 2>/dev/null || true
      $SUDO localectl set-x11-keymap "${ZOI_XKB}" pc105 "" grp:alt_shift_toggle 2>/dev/null || true
      fi

  TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
  [ -n "$TARGET_HOME" ] || die "No pude resolver el home de $TARGET_USER."

  DEST_REPO="${ZOI_DIR:-$TARGET_HOME/projects/zoi-debian}"
  if [ -n "$REPO_FROM_SCRIPT" ] && [ -d "$REPO_FROM_SCRIPT/dotfiles" ]; then
    if [ "$REPO_FROM_SCRIPT" != "$DEST_REPO" ]; then
      log "Copiando el repo a $DEST_REPO."
      mkdir -p "$(dirname "$DEST_REPO")"
      if [ ! -d "$DEST_REPO" ]; then
        cp -a "$REPO_FROM_SCRIPT" "$DEST_REPO"
      fi
    else
      DEST_REPO="$REPO_FROM_SCRIPT"
    fi
  else
    mkdir -p "$(dirname "$DEST_REPO")"
    if [ -d "$DEST_REPO/.git" ]; then
      log "Actualizando $DEST_REPO."
      git -C "$DEST_REPO" pull --ff-only || warn "git pull falló; sigo con la copia local."
    else
      case "$ZOI_REPO" in
        *"<owner>"*|*"<you>"*)
          die "Definí ZOI_REPO=https://github.com/<tu-usuario>/zoi-debian.git (curl|bash no trae el repo)."
          ;;
      esac
      log "Clonando $ZOI_REPO → $DEST_REPO."
      git clone --depth 1 -b "$ZOI_BRANCH" "$ZOI_REPO" "$DEST_REPO"
    fi
  fi
  chown -R "$TARGET_USER:$TARGET_USER" "$DEST_REPO" "$(dirname "$DEST_REPO")" 2>/dev/null || true

  if [ "$(id -u)" -eq 0 ]; then
    log "Re-lanzando el resto de la instalación como $TARGET_USER."
    exec sudo -u "$TARGET_USER" -H \
      env ZOI_BOOTSTRAPPED=1 ZOI_DIR="$DEST_REPO" ZOI_SKIP_REBOOT="${ZOI_SKIP_REBOOT:-}" \
          TARGET_USER="$TARGET_USER" \
          ZOI_LANG="$ZOI_LANG" ZOI_XKB="$ZOI_XKB" ZOI_TZ="$ZOI_TZ" \
      bash "$DEST_REPO/scripts/install.sh"
  fi

  export ZOI_DIR="$DEST_REPO"
  export ZOI_BOOTSTRAPPED=1
  export ZOI_LANG ZOI_XKB ZOI_TZ
fi

# ================================================================= desktop stack (as the login user)
TARGET_USER="${TARGET_USER:-$USER}"
ZOI_DIR="${ZOI_DIR:-$HOME/projects/zoi-debian}"
QS_DOT="$HOME/.config/quickshell"

if [ "$(id -u)" -eq 0 ]; then
  die "La fase de escritorio no debe correr como root."
fi
SUDO=sudo

ARCH="$(dpkg_arch)"
export ARCH
log "Fase 2: paquetes y dotfiles para $USER ($HOME) · arch $ARCH."

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
  qt6-wayland
  pipewire wireplumber
  wlsunset wtype wl-clipboard grim slurp wf-recorder
  playerctl mpv mpv-mpris yt-dlp
  cliphist
  figlet python3-terminaltexteffects
  brightnessctl
  lightdm
  kbd
  fish
  jq
  bc
  btop
  python3-gi gir1.2-gdkpixbuf-2.0 libglib2.0-bin
  libqrencode4 qrencode
  polkitd pkexec
  fonts-noto fonts-noto-color-emoji fonts-noto-cjk
  network-manager
  bluez bluez-tools
  pulseaudio-utils
  xdg-utils xdg-user-dirs
  pavucontrol
  amberol loupe
  seatd
  ffmpeg poppler-utils fd-find ripgrep fzf imagemagick p7zip-full
  git curl ca-certificates xz-utils
)

BP_PKGS=(quickshell)

log "Instalando paquetes base (puede tardar 1-3 min)."
$SUDO apt-get install -y --no-install-recommends "${PKGS[@]}"
log "Asegurando paquetes de backports."
$SUDO apt-get install -y --no-install-recommends -t trixie-backports "${BP_PKGS[@]}"

# seatd: Lemurs is a systemd service, so logind never gives Sway an active seat.
# Debian ships /usr/sbin/seatd and unit `ExecStart=seatd -g video`. Do not
# drop-in /usr/bin/seatd (203/EXEC, no socket).
if [ -x /usr/sbin/seatd ] || [ -x /usr/bin/seatd ]; then
  $SUDO rm -f /etc/systemd/system/seatd.service.d/video.conf
  $SUDO rmdir /etc/systemd/system/seatd.service.d 2>/dev/null || true
  $SUDO systemctl daemon-reload
  $SUDO systemctl enable --now seatd || warn "No pude habilitar seatd."
fi
# renderD128 is 0660 render; Lemurs+seatd does not get logind uaccess ACLs.
# Do not use SUDO_USER: after `sudo -u <desktop>` from root it is root.
_desk="${TARGET_USER:-$USER}"
_glist=""
for _g in render video seat; do
  getent group "$_g" >/dev/null 2>&1 || continue
  _glist="${_glist:+$_glist,}$_g"
done
if [ -n "$_glist" ] && [ -n "$_desk" ] && [ "$_desk" != root ]; then
  $SUDO usermod -aG "$_glist" "$_desk" || true
fi

# ---------------------------------------------------------------- nodejs (latest current, nodejs.org; amd64/arm64)
node_arch=""
case "$ARCH" in
  amd64) node_arch="x64" ;;
  arm64) node_arch="arm64" ;;
esac
if [ -n "$node_arch" ]; then
  node_latest=""
  node_shasums="$(curl -fsSL https://nodejs.org/dist/latest/SHASUMS256.txt)" || node_shasums=""
  if [ -n "$node_shasums" ]; then
    node_latest="$(printf '%s\n' "$node_shasums" | awk -v suf="-linux-${node_arch}.tar.xz" '
      index($2, suf) && $2 ~ suf "$" {
        v=$2
        sub(/^node-v/, "", v)
        sub(/-linux-.*$/, "", v)
        print v
        exit
      }')"
  fi
  node_have=""
  if command -v node >/dev/null 2>&1; then
    node_have="$(node -v 2>/dev/null | sed 's/^v//')"
  fi
  if [ -z "$node_latest" ]; then
    warn "No pude resolver Node.js latest desde nodejs.org."
  elif [ "$node_have" = "$node_latest" ]; then
    log "Node.js ya está en v$node_latest."
  else
    log "Instalando Node.js v${node_latest} ($ARCH) en /usr/local."
    node_tmp="$(mktemp -d)"
    node_url="https://nodejs.org/dist/latest/node-v${node_latest}-linux-${node_arch}.tar.xz"
    if curl -fsSL "$node_url" -o "$node_tmp/node.tar.xz" \
      && $SUDO tar -xJf "$node_tmp/node.tar.xz" -C /usr/local --strip-components=1; then
      log "Node.js $(/usr/local/bin/node -v)  npm $(/usr/local/bin/npm -v 2>/dev/null || echo '?')"
    else
      warn "No pude instalar Node.js v${node_latest}."
    fi
    rm -rf "$node_tmp"
  fi
else
  warn "Node.js no publica tarball linux para $ARCH; salteo."
fi

# ---------------------------------------------------------------- yazi (official APT repo; amd64/arm64)
if arch_in "$ARCH" amd64 arm64; then
  if [ ! -f /usr/share/keyrings/yazi-keyring.gpg ]; then
    log "Agregando el repo APT oficial de Yazi ($ARCH)."
    curl -fsSL https://yazi-rs.github.io/builds/yazi-keyring.gpg | $SUDO tee /usr/share/keyrings/yazi-keyring.gpg >/dev/null
  fi
  echo "deb [arch=$ARCH signed-by=/usr/share/keyrings/yazi-keyring.gpg] https://yazi-rs.github.io/builds/ stable main" | $SUDO tee /etc/apt/sources.list.d/yazi.list >/dev/null
  $SUDO apt-get update -y
  log "Instalando yazi (file manager, previews Sixel en foot)."
  $SUDO apt-get install -y --no-install-recommends yazi || warn "No se pudo instalar yazi desde el repo oficial."
else
  warn "Yazi APT no publica $ARCH; no agrego el repo ni instalo yazi."
fi

# ---------------------------------------------------------------- Mullvad Browser (official APT repo; amd64)
if arch_in "$ARCH" amd64; then
  if [ ! -f /usr/share/keyrings/mullvad-keyring.asc ]; then
    log "Agregando el repo APT oficial de Mullvad ($ARCH)."
    curl -fsSL https://repository.mullvad.net/deb/mullvad-keyring.asc | $SUDO tee /usr/share/keyrings/mullvad-keyring.asc >/dev/null
  fi
  echo "deb [arch=$ARCH signed-by=/usr/share/keyrings/mullvad-keyring.asc] https://repository.mullvad.net/deb/stable stable main" | $SUDO tee /etc/apt/sources.list.d/mullvad.list >/dev/null
  $SUDO apt-get update -y
  log "Instalando Mullvad Browser (fallback si no hay Thorium)."
  $SUDO apt-get install -y --no-install-recommends mullvad-browser || warn "No se pudo instalar mullvad-browser."
else
  warn "Mullvad Browser no tiene paquete para $ARCH; salteo."
fi
# XDG default: Thorium if present, else Mullvad.
browser_set=""
for desk in thorium-browser.desktop mullvad-browser.desktop net.mullvad.MullvadBrowser.desktop mullvadbrowser.desktop; do
  if [ -f "/usr/share/applications/$desk" ] || [ -f "$HOME/.local/share/applications/$desk" ]; then
    xdg-settings set default-web-browser "$desk" 2>/dev/null || true
    xdg-mime default "$desk" x-scheme-handler/http 2>/dev/null || true
    xdg-mime default "$desk" x-scheme-handler/https 2>/dev/null || true
    xdg-mime default "$desk" text/html 2>/dev/null || true
    browser_set="$desk"
    break
  fi
done
if [ -n "$browser_set" ]; then
  log "Navegador XDG default: $browser_set"
fi

# ---------------------------------------------------------------- user dirs
log "Inicializando xdg-user-dirs."
xdg-user-dirs-update || true

# ---------------------------------------------------------------- repo already on disk
if [ ! -d "$ZOI_DIR/dotfiles" ]; then
  die "No encuentro $ZOI_DIR/dotfiles. Corré el instalador desde un clone del repo."
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
if [ -n "${ZOI_XKB:-}" ]; then
  log "Sway xkb_layout → $ZOI_XKB"
  sed -i "s/xkb_layout .*/xkb_layout ${ZOI_XKB}/" "$HOME/.config/sway/config"
fi


# ---------------------------------------------------------------- foot + fish
log "Instalando foot + fish como terminal y shell default."
mkdir -p "$HOME/.config/foot"
if [ -f "$ZOI_DIR/dotfiles/config/foot/foot.ini" ]; then
  cp "$ZOI_DIR/dotfiles/config/foot/foot.ini" "$HOME/.config/foot/foot.ini"
fi
mkdir -p "$HOME/.config/fish/conf.d"
if [ -f "$ZOI_DIR/dotfiles/config/fish/conf.d/zoi.fish" ]; then
  cp "$ZOI_DIR/dotfiles/config/fish/conf.d/zoi.fish" "$HOME/.config/fish/conf.d/zoi.fish"
fi
if [ ! -f "$HOME/.config/fish/config.fish" ] && [ -f "$ZOI_DIR/dotfiles/config/fish/config.fish" ]; then
  cp "$ZOI_DIR/dotfiles/config/fish/config.fish" "$HOME/.config/fish/config.fish"
fi
if [ -f /usr/share/applications/foot.desktop ]; then
  mkdir -p "$HOME/.local/share/applications" "$HOME/.config"
  xdg-mime default foot.desktop x-scheme-handler/terminal 2>/dev/null || true
  printf 'foot.desktop\n' > "$HOME/.config/xdg-terminals.list"
fi

# ---------------------------------------------------------------- herdr config (before first theme apply)
log "Sembrando config de Herdr (~/.config/herdr)."
mkdir -p "$HOME/.config/herdr"
if [ ! -f "$HOME/.config/herdr/config.toml" ] && [ -f "$ZOI_DIR/dotfiles/config/herdr/config.toml" ]; then
  cp "$ZOI_DIR/dotfiles/config/herdr/config.toml" "$HOME/.config/herdr/config.toml"
fi

# ---------------------------------------------------------------- local-bin
log "Instalando scripts auxiliares y CLI zoi-theme en ~/.local/bin."
mkdir -p "$HOME/.local/bin"
find "$ZOI_DIR/dotfiles/local-bin" -maxdepth 1 -type f ! -name '*.pyc'   -exec install -m 755 {} "$HOME/.local/bin/" \;

# ---------------------------------------------------------------- inlyne (GPU markdown viewer; amd64/arm64)
INLYNE_VER="0.5.3"
case "$ARCH" in
  amd64) inlyne_triple="x86_64-unknown-linux-gnu" ;;
  arm64) inlyne_triple="aarch64-unknown-linux-gnu" ;;
  *) inlyne_triple="" ;;
esac
if [ -n "$inlyne_triple" ]; then
  if command -v inlyne >/dev/null; then
    log "Inlyne ya está en PATH."
  else
    log "Instalando Inlyne v${INLYNE_VER} ($ARCH) en ~/.local/bin."
    inlyne_tmp="$(mktemp -d)"
    inlyne_url="https://github.com/Inlyne-Project/inlyne/releases/download/v${INLYNE_VER}/inlyne-v${INLYNE_VER}-${inlyne_triple}.tar.gz"
    if curl -fsSL "$inlyne_url" | tar -xzf - -C "$inlyne_tmp"; then
      inlyne_bin="$(find "$inlyne_tmp" -type f -name inlyne | head -n 1)"
      if [ -n "$inlyne_bin" ]; then
        install -m 755 "$inlyne_bin" "$HOME/.local/bin/inlyne"
      else
        warn "El tarball de Inlyne no trajo el binario."
      fi
    else
      warn "No pude descargar Inlyne v${INLYNE_VER}."
    fi
    rm -rf "$inlyne_tmp"
  fi
else
  warn "Inlyne no publica binario para $ARCH; salteo el visor markdown GPU."
fi

log "Configurando Yazi (foot + Sixel) como file manager default."
mkdir -p "$HOME/.config/yazi" "$HOME/.local/share/applications"
if [ -f "$ZOI_DIR/dotfiles/yazi/yazi.toml" ]; then
  cp "$ZOI_DIR/dotfiles/yazi/yazi.toml" "$HOME/.config/yazi/yazi.toml"
fi
if [ -f "$ZOI_DIR/dotfiles/applications/yazi.desktop" ]; then
  cp "$ZOI_DIR/dotfiles/applications/yazi.desktop" "$HOME/.local/share/applications/yazi.desktop"
fi
if [ -f "$ZOI_DIR/dotfiles/applications/yazi-folder.desktop" ]; then
  cp "$ZOI_DIR/dotfiles/applications/yazi-folder.desktop" "$HOME/.local/share/applications/yazi-folder.desktop"
fi
if [ -f "$ZOI_DIR/dotfiles/applications/inlyne.desktop" ]; then
  cp "$ZOI_DIR/dotfiles/applications/inlyne.desktop" "$HOME/.local/share/applications/inlyne.desktop"
fi
rm -f "$HOME/.local/share/applications/zoi-markdown.desktop"
if command -v xdg-mime >/dev/null && [ -f "$HOME/.local/share/applications/yazi.desktop" ]; then
  xdg-mime default yazi-folder.desktop inode/directory || true
  xdg-mime default yazi-folder.desktop inode/mount-point || true
  xdg-mime default inlyne.desktop text/markdown || true
  xdg-mime default inlyne.desktop text/x-markdown || true
fi

# ---------------------------------------------------------------- media defaults
log "Defaults XDG: mpv (video), Amberol (audio), Loupe (imágenes)."
if command -v xdg-mime >/dev/null; then
  for mime in video/mp4 video/webm video/x-matroska video/quicktime video/x-msvideo video/mpeg video/ogg video/x-ogm+ogg video/x-flv; do
    xdg-mime default mpv.desktop "$mime" 2>/dev/null || true
  done
  for mime in audio/mpeg audio/mp4 audio/flac audio/x-flac audio/ogg audio/x-vorbis+ogg audio/x-wav audio/wav audio/aac audio/x-m4a audio/mp3 application/ogg; do
    xdg-mime default io.bassi.Amberol.desktop "$mime" 2>/dev/null || true
  done
  for mime in image/jpeg image/png image/gif image/webp image/bmp image/tiff image/svg+xml image/avif image/jxl image/heic image/heif; do
    xdg-mime default org.gnome.Loupe.desktop "$mime" 2>/dev/null || true
  done
fi


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

# ---------------------------------------------------------------- initialize theme from default wallpaper
# Selector Quickshell (Session → Theme) lee:
#   ~/.local/state/quickshell/theme       id activo
#   ~/.local/state/quickshell/colors.json paleta para Color.qml al boot
mkdir -p "$HOME/.local/state/quickshell" "$HOME/.local/state/zoi/theme"
if [ -f "$HOME/.local/state/quickshell/theme" ] || [ -f "$HOME/.local/state/quickshell/colors.json" ]; then
  log "Tema ya existe; no piso la paleta con baby-yoda."
else
log "Aplicando paleta extraída de baby-yoda-cartoon.jpg."
WALL="$HOME/Imágenes/baby-yoda-cartoon.jpg"
if [ -x "$HOME/.local/bin/qs-theme-from-wallpaper" ] && [ -f "$WALL" ]; then
  PAL="$("$HOME/.local/bin/qs-theme-from-wallpaper" --json "$WALL")" || PAL=""
  if [ -n "$PAL" ]; then
    "$HOME/.local/bin/zoi-theme" apply-json "$PAL" || warn "zoi-theme apply-json falló."
  else
    warn "No pude extraer paleta; fallback tokyo-night."
    "$HOME/.local/bin/zoi-theme" set tokyo-night || true
  fi
else
  "$HOME/.local/bin/zoi-theme" set tokyo-night || warn "No se pudo aplicar tema inicial."
fi

fi
# Si un dispatcher opcional (gsettings) abortó un apply viejo, igual sembrar
# colors.json para que el selector sobreviva al primer login.
if [ ! -f "$HOME/.local/state/quickshell/colors.json" ] && [ -f "$HOME/.local/state/zoi/theme/current/colors.json" ]; then
  log "Sembrando ~/.local/state/quickshell/colors.json desde el motor de temas."
  cp "$HOME/.local/state/zoi/theme/current/colors.json" "$HOME/.local/state/quickshell/colors.json"
fi
if [ ! -f "$HOME/.local/state/quickshell/theme" ] && [ -f "$HOME/.local/state/quickshell/colors.json" ]; then
  python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("id","tokyo-night"))' \
    "$HOME/.local/state/quickshell/colors.json" > "$HOME/.local/state/quickshell/theme" || true
fi

# ---------------------------------------------------------------- fish as login shell
FISH_BIN="$(command -v fish || true)"
LOGIN_USER="${TARGET_USER:-$USER}"
if [ -n "$FISH_BIN" ]; then
  if ! grep -qxF "$FISH_BIN" /etc/shells 2>/dev/null; then
    log "Agregando $FISH_BIN a /etc/shells."
    printf '%s\n' "$FISH_BIN" | $SUDO tee -a /etc/shells >/dev/null
  fi
  CURRENT_SHELL="$(getent passwd "$LOGIN_USER" | cut -d: -f7 || true)"
  if [ "$CURRENT_SHELL" != "$FISH_BIN" ]; then
    log "Login shell de $LOGIN_USER → fish."
    $SUDO chsh -s "$FISH_BIN" "$LOGIN_USER" || warn "chsh falló; corré: chsh -s $FISH_BIN $LOGIN_USER"
  else
    log "Login shell ya es fish ($LOGIN_USER)."
  fi
fi

# ---------------------------------------------------------------- lemurs display manager
if [ -x "$ZOI_DIR/scripts/lemurs-setup.sh" ]; then
  if arch_in "$ARCH" amd64; then
    log "Instalando Lemurs (TUI DM, vtrgb + PAM Debian). LightDM queda instalado pero deshabilitado."
    if ! "$ZOI_DIR/scripts/lemurs-setup.sh" apply; then
      if systemctl is-enabled lemurs >/dev/null 2>&1 && [ -f /etc/lemurs/config.toml ]; then
        warn "lemurs-setup apply salió !=0, pero Lemurs está enabled."
      else
        warn "Lemurs no quedó enabled (falta /etc/lemurs/config.toml o el unit). LightDM sigue. Reintentá: sudo $ZOI_DIR/scripts/lemurs-setup.sh apply"
      fi
    fi
  else
    warn "Lemurs upstream es binario x86_64; salteo en $ARCH (LightDM queda)."
  fi
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

# ---------------------------------------------------------------- herdr
log "Instalando Herdr (https://herdr.dev)."
if command -v herdr >/dev/null 2>&1; then
  log "herdr ya está en PATH."
else
  curl -fsSL https://herdr.dev/install.sh | sh || warn "No se pudo instalar herdr. Después: curl -fsSL https://herdr.dev/install.sh | sh"
fi

# ---------------------------------------------------------------- pi-agent
log "Instalando Pi coding agent (https://pi.dev)."
if command -v pi >/dev/null 2>&1; then
  log "pi ya está en PATH."
else
  curl -fsSL https://pi.dev/install.sh | sh || warn "No se pudo instalar pi. Después: curl -fsSL https://pi.dev/install.sh | sh"
fi
mkdir -p "$HOME/.config/fish/conf.d"
if ! grep -q 'pi-node' "$HOME/.config/fish/conf.d/zoi.fish" 2>/dev/null; then
  cat >> "$HOME/.config/fish/conf.d/zoi.fish" <<'EOF'
for d in ~/.local/bin ~/.local/share/pi-node/bin ~/.local/share/pi-node/current/bin ~/.local/share/pi-node/node-*/bin
  if test -d $d
    fish_add_path $d
  end
end
EOF
fi

# ---------------------------------------------------------------- sanity
log "Verificando binarios clave."
MISSING=0
for b in sway qs swaymsg playerctl wlsunset foot fish yazi qs-files qs-browser qs-keys-apply qs-md inlyne cliphist wl-copy wtype grim slurp wf-recorder wireplumber btop bc zoi-theme git curl node npm mpv amberol loupe; do
  command -v "$b" >/dev/null || { warn "Falta binario: $b"; MISSING=$((MISSING+1)); }
done
command -v thorium-browser >/dev/null || command -v mullvad-browser >/dev/null || warn "No hay Thorium ni Mullvad; Super+Shift+Return usa qs-browser (XDG)."
command -v herdr >/dev/null || warn "Falta binario: herdr (curl -fsSL https://herdr.dev/install.sh | sh)."
command -v pi >/dev/null || warn "Falta binario: pi (reiniciá la shell o agregá el PATH de pi.dev)."

log "Listo."
if [ "$MISSING" -gt 0 ]; then
  warn "Faltan $MISSING binarios — instalá los paquetes correspondientes y corré de nuevo."
fi
log "Atajos: docs/shortcuts.md  ·  Temas: docs/configuration.md  ·  Fallos: docs/troubleshooting.md"

if [ "${ZOI_SKIP_REBOOT:-}" != "1" ]; then
  log "Reiniciá el PC para entrar con Lemurs (TTY2) y comprobar Sway + qs + foot/fish."
  ANSWER="$(ask "¿Reiniciar ahora? [Y/n] ")"
  case "$ANSWER" in
    ""|Y|y|S|s) $SUDO systemctl reboot ;;
    *) log "OK. Cuando quieras: sudo reboot" ;;
  esac
fi
