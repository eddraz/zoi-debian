# Troubleshooting

Problemas frecuentes y cómo resolverlos.

## "qs no arrancó"

```sh
# Ver logs
ls -t /run/user/$(id -u)/quickshell/by-id/*/log.log | head -1 | xargs tail -30

# Si hay un crash
ls ~/.cache/quickshell/crashes/
```

Errores comunes:

- `Could not find the Qt platform plugin "wayland"` — falta `qt6-wayland`. El paquete `quickshell` de Debian solo tira `libqt6waylandclient6`; el plugin QPA vive en `qt6-wayland` y `install.sh` usa `--no-install-recommends`. Instalálo y relanzá:
  ```sh
  sudo apt-get install -y --no-install-recommends qt6-wayland
  /usr/bin/qs -n --daemonize
  ```
- `Type X unavailable` — un import falla. Probablemente editaste un archivo y el qmldir no se actualizó. Verificá `~/.config/quickshell/Commons/qmldir`.
- `Expected token '}'` — sintaxis QML rota. El error apunta a la línea exacta.
- `Cannot assign to read-only property` — bug en un binding. Probá `Component.onCompleted` o usá `var` en vez de `int` para `cursorArr`.

## El chip de weather se queda en nube + `…`

Eso es `Weather.label` con `ready: false` (fetch que no arranca, red caída al boot, o el chip que no ve el singleton).

Al login `qs` corre antes de que haya Internet. El helper reintenta y guarda el último JSON en `~/.cache/quickshell/weather.json`; el chip debería pintar cache enseguida y refrescar cuando la red aparezca (backoff 3s–60s, no hace falta esperar 20 min).

1. El helper tiene que devolver JSON con `temp` numérico:
   ```sh
   ~/.local/bin/qs-weather
   # {"city": "Bogotá", "temp": 23.8, ...}
   ```
   Si falla, instalá `python3` y copiá `dotfiles/local-bin/qs-weather` a `~/.local/bin` (`install -m 755`). ip-api cae a Bogotá; Open-Meteo sí necesita red. Si Open-Meteo falla pero hay cache, imprime el cache.
2. Forzá un fetch:
   ```sh
   /usr/bin/qs ipc call weather refresh
   ```
   Clic medio en el chip o Enter en `Super+T` hacen lo mismo.
3. `widgets/Weather.qml` **no** puede usar `Weather.label` a secas: el archivo se llama igual que el singleton. Tiene que ser `import "../Commons" as Commons` y `Commons.Weather.label`.
4. `shell.qml` debe forzar el singleton: `readonly property bool _bootWeather: Weather.ready`.
5. Si el panel muestra datos y el chip no, es el sombreado del nombre (paso 3).
6. Recargá o reiniciá: `pkill qs; /usr/bin/qs -n --daemonize`. Logs: `qs-weather:` en el `log.log` de quickshell.

## "El popup no se ve"

- Verificá que `WlrLayershell.layer: WlrLayer.Overlay` esté en PopupCard.
- Verificá que `WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive` cuando está abierto.
- Si hay un layershell nativo de Sway (waybar) en Overlay, chocan. Matá waybar: `pkill waybar`.

## "Escape no cierra el popup"

Sway a veces intercepta Escape (porque es el `bindsym $mod+Escape` que abre Session). Probá `Super+Q`.

## "Las teclas de flecha no llegan al popup"

El popup tiene `keyboardFocus: Exclusive`, pero si `card.forceActiveFocus()` falla, el foco queda en el bar.

Workaround: abrí y cerrá el popup con `Super+Q` después de cada cambio en `~/.config/quickshell/`.

## "Mi plugin nuevo no aparece"

`PluginRegistry.hostOrder` define el orden de carga de overlays/services. Si agregás un id al catalog pero no a `hostOrder`, no se monta.

Para bar widgets y paneles, agregá el id al array de la sección en `shell.json`.

## "Mi nuevo IpcHandler dice 'Handler was registered but will not be used'"

Hay dos cargando el mismo target. Probable causa: dos shells corriendo a la vez.

```sh
pgrep -af quickshell
kill <pid>
```

O el catálogo tiene el mismo `target:` declarado dos veces.

## "Las teclas de brillo no hacen nada"

En Debian, `brightnessctl` no trae las reglas udev: aunque tu usuario esté en el grupo `video`, escribir el backlight da `Permission denied`.

```sh
brightnessctl set 5%+          # si tira "Permission denied", es esto
stat -c '%U %G %a' /sys/class/backlight/*/brightness   # grupo debe ser video
```

`install.sh` instala la regla `/etc/udev/rules.d/90-brightnessctl.rules` (grupo `video` para backlight, `input` para leds) y la aplica con `udevadm trigger`. A mano:

```sh
sudo tee /etc/udev/rules.d/90-brightnessctl.rules >/dev/null <<'EOF'
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video $sys$devpath/brightness", RUN+="/bin/chmod g+w $sys$devpath/brightness"
ACTION=="add", SUBSYSTEM=="leds", RUN+="/bin/chgrp input $sys$devpath/brightness", RUN+="/bin/chmod g+w $sys$devpath/brightness"
EOF
sudo udevadm control --reload-rules
sudo udevadm trigger -v -c add /sys/class/backlight/amdgpu_bl0  # tu device
```

Si udev no aplica el grupo (algunos devices saltan las reglas `RUN`), fallback con systemd-tmpfiles:

```sh
printf 'z /sys/class/backlight/amdgpu_bl0/brightness 0664 root video - -\n' \
  | sudo tee /etc/tmpfiles.d/backlight.conf
sudo systemd-tmpfiles --create /etc/tmpfiles.d/backlight.conf
```

Las teclas XF86 de volumen usan `wpctl` (PipeWire); si fallan, chequeá `wpctl get-volume @DEFAULT_AUDIO_SINK@` y que `wireplumber` esté corriendo.

## "El wallpaper no se aplica"

```sh
swaymsg 'output * bg'  # ver outputs actuales
swaymsg "output eDP-1 bg \"$HOME/Imágenes/baby-yoda-cartoon.jpg\" fill"
```

Si usás `swaybg -o * -o eDP-1` (stack), parpadea. Preferí `swaymsg output * bg`.

## "El lock screen queda negro"

`Wallpaper.current` no está seteado. Aplicá wallpaper desde Session → Wallpaper. Si está roto, editá a mano:

```sh
echo "$HOME/Imágenes/baby-yoda-cartoon.jpg" > ~/.local/state/quickshell/wallpaper
```

## "Mi emoji picker no se abre"

```sh
# IPC
qs ipc call emojis toggle
# Si dice "ok" pero no se ve: el panel no se cargó.
ls -t /run/user/$(id -u)/quickshell/by-id/*/log.log | head -1 | xargs tail -20
```

Si el panel nunca se cargó, `PluginRegistry.panelUrl("emojis")` devolvió `""`. Verificá que el catalog tenga la entrada `"emojis"`.

## "El screensaver no se dispara"

`swayidle` debe estar corriendo:

```sh
pgrep swayidle
```

Si no está, agregá `exec swayidle -w ...` a tu `sway/config`. El config actual lo tiene, pero un reload de sway puede haberlo matado.

## "Stay awake no funciona"

Verificá que `WlIdleInhibitor` esté activo:

```sh
cat ~/.local/state/quickshell/stay-awake
# debe decir "on"
```

Si está `on` y el screensaver igual dispara, hay un bug en `Commons/Idle.qml`. Reportá con logs.

## "MPRIS no muestra nada"

```sh
playerctl -l
```

Si lista players pero el widget del bar no se actualiza, hay un binding que no se triggereó. Reiniciá `qs`.

## "El clipboard no pega al input focused"

`wtype` necesita **focus de teclado Wayland**. Si el popup roba el focus (tiene `keyboardFocus: Exclusive`), `wtype Shift+Insert` no llega al input debajo.

Workaround: cerrar el popup primero (Enter ya copió), después pegar manualmente con `Ctrl+V` o `Shift+Ins`.

## "Wifi no funciona"

NetworkManager debe estar corriendo:

```sh
systemctl status NetworkManager
sudo systemctl enable --now NetworkManager
```

## "Bluetooth no funciona"

```sh
sudo systemctl enable --now bluetooth
sudo rfkill unblock bluetooth
```

## "El audio no funciona"

```sh
systemctl --user status wireplumber
systemctl --user enable --now wireplumber
```

Si tenés PulseAudio legacy, conflict. PipeWire + WirePlumber es lo que usa QS.

## "Quickshell usa 100% CPU"

Probable: binding loop en algún `Repeater`. Mirar logs:

```sh
ls -t /run/user/$(id -u)/quickshell/by-id/*/log.log | head -1 | xargs grep -i 'binding loop'
```

El error indica el archivo y línea. Soluciones comunes:
- No bindees `height` a `item.implicitHeight` en un Loader dentro de un Repeater (usá el natural).
- No bindees `width` de una `Row` a `parent.width - 96` si el padre no está listo.

## "No veo los íconos del bar"

`StatusIcon.qml` los pinta con QPainter Canvas. Si ves rectángulos negros, hay un error en el source SVG path. Ver `widgets/Volume.qml` para la API.

## "Mi wallpaper queda pixeleado / chroma striped"

Wallpaperflare a veces tiene JPEGs con chroma subsampling agresivo. Pasalo por `ffmpeg -i in.jpg -vf format=yuv420p -q:v 2 out.jpg` antes de aplicar.

## "El screensaver dice 'command not found: terminaltexteffects'"

```sh
pip install terminaltexteffects
# o
sudo apt install python3-terminaltexteffects
```

## Al reiniciar, Quickshell vuelve a Mocha (el selector no recuerda el tema)

El id vive en `~/.local/state/quickshell/theme`. Los colores de la barra viven en `~/.local/state/quickshell/colors.json`. Si solo existe `theme`, `Color.qml` arranca con los defaults Mocha.

```sh
cat ~/.local/state/quickshell/theme
python3 -c "import json,os; d=json.load(open(os.path.expanduser('~/.local/state/quickshell/colors.json'))); print(d.get('id'), d.get('accent'))"
```

Reaplicar desde **Session → Theme** (fuente de verdad). Eso escribe ambos archivos. Si `zoi-theme` se queja de `gsettings`:

```sh
sudo apt-get install -y --no-install-recommends libglib2.0-bin
```

Un apply viejo puede haber dejado paleta en `~/.local/state/zoi/theme/current/colors.json` y no en Quickshell:

```sh
cp ~/.local/state/zoi/theme/current/colors.json ~/.local/state/quickshell/colors.json
```

## `install.sh`: sudoers / «¿Agregar a … en sudoers?»

El instalador no escribe sudoers a ciegas. Si dijiste **n**, no hay `/etc/sudoers.d/zoi-<usuario>` y la fase 2 puede pedir contraseña o fallar sin `sudo`.

```sh
# ver
ls -l /etc/sudoers.d/zoi-*
sudo -l -U "$USER"

# agregar ahora (mismo contenido que el instalador)
echo "$USER ALL=(ALL:ALL) ALL" | sudo tee /etc/sudoers.d/zoi-$USER
sudo chmod 440 /etc/sudoers.d/zoi-$USER
sudo visudo -cf /etc/sudoers.d/zoi-$USER

# quitar
sudo rm -f /etc/sudoers.d/zoi-$USER
```

En no interactivo: `ZOI_SUDOERS=0` omite; `ZOI_SUDOERS=1` (default con `ZOI_NONINTERACTIVE=1`) escribe el drop-in.

## `install.sh`: `usermod: orden no encontrada` (o `locale-gen` / `update-locale`)

En Debian esos binarios están en `/usr/sbin`. Un PATH de usuario (`sudo -E`, `su` sin `-`, agentes) no lo incluye y bash sale 127.

Los scripts (`install.sh`, `uninstall.sh`) anteponen `/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin` al PATH. Si corrés `usermod` a mano:

```sh
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:$PATH"
command -v usermod   # /usr/sbin/usermod
sudo usermod -aG render,video $USER
```

## Falta `amberol` / `loupe`

Están en Debian `main`. Si el sanity del install los marcó:

```sh
sudo apt install -y amberol loupe
```

`install.sh` ahora los incluye en `PKGS`.

## `cp: -r not specified; omitting directory .../__pycache__`

El glob `local-bin/*` copiaba el directorio de bytecode y, con `set -e`, cortaba el setup. Ahora `find -type f`.

## Inlyne no abre / `qs-md` falla

```sh
command -v inlyne; inlyne --version   # esperá 0.5.3 en ~/.local/bin
qs-md ~/projects/zoi-debian/docs/README.md
```

`install.sh` solo baja el tarball en **amd64/arm64**. No hay overlay Quickshell: Markdown es una ventana (`inlyne view`).

## Yazi muestra rectángulos en vez de íconos

ZOI no instala Nerd Font. El tema usa ASCII (`>` carpetas, `-` archivos) en `~/.config/yazi/theme.toml`. Si ves cajas, Yazi está usando el preset; reaplicá tema (`zoi-theme set wallpaper` o el que uses).

## Yazi: `at least one of url or mime must be specified`

Yazi 26 no acepta `name = "*.md"` en `[open]`. Tiene que ser `url = "*.md"` o `mime = "text/markdown"`. El `yazi.toml` del repo ya va así.

## Yazi APT: omitiendo `binary-i386`

El repo oficial no publica i386. `install.sh` escribe `deb [arch=$ARCH …]`. A mano: `arch=amd64` (o `arm64`) en `/etc/apt/sources.list.d/yazi.list`.

## "Cómo desinstalo"

```sh
~/projects/zoi-debian/scripts/uninstall.sh
```

El script `scripts/uninstall.sh` realiza una desinstalación limpia:
- Respalda `~/.config/quickshell` con marca temporal (`quickshell.bak.<timestamp>`).
- Elimina `qs-*`, `zoi-theme` e `inlyne` de `~/.local/bin/`, más `~/.config/inlyne`.
- Limpia los directorios de estado en `~/.local/state/quickshell` y `~/.local/state/zoi`.
- Remueve los comandos `exec_always` de `~/.config/sway/config`.
- Mantiene los paquetes apt instalados intactos (para removerlos por completo, seguir las instrucciones que imprime al finalizar).

## Gráficos / firmware / zram

Diagnóstico (Mesa y Vulkan vienen con `install.sh`):

```sh
lspci -nnk | grep -A3 -Ei 'VGA|3D|Network|Audio'
glxinfo -B
vulkaninfo --summary
journalctl -b -p warning | grep -Ei 'firmware|amdgpu|rtw|wifi'
sudo zramctl
```

zram: `/etc/default/zramswap` (`ALGO=zstd`, `PERCENT=60`). Si no hay dispositivo: `sudo systemctl restart zramswap`.

Firmware del equipo (opcional, con el cargador conectado):

```sh
sudo fwupdmgr refresh --force
fwupdmgr get-updates
# solo si revisaste la lista:
sudo fwupdmgr update
```

`install.sh` **no** corre `fwupdmgr update` solo (puede flashear BIOS).

Extensiones tipo *Paneles transparentes* / *Burn My Windows* / Alt-Tab carrusel 3D son de GNOME/Cinnamon. ZOI es **Sway + Quickshell**; no aplican.
