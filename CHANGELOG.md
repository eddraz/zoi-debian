# CHANGELOG

## Unreleased

### Features
- **Optional Limine UEFI helper**: `scripts/limine-setup.sh` (dry-run by default) copies upstream `BOOTX64.EFI`, writes `limine.conf` under `/boot/limine` (so it can be recolored), and can add an NVRAM entry without removing GRUB. Documented in `docs/limine.md`. Not invoked by `install.sh`.
- **Limine follows zoi-theme**: `limine.conf.tpl` maps the 22-color palette onto Limine `term_*` / `interface_*` options. Theme apply writes `~/.config/zoi/themed/limine.conf` and merges it into `/boot/limine/limine.conf` when that directory is writable.
- **Lemurs display manager**: TUI login (TTY2) with `lemurs-variables.toml.tpl`. First install extracts the palette from `assets/default-wallpaper.jpg` (Baby Yoda) instead of tokyo-night. LightDM stays installed as fallback.
- **Default file manager is foot + Yazi + Sixel**: `qs-files`, `yazi.desktop` as `inode/directory`, official Yazi APT repo in `install.sh`, and `yazi-theme.toml.tpl` dispatched by `zoi-theme`. Super+Shift+F.

## 0.1.3 — 2026-09-10

### Features & Fixes
- **Unified Tab / Shift+Tab Navigation Across Panels**:
  - Implemented seamless navigation through all interactive controls (`inputs`, buttons, progress bar / volume / brightness sliders, toggles, list items) across all 14 panels and overlays.
  - Allowed Tab to seamlessly exit search inputs (`findField`) and jump directly to panel controls when search text has no matches or is idle.
  - Added Tab key navigation between password `TextInput` and `Join` button in `NetworkPanel.qml`.
  - Added Tab key focus navigation in `ReminderOverlay.qml`.
- **Quickshell Theme Boot Persistence**:
  - Bound `Commons/Color.qml` directly to `~/.local/state/quickshell/colors.json` via a reactive `FileView` (`watchChanges: true`).
  - Resolved lazy-loading singleton limitation where `Color.qml` stayed on static defaults on boot because `Themes.qml` was only instantiated on demand.
  - Fixed blue channel calculation bug (`round(g)` -> `round(b)`) in `zoi-theme`'s `rgb_to_hex`.
- **Documentation & Script Refinements**:
  - Corrected Debian package name in `scripts/install.sh` and `docs/install.md` (`polkit` -> `polkitd pkexec`).
  - Updated `docs/troubleshooting.md` with full details of `scripts/uninstall.sh`.
  - Updated `docs/features.md`, `docs/shortcuts.md`, and `skills/zoi-debian/SKILL.md` with latest architecture, navigation, and GdkPixbuf color extraction specifications.

## 0.1.2 — 2026-09-10

### Features & Major Improvements
- **ZOI Theme Engine (`zoi-theme`)**:
  - Implemented the declarative theme architecture inspired by Omarchy Quatro with standardized 22-color palettes (`colors.toml`) and `.tpl` templates.
  - Included 17 built-in themes: Tokyo Night, Catppuccin (Mocha, Macchiato, Frappé, Latte), Gruvbox, Nord, Kanagawa, Dracula, Rosé Pine, Everforest, Osaka Jade, Retro 82, Solitude, Matte Black, Miasma, and Lumon.
  - Dynamic template compilation with atomic staging and file locking (`flock`).
  - Real-time cross-application dispatching to:
    - **Foot**: `~/.config/foot/foot.ini`
    - **Sway**: `~/.config/sway/theme.conf` + dynamic window borders via `swaymsg client.*`
    - **btop**: `~/.config/btop/themes/zoi.theme` + `btop.conf`
    - **Helix Editor**: `~/.config/helix/themes/zoi.toml` + `config.toml`
    - **Zed Editor**: `~/.config/zed/themes/zoi.json` + `settings.json`
    - **VSCode / Antigravity IDE**: `settings.json` (`workbench.colorCustomizations`)
    - **GTK 3 & GTK 4 / LibreWolf**: `~/.config/gtk-3.0/gtk.css`, `~/.config/gtk-4.0/gtk.css` + `gsettings`
    - **Herdr**: `~/.config/herdr/config.toml`
  - User hook execution support via `~/.config/zoi/hooks/theme-set.d/*`.
- **Wallpaper 22-Color Palette Extraction**:
  - Rewrote `qs-theme-from-wallpaper` to generate full 22-color palettes adhering to WCAG AAA contrast (> 7:1), deep tinted dark backgrounds, and vibrant extracted accents.
  - Selecting a wallpaper now immediately applies and propagates the extracted theme across all supported applications.
- **Search Isolation & Hotkey Suspension**:
  - Added `Popups.isSearching` state across all Quickshell popups and panels.
  - Suspended all quick numbers (1-9, 0) and hotkeys when search bars or text inputs are active.
  - Number jump badges (`IndexBadge.qml`) automatically hide during search as visual confirmation.
  - Integrated keyboard navigation in search matches (`Down`/`Tab` for next, `Up`/`Shift+Tab` for prev, `Enter` to run, `Escape` to cancel).
- **Network Panel QR Sharing**:
  - Added a vector QR code icon in `StatusIcon.qml` (`paintQr`).
  - Added a QR sharing action button in the card header next to the search button.
  - Dedicated `Q` hotkey to instantly display the Wi-Fi QR code when the Network panel is open.
- **Installation & Maintenance Scripts**:
  - Updated `scripts/install.sh` with dependencies (`bc`, `btop`, `python3-gi`, `gir1.2-gdkpixbuf-2.0`, `libqrencode4`).
  - Integrated theme and template deployment to `~/.config/zoi/` and `~/.local/share/zoi/`.
  - Added initial theme application during installation.
  - Updated `scripts/uninstall.sh` to clean up theme state and binaries.

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
