# zoi-debian

Un shell de escritorio completo para **Debian 13 (trixie) + Sway** basado en **Quickshell**, modelando el flujo de Omarchy Quattro pero sin Hyprland ni dependencias de Arch.

Catppuccin Mocha como paleta base, paneles con teclado al estilo vim (hjkl), launcher, lock screen, screensaver, MPRIS, night light, weather, emoji picker, lofi radio, reminders, DND, todo desde un único proceso `qs` que se controla por IPC.

> **Default wallpaper:** `assets/default-wallpaper.jpg` (un dibujo estilo cartoon de Baby Yoda — kawaii, ambienta el inicio).

## Quickstart

```sh
curl -fsSL https://raw.githubusercontent.com/<owner>/zoi-debian/main/scripts/install.sh | sh
```

…o, en este dev tree, simplemente:

```sh
git clone https://github.com/<owner>/zoi-debian ~/projects/zoi-debian
cd ~/projects/zoi-debian
./scripts/install.sh
```

El instalador es **idempotente**: si una dependencia o dotfile ya está presente, lo deja en paz. Podés correrlo varias veces.

Después de instalar, cerrá sesión y volvé a entrar (para que `systemd --user`, sway, qs se reinicien limpios). El wallpaper por defecto aparece en el lock screen.

## Qué se instala

- **Sway** (WM) + **foot** (terminal) + **waybar** queda deshabilitado (lo reemplaza qs).
- **Quickshell 0.3.0** desde trixie-backports.
- **PipeWire** implícito vía los servicios de QS.
- Utilidades: `grim` `slurp` `wf-recorder` `wlsunset` `wtype` `wl-clipboard` `swayidle` `swaylock` `swaybg` `swaymsg` `playerctl` `mpv` `mpv-mpris` `yt-dlp` `cliphist` `figlet` `python3-terminaltexteffects` `brightnessctl` `light` `libreoffice` (opcional) `librewolf` (default browser).
- **Fish** shell (default interactive shell).
- Fuente: **Noto Color Emoji** para el picker de emojis. No instalamos Nerd Font (los íconos del bar son Canvas / QPainter).

Ver [docs/install.md](docs/install.md) para el detalle completo de paquetes y proveedores.

## Estructura del repo

```
zoi-debian/
├── README.md                  este archivo
├── docs/
│   ├── install.md             paquetes, fuentes, systemd
│   ├── features.md            qué hace cada feature
│   ├── configuration.md       dónde está cada config
│   ├── shortcuts.md           tabla completa de atajos
│   ├── architecture.md        PluginRegistry + singletons
│   └── troubleshooting.md     problemas frecuentes
├── scripts/
│   ├── install.sh             bootstrap completo (curl | sh friendly)
│   └── uninstall.sh
├── dotfiles/
│   ├── quickshell/            todo el árbol de QML
│   ├── sway/config            bindings + autoexec
│   ├── config/foot/foot.ini
│   └── local-bin/             scripts auxiliares qs-*
├── assets/
│   └── default-wallpaper.jpg  baby-yoda
└── skills/
    └── zoi-debian/
        └── SKILL.md           manual de la AI para mantener este repo
```

## Características

| Feature | Cómo se activa |
|---|---|
| Catppuccin Mocha bar + tokens | siempre |
| Launch app launcher | `Super+Space` |
| Notifications bell | click en la campana |
| Lock screen (swaylock) | `Super+Escape → Lock` o `qs ipc call lock lock` |
| Idle / screensaver TTE "ZOI" | después de 150s sin actividad |
| MPRIS media chip + panel | cualquier reproductor (mpv, Brave, lofi) |
| Night light (wlsunset 4000K) | `Session → Night light` toggle |
| Polkit overlay themeado | automático cuando algo pide auth |
| Wallpaper picker | `Session → Wallpaper` (lee `~/Imágenes`) |
| Theme picker (9 paletas) | `Session → Theme` |
| Emoji picker | `Super+.` (latam: `Super+Shift+,`) |
| Clipboard history | `Super+V` |
| Reminders (systemd-run timers) | `Super+Shift+N` |
| DND (do not disturb) | click derecho en la campana |
| Stay awake | `Session → Stay awake` toggle |
| Power actions | `Session → Lock / Suspend / Log out / Reboot / Shut down` |
| Lofi radio (`mpv` + `mpv-mpris`) | `Audio panel → Lofi radio` |
| Weather (Open-Meteo, IP geolocation) | click en el chip de weather |
| Bar visual editor | `Super+Shift+B` o `Session → Bar` |
| OSD volume / brightness | botones multimedia / teclas brillo |

Ver [docs/features.md](docs/features.md) para detalle.

## Atajos (resumen)

| Combo | Acción |
|---|---|
| `Super+Space` | Launcher |
| `Super+Q` | Cerrar popup / panel actual |
| `Super+Escape` | Session panel |
| `Super+Tab` | Workspace next |
| `Super+Shift+Tab` | Workspace prev |
| `Super+V` | Clipboard history |
| `Super+period` / `Super+Shift+comma` | Emoji picker |
| `Super+C / T / N / M / P / I / U` | Calendar / Weather / Notifs / Audio / Power / Network / Bluetooth |
| `Super+Shift+B` | Bar visual editor |
| `Super+Shift+N` | Reminders overlay |
| `Super+Shift+R` | Media arm (1/2/3 = prev/play/next) |
| `Super+Shift+W` | Cerrar ventana |
| `Super+Return` | Terminal (foot + fish) |
| `Super+Shift+Return` | LibreWolf |

Ver [docs/shortcuts.md](docs/shortcuts.md) para el mapa completo.

## Agradecimientos

Omarchy Quattro (Manjaro / Hyprland) — robamos los patrones, no el código. Todo lo que ves aquí es **first-party**: sin `qs.Ui`, sin `$OMARCHY_PATH`, sin clones, sin third-party plugins.
