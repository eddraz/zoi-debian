# Arquitectura

## Visión general

```
┌──────────────────────────────────────────────────────┐
│ sway (window manager)                                │
│   └─ exec_always qs -n --daemonize                   │
│       └─ shell.qml (ShellRoot)                       │
│            ├─ Bar { left/center/right columns }      │
│            ├─ PopupCard { panel by popup name }      │
│            └─ Instantiator { host overlays/services }│
└──────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────┐
│ Singletons (Commons/*.qml) — procesos state         │
│   Color • Style • Popups • Audio • Brightness •      │
│   KeyNav • Media • Weather • Wallpaper • Themes •    │
│   Notifs • Idle • NightLight • Keyboard • Reminders  │
│   Radio • HoverTip • PluginRegistry                  │
└──────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────┐
│ IPC (qs ipc call <target> <method> <args>)           │
│   popups toggle audio                                │
│   session toggle                                     │
│   osd volume +5                                      │
│   launcher toggle                                    │
└──────────────────────────────────────────────────────┘
```

## PluginRegistry

Singleton central que **descubre, valida y persiste** la composición del shell. No es `qs.Ui` ni el sistema de clones de Omarchy: es un registro **first-party** mucho más simple.

### Catalog (dentro de `PluginRegistry.qml`)

```js
catalog = {
  "workspaces": {
    kinds: ["bar-widget"],
    source: "../widgets/Workspaces.qml",
    defaultSection: "left",
    label: "Workspaces"
  },
  "weather": {
    kinds: ["bar-widget", "panel"],
    source: "../widgets/Weather.qml",
    panel: "../panels/WeatherPanel.qml",
    popup: "weather",
    title: "Weather",
    defaultSection: "right"
  },
  "osd": { kinds: ["service"], source: "../Osd.qml" },
  ...
}
```

Cada id declara **kinds** (uno o más de `bar-widget`, `panel`, `service`, `overlay`) y los archivos QML que el host monta dinámicamente.

### Layout persistido (`~/.config/quickshell/shell.json`)

```json
{
  "version": 1,
  "bar": {
    "layout": {
      "left":   ["session", "workspaces", "window"],
      "center": ["reminders", "clock", "weather"],
      "right":  ["keyboard", "media", "audio", ...]
    }
  },
  "disabledPlugins": []
}
```

Un `FileView` con `watchChanges: true` recarga el layout automáticamente cuando se reorganiza desde el Bar editor.

### Loaders por sección

**Bar.qml** carga widgets con un `Repeater` + `ChipLoader` (inline component):

```qml
component ChipLoader: Loader {
    required property var modelData
    source: PluginRegistry.widgetUrl(String(modelData))
    onLoaded: bindChip(item, String(modelData))
}
```

`bindChip` conecta la signal `togglePanel` del widget a `Popups.toggle(meta.popup)` o a un IPC directo (`meta.ipc`).

**shell.qml** carga overlays con un `Instantiator`:

```qml
Instantiator {
    model: PluginRegistry.hostIds
    delegate: Loader {
        required property var modelData
        source: PluginRegistry.hostUrl(String(modelData))
    }
}
```

**PopupCard.qml** carga el panel del popup actual:

```qml
Loader {
    active: screenRoot.popup !== ""
    source: PluginRegistry.panelUrl(screenRoot.popup)
    onLoaded: bindPanel(item)
}
```

### Helpers de mutación

| Helper | Efecto |
|---|---|
| `moveWithinSection(section, from, to)` | swap dentro de la sección |
| `moveToSection(id, fromSec, toSec, idx)` | mover chip entre secciones |
| `togglePlugin(id, enabled)` | prender/apagar en `disabledPlugins[]` |
| `writeShell()` | escribe JSON vía `bash -c 'tmp+rename'` (atómico, dispara FileView) |
| `orderedIds(section)` | `layout[section]` slice |
| `availableBarIds(section)` | chips en catalog con `defaultSection == section` que no están ya en ninguna sección |
| `sectionIndexOf(id)` | -1 si no está, si no índice de sección |
| `panelByPopup(name)` | entry del catalog que tiene `popup == name` |
| `panelUrl(popup)` | URL resuelta del QML del panel |
| `panelMeta(popup)` | entry completo (title, centerCard, cardWidth) |

### Reglas importantes

- **`applyConfig` salta si el JSON no cambió** — si no, el `Instantiator` duplica `IpcHandler`s y ves `WARN scene: QML IpcHandler at @Osd.qml[58:5]: Handler was registered but will not be used because another handler is registered for target osd`.

- **`ChipLoader` no debe bindear `height` a `item.implicitHeight`** — produce `WARN scene: QML ChipLoader at @Bar.qml[42:13]: Binding loop detected for property "height"`.

- **`PopupCard.visiblePanel()` desenvuelve `Loader.item`** — si no, `/`, Tab, J/K, H/L no llegan al panel cargado dinámicamente.

- **El hostOrder de overlays/services importa** — algunos servicios registran IpcHandler en construcción y se duplican si dos coexisten. Mantener `hostOrder` estable en `PluginRegistry.qml`.
- **Markdown no es overlay de qs** — Inlyne es una ventana (`qs-md`). No va en `hostOrder`.

## Hot reload

`FileView` (en `PluginRegistry.qml`):

```qml
FileView {
    path: root.configPath
    watchChanges: true
    printErrors: false
    onLoaded: root.applyConfig(text())
    onFileChanged: reload()
}
```

`Quickshell.Io.FileView` vigila el archivo con inotify. Cuando escribimos vía `writeShell()` con `tmp+rename`, el inotify dispara, `onFileChanged` corre, `reload()` recarga, `onLoaded` aplica, `revision` cambia, todos los `readonly property var XIds: { revision; ... }` se recalculan, los `Repeater` se re-bindea, los `Loader` se montan/desmontan.

## IPC system

Quickshell expone un bus Unix-socket por shell instance. Los targets son globales (no por panel). Si tenés dos shells cargando el mismo QML con IpcHandler al mismo target, **el segundo gana** y el primero ve `WARN scene: QML IpcHandler ... Handler was registered but will not be used`.

Targets registrados en este shell:

- `session` — `Popups.qml` (toggle / open)
- `popups` — `Popups.qml` (toggle / open / close)
- `clipboard` — `Clipboard.qml` (toggle)
- `emojis` — `Emojis.qml` (toggle)
- `reminders` — `Reminders.qml` (toggle)
- `media` — `Media.qml` (toggleArm)
- `osd` — `Osd.qml` (volume / brightness)
- `lock` — `Lock.qml` (lock)

## Singletons vs instances

Todos los servicios en `Commons/` son `pragma Singleton` + `Singleton { ... }` registrados en `Commons/qmldir`. Esto los expone como:

```qml
import "../Commons"
// luego:
Audio.percent
Wallpaper.current
Popups.requested
PluginRegistry.hostIds
```

Los singletons **comparten estado entre importers**. Si importás relativo (sin `qs.Commons`), el singleton se duplica por importer y cada uno tiene su propio `percent` — esto fue un bug en Omarchy que aprendimos a evitar.

**Nombre del archivo = nombre del tipo.** Un widget `widgets/Weather.qml` sombrea el singleton `Commons.Weather`. Dentro del chip, `Weather.label` no es el servicio: el fetch no se monta y el chip se queda en `…`. Importá con alias (`import "../Commons" as Commons` → `Commons.Weather.label`) o no uses el mismo basename. `Reminder.qml` vs `Reminders` no choca; Weather sí.

`shell.qml` fuerza singletons perezosos al boot (`Themes.currentId`, `Weather.ready`) para que existan aunque ningún chip los referencie bien.

**Process restart:** `running = false` seguido de `running = true` en el mismo tick no relanza el proceso. Usá `Qt.callLater` o un `Timer { interval: 0 }`.

## Panel loading pattern

Cada panel en `panels/<X>Panel.qml` es un `Column` (o `Item`) que expone opcionalmente:

- `signal open<Y>` — el panel padre dispara otro popup
- `function handleKey(event)` — recibe keys de PopupCard
- `function handleEscape()` — popup quiere cerrar
- `function nextSection(back)` — para Tab
- `function focusItem(entry)` — para `/` search
- `readonly property var searchEntries` — para `/` search
- `property bool capturing` / `conflictOpen` — KeysPanel captura un combo nuevo; PopupCard le cede el teclado antes de `/` y Super+Q.

`KeysMap` (singleton) es el catálogo de atajos + overrides en `~/.config/zoi/keys.json`. `qs-keys-apply` (exec_always) los empuja a Sway.

`bindPanel(item)` en `Bar.qml` conecta `openKeys/openWallpaper/openTheme/openBar` si existen.

## Estilo y arquitectura de temas

ZOI cuenta con un sistema de temas desacoplado y reactivo de dos niveles:

1. **Nivel UI Quickshell (`Color.qml`, `Themes.qml`, `Wallpaper.qml`)**:
   - El selector es `ThemePanel.qml` → `Themes.apply(id)` (usuario) / `Themes.restore(id)` (boot).
   - `shell.qml` fuerza `Themes.currentId` y `Weather.ready` al arrancar para que esos singletons no dependan de abrir un panel.
   - `Color.qml` hidrata la barra desde `~/.local/state/quickshell/colors.json` (`FileView`, `watchChanges`).
   - `Themes.persist()` escribe ese JSON; `zoi-theme` lo replica en `_dispatch_state` **antes** de GTK/Sway/etc.

2. **Nivel Sistema (`zoi-theme` + Templates `*.tpl`)**:
   - Compilador maestro que procesa plantillas declarativas usando paletas de 22 colores estandarizadas (`colors.toml`).
   - Bloqueo por archivo (`flock`) y staging atómico en `~/.local/state/zoi/theme/current`.
   - Propaga simultáneamente a Foot, Sway, btop, Helix, Zed, VSCode/Antigravity, GTK, Herdr, Yazi, Inlyne y Lemurs (`vtrgb`).
   - Ejecuta hooks de usuario en `~/.config/zoi/hooks/theme-set.d/*`.

## Display manager (Lemurs)

Lemurs vive **fuera** de Quickshell: unidad systemd en TTY2. La paleta llega por `zoi-theme` → `vtrgb` + títulos en `variables.toml`. El PAM es stack de DM Debian (`common-auth`), no `/etc/pam.d/login`. Detalle: [lemurs.md](lemurs.md).

## Tradeoffs y límites

- **No hay plugins de terceros**. First-party only. Discovery en `~/.config/quickshell/plugins/` queda para una versión futura si se justifica.
- **No hay drag visual** (mouse drag & drop) en el Bar editor — sólo teclado. Drag-and-drop en QML es trabajoso y el teclado es suficiente con el modelo pick+arrows.
- **Hot reload a veces pierde foco de teclado**. Si dejás de poder tipear, abrí y cerrá el popup (`Super+Q`).
- **`qs` debe reiniciarse** cuando se agregan nuevos IpcHandler targets (los handlers se registran en `Component.onCompleted`).
- **Lemurs no muestra el jpg**. TTY = 16 colores (`setvtrgb`). Hex solo funciona en `lemurs --preview` dentro de un terminal truecolor.
