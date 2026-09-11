#!/usr/bin/env bash
# Apply seatd + Lemurs Sway wrapper. Run: sudo bash scripts/apply-lemurs-seatd.sh
set -euo pipefail

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
owner="${SUDO_USER:-}"
if [ -z "$owner" ] || [ "$owner" = root ]; then
  owner="$(logname 2>/dev/null || true)"
fi
if [ -n "$owner" ] && [ "$owner" != root ]; then
  usermod -aG render,video,seat "$owner" || usermod -aG render,video "$owner" || true
  echo "groups $owner: $(id -nG "$owner")"
fi
echo "seatd: $(systemctl is-active seatd)"
ls -l /run/seatd.sock /dev/dri/renderD128 /etc/lemurs/wayland/sway
echo "Reboot so group render applies, then log in via Lemurs (sway)."
