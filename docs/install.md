# Guía de instalación

Esta guía describe cómo levantar `zoi-debian` desde cero en Debian 13 (trixie) con Sway + Quickshell.

## Requisitos

- Debian 13 (trixie) **instalación terminal** (netinst, sin GNOME/KDE).
- Root o un usuario que pueda usar `sudo`.
- Red: ethernet, o Wi‑Fi que el propio `install.sh` puede pedir (SSID + clave).
- Aprox. **1 GB** libre (Sway, Quickshell, Mullvad Browser, Pi).
- Arquitectura nativa (`dpkg --print-architecture`). Los repos de terceros se pinnean a esa ISA (no a i386 foreign).

| Arch | Debian (Sway, qs, …) | Yazi | Mullvad | Inlyne | Node |
|---|---|---|---|---|---|
| **amd64** | sí | sí | sí | sí | sí |
| **arm64** | sí | sí | no | sí | sí |
| **otra** | intenta | no | no | no | no |

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

1. **Lee la arquitectura** y saltea Yazi / Mullvad / Inlyne / Node.js si no hay binario para esa ISA.
2. **Asegura PATH de sbin** (`/usr/sbin:/sbin`) para `usermod`, `locale-gen`, `update-locale`.
3. **Pregunta** si agregar al usuario del SO en sudoers (`/etc/sudoers.d/zoi-<usuario>` + grupo `sudo`). Default **Y**. Si el drop-in ya existe, no pregunta.
4. **Activa backports** (`/etc/apt/sources.list.d/backports.list`) si no existe.
5. **Instala paquetes** (ver tabla abajo), incluyendo **curl**, **git**, **Node.js latest**, **gh**, **Zed**, **UPower**, **zram**, firmware según GPU/NIC y **Brave Origin** (instalador oficial `FLAVOR=origin`; no cambia el default XDG).
6. **Clona** el repo de zoi-debian en `$ZOI_DIR`.
7. **Copia dotfiles y temas**:
   - `~/.config/quickshell/` (todos los QML + `shell.json`)
   - `~/.config/zoi/themes/` y `~/.config/zoi/themed/` (17 temas + plantillas `.tpl`)
   - `~/.config/sway/config`
   - `~/.config/foot/foot.ini`
   - `~/.local/bin/` (`zoi-theme`, `inlyne`, helpers `qs-*` incl. `qs-md` / `qs-docs` / `qs-md-open`)
8. **Pone wallpaper por defecto** (`assets/default-wallpaper.jpg` → `~/Imágenes/baby-yoda-cartoon.jpg`).
9. Extrae la paleta de ese fondo **solo en el primer install** (`zoi-theme apply-json`). Un re-run no pisa el tema activo.
10. **Habilita LightDM** (y quita leftovers de Lemurs si hay).
11. **Cambia la shell** a `fish`.
12. **Agrega** `exec_always` de qs + qs-idle al `sway/config`.
13. **Permisos de brillo**: instala `/etc/udev/rules.d/90-brightnessctl.rules` (grupo `video` para backlight; Debian no trae las reglas de `brightnessctl`) con fallback systemd-tmpfiles. Sin esto, las teclas XF86 de brillo dan `Permission denied`.
14. Verifica binarios.

### 3. Cerrá sesión y volvé a entrar

Importante: el primer arranque de `qs` necesita:
- LightDM con sesión Sway (o `sway` directo desde TTY).
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
| `lightdm` | Display manager (sesión Sway) |
| `upower` | Batería D-Bus (`Quickshell.Services.UPower`, widget Battery) |
| `zram-tools` | Swap comprimido (`/etc/default/zramswap`: `ALGO=zstd`, `PERCENT=60`, `PRIORITY=100`) |
| `fwupd` | Actualizaciones de firmware del equipo (no se corre `fwupdmgr update` solo) |
| `libgl1-mesa-dri` `mesa-vulkan-drivers` `vulkan-tools` | OpenGL/Vulkan. En amd64 también `:i386` para Steam |
| `amd64-microcode` / `intel-microcode` | Microcódigo de CPU si el procesador es AMD o Intel |
| `firmware-amd-graphics` `firmware-realtek` | Firmware GPU AMD y NIC Realtek (apt, no drivers de páginas externas) |
| `pciutils` `usbutils` | Detección de GPU/NIC para firmware |
| `firmware-linux*` Mesa VA/Vulkan | Firmware + aceleración según hardware (Intel/AMD/NVIDIA, iwlwifi, realtek, …) |
| `gh` | **No es solo apt.** Repo oficial GitHub CLI; keyring verificado por SHA256 |
| `zed` | **No es paquete apt.** Instalador `zed.dev/install.sh` |
| `thunar` | File manager extra (Yazi sigue como default XDG) |
| `voxtype` | Voz a texto Wayland. `.deb` amd64 de [peteonrails/voxtype](https://github.com/peteonrails/voxtype). No pisa Super+V (clipboard) |
| `deno` `bun` `pnpm` | Runtimes JS. Deno/Bun al home; pnpm vía corepack |
| `cloudflared` | Cloudflare Tunnel. `.deb` GitHub latest |
| `bruno` | Cliente API. `.deb` GitHub latest (amd64/arm64) |
| `podman` | Contenedores rootless (`uidmap` `slirp4netns` `fuse-overlayfs`) |
| `balena-etcher` | Flasher USB. `.deb` amd64 de [balena-io/etcher](https://github.com/balena-io/etcher/releases) |
| `snapd` | Snap. Quita `/etc/apt/preferences.d/nosnap.pref` si existe; `enable snapd.socket`; `/snap` → `/var/lib/snapd/snap` |
| `flatpak` | Flatpak + remote Flathub + `xdg-desktop-portal-wlr` |
| Homebrew | [linuxbrew](https://brew.sh). `NONINTERACTIVE=1` install.sh; `brew shellenv` en `zoi.fish` |
| llama.cpp | **No Homebrew.** Clone + cmake en `~/apps/llama.cpp` ([MBZUAI-IFM `model/K2Horizon`](https://github.com/MBZUAI-IFM/llama.cpp/tree/model/K2Horizon)) → `~/.local/bin/llama-cli` y `llama-server`. |
| K2-Horizon GGUF | [IFM/K2-Horizon-0.9B-GGUF](https://huggingface.co/IFM/K2-Horizon-0.9B-GGUF) → `~/models/K2-Horizon-1B-BF16.gguf` (BF16, ~1.8 GB). Wrappers: `k2-chat`, `k2-server` (ctx default 8192; 128K = YaRN). |
| Go | Tarball oficial [go.dev](https://go.dev/dl/) → `/usr/local/go` (SHA256; ≥1.25.10). PATH: `/usr/local/go/bin` y `~/go/bin` |
| `gentle-ai` | [Gentleman-Programming/gentle-ai](https://github.com/Gentleman-Programming/gentle-ai) `go install …/v2/cmd/gentle-ai@latest` |
| `engram` | [Gentleman-Programming/engram](https://github.com/Gentleman-Programming/engram) `go install …/cmd/engram@latest` |
| `gentle-pi` | [Gentleman-Programming/gentle-pi](https://github.com/Gentleman-Programming/gentle-pi) `pi install npm:gentle-pi@latest` |
| `gga` | [gentleman-guardian-angel](https://github.com/Gentleman-Programming/gentleman-guardian-angel) `brew install gentleman-programming/tap/gga` o `./install.sh` del repo |
| `codegraph` | CLI en PATH. No se corre `codegraph install --yes` (eso cablea Cursor/Claude/Copilot). No se escribe MCP Gemini ni se cablea MCP a Pi. |
| `chrome-devtools-mcp` | npm global → binario en PATH. No se cablea MCP a Pi ni a otros IDEs. |
| Cloudflare MCP | Remoto `https://mcp.cloudflare.com/mcp`. Skills **solo Pi** (`~/.pi/agent/skills/`). Snapshot `~/.config/zoi/mcp-cloudflare.json`. Como Herdr: no se instala en todos los IDEs. |
| `context7` (MCP) | HTTP público `https://mcp.context7.com/mcp` para **lookup de docs** ([context7.com](https://context7.com)). Sin auth, rate-limit por IP. Se siembra en `~/.pi/agent/mcp.json` (camino **nativo de Pi**), no en `~/.config/mcp/mcp.json` (pi-mcp-adapter). Convive con los dos configs que siembra ZOI — ver [configuration.md](configuration.md#mcp-model-context-protocol). |
| `rustc` `cargo` | **rustup** (`https://sh.rustup.rs`, toolchain stable) → `~/.cargo/bin` |
| `hx` | **Helix**. [Paquete Debian de GitHub](https://docs.helix-editor.com/package-managers.html#ubuntudebian) (amd64 `.deb`; arm64 tarball + `runtime` en `~/.config/helix/runtime`) |
| Drift | Video editor [CutWire-Studios/Drift](https://github.com/CutWire-Studios/Drift). `flatpak install flathub org.cutwire.Drift`; fallback AppImage amd64 |
| `mullvad-browser` | Se instala (amd64). XDG default = Thorium si existe, si no Mullvad. `qs-browser` sigue XDG |
| Brave Origin | **No es paquete apt.** `curl -fsS https://dl.brave.com/install.sh \| FLAVOR=origin sh`. No entra al default XDG (sigue Thorium, si no Mullvad). |
| `yazi` | File manager (foot + Sixel). Repo APT oficial, `deb [arch=$ARCH …]` (amd64/arm64) |
| `inlyne` | **No es paquete apt.** Release GitHub v0.5.3 → `~/.local/bin/inlyne` (amd64/arm64) |
| `curl` | HTTP (keys APT, Herdr, Pi, Node.js, Inlyne). Fase 1 y fase 2 |
| `git` | Clone/update del repo. Fase 1 y fase 2 |
| `xz-utils` | Extrae el tarball de Node.js |
| `nodejs` / `npm` | **No es paquete apt.** Current latest de [nodejs.org](https://nodejs.org/dist/latest/) → `/usr/local` (amd64/arm64). Un re-run actualiza si hay versión nueva |
| `herdr` | Multiplexer de terminales para agentes. Instalador oficial `herdr.dev/install.sh` |
| `ffmpeg` `poppler-utils` `fd-find` `ripgrep` `fzf` `imagemagick` `p7zip-full` `ffmpegthumbnailer` `chafa` `unzip` | Previews de Yazi |
| `fish` | Login shell + shell de foot |
| `bc` | Cálculos matemáticos en scripts auxiliares |
| `btop` | Monitor de recursos del sistema (themeado por zoi-theme) |
| `python3` | Helpers `qs-weather` / `qs-holidays` / `qs-keys-apply` (`/usr/bin/python3`). Weather cache: `~/.cache/quickshell/weather.json` |
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
│   ├── Weather.qml          # Open-Meteo singleton: cache + Process.exec + retry al boot
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
    ├── Weather.qml          # chip: import Commons as Commons (no sombrear el singleton)
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
├── qs-weather               # IP geo + Open-Meteo (python3); fallback Bogotá + cache
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

~/.cache/quickshell/weather.json  # último fetch Open-Meteo (chip al reboot)

~/.config/quickshell/screensaver.txt   # texto del banner (default: ZOI)
```

## Sudoers

El instalador **pregunta** antes de dar privilegios:

```text
Puedo escribir /etc/sudoers.d/zoi-<usuario> con: <usuario> ALL=(ALL:ALL) ALL
¿Agregar a <usuario> en sudoers? [Y/n]
```

- **Y** (default): drop-in validado con `visudo -c`, modo `0440`, y el usuario entra al grupo `sudo`.
- **n**: no toca sudoers. La fase 2 igual necesita `sudo` para apt.
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
sudo systemctl enable --now NetworkManager bluetooth lightdm
```

### Verificar

`install.sh` deja el autostart de Quickshell en la config de Sway (bloque `# zoi-debian quickshell: bar + overlays autostart`):

```sh
exec_always ~/.local/bin/qs-shell
```

Para probar sin reloguear:

```sh
~/.local/bin/qs-shell &
/usr/bin/qs ipc call launcher toggle  # debería abrir el launcher
```

Si no se ve nada, mirá `~/.cache/quickshell/crashes/<shell>/`.

## Variante Waybar

El default es la barra Quickshell. Para barra nativa **Waybar** (mismos overlays QML: launcher, notifs, lock, OSD):

```sh
./scripts/install-waybar.sh
```

Si el desktop no está, corre `install.sh` primero. Clicks de Waybar llaman `qs ipc`. Tema: `waybar.css.tpl` vía `zoi-theme`.

## Variante Swaybar

Misma idea, barra nativa de Sway (`swaybar`) en vez de Waybar. Quickshell sigue en overlays (launcher, notifs, lock, OSD). No instala paquetes extra.

```sh
./scripts/install-swaybar.sh
```

Status: `qs-swaybar-status`. Tema: `zoi-theme` pinta `bar zoi` si `bar-backend` es `swaybar`. Volver al default: `./scripts/install.sh`.

## Desinstalar

```sh
~/projects/zoi-debian/scripts/uninstall.sh
```

Quita el shell ZOI (`qs-*`, Inlyne, `~/.config/quickshell`) y leftovers de Lemurs. Habilita LightDM. Los paquetes apt quedan.
