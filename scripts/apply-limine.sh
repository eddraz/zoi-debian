#!/usr/bin/env bash
# Download Limine as the desktop user (DNS works), then apply as root.
# Fish:  bash ~/projects/zoi-debian/scripts/apply-limine.sh --make-default
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SETUP="$REPO/scripts/limine-setup.sh"
URL="${LIMINE_URL:-https://github.com/Limine-Bootloader/Limine/releases/download/v${LIMINE_VERSION:-12.9.0}/limine-binary.tar.xz}"
TARBALL="${LIMINE_TARBALL:-/tmp/limine-binary.tar.xz}"

[ -x "$SETUP" ] || { echo "missing $SETUP" >&2; exit 1; }

if [ "$(id -u)" -eq 0 ]; then
  [ -f "$TARBALL" ] || { echo "LIMINE_TARBALL missing: $TARBALL" >&2; exit 1; }
  exec env LIMINE_TARBALL="$TARBALL" "$SETUP" apply "$@"
fi

echo "Downloading $URL"
curl -fL --retry 3 -o "$TARBALL" "$URL"
ls -l "$TARBALL"
exec sudo env LIMINE_TARBALL="$TARBALL" "$SETUP" apply "$@"
