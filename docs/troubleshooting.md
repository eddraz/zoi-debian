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

- `Type X unavailable` — un import falla. Probablemente editaste un archivo y el qmldir no se actualizó. Verificá `~/.config/quickshell/Commons/qmldir`.
- `Expected token '}'` — sintaxis QML rota. El error apunta a la línea exacta.
- `Cannot assign to read-only property` — bug en un binding. Probá `Component.onCompleted` o usá `var` en vez de `int` para `cursorArr`.

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

## Lemurs se ve negro/VGA, no el theme del wallpaper

El TTY del kernel no entiende hex. Tiene que existir `/etc/lemurs/vtrgb` y la unit tiene que correr `setvtrgb` *antes* de Lemurs. El `config.toml` usa nombres ANSI (`black`, `light yellow`), no `$accent`.

```sh
cat /etc/lemurs/vtrgb
grep ExecStartPre /etc/systemd/system/lemurs.service
# próximo arranque de Lemurs (reboot). No hace falta restart desde la sesión gráfica.
```

## Lemurs: authentication failed (usuario/contraseña bien)

No es la contraseña. En `/var/log/lemurs.log` vas a ver `Validated account` y después `Failed to open a PAM session`. Debian `/etc/pam.d/login` tiene `session required pam_loginuid.so`; Lemurs corre como unidad systemd y el kernel responde EPERM ([lemurs#166](https://github.com/coastalwhite/lemurs/issues/166)). El greeter traduce eso a *authentication failed*.

```sh
sudo install -m 0644 -o root -g root dotfiles/lemurs/lemurs.pam /etc/pam.d/lemurs
```

El próximo intento en TTY2 alcanza. En el switcher usá **sway** (sin cache el default es XFCE).

## `install.sh`: `work: variable sin asignar` (Lemurs)

Era un `trap RETURN` sobre una variable `local`. Lemurs igual quedaba installed/enabled. Ya está arreglado en `lemurs-setup.sh`. Si ves el warning viejo: `systemctl is-enabled lemurs` y `lemurs --version`.

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

## Limine no arranca Debian

El helper opcional está documentado en [limine.md](limine.md). GRUB no se desinstala.

- Firmware: elegí la entrada `debian` (`shimx64.efi`).
- `sudo ./scripts/limine-setup.sh status` — ¿están `BOOTX64.EFI` y `limine.conf`?
- El kernel se lee por `guid(<UUID-de-/>):/boot/vmlinuz-...`. Si Limine dice que no encuentra el archivo, el UUID de `/` no coincide o `/boot` no está en esa partición.
- Secure Boot tiene que estar **off** para este helper.
- No uses este script si no querés cambiar el bootloader; `install.sh` no lo corre.
