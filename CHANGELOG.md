# CHANGELOG

## 0.1.1 — 2026-09-10

### Improvements & Fixes
- **Bar Visual Editor**:
  - Added support for moving chips across columns (Left, Center, Right).
  - Added auto-saving on any reordering or column change, removing the manual Save button.
- **Default Bar Layout**:
  - Standardized default layout across `dotfiles/quickshell/shell.json` and `PluginRegistry.qml`:
    - `left`: `session`, `workspaces`, `window`
    - `center`: `reminders`, `clock`, `weather`
    - `right`: `keyboard`, `media`, `audio`, `power`, `bluetooth`, `network`, `notifs`, `dnd`, `tray`
- **System Tray Widget**:
  - Added system tray icon in `StatusIcon.qml` (`icon: "tray"`).
  - Added collapsible tray toggle in `Tray.qml` to expand/collapse active status items.
- **Media & Lofi Radio**:
  - Isolated `qs-lofi` from MPRIS (`--load-scripts=no`) so it only runs on demand via Volume and does not hijack the media player.
  - Retained `activePlayer` reference in `Media.qml` on pause, preserving the song title/artist and only switching the icon to Play.
  - Added `Radio.stop()` to cleanly terminate the radio process when regular media begins playing.
- **Icons & Visuals**:
  - Redesigned Wi-Fi icon geometry and signal level calculation in `StatusIcon.qml` and `Network.qml`.
  - Fixed Power icon orientation and added user avatar icon to session chip.
- **Portability & Scripts**:
  - Replaced hardcoded paths with portable `$HOME` / `Quickshell.env("HOME")` in `Clipboard.qml`, `qs-idle`, `sway/config`, and `scripts/install.sh`.
  - Improved Sway autostart cleanup in `scripts/uninstall.sh`.

## 0.1.0 — 2026-09-09

Initial snapshot of the working shell on `fixy` (eddraz's laptop).

### Features
- Catppuccin Mocha bar (15 chips via PluginRegistry)
- PopupCard-based popups for: calendar, weather, notifications, audio, power, network, bluetooth, session, notifs, keys, wallpaper, theme, keyboard, media, bar editor
- Launcher (full app list, no rofi)
- Lock screen (WlSessionLock + PAM)
- Idle / screensaver TTE "ZOI"
- Stay awake (WlIdleInhibitor)
- Clipboard history (cliphist + wl-paste)
- Screenshots / Recording (grim + wf-recorder)
- Notifications daemon
- Emoji picker (8-col grid, Noto Color Emoji)
- MPRIS media chip + panel (exclusive playback)
- Night light (wlsunset 4000K)
- Polkit overlay (replaces polkit-gnome)
- Wallpaper picker (swaymsg bg)
- Theme picker (9 palettes, live-update)
- Weather (Open-Meteo, IP geolocation)
- Lofi radio (mpv + mpv-mpris)
- Reminders (systemd-run timers)
- DND indicator (right-click bell)
- PluginRegistry (first-party catalog + shell.json layout)
- Bar visual editor (pick-and-drop keyboard model)

### Bindings
- `Super+Space` Launcher
- `Super+Q` Close
- `Super+Escape` Session
- `Super+V` Clipboard
- `Super+period` / `Super+Shift+,` Emoji
- `Super+C/T/N/M/P/I/U` Panel chips
- `Super+Shift+B` Bar editor
- `Super+Shift+N` Reminders
- `Super+Shift+R` Media arm (1/2/3)
- `Super+Shift+S` Screenshot
- `Super+Shift+W` Close window
- `Super+Return` / `Super+Shift+Return` Foot / LibreWolf

### Stack
- Debian 13.6 (trixie)
- Sway 1.10.1
- Quickshell 0.3.0 (trixie-backports)
- foot 1.21.0
- PipeWire + WirePlumber
- Catppuccin Mocha

### Known limitations
- First-party plugins only. No third-party discovery.
- Bar editor is keyboard-only (no mouse drag-and-drop).
- `wtype` Shift+Insert clipboard paste is best-effort — popup focus may interfere.
- Tensaku/Satty not packaged for Debian (no annotation editor for screenshots).
