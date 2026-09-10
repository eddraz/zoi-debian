# Atajos de teclado

Esta tabla lista todos los binds de Sway + atajos internos de Quickshell.

## Sway (sway/config)

| Combo | Acción | Comando |
|---|---|---|
| `Super+Return` | Terminal (foot + fish) | `$term` |
| `Super+Shift+Return` | LibreWolf | `/usr/bin/librewolf` |
| `Super+KP_Enter` | Terminal | `$term` |
| `Super+Shift+KP_Enter` | LibreWolf | `/usr/bin/librewolf` |
| `Super+Escape` | Session panel | `qs ipc call session toggle` |
| `Super+Q` | Cerrar popup / panel | `qs ipc call popups close` |
| `Super+C` | Calendar panel | `qs ipc call popups toggle calendar` |
| `Super+T` | Weather panel | `qs ipc call popups toggle weather` |
| `Super+N` | Notifs panel | `qs ipc call popups toggle notifs` |
| `Super+Shift+N` | Reminders overlay | `qs ipc call reminders toggle` |
| `Super+M` | Audio panel | `qs ipc call popups toggle audio` |
| `Super+P` | Power panel | `qs ipc call popups toggle power` |
| `Super+I` | Network panel | `qs ipc call popups toggle network` |
| `Super+U` | Bluetooth panel | `qs ipc call popups toggle bluetooth` |
| `Super+Shift+B` | Bar visual editor | `qs ipc call popups toggle bar` |
| `Super+Space` | Launcher | `$menu` (`zoi-launcher`) |
| `Super+V` | Clipboard history | `qs ipc call clipboard toggle` |
| `Super+.` | Emoji picker | `qs ipc call emojis toggle` |
| `Super+Shift+,` | Emoji picker (latam) | `qs ipc call emojis toggle` |
| `Super+B` | Splith | `splith` |
| `Super+Ctrl+V` | Splitv | `splitv` |
| `Super+S` | Stacking | `layout stacking` |
| `Super+W` | Tabbed | `layout tabbed` |
| `Super+Shift+W` | Cerrar ventana | `kill` |
| `Super+E` | Toggle split | `layout toggle split` |
| `Super+F` | Fullscreen | `fullscreen` |
| `Super+Shift+Space` | Floating toggle | `floating toggle` |
| `Super+D` | Focus mode toggle | `focus mode_toggle` |
| `Super+A` | Focus parent | `focus parent` |
| `Super+Minus` | Scratchpad show | `scratchpad show` |
| `Super+Shift+Minus` | Move to scratchpad | `move scratchpad` |
| `Super+R` | Resize mode | `mode "resize"` |
| `Super+Shift+R` | Media arm (1/2/3) | `qs ipc call media toggleArm` |
| `Super+Shift+S` | Screenshot | `qs-screenshot` |
| `Super+Shift+C` | Recargar Sway | `reload` |
| `Super+Shift+E` | Salir de Sway | `swaynag` confirmar |

### Workspaces

| Combo | Acción |
|---|---|
| `Super+0..9` | Workspace N |
| `Super+Shift+0..9` | Mover ventana a N |
| `Super+Tab` | Workspace next |
| `Super+Shift+Tab` | Workspace prev |

### Focus + movement

| Combo | Acción |
|---|---|
| `Super+L` | Focus right (vim) |
| `Super+H` (Sin Shift) en popups | slider down / cursor left |
| `Super+←/→/↑/↓` | Focus direction |
| `Super+Shift+←/→/↑/↓` | Move window |
| `Super+Alt+←/→/↑/↓` | Resize window |

### Media / brightness

| Tecla | Acción |
|---|---|
| `XF86AudioRaiseVolume` | OSD volume up (`qs ipc call osd volume +5`) |
| `XF86AudioLowerVolume` | OSD volume down |
| `XF86AudioMute` | Toggle mute |
| `XF86AudioMicMute` | Toggle mic mute |
| `XF86AudioPlay` | MPRIS play-pause |
| `XF86AudioNext` | MPRIS next |
| `XF86AudioPrev` | MPRIS prev |
| `XF86KbdBrightnessUp` | OSD brightness up |
| `XF86KbdBrightnessDown` | OSD brightness down |
| `XF86MonBrightnessUp` | OSD screen brightness up |
| `XF86MonBrightnessDown` | OSD screen brightness down |

## Dentro de un popup

| Tecla | Acción (universal) |
|---|---|
| `0-9` | Saltar al ítem N |
| `↑/↓` o `J/K` | Cursor arriba/abajo |
| `←/→` o `H/L` | Cursor izquierda/derecha (slider o columna según panel) |
| `Tab` / `Shift+Tab` | Sección siguiente / anterior |
| `/` | Mostrar campo de búsqueda (si `searchEntries` está implementado) |
| `Escape` | Limpiar búsqueda o cerrar popup |
| `Enter` | Activar el ítem seleccionado |

## Popups específicos

### Audio panel
- `0` = volumen (cursor al slider)
- `H/L` o `←/→` = −/+ 5%
- `1` = mute speakers
- `2` = mic slider
- `3` = mute mic
- `4+` = devices (sink/source)
- último = lofi radio (Enter to play)

### Power panel
- `0` = brillo slider
- `H/L` o `←/→` = −/+ 5%
- `1+` = perfiles (Power-Saver / Balanced / Performance)

### Media panel
- `0+` = players
- `Enter` = play-pause
- `H/L` o `←/→` = prev/next
- `Space` = play-pause (también)

### Session panel
- `0` = Shortcuts (`openKeys`)
- `1` = Bar (`openBar`)
- `2` = Stay awake (toggle)
- `3` = Night light (toggle)
- `4` = Theme (`openTheme`)
- `5` = Wallpaper (`openWallpaper`)
- `6+` = Lock, Suspend, Log out (con confirm), Reboot (confirm), Shut down (confirm)

### Theme panel
- `0` = paleta activa
- `1` = wallpaper picker
- `2` = screensaver text editor
- `Tab` cicla entre secciones
- `/` busca paleta/wallpaper

### Bar editor
- `↑/↓` o `J/K` = cursor en columna
- `←/→` = cambiar columna
- `Shift` = pick / drop
- `Shift + ↑/↓` = reorder con pick
- `Shift + ←/→` = mover a otra columna con pick
- `Enter` = drop / toggle
- `Escape` = cancel pick
- `0-9` = jump a índice
- Hover (mouse) = highlight tenue + click = focus

### Network panel
- `0` = Wi-Fi on/off
- `1+` = redes
- `Enter` = conectar / desconectar

### Bluetooth panel
- `0` = Bluetooth on/off
- `1+` = devices
- `Enter` = connect / disconnect

### Calendar panel
- `←/→` = mes anterior / siguiente
- `↑/↓` = semana
- `Enter` = hoy

### Wallpaper panel
- `/` = buscar
- `Enter` = aplicar
- Grid navegable con `↑/↓/←/→`

### Clipboard history
- `0-9` = jump
- `Enter` = copia y **pega al input focused**
- `H` o `Delete` = borrar entrada individual
- `/` = buscar

### Notifications panel
- `0-9` = jump
- `Enter` = abrir URI
- `H` o `Delete` = descartar

### Keys (Shortcuts) panel
- `/` = mostrar buscador
- `↑/↓` = navegar

### Emoji picker
- escribe para buscar
- `↑/↓/←/→` = navegar grid 8 columnas
- `Enter` = copia y pega

### Reminders overlay
- input minutos + mensaje
- `Enter` = crear

### Media arm overlay (Super+Shift+R primero)
- `1` = prev
- `2` = play-pause
- `3` = next
- `Esc` o click-out = salir

## Mouse

| Acción | Resultado |
|---|---|
| Click chip del bar | Abre panel correspondiente |
| Click derecho bell | Toggle DND |
| Click save en Bar editor | Persiste |
| Hover chip | Highlight tenue |
| Hover columna title | Cambia cursor a pointer (clickeable) |
| Hover help text (Bar) | Tooltip con detalle |
| Click fuera del popup | Dismiss |
| Scroll sobre chip de volumen | Ajusta volumen |
| Scroll sobre chip de brillo | Ajusta brillo |

## IPC targets disponibles

```sh
qs ipc call session toggle|open
qs ipc call popups toggle|open|close <name>
qs ipc call popups close            # close all
qs ipc call launcher toggle
qs ipc call clipboard toggle
qs ipc call lock lock
qs ipc call osd volume|brightness
qs ipc call emojis toggle
qs ipc call reminders toggle
qs ipc call media toggleArm
```

Donde `<name>` es uno de: `media`, `audio`, `power`, `network`, `bluetooth`, `session`, `notifs`, `keys`, `wallpaper`, `theme`, `keyboard`, `weather`, `calendar`, `bar`.
