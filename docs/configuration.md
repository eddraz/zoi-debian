# Configuración

Dónde está cada config, qué hace, cómo la cambiás.

## Sway

`~/.config/sway/config`

```ini
# Variables
$mod = Mod4                    # Super
$right = l                     # vim right
$down = j
$up = k
$left = h
$term = /usr/bin/foot /usr/bin/fish
$menu = ~/.local/bin/zoi-launcher

# Default border
default_border pixel 1
titlebar off

# Output config (eDP-1 es la laptop; HDMI-A-1 si conectás un monitor)
output eDP-1 resolution 1366x768 position 0,0

# Input
input type:keyboard { xkb_layout latam,us; xkb_options grp:alt_shift_toggle }
input type:touchpad { tap enabled; natural_scroll enabled; click_method clickfinger; pointer_accel 0.25 }

# Idle / screensaver
exec swayidle -w \
    timeout 150 ~/.local/bin/qs-screensaver \
    timeout 300 swaymsg 'output * power off'; qs ipc call lock lock \
    timeout 330 swaymsg 'output * power off' \
    resume ~/.local/bin/qs-screensaver stop; swaymsg 'output * power on' \
    before-sleep qs-screensaver stop; qs ipc call lock lock

# Arrancar qs en lugar de waybar
exec_always /usr/bin/qs -n --daemonize

# Keybindings
bindsym $mod+Escape exec /usr/bin/qs ipc call session toggle
bindsym $mod+q exec /usr/bin/qs ipc call popups close
bindsym $mod+c exec /usr/bin/qs ipc call popups toggle calendar
# ... etc

# Mouse bindings
bindsym --to-code button9 exec /usr/bin/qs ipc call launcher toggle
```

Para aplicar cambios sin reiniciar Sway:

```sh
swaymsg reload
```

## Quickshell

### `~/.config/quickshell/shell.json`

Layout de la barra y plugins deshabilitados. **NO editar a mano en caliente** — el FileView está observando. Usá el Bar editor (`Super+Shift+B`) o editá y dejá que el watcher recargue.

### `~/.config/quickshell/screensaver.txt`

Una línea con la palabra que el screensaver TTE muestra como banner. Default `ZOI`. Cambialo a lo que quieras, en minúsculas o mayúsculas, sin espacios.

### Estado runtime

`~/.local/state/quickshell/`:

| Archivo | Contenido |
|---|---|
| `night-light` | `on` o `off` |
| `wallpaper` | path absoluto al wallpaper activo |
| `theme` | id de paleta activa (`mocha`, `macchiato`, ...) |
| `dnd` | `on` o `off` |
| `stay-awake` | `on` o `off` |
| `screensaver-colors` | cache de los colores derivados del wallpaper (escrito por `qs-theme-from-wallpaper`) |

## Foot

`~/.config/foot/foot.ini`

```ini
[main]
font=monospace:size=11
pad=8x8
term=xterm-256color

[colors]
# Catppuccin Mocha
background=1e1e2e
foreground=cdd6f4
regular0=45475a
...
```

Cambiá `font=` para usar otra tipografía (no requiere Nerd Font; los íconos del bar son Canvas).

## Fish

`~/.config/fish/config.fish` (lo crea `fish` por defecto). Seteá:

```fish
set -gx PATH ~/.local/bin $PATH
set -gx EDITOR hx   # o nano, vim, lo que prefieras
```

## LightDM

Si querés autologin, editá `/etc/lightdm/lightdm.conf`:

```ini
[Seat:*]
autologin-user=eddraz
autologin-session=sway
```

## Variables de entorno relevantes

| Variable | Default | Efecto |
|---|---|---|
| `QS_NO_RELOAD_POPUP` | (unset) | En `shell.qml` como `//@ pragma Env QS_NO_RELOAD_POPUP=1` para evitar popups de reload |
| `XDG_CURRENT_DESKTOP` | `sway` | Necesario para algunos portales XDG |
| `XDG_SESSION_TYPE` | `wayland` | Para apps que preguntan |
| `WAYLAND_DISPLAY` | (auto) | El socket de Wayland |
| `LANG` / `LC_ALL` | `es_CO.UTF-8` | Locale (Bogotá) |

## Quickshell system service (opcional)

Si querés que `qs` arranque al inicio **antes** de Sway (por ejemplo para que el wallpaper se vea en el lightdm-gtk-greeter), activá:

```sh
systemctl --user enable qs.service
```

(no incluido por default — depende de `qs --service` y de cómo configures tu greeter).

## Logs y debug

### Logs de Quickshell

```sh
# Última shell instance (ruta cambia cada restart)
ls -t /run/user/$(id -u)/quickshell/by-id/*/log.log | head -1 | xargs tail -f

# O por shell-id fijo (configurable)
journalctl --user -u quickshell -f
```

### Crashes

`~/.cache/quickshell/crashes/<shell-id>/` — coredump + stacktrace. Si el shell crashea con `Failed to load configuration`, abrí ese directorio.

### Logs de swayidle

`journalctl --user -u swayidle -f` (si lo arrancás como user service).

### Logs de cliphist

`~/.cache/qs-cliphist.log` (si lo redirigís).

### Habilitar QML verbose

```sh
QSG_INFO=1 QT_LOGGING_RULES="*.debug=true" qs -n
```

(no lo hagas en producción — es muy ruidoso).

## Cambios comunes

### Cambiar el layout de la barra

**Recomendado**: usar el Bar editor (`Super+Shift+B`). Al reordenar o mover chips entre Left/Center/Right los cambios se guardan automáticamente.

**Manual**:

```sh
# Editar
nano ~/.config/quickshell/shell.json
# Layout por defecto:
{
  "bar": {
    "layout": {
      "left": ["session", "workspaces", "window"],
      "center": ["reminders", "clock", "weather"],
      "right": ["keyboard", "media", "audio", "power", "bluetooth", "network", "notifs", "dnd", "tray"]
    }
  }
}
```

Guardá, y `qs` recarga solo.

### Cambiar wallpaper default

Reemplazá el archivo en `~/Imágenes/baby-yoda-cartoon.jpg` y aplicá desde Session → Wallpaper, o:

```sh
~/.local/bin/qs-wallpaper set /ruta/a/nuevo/wallpaper.jpg
```

### Cambiar la paleta

Session → Theme → clic en la paleta. Se aplica en vivo.

### Cambiar screensaver text

```sh
echo "KOI" > ~/.config/quickshell/screensaver.txt
```

Próximo screensaver muestra "KOI".

### Cambiar la ciudad del weather

Editá `~/.local/bin/qs-weather`:

```sh
LAT="4.6"
LON="-74.0"   # Bogotá default; cambialo a tu ciudad
```

### Ajustar el timeout del screensaver / lock

`sway/config`:

```ini
timeout 150 ~/.local/bin/qs-screensaver      # screensaver a 150s
timeout 300 swaymsg 'output * power off'; qs ipc call lock lock   # lock + DPMS a 300s
timeout 330 swaymsg 'output * power off'    # DPMS forzado a 330s
```

`swaymsg reload` después.

### Personalizar atajos

`sway/config` → `bindsym $mod+X exec ...`. `swaymsg reload`.

### Desactivar una feature

Session → Theme no tiene off — pero podés deshabilitar el plugin en `shell.json`:

```json
{
  "bar": {
    "layout": {
      "left": ["session", "workspaces", "window"],
      "center": ["reminders", "clock", "weather"],
      "right": ["keyboard", "media", "audio", "power", "bluetooth", "network", "notifs", "dnd", "tray"]
    }
  },
  "disabledPlugins": ["weather"]
}
```

El chip de weather desaparece de la barra y `Weather.qml` no se monta como overlay.

Para deshabilitar un overlay (launcher, lock, etc.), editá `PluginRegistry.qml` y quitá el id de `hostOrder`.

### Cambiar idioma del teclado

`sway/config`:

```ini
input type:keyboard {
    xkb_layout latam,us
    xkb_options grp:alt_shift_toggle
}
```

Cambiá `latam` por `es`, `latam`, `de`, etc. Para más layouts, agregá separados por coma.

`grp:alt_shift_toggle` cambia con `Alt+Shift`. Otras variantes:
- `grp:win_space_toggle` — Super+Space (choca con Launcher)
- `grp:ctrl_shift_toggle` — Ctrl+Shift
- `grp:caps_toggle` — Caps Lock
