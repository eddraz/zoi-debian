#!/usr/bin/env bash
# Apply seatd + Lemurs Sway wrapper. Run: sudo bash scripts/apply-lemurs-seatd.sh
set -euo pipefail

# usermod vive en /usr/sbin; un PATH de usuario no lo incluye.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:${PATH:-/usr/bin:/bin}"

if [ "$(id -u)" -ne 0 ]; then
  exec sudo -E bash "$0" "$@"
fi

REPO="$(cd "$(dirname "$0")/.." && pwd)"
WRAPPER="$REPO/dotfiles/lemurs/wayland-sway"
[ -f "$WRAPPER" ] || { echo "missing $WRAPPER" >&2; exit 1; }

apt-get install -y --no-install-recommends seatd
# Debian unit is already `seatd -g video` and the binary is /usr/sbin/seatd.
# A drop-in pointing at /usr/bin/seatd is 203/EXEC and leaves no socket.
rm -f /etc/systemd/system/seatd.service.d/video.conf
rmdir /etc/systemd/system/seatd.service.d 2>/dev/null || true
systemctl daemon-reload
systemctl enable --now seatd
install -m 0755 "$WRAPPER" /etc/lemurs/wayland/sway
owner="${TARGET_USER:-}"
if [ -z "$owner" ] || [ "$owner" = root ]; then
  owner="${SUDO_USER:-}"
fi
if [ -z "$owner" ] || [ "$owner" = root ]; then
  owner="$(logname 2>/dev/null || true)"
fi
if [ -z "$owner" ] || [ "$owner" = root ]; then
  owner="$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 && $1 != "nobody" {print $1; exit}')"
fi
if [ -n "$owner" ] && [ "$owner" != root ]; then
  _glist=""
  for _g in render video seat; do
    getent group "$_g" >/dev/null 2>&1 || continue
    _glist="${_glist:+$_glist,}$_g"
  done
  if [ -n "$_glist" ]; then
    usermod -aG "$_glist" "$owner" || true
  fi
  echo "groups $owner: $(id -nG "$owner")"
fi
echo "seatd: $(systemctl is-active seatd)"
ls -l /run/seatd.sock /dev/dri/renderD128 /etc/lemurs/wayland/sway
echo "Reboot so group render applies, then log in via Lemurs (sway)."
