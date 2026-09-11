# Guía de instalación

Esta guía describe cómo levantar `zoi-debian` desde cero en Debian 13 (trixie) con Sway + Quickshell.

## Requisitos

- Debian 13 (trixie) con `sudo` o acceso root.
- Conexión a internet.
- Aprox. **400 MB** de espacio en disco.

## Pasos

### 1. Bootstrap vía curl

```sh
curl -fsSL https://raw.githubusercontent.com/<owner>/zoi-debian/main/scripts/install.sh | sh
```

Por defecto clona el repo en `~/projects/zoi-debian`. Variables de entorno:

| Variable | Default | Descripción |
|---|---|---|
| `ZOI_REPO` | `<owner>/zoi-debian` | Repo a clonar |
| `ZOI_BRANCH` | `main` | Rama |
| `ZOI_DIR` | `~/projects/zoi-debian` | Carpeta destino |

### 2. Lo que hace el instalador

1. **Activa backports** (`/etc/apt/sources.list.d/backports.list`) si no existe.
2. **Instala paquetes** (ver tabla abajo).
3. **Clona** el repo de zoi-debian en `$ZOI_DIR`.
4. **Copia dotfiles y temas**:
   - `~/.config/quickshell/` (todos los QML + `shell.json`)
   - `~/.config/zoi/themes/` y `~/.config/zoi/themed/` (17 temas + plantillas `.tpl`)
   - `~/.config/sway/config`
   - `~/.config/foot/foot.ini`
   - `~/.local/bin/` (`zoi-theme` CLI + 18 scripts auxiliares `qs-*`)
5. **Pone wallpaper por defecto** (`assets/default-wallpaper.jpg` → `~/Imágenes/baby-yoda-cartoon.jpg`).
6. Extrae la paleta de ese fondo y la aplica con `zoi-theme apply-json`.
7. **Instala Lemurs** como DM (TTY2); LightDM queda de fallback.
8. **Cambia la shell** a `fish`.
9. **Agrega** `exec_always` de qs + qs-idle al `sway/config`.
10. Verifica binarios.

### 3. Cerrá sesión y volvé a entrar

Importante: el primer arranque de `qs` necesita:
- `lemurs` en TTY2 con sesión Sway (o `sway` directo desde TTY). LightDM es fallback.
- `wireplumber` corriendo (audio).
- `NetworkManager` para wifi (NetworkPanel + BT).
- `bluez` para Bluetooth.

## Paquetes instalados

### Backports

| Paquete | Versión esperada | Por qué |
|---|---|---|
| `quickshell` | 0.3.0 | El host del shell |

### Repositorio principal

| Paquete | Función |
|---|---|
| `sway` | Window manager |
| `swaybg` | Wallpaper (alternativa a `swaymsg output * bg`) |
| `swaylock` | Lock screen (PAM: `Quickshell.Services.Pam`) |
| `swayidle` | Idle / DPMS / lock timers |
| `foot` | Terminal Wayland default (Sixel, shell=fish) |
| `foot-themes` | Temas para foot |
| `pipewire` + `wireplumber` | Audio (latencia baja) |
| `wlsunset` | Night light (control de temperatura) |
| `wtype` | Wayland virtual keyboard (clipboard paste) |
| `wl-clipboard` | `wl-copy` + `wl-paste` |
| `grim` + `slurp` | Screenshots rectangulares |
| `wf-recorder` | Grabación de pantalla |
| `playerctl` | MPRIS CLI |
| `mpv` + `mpv-mpris` | Reproductor + bridge MPRIS |
| `yt-dlp` | Lo fi radio streaming |
| `cliphist` | Historial de clipboard |
| `figlet` | Banner ZOI para el screensaver |
| `python3-terminaltexteffects` | TTE effects para el screensaver |
| `brightnessctl` | Brillo (Power panel) |
| `light` | Brillo de teclado |
| `lightdm` | Fallback display manager (deshabilitado si Lemurs se instaló) |
| `mullvad-browser` | Browser default. Repo APT oficial `repository.mullvad.net` |
| `yazi` | File manager (foot + Sixel). Repo APT oficial `yazi-rs.github.io/builds` |
| `ffmpeg` `poppler-utils` `fd-find` `ripgrep` `fzf` `imagemagick` `p7zip-full` | Previews de Yazi |
| `fish` | Login shell + shell de foot |
| `bc` | Cálculos matemáticos en scripts auxiliares |
| `btop` | Monitor de recursos del sistema (themeado por zoi-theme) |
| `python3-gi` + `gir1.2-gdkpixbuf-2.0` | Extracción de paleta de 22 colores desde wallpapers |
| `libqrencode4` + `qrencode` | Generación de código QR para compartir red Wi-Fi |
| `network-manager` + `applet` | Wifi panel |
| `bluez` + `bluez-tools` | Bluetooth panel |
| `polkitd` + `pkexec` | Demonio Polkit y ejecutable de autenticación |
| `fonts-noto` + `fonts-noto-color-emoji` + `fonts-noto-cjk` | Tipografías |
| `jq` | Parser JSON |
| `xdg-utils` + `xdg-user-dirs` | Estándar XDG |
| `pavucontrol` | Mixer (opcional) |

### Fuentes

- **Noto Color Emoji**: íconos de sistema, emojis en `Emojis.qml`.
- **Nerd Font NO se instala** — los íconos del bar se pintan con `QPainter` (Canvas) en `Ui/StatusIcon.qml`.

## Estructura después de instalar

```
~/.config/quickshell/
├── shell.qml                # entry point (ShellRoot)
├── shell.json               # PluginRegistry layout
├── screensaver.txt          # "ZOI"
├── emojis.json              # base de datos del emoji picker
├── Bar.qml                  # bar (Repeater + ChipLoader)
├── Clipboard.qml            # overlay clipboard
├── Emojis.qml               # overlay emoji picker
├── Idle.qml                 # bridge swayidle → qs
├── Launcher.qml             # full app list (sin rofi)
├── Lock.qml                 # lock screen
├── MediaArm.qml             # overlay media arm (1/2/3)
├── NightLight.qml           # toggle service
├── Notifications.qml        # daemon notificaciones
├── Osd.qml                  # OSD volume/brightness
├── Polkit.qml               # themed polkit dialog
├── ReminderOverlay.qml      # overlay reminder
├── Commons/
│   ├── Audio.qml            # PipeWire wrapper
│   ├── Brightness.qml       # brightnessctl wrapper
│   ├── Color.qml            # Catppuccin Mocha + focusFill
│   ├── HoverTip.qml         # tooltip singleton
│   ├── Idle.qml             # Stay awake
│   ├── KeyNav.qml           # hjkl helpers
│   ├── Keyboard.qml         # XKB layout tracker
│   ├── Media.qml            # MPRIS wrapper
│   ├── NightLight.qml       # wlsunset wrapper
│   ├── Notifs.qml           # DND + unread
│   ├── PluginRegistry.qml   # **first-party catalog**
│   ├── Popups.qml           # IPC singleton
│   ├── Radio.qml            # lofi mpv player
│   ├── Reminders.qml        # systemd-run timers
│   ├── Style.qml            # tokens (barHeight, radius, font)
│   ├── Themes.qml           # 9 paletas
│   ├── Wallpaper.qml        # swaybg wrapper
│   ├── Weather.qml          # Open-Meteo
│   └── qmldir               # registro de singletons
├── Ui/
│   ├── HoverMouse.qml
│   ├── HoverTipLayer.qml
│   ├── IndexBadge.qml
│   ├── PopupCard.qml
│   └── StatusIcon.qml
├── panels/                  # cargados por PluginRegistry.panelUrl(popup)
│   ├── AudioPanel.qml
│   ├── BarEditorPanel.qml
│   ├── BluetoothPanel.qml
│   ├── CalendarPanel.qml
│   ├── KeyboardPanel.qml
│   ├── KeysPanel.qml
│   ├── MediaPanel.qml
│   ├── NetworkPanel.qml
│   ├── NotifPanel.qml
│   ├── PowerPanel.qml
│   ├── SessionPanel.qml
│   ├── ThemePanel.qml
│   ├── WallpaperPanel.qml
│   └── WeatherPanel.qml
└── widgets/                 # cargados por PluginRegistry.widgetUrl(id)
    ├── ActiveWindow.qml
    ├── Battery.qml
    ├── Bluetooth.qml
    ├── Clock.qml
    ├── Dnd.qml
    ├── KbLayout.qml
    ├── Network.qml
    ├── NotifBell.qml
    ├── Player.qml
    ├── Reminder.qml
    ├── Session.qml
    ├── Tray.qml
    ├── Volume.qml
    ├── Weather.qml
    └── Workspaces.qml

~/.config/zoi/
├── themes/                  # 17 paletas estándar (colors.toml)
├── themed/                  # plantillas declarativas (*.tpl)
└── hooks/theme-set.d/       # hooks de usuario post-cambio de tema

~/.local/bin/
├── zoi-theme                # CLI y motor de compilación de temas
└── qs-*                     # 18 scripts auxiliares de Quickshell

~/.local/state/zoi/theme/    # estado del motor de temas
├── current/                 # archivos compilados activos (foot.ini, sway.theme.conf, btop.theme, etc.)
├── colors.json              # paleta activa en JSON
├── colors.toml              # paleta activa en TOML
└── colors.sh                # exports de entorno

~/.local/state/quickshell/   # estado runtime de quickshell
├── night-light              # on/off + temperatura
├── wallpaper                # path absoluto
├── dnd                      # on/off
├── stay-awake               # on/off
└── theme                    # id de paleta activa

~/.config/quickshell/screensaver.txt   # texto del banner (default: ZOI)
```

## Post-instalación

### Habilitar servicios

```sh
systemctl --user enable --now wireplumber
sudo systemctl enable --now NetworkManager bluetooth
# Lemurs lo habilita install.sh / lemurs-setup.sh apply (próximo boot, TTY2)
```

### Verificar

```sh
swaymsg exec /usr/bin/qs -n --daemonize
/usr/bin/qs ipc call launcher toggle  # debería abrir el launcher
```

Si no se ve nada, mirá `~/.cache/quickshell/crashes/<shell>/`.

## Desinstalar

```sh
~/projects/zoi-debian/scripts/uninstall.sh
```

(Elimina dotfiles de `~/.config/quickshell`, restaura `waybar` como bar default.)

## Bootloader (opcional)

`install.sh` no cambia GRUB. Si querés Limine en UEFI, ver [limine.md](limine.md).

Display manager: [lemurs.md](lemurs.md).
