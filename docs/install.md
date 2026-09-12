# Guía de instalación

Esta guía describe cómo levantar `zoi-debian` desde cero en Debian 13 (trixie) con Sway + Quickshell.

## Requisitos

- Debian 13 (trixie) **instalación terminal** (netinst, sin GNOME/KDE).
- Root o un usuario que pueda usar `sudo`.
- Red: ethernet, o Wi‑Fi que el propio `install.sh` puede pedir (SSID + clave).
- Aprox. **1 GB** libre (Sway, Quickshell, Mullvad Browser, Pi).
- Arquitectura nativa (`dpkg --print-architecture`). Los repos de terceros se pinnean a esa ISA (no a i386 foreign).

| Arch | Debian (Sway, qs, …) | Yazi | Mullvad | Lemurs | Inlyne | Node |
|---|---|---|---|---|---|---|
| **amd64** | sí | sí | sí | sí | sí | sí |
| **arm64** | sí | sí | no | no | sí | sí |
| **otra** | intenta | no | no | no | no | no |

## Pasos

### 1. Clonar y correr el instalador

```sh
# Clone (hace falta curl + git)
apt update && apt install -y curl git
git clone https://github.com/<owner>/zoi-debian ~/zoi-debian
cd ~/zoi-debian
./scripts/install.sh

# O curl | bash (red ya disponible; no uses `sh`)
curl -fsSL https://raw.githubusercontent.com/<owner>/zoi-debian/main/scripts/install.sh \
  | sudo ZOI_REPO=https://github.com/<owner>/zoi-debian.git bash
```

El script pide **solo lo que falta**: Wi‑Fi si no hay red; locale / teclado / timezone si el sistema no los tiene; **sudoers para el usuario actual** (confirmación `[Y/n]`). **No** pide nombre, correo, usuario ni contraseña: usa la cuenta del SO y no crea usuarios. Re-correr en un PC ya configurado no vuelve a preguntar eso (si `/etc/sudoers.d/zoi-<usuario>` ya existe, no re-pregunta).

Variables de entorno:

| Variable | Default | Descripción |
|---|---|---|
| `ZOI_REPO` | `<owner>/zoi-debian` | Repo a clonar |
| `ZOI_BRANCH` | `main` | Rama |
| `ZOI_DIR` | `~/projects/zoi-debian` | Carpeta destino |
| `ZOI_SUDOERS` | `1` si `ZOI_NONINTERACTIVE=1` | `1` escribe `/etc/sudoers.d/zoi-<usuario>`; `0` no toca sudoers. En modo interactivo se pregunta |

### 2. Lo que hace el instalador

1. **Lee la arquitectura** y saltea Yazi / Mullvad / Lemurs / Inlyne / Node.js si no hay binario para esa ISA.
2. **Asegura PATH de sbin** (`/usr/sbin:/sbin`) para `usermod`, `locale-gen`, `update-locale`.
3. **Pregunta** si agregar al usuario del SO en sudoers (`/etc/sudoers.d/zoi-<usuario>` + grupo `sudo`). Default **Y**. Si el drop-in ya existe, no pregunta.
4. **Activa backports** (`/etc/apt/sources.list.d/backports.list`) si no existe.
5. **Instala paquetes** (ver tabla abajo), incluyendo **curl**, **git** y **Node.js latest** (nodejs.org → `/usr/local`).
6. **Clona** el repo de zoi-debian en `$ZOI_DIR`.
7. **Copia dotfiles y temas**:
   - `~/.config/quickshell/` (todos los QML + `shell.json`)
   - `~/.config/zoi/themes/` y `~/.config/zoi/themed/` (17 temas + plantillas `.tpl`)
   - `~/.config/sway/config`
   - `~/.config/foot/foot.ini`
   - `~/.local/bin/` (`zoi-theme`, `inlyne`, helpers `qs-*` incl. `qs-md` / `qs-docs` / `qs-md-open`)
8. **Pone wallpaper por defecto** (`assets/default-wallpaper.jpg` → `~/Imágenes/baby-yoda-cartoon.jpg`).
9. Extrae la paleta de ese fondo **solo en el primer install** (`zoi-theme apply-json`). Un re-run no pisa el tema activo.
10. **Instala Lemurs** como DM (TTY2) en amd64; LightDM queda de fallback.
11. **Cambia la shell** a `fish`.
12. **Agrega** `exec_always` de qs + qs-idle al `sway/config`.
13. Verifica binarios.

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
| `qt6-wayland` | Plugin QPA Wayland de Qt 6. `quickshell` no lo declara como Depends; sin él `qs` crashea al arrancar |
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
| `mpv` + `mpv-mpris` | Video default (XDG) + lofi/MPRIS |
| `amberol` | Reproductor de audio default (Debian `main`; `install.sh` lo instala) |
| `loupe` | Visor de imágenes default (Debian `main`; `install.sh` lo instala) |
| `yt-dlp` | Lo fi radio streaming |
| `cliphist` | Historial de clipboard |
| `figlet` | Banner ZOI para el screensaver |
| `python3-terminaltexteffects` | TTE effects para el screensaver |
| `brightnessctl` | Brillo (Power panel) |
| `light` | Brillo de teclado |
| `lightdm` | Fallback display manager (deshabilitado si Lemurs se instaló) |
| `kbd` | `setvtrgb` para la paleta VGA de Lemurs en TTY2 |
| `lemurs` | **No es paquete apt.** Tarball GitHub v0.4 → `/usr/local/bin/lemurs` (amd64). PAM + `/etc/lemurs/vtrgb` |
| `seatd` | DRM para Sway detrás de Lemurs (`/usr/sbin/seatd -g video`). El usuario va en grupos `video` y `render` |
| `mullvad-browser` | Se instala (amd64). XDG default = Thorium si existe, si no Mullvad. `qs-browser` sigue XDG |
| `yazi` | File manager (foot + Sixel). Repo APT oficial, `deb [arch=$ARCH …]` (amd64/arm64) |
| `inlyne` | **No es paquete apt.** Release GitHub v0.5.3 → `~/.local/bin/inlyne` (amd64/arm64) |
| `curl` | HTTP (keys APT, Herdr, Pi, Node.js, Inlyne). Fase 1 y fase 2 |
| `git` | Clone/update del repo. Fase 1 y fase 2 |
| `xz-utils` | Extrae el tarball de Node.js |
| `nodejs` / `npm` | **No es paquete apt.** Current latest de [nodejs.org](https://nodejs.org/dist/latest/) → `/usr/local` (amd64/arm64). Un re-run actualiza si hay versión nueva |
| `herdr` | Multiplexer de terminales para agentes. Instalador oficial `herdr.dev/install.sh` |
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
│   ├── KeysCombo.js         # parseo Super+W ↔ Mod4+w
│   ├── KeysMap.qml          # catálogo + overrides ~/.config/zoi/keys.json
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
│   ├── ActionListItem.qml
│   ├── HoverMouse.qml
│   ├── HoverTipLayer.qml
│   ├── IndexBadge.qml
│   ├── PopupCard.qml
│   ├── SearchBar.qml
│   ├── StatusIcon.qml
│   └── VolumeSlider.qml
├── panels/                  # cargados por PluginRegistry.panelUrl(popup)
│   ├── AppsPanel.qml
│   ├── AudioPanel.qml
│   ├── BarEditorPanel.qml
│   ├── BluetoothPanel.qml
│   ├── CalendarPanel.qml
│   ├── KeyboardPanel.qml
│   ├── KeysPanel.qml
│   ├── LearnPanel.qml
│   ├── MediaPanel.qml
│   ├── NetworkPanel.qml
│   ├── NotifPanel.qml
│   ├── PowerPanel.qml
│   ├── SessionPanel.qml
│   ├── ThemePanel.qml
│   ├── TriggerPanel.qml
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

~/.config/herdr/config.toml  # Herdr; paleta vía zoi-theme

~/.config/zoi/
├── themes/                  # 17 paletas estándar (colors.toml)
├── themed/                  # plantillas declarativas (*.tpl)
└── hooks/theme-set.d/       # hooks de usuario post-cambio de tema

~/.local/bin/
├── zoi-theme                # CLI y motor de temas
├── inlyne                   # visor markdown GPU
├── qs-md / qs-docs / qs-md-open
├── qs-browser               # Super+Shift+Return → XDG default browser
├── qs-keys-apply            # reaplica atajos custom a Sway
└── qs-*                     # resto de helpers Quickshell

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
├── theme                    # id de paleta activa (selector Session → Theme)
└── colors.json              # paleta para Color.qml al boot

~/.config/quickshell/screensaver.txt   # texto del banner (default: ZOI)
```

## Sudoers

El instalador **pregunta** antes de dar privilegios:

```text
Puedo escribir /etc/sudoers.d/zoi-<usuario> con: <usuario> ALL=(ALL:ALL) ALL
¿Agregar a <usuario> en sudoers? [Y/n]
```

- **Y** (default): drop-in validado con `visudo -c`, modo `0440`, y el usuario entra al grupo `sudo`.
- **n**: no toca sudoers. La fase 2 igual necesita `sudo` para apt/seatd/Lemurs.
- Re-run: si el archivo ya está, no vuelve a preguntar.
- No interactivo: `ZOI_NONINTERACTIVE=1` (agrega) o `ZOI_SUDOERS=0` (omite).

`#includedir /etc/sudoers.d` ignora nombres con punto. El drop-in se llama `zoi-<usuario>` con caracteres raros pasados a `_`.

A mano:

```sh
echo "$USER ALL=(ALL:ALL) ALL" | sudo tee /etc/sudoers.d/zoi-$USER
sudo chmod 440 /etc/sudoers.d/zoi-$USER
sudo visudo -cf /etc/sudoers.d/zoi-$USER
sudo usermod -aG sudo "$USER"
```

`uninstall.sh` **no** borra ese drop-in.

## Post-instalación

### Habilitar servicios

```sh
systemctl --user enable --now wireplumber
sudo systemctl enable --now NetworkManager bluetooth
# Lemurs: install.sh / lemurs-setup.sh apply (enable, no start). TTY2 + vtrgb.
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

Quita el shell ZOI (`qs-*`, Inlyne, `~/.config/quickshell`). Los paquetes apt quedan.

Display manager: [lemurs.md](lemurs.md).
