# Features

Detalle de cada feature, cómo funciona por dentro, qué archivos toca.

## Índice

1. [Bar + tokens](#bar--tokens)
2. [OSD (volume / brightness)](#osd-volume--brightness)
3. [PopupCard + paneles](#popupcard--paneles)
4. [Launcher](#launcher)
5. [Lock screen](#lock-screen)
6. [Idle / screensaver](#idle--screensaver)
7. [Stay awake](#stay-awake)
8. [Notifications daemon + DND](#notifications-daemon--dnd)
9. [Clipboard history](#clipboard-history)
10. [Screenshots + Recording](#screenshots--recording)
11. [Input (keyboard, pointer)](#input-keyboard-pointer)
12. [MPRIS + Media panel](#mpris--media-panel)
13. [Night light (wlsunset)](#night-light-wlsunset)
14. [Polkit overlay](#polkit-overlay)
15. [Wallpaper picker](#wallpaper-picker)
16. [Theme picker](#theme-picker)
17. [Screensaver TTE](#screensaver-tte)
18. [Emoji picker](#emoji-picker)
19. [Weather](#weather)
20. [Lofi radio](#lofi-radio)
21. [Reminders](#reminders)
22. [DND indicator](#dnd-indicator)
23. [PluginRegistry](#pluginregistry)
24. [Bar visual editor](#bar-visual-editor)
25. [System tray](#system-tray)

---

## Bar + tokens

`Bar.qml` es un `Variants` por pantalla (Sway outputs). Carga widgets vía `PluginRegistry.leftIds/centerIds/rightIds` con un `Repeater + ChipLoader` por columna. La barra usa el **Color singleton** y los tokens de `Style.qml`.

**Tokens clave (`Style.qml`):**

| Token | Default | Uso |
|---|---|---|
| `barHeight` | 28 | Altura de la barra |
| `pad` | 8 | Padding lateral |
| `gap` | 6 | Separación entre filas en popups |
| `radius` | 4 | Radius default |
| `chipHeight` | 18 | Altura del chip |
| `fontFamily` | monospace | fontconfig binding |
| `fontCaption` | 11 | Tamaño texto chico |
| `fontBody` | 12 | Tamaño texto normal |
| `popupMaxWidth` | 420 | Ancho máx PopupCard |
| `iconSize` | 18 | Tamaño íconos |

**Paleta Catppuccin Mocha (`Color.qml`):**

```qml
property color background: "#1e1e2e"   // base
property color mantle:     "#181825"
property color crust:      "#11111b"
property color foreground: "#cdd6f4"   // texto principal
property color muted:      "#a6adc8"
property color overlay:    "#6c7086"
property color surface:    "#313244"
property color accent:     "#89b4fa"
property color urgent:     "#f38ba8"
property color green:      "#a6e3a1"
property color peach:      "#fab387"
property color yellow:     "#f9e2af"
property color focusFill:  accent @ 0.22
```

---

## OSD (volume / brightness)

`Osd.qml` muestra un overlay centrado con el valor actual. Disparado por:

- **Volume keys** (`XF86AudioRaiseVolume` / `LowerVolume` / `Mute`) — `sway` los captura y los manda a `qs ipc call osd volume`.
- **Brightness keys** (`XF86KbdBrightnessUp` / `Down`) — `sway` los manda a `qs ipc call osd brightness`.

El `Commons/Audio.qml` ajusta PipeWire vía `wpctl`. `Commons/Brightness.qml` ajusta brillo vía `brightnessctl`.

**Auto-hide** a los 1.5s sin actividad.

---

## PopupCard + paneles

`Ui/PopupCard.qml` es un `PanelWindow` con `WlrLayer.Overlay` + `keyboardFocus: Exclusive` cuando está abierto. Su layout interno:

```
PopupCard (anchors to bar)
└── Column
    ├── Title        (opcional)
    ├── FindBar      (visible cuando searching === true)
    └── Flickable
        └── Column body
            ├── Panel 1 (instanciado por PluginRegistry)
            ├── Panel 2 ...
            └── Loader (Loader.item cuando panelUrl(popup))
```

**Patrón clave**: `Popups.requested` es un string. Cuando vale `"bar"` o `"weather"` o `"media"`, etc., `PopupCard` carga el panel correspondiente vía `PluginRegistry.panelUrl(screenRoot.popup)`. El `Loader` se monta y `bindPanel(item)` conecta `openKeys`/`openWallpaper`/`openTheme`/`openBar` según el panel.

**Navegación dentro del popup:**

- `0-9` salta al ítem del índice.
- `↑/↓` o `J/K` mueve cursor.
- `H/L` o `←/→` mueve slider (volumen, mic, brillo).
- `/` muestra el campo de búsqueda (solo si el panel expone `searchEntries`).
- `Tab`/`Shift+Tab` cicla secciones (Theme, Audio, Session, etc.).
- `Escape` borra el search si está activo, o cierra el popup.
- `Super+Q` siempre cierra.

`visiblePanel()` desenvuelve `Loader.item` para que `/`, Tab, J/K, H/L, Enter sigan andando cuando el panel es un `Loader`.

---

## Launcher

`Launcher.qml` — full app list con `Quickshell.iconPath(modelData.icon)`. Sin rofi, sin fuzzel.

- **Activación**: `Super+Space` (`sway: bindsym $mod+Space exec $menu`).
- **Búsqueda**: empieza a tipear; filtra en vivo por nombre.
- **Navegación**: `↑/↓` o `J/K` mueve selección, flechas siguen la selección visual.
- **Enter** ejecuta vía `xdg-open` o `Quickshell.execDetached`.
- **Escape** cierra.

Lista de apps: `Quickshell.DesktopEntries.applications` (todo lo que esté en `~/.local/share/applications/` + `/usr/share/applications/`).

---

## Lock screen

`Lock.qml` usa `Quickshell.Wayland.WlSessionLock` para tomar el control exclusivo de las pantallas y `Quickshell.Services.Pam` para autenticar vía PAM (módulo `pam_unix.so` por debajo).

**Wallpaper como fondo**: `Wallpaper.current` se lee y se aplica con `swaybg -i <path>` detrás del lock. Una capa negra al 55% le da opacidad.

**Cómo se activa**:
- `Session → Lock` (el chip "Lock" del panel).
- `qs ipc call lock lock`.
- `swayidle` después de 300s (configurable en `qs-idle`).

**Importante**: `Super+L` queda como `focus right` (vim nav). `Super+Escape` abre Session, no Lock. Si presionás Lock desde Session, ejecutás `qs ipc call lock lock`.

---

## Idle / screensaver

`swayidle` lo arranca `~/.local/bin/qs-idle`, que se llama desde `sway/config` con `exec_always`:

```
exec_always ~/.local/bin/qs-idle
```

El script `qs-idle`:

```sh
pkill -x swayidle 2>/dev/null || true
exec swayidle -w \
    timeout 150 "$HOME/.local/bin/qs-screensaver" \
    timeout 300 "$HOME/.local/bin/qs-screensaver stop; /usr/bin/qs ipc call lock lock" \
    timeout 330 'swaymsg "output * power off"' \
    resume "$HOME/.local/bin/qs-screensaver stop; swaymsg \"output * power on\"" \
    before-sleep "$HOME/.local/bin/qs-screensaver stop; /usr/bin/qs ipc call lock lock"
```

**Flujo:**

1. **0–150s**: `qs-screensaver` espera. Cualquier actividad mata el proceso.
2. **150s**: corre `qs-screensaver` → `~/.local/bin/qs-screensaver-run` → `foot --fullscreen python3 -m terminaltexteffects ...` con el banner "ZOI" en ASCII art.
3. **300s**: lock + DPMS off.
4. **330s**: DPMS off forzado.

**Stay awake** cancela todo: si `Idle.stayAwake === true`, el screensaver no se dispara (swayidle recibe un inhibit signal vía `WlIdleInhibitor`).

---

## Stay awake

`Commons/Idle.qml` activa un `WlIdleInhibitor`. Mientras esté activo, swayidle no dispara.

- **Toggle**: `Session → Stay awake`.
- **Estado**: `~/.local/state/quickshell/stay-awake` (persistido).

Chip en la barra muestra "Zzz" cuando está activo (icono `sleep` en canvas).

---

## Notifications daemon

`Notifications.qml` usa `Quickshell.Services.Notifications`. El icono de la campana (`widgets/NotifBell.qml`) muestra badge con `Notifs.unread`.

**Click derecho en la campana** → toggle DND (peach bell-off chip cuando está activo, persistido en `~/.local/state/quickshell/dnd`).

**Click izquierdo** → abre `NotifPanel.qml` con la lista. `0-9` salta al ítem, `J/K` navega, `H/L` borra individual, Enter abre el URI de la notif.

---

## Clipboard history

`Clipboard.qml` usa `cliphist` + `wl-paste --watch`.

- **Watcher**: `~/.local/bin/qs-clipwatch` corre `wl-paste --watch cliphist store` en background.
- **Activación**: `Super+V` (`sway: bindsym $mod+v exec /usr/bin/qs ipc call clipboard toggle`).
- **Navegación**: `0-9` jump, `J/K` mover, `/` buscar.
- **Enter**: copia al clipboard + **pega al input focused**: `wl-copy` + `wl-copy --primary` → sleep 0.25s → `wtype Shift+Insert`.
- **`H`/`Delete`**: borrar entrada individual (`qs-clip-delete`).
- **Escape**: cerrar.

---

## Screenshots + Recording

- **`Super+Shift+S`** → `qs-screenshot` → `grim -g "$(slurp)" ~/Imágenes/screenshots/<timestamp>.png`.
- **`Super+Shift+R`** (o botón de grab) → `qs-screenrecord` → `wf-recorder -g "$(slurp)" -f ~/Vídeos/records/<timestamp>.mp4`.

Capturas van a `~/Imágenes/screenshots/`, recordings a `~/Vídeos/records/`. El wallpaper picker **omite esas carpetas**.

---

## Input (keyboard, pointer)

`sway/config`:

```
input type:keyboard {
    xkb_layout latam,us
    xkb_options grp:alt_shift_toggle
}
input type:touchpad {
    tap enabled
    natural_scroll enabled
    click_method clickfinger
    pointer_accel 0.25
}
```

- **Layout** español latino + US, `Alt+Shift` para cambiar.
- **Touchpad**: tap, scroll natural, click con dos dedos (no click izquierdo + derecho), aceleración 0.25 (suave).
- **Bloq Mayús** se respeta: `shift+Alt+Mayús` también rota.

---

## MPRIS + Media panel

`Commons/Media.qml` envuelve `Quickshell.Services.Mpris`. Múltiples players (navegadores, Spotify, mpv, etc.) se unifican en una cola **exclusiva**: cuando uno arranca, los demás se pausan (`Media.pauseOthers(keep)`).

- **Persistencia en pausa**: Al pausar una canción, `Media.qml` retiene la referencia al reproductor activo (`activePlayer`). El título de la pista y el artista permanecen visibles en la barra sin alternar a otros reproductores ni resetearse; únicamente el ícono conmuta de `pause` a `play`. Al presionar `Play`, se reanuda directamente la canción pausada.
- **Widget del bar** (`Player.qml`): se muestra dinámicamente cuando hay un reproductor activo. Presenta el ícono de estado y el título elidido a ~96px.
- **Panel** (`MediaPanel.qml`): controles de transporte (prev/play-pause/next), metadata y atajos de teclado.

---

## Night light (wlsunset)

`Commons/NightLight.qml` arranca `wlsunset -T 4000` cuando se activa, lo mata cuando se desactiva.

- **Toggle**: `Session → Night light`.
- **Persistencia**: `~/.local/state/quickshell/night-light`.
- **Temperatura fija 4000K** (no configurable por ahora; edición simple en `NightLight.qml`).

---

## Polkit overlay

`Polkit.qml` registra `Quickshell.Services.Polkit.PolkitAgent` en `/org/quickshell/PolkitAgent`. Esto **reemplaza** `polkit-gnome`, `kde-polkit-agent`, `lxqt-policykit-agent`.

- **Catppuccin-themed**: input box con fondo surface, texto popupText, borde accent cuando focused.
- **Shake on error**: animation on `errorFlash === true`.
- **Input locked** mientras valida: muestra "Checking..." y deshabilita typing.

Si ves el diálogo default de polkit-gnome o lxqt, deshabilitálo:

```sh
sudo systemctl disable --now lxqt-policykit-agent.service
```

---

## Wallpaper picker

`WallpaperPanel.qml` lista `~/Imágenes/*.jpg|*.png` (omite `screenshots/`). Aplica vía:

```sh
~/.local/bin/qs-wallpaper set <path>
# internamente:
swaymsg 'output * bg "'$path'" fill'
```

(Prefiere `swaymsg output * bg` sobre `swaybg` por-output porque stackear `swaybg -o * -o eDP-1` causa flickering.)

**Persistencia**: `~/.local/state/quickshell/wallpaper`.

**Lock screen**: lee `Wallpaper.current` y lo aplica como dimmed (alpha 0.55) detrás del lock.

---

## Theme picker

`ThemePanel.qml` ofrece 9 paletas: **Catppuccin** (Mocha / Macchiato / Frappé / Latte), **Kanagawa**, **Nord**, **Gruvbox**, **Dracula**, **Rosé Pine**. Cambia `Color.background/mantle/...` en vivo (las propiedades son writable). Tema actual persistido en `~/.local/state/quickshell/theme`.

**Wallpaper-derived colors**: clic en "Derive from wallpaper" corre `qs-theme-from-wallpaper` que extrae colores con Python+Pillow y los aplica como accent + foreground.

---

## Screensaver TTE

`~/.local/bin/qs-screensaver` espera; al dispararse llama a `qs-screensaver-run`:

```sh
foot --fullscreen \
  bash -c 'python3 -m terminaltexteffects -a "$(figlet -f banner "$WORD")" <(echo)'
```

donde `WORD` viene de `~/.config/quickshell/screensaver.txt` (default `ZOI`). El efecto TTE es aleatorio entre ~30 disponibles.

**Cualquier tecla** o resume de swayidle mata el proceso.

---

## Emoji picker

`Emojis.qml` + `emojis.json` (base de datos completa). 

- **Activación**: `Super+.` (latam: `Super+Shift+,` por el layout).
- **Búsqueda**: tipea nombre o keyword.
- **Grid** 8 columnas, scrollable.
- **Enter**: copia al clipboard + **pega al input focused** (`wl-copy` + `wtype Shift+Insert`).

Restart de `qs` necesario si cambiás los IPC targets (los `IpcHandler` se registran en construcción).

---

## Weather

`Commons/Weather.qml` consume Open-Meteo:

```sh
~/.local/bin/qs-weather
# internamente:
curl "https://api.open-meteo.com/v1/forecast?latitude=4.6&longitude=-74.0&current_weather=true"
```

Geolocation por IP (default Bogotá: 4.6, -74.0). Para cambiar tu ciudad, editá `qs-weather`.

**Widget del bar** muestra label compacto ("Drizzle 21°"). **Panel** muestra 5 días.

---

## Calendar

`CalendarPanel.qml` — calendario mensual con navegación por mes/año, día actual resaltado, fines de semana en peach, festivos nacionales en urgent (vía `qs-holidays`, que detecta el país desde `$LANG`), y ubicación actual debajo del título.

- **Activación**: click en el chip del reloj o `Super+C`.
- **Navegación**: botones chevron dibujados en Canvas (`StatusIcon`: `chev-double-left`, `chev-left`, `chev-right`, `chev-double-right`) para año/mes anterior/siguiente. Click en el título vuelve a hoy. Teclado: `←/→` mes, `↑/↓` año, `Enter` hoy.
- **País**: muestra `Ciudad · País` (ej. "Bogotá · Colombia") usando `Weather.city` + `Weather.country`, que vienen de `qs-weather` vía ip-api. Si no hay red, la línea se oculta.
- **Mes correcto**: `Qt.locale().monthName()` en este build de Qt es 0-indexed — se pasa `month - 1`. Si ves el mes corrido, revisá esa línea.
- **Festivos**: `qs-holidays <año>` devuelve `{ "YYYY-MM-DD": "nombre" }`. Hover sobre un día festivo muestra el nombre en tooltip. Leyenda abajo: Hoy / Fin de semana / Festivo.

## Lofi radio

`AudioPanel.qml` tiene una fila dedicada para activar o apagar "Lofi radio". Su invocación ejecuta `~/.local/bin/qs-lofi`:

```sh
~/.local/bin/qs-lofi
# mpv --no-video --really-quiet --load-scripts=no \
#      https://play.streamafrica.net/lofiradio
```

- **Aislamiento MPRIS**: Se ejecuta con `--load-scripts=no` para no cargar plugins MPRIS en D-Bus, evitando colisiones o secuestros de estado con los reproductores multimedia de la barra (`Player.qml`).
- **Activación exclusiva**: Lofi Radio se activa y desactiva exclusivamente desde el panel de **Volume** (`AudioPanel.qml`). Si se reproduce audio en otro reproductor (navegador, Spotify), la radio se detiene limpiamente.

---

## Reminders

`Reminders.qml` + `RemindersOverlay.qml` usan `systemd-run --user --on-active=<seconds>`. 

- **Activación**: `Super+Shift+N` (`sway: bindsym $mod+Shift+n exec /usr/bin/qs ipc call reminders toggle`).
- **Overlay**: input minutes + mensaje → Enter → `qs-reminder "msg"` → timer systemd → IPC `reminder fired`.
- **Chip en bar**: ícono alarm canvas, badge con count.
- **Cuando dispara**: overlay fullscreen durante 5 min con mensaje + minutos, luego cierra.

---

## DND indicator

`widgets/Dnd.qml` lee `Notifs.dnd` y dibuja la campana tachada en peach cuando está activo. Click derecho en la campana (`widgets/NotifBell.qml`) toggle DND.

**Persistencia**: `~/.local/state/quickshell/dnd`.

---

## PluginRegistry

Singleton en `Commons/PluginRegistry.qml`. Catalog first-party: 15 chips + 11 hosts. Layout persistido en `~/.config/quickshell/shell.json`.

Ver `docs/architecture.md` para detalle.

---

## Bar visual editor

`panels/BarEditorPanel.qml`. Tres columnas Left/Center/Right. Cursor por columna (`_cursorArr`).

**Teclado**:

| Tecla | Sin pick | Con pick |
|---|---|---|
| `↑/↓` o `J/K` | cursor ↑/↓ | reorder chip |
| `←/→` | cursor ←/→ | mover a otra columna |
| `Shift` | pick / drop | — |
| `Enter` | toggle on/off | drop |
| `Escape` | cerrar popup | cancel pick |
| `Tab` | cambiar columna | cambiar columna |
| `0-9` | jump a índice | jump a índice |
| `/` | buscar | buscar |

**Hover**: cada chip tiene `MouseArea` que pinta `focusFill` al entrar y restaura la expresión original al salir (`Qt.binding(...)`).

**Persistencia**: Auto-guardado instantáneo. Cada reordenamiento o movimiento entre columnas (Left, Center, Right) se persiste atómicamente a `~/.config/quickshell/shell.json` mediante `PluginRegistry.writeShell()` sin necesidad de botón de guardado manual.

---

## System tray

`widgets/Tray.qml` maneja la bandeja del sistema (SNI/StatusNotifierItem):
- **Ícono representativo**: Dibujado con `StatusIcon.qml` (`icon: "tray"`).
- **Modo colapsable**: Hacer clic en el ícono de bandeja expande o contrae los ítems activos de la bandeja para ahorrar espacio en la barra.

---

## Screenshots / Recordings

- `qs-screenshot`: `grim -g "$(slurp)" ~/Imágenes/screenshots/<timestamp>.png`
- `qs-screenrecord`: `wf-recorder -g "$(slurp)" -f ~/Vídeos/records/<timestamp>.mp4`

Wallpaper picker **omite** `screenshots/` y `records/`.
