#!/bin/bash
# install-sddm.sh — switch zoi-debian to SDDM with the zoi theme (palette-synced).
# Run as the regular user; asks sudo once for /usr and the service switch.
set -euo pipefail

REPO="${ZOI_REPO:-$(cd "$(dirname "$0")/.." && pwd)}"
THEME_DIR="/usr/share/sddm/themes/zoi"
HOOK_DIR="$HOME/.config/zoi/hooks/theme-set.d"
WALLPAPER="${1:-$REPO/assets/default-wallpaper.jpg}"

sudo install -d -m 0755 "$THEME_DIR"
sudo install -m 0644 "$REPO/dotfiles/themes/sddm/Main.qml" "$THEME_DIR/Main.qml"
sudo install -m 0644 "$REPO/dotfiles/themes/sddm/metadata.desktop" "$THEME_DIR/metadata.desktop"
sudo install -m 0644 "$WALLPAPER" "$THEME_DIR/default-background.jpg"

# Default theme.conf from the current palette (also registers the template with zoi-theme)
install -d -m 0755 "$REPO/dotfiles/themes/templates" 2>/dev/null || true
"$HOME/.local/bin/zoi-sddm-sync"

# Hook so every `zoi-theme set <id>` re-syncs SDDM
install -d -m 0755 "$HOOK_DIR"
install -m 0755 "$REPO/dotfiles/local-bin/zoi-sddm-sync" "$HOME/.local/bin/zoi-sddm-sync"
ln -sf "$HOME/.local/bin/zoi-sddm-sync" "$HOOK_DIR/10-sddm"

# Display manager switch
sudo tee /etc/sddm.conf.d/zoi.conf >/dev/null <<'EOF'
[Theme]
Current=zoi
EOF
sudo systemctl disable lightdm.service 2>/dev/null || true
sudo systemctl enable sddm.service

echo "SDDM instalado como display manager con theme 'zoi'."
echo "Toma efecto en el próximo reboot o con: sudo systemctl restart sddm"
