# Configuración

Dónde está cada config, qué hace, cómo la cambiás.

## MCP (Model Context Protocol)

ZOI siembra **dos configs paralelos** para que Pi tenga servers MCP activos:

1. **`~/.config/mcp/mcp.json`** — el que lee `pi-mcp-adapter`
   (`pi install npm:pi-mcp-adapter@latest`). Carga lazy, single proxy
   `mcp(...)`. Cubre `chrome-devtools`, `cloudflare-api`, `cloudflare-docs`.
2. **`~/.pi/agent/mcp.json`** — el que Pi lee **nativamente**. Cubre
   `codegraph`, `context7`, `engram`, `mcp` (Cloudflare vía HTTP público).

`pi-mcp-adapter` es la extensión comunitaria porque el core de Pi **no soporta
MCP por diseño del upstream**; aun así Pi trae soporte nativo experimental y
lee `~/.pi/agent/mcp.json` aunque el adapter esté instalado. Por eso ZOI
siembra los dos: el adapter da los servers que requieren stdio / carga lazy
(pesados), y el nativo da los HTTP simples (`context7`, Cloudflare) y los
spawners de binarios Go (`codegraph`, `engram`). Más info sobre el adapter en
https://github.com/nicobailon/pi-mcp-adapter.

### Config sembrado por ZOI (pi-mcp-adapter)

`~/.config/mcp/mcp.json` (path canónico user-global que lee pi-mcp-adapter;
precedencia sobre `~/.pi/agent/mcp.json`, `.mcp.json`, `.pi/mcp.json`):

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "/home/<usuario>/.local/bin/chrome-devtools-mcp",
      "args": []
    },
    "cloudflare-api": {
      "serverUrl": "https://mcp.cloudflare.com/mcp"
    },
    "cloudflare-docs": {
      "serverUrl": "https://docs.mcp.cloudflare.com/mcp"
    }
  }
}
```

| Server | Tipo | Auth | Notas |
|---|---|---|---|
| `chrome-devtools` | stdio | — | Local, apunta al binario `~/.local/bin/chrome-devtools-mcp` que pone ZOI. |
| `cloudflare-api` | HTTP/SSE | OAuth Cloudflare | La primera invocación abre un browser flow contra tu cuenta. |
| `cloudflare-docs` | HTTP/SSE | OAuth Cloudflare | Idem. |

### Config sembrado por ZOI (nativo de Pi)

`~/.pi/agent/mcp.json` (path nativo de Pi; convive con el adapter). Es donde
vive `context7`:

```json
{
  "mcpServers": {
    "codegraph": {
      "args": ["serve", "--mcp"],
      "command": "codegraph"
    },
    "context7": {
      "url": "https://mcp.context7.com/mcp"
    },
    "engram": {
      "args": ["-e", "const { spawn } = require('node:child_process'); …"],
      "command": "node",
      "directTools": false,
      "lifecycle": "lazy"
    },
    "mcp": {
      "url": "https://mcp.cloudflare.com/mcp"
    }
  }
}
```

| Server | Tipo | Auth | Notas |
|---|---|---|---|
| `codegraph` | stdio | — | Binario `codegraph serve --mcp` (PATH). Solo corre cuando Pi lo invoca. |
| `context7` | HTTP | — | **Lookup de docs de librerías** ([context7.com](https://context7.com)). Sin auth, rate-limit por IP. Endpoint público. |
| `engram` | stdio | — | `node` hace spawn de `engram mcp --tools=agent`; respeta `$ENGRAM_BIN`. |
| `mcp` | HTTP | — | Cloudflare MCP vía HTTP público (mismo endpoint que `cloudflare-api` pero por el camino nativo). |

> Hist: antes este config traía `deepwiki` (SSE). El endpoint público murió
> (HTTP 410 en `mcp.deepwiki.com/sse`, verificado Sep 2026). `context7` estaba
> en el preset list de `pi-mcp-adapter` y era la opción preferida para
> lookup de docs; pasó al config nativo para no duplicar servers entre los
> dos paths.

### Comandos

- `/mcp` — panel interactivo: ver servers, tools, estado.
- `/mcp disable <server>` / `/mcp enable <server>` — toggle por server
  (persiste en `.pi/mcp.json` local del proyecto).
- `/reload` — releer la config después de cambios manuales.
- `pi-mcp-adapter init` — detectar configs de Cursor/Claude/Codex y adoptarlos.

### Cambios comunes

- **Sumar un server al adapter**: editá `~/.config/mcp/mcp.json`, agregá la
  entrada bajo `mcpServers`, y corré `/reload` dentro de Pi.
- **Sumar un server al nativo**: editá `~/.pi/agent/mcp.json`. Pi lo relee
  con `/reload` (sin reiniciar).
- **Forzar re-sembrado del config del adapter**: borrá `~/.config/mcp/mcp.json`
  y re-ejecutá `sudo ./scripts/install.sh` (o la parte de
  `install_go_and_gentleman`).
- **Forzar re-sembrado del nativo**: borrá `~/.pi/agent/mcp.json` y re-ejecutá
  `install.sh`. Idempotente: si los 4 servers ya están, no pisa overrides.
- **Desinstalar**: `pi uninstall npm:pi-mcp-adapter` + `scripts/uninstall.sh`
  (limpia `~/.config/mcp/mcp.json` solo si contiene exactamente nuestros servers;
  el nativo en `~/.pi/agent/mcp.json` queda a tu cargo).

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
$files = ~/.local/bin/qs-files
$browser = ~/.local/bin/qs-browser
$menu = /usr/bin/qs ipc call launcher toggle

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
exec_always ~/.local/bin/qs-keys-apply

# Keybindings
bindsym $mod+Escape exec /usr/bin/qs ipc call session toggle
bindsym $mod+slash exec /usr/bin/qs ipc call popups toggle keys
bindsym $mod+q exec /usr/bin/qs ipc call popups close
bindsym $mod+c exec /usr/bin/qs ipc call popups toggle calendar
# Hardware keys (all remain active while Sway is locked)
bindsym --locked XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && /usr/bin/qs ipc call osd volume
bindsym --locked XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && /usr/bin/qs ipc call osd volume
bindsym --locked XF86AudioRaiseVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && /usr/bin/qs ipc call osd volume
bindsym --locked XF86AudioPlay exec playerctl play-pause
bindsym --locked XF86AudioPause exec playerctl play-pause
bindsym --locked XF86AudioNext exec playerctl next
bindsym --locked XF86AudioPrev exec playerctl previous
bindsym --locked XF86MonBrightnessDown exec brightnessctl set 5%- && /usr/bin/qs ipc call osd brightness
bindsym --locked XF86MonBrightnessUp exec brightnessctl set 5%+ && /usr/bin/qs ipc call osd brightness
# ... etc

# Mouse bindings
bindsym --to-code button9 exec /usr/bin/qs ipc call launcher toggle
```

Para aplicar cambios sin reiniciar Sway:

```sh
swaymsg reload
```

Markdown no es un bind de Sway: `qs-md`, `qs-docs` y `qs-md-open` en `~/.local/bin` abren Inlyne.

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
| `theme` | id de paleta activa (`wallpaper`, `tokyo-night`, `gruvbox`, ...) |
| `colors.json` | paleta completa (22 colores). `Color.qml` la carga al boot; `Themes.persist()` la escribe al elegir en Session → Theme |
| `dnd` | `on` o `off` |
| `stay-awake` | `on` o `off` |
| `screensaver-colors` | cache crust+accent para el screensaver TTE |

## Motor de Temas ZOI (`zoi-theme`)

ZOI implementa la arquitectura declarativa de **Omarchy Quatro**, permitiendo aplicar temas unificados a nivel de todo el sistema operativo con paletas normalizadas de 22 colores y plantillas `.tpl`.

### 1. Paleta de 22 Colores Estándar (`colors.toml`)

Cada tema se define en un archivo `colors.toml` con las siguientes 22 variables normalizadas:

```toml
name = "Tokyo Night"
mode = "dark" # "dark" | "light"

# Colores principales
background = "#1a1b26"
foreground = "#c0caf5"
accent = "#7aa2f7"

# Jerarquía de fondos y textos
dark_background = "#16161e"
darker_background = "#0f0f14"
lighter_background = "#24283b"
dark_foreground = "#565f89"
light_foreground = "#cfc9c2"
bright_foreground = "#ffffff"

# Selección y atenuados
selection = "#283457"
muted = "#565f89"

# 8 Colores ANSI estándar
red = "#f7768e"
orange = "#ff9e64"
yellow = "#e0af68"
green = "#9ece6a"
cyan = "#7dcfff"
blue = "#7aa2f7"
magenta = "#bb9af7"
brown = "#8f5e15"

# 6 Colores ANSI brillantes
bright_red = "#ff899d"
bright_yellow = "#f1c37b"
bright_green = "#b1e380"
bright_cyan = "#8ee2ff"
bright_blue = "#8cb2ff"
bright_magenta = "#caa9ff"
```

### 2. Plantillas Declarativas (`*.tpl`)

Ubicadas en `~/.config/zoi/themed/*.tpl` (o `dotfiles/themes/templates/*.tpl`):
- `{{ variable }}`: Inserta el color con `#` (ej: `#7aa2f7`).
- `{{ variable_strip }}`: Inserta el color sin `#` (ej: `7aa2f7` para foot/hex).
- `{{ variable_rgb }}`: Inserta valores RGB separados por coma (ej: `122, 162, 247`).
- `{{ mix c1 c2 25% }}`: Mezcla dos colores con un ratio porcentual o decimal.

Aplicaciones compiladas automáticamente:
- **Foot Terminal**: `~/.config/foot/foot.ini` (Se recargan los colores en terminales activas en tiempo real enviando secuencias de escape OSC al PTY).
- **Sway Window Manager**: `~/.config/sway/theme.conf` + bordes dinámicos vía `swaymsg`
- **btop**: `~/.config/btop/themes/zoi.theme` + `btop.conf`
- **Helix Editor**: `~/.config/helix/themes/zoi.toml` + `config.toml`
- **Zed Editor**: `~/.config/zed/themes/zoi.json` + `settings.json`
- **VSCode / VSCodium**: `settings.json` (`workbench.colorCustomizations`)
- **GTK 3.0 y GTK 4.0 / LibreWolf**: `~/.config/gtk-3.0/gtk.css` y `~/.config/gtk-4.0/gtk.css` + `gsettings prefer-dark/prefer-light` (`libglib2.0-bin`; si falta, el resto del tema igual se aplica)
- **Herdr**: `~/.config/herdr/config.toml` (seed del repo; `zoi-theme` pinta `[theme.custom]`). Guía: [herdr.md](herdr.md).
- **Yazi**: `~/.config/yazi/yazi.toml` (openers; `url = "*.md"`) y `theme.toml` (íconos ASCII).
- **Inlyne**: `~/.config/inlyne/inlyne.toml` (colores `0xRRGGBB`).

### 3. Comandos CLI `zoi-theme`

```sh
# Listar todos los temas disponibles (sistema y usuario)
zoi-theme list

# Aplicar un tema por nombre/ID
zoi-theme set tokyo-night
zoi-theme set catppuccin-mocha
zoi-theme set gruvbox
zoi-theme set nord

# Ver tema actual
zoi-theme current

# Obtener definición de un tema en JSON
zoi-theme get tokyo-night

# Aplicar paleta personalizada desde JSON
zoi-theme apply-json '{"background": "#11111b", "foreground": "#cdd6f4", "accent": "#89b4fa"}'
```

### 4. Hooks de Usuario

Al cambiar de tema, `zoi-theme` ejecuta de forma automática cualquier script ejecutable ubicado en `~/.config/zoi/hooks/theme-set.d/*`, pasándole el `theme_id` como primer argumento.

### 5. Extracción Dinámica desde Fondos de Pantalla

El helper `~/.local/bin/qs-theme-from-wallpaper` extrae la paleta completa de 22 colores con contraste WCAG AAA (> 7:1) a partir de cualquier imagen, oscureciendo fondos con tinte sutil y seleccionando acentos vibrantes. Se aplica inmediatamente al seleccionar un fondo en el panel de **Wallpaper**.

---

## Foot

`~/.config/foot/foot.ini` (generado y gestionado por `zoi-theme`):

```ini
[main]
font=monospace:size=11
pad=8x8
term=xterm-256color
```

Cambiá `font=` para usar otra tipografía (no requiere Nerd Font; los íconos del bar son Canvas).

## Fish

El setup instala **foot + fish** juntos:

- Login shell: `chsh -s /usr/bin/fish`
- Foot: `shell=/usr/bin/fish` en `foot.ini` y `$term = /usr/bin/foot /usr/bin/fish` en Sway
- `~/.config/fish/conf.d/zoi.fish` agrega `~/.local/bin` al PATH (no pisa tu `config.fish`)
- `config.fish` de stock solo se copia si todavía no existe

```fish
# conf.d/zoi.fish
fish_add_path ~/.local/bin
```

## LightDM

Display manager del setup. Sesión Sway. Un re-run de `install.sh` deshabilita leftovers de Lemurs y hace `enable` de LightDM (sin arrancarlo en caliente).

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

Session → Theme → clic en la paleta. Es la fuente de verdad de Quickshell:

1. `Themes.apply(id)` pinta `Color.*` en vivo y escribe `theme` + `colors.json`.
2. `qs-theme-apply` → `zoi-theme` propaga Foot/Sway/GTK/etc. (fan-out, no el selector).
3. Al boot, `shell.qml` instancia `Themes`; `restore(id)` hidrata el **ACTIVO** del panel **sin** volver a despachar. `Color.qml` lee `colors.json` directo.

No hace falta `zoi-theme set` para que la barra recuerde el tema.

### Cambiar screensaver text

```sh
echo "KOI" > ~/.config/quickshell/screensaver.txt
```

Próximo screensaver muestra "KOI".

### Cambiar la ciudad del weather

`qs-weather` geolocaliza por IP (`ip-api.com`). Si eso falla, usa Bogotá. Editá el dict `DEFAULT` en `~/.local/bin/qs-weather` (y el mismo archivo en `dotfiles/local-bin/`):

```python
DEFAULT = {
    "city": "Bogotá",
    "country": "Colombia",
    "countryCode": "CO",
    "lat": 4.6097,
    "lon": -74.0817,
}
```

Clic medio en el chip, Enter en el panel, o `qs ipc call weather refresh`. El último JSON queda en `~/.cache/quickshell/weather.json` para el próximo boot (el chip no espera 20 min si al login todavía no hay red: backoff 3s–60s). `install.sh` crea ese directorio. No hace falta reiniciar `qs` si el helper ya está en `~/.local/bin`.

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
