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
echo "seatd: $(systemctl is-active seatd)"
ls -l /run/seatd.sock /etc/lemurs/wayland/sway
