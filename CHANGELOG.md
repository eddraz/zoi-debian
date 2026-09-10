# CHANGELOG

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
