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

## "Cómo desinstalo"

```sh
~/projects/zoi-debian/scripts/uninstall.sh
```

El script `scripts/uninstall.sh` realiza una desinstalación limpia:
- Respalda `~/.config/quickshell` con marca temporal (`quickshell.bak.<timestamp>`).
- Elimina los ejecutables `qs-*` y `zoi-theme` de `~/.local/bin/`.
- Limpia los directorios de estado en `~/.local/state/quickshell` y `~/.local/state/zoi`.
- Remueve los comandos `exec_always` de `~/.config/sway/config`.
- Mantiene los paquetes apt instalados intactos (para removerlos por completo, seguir las instrucciones que imprime al finalizar).
