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

## Panel loading pattern

Cada panel en `panels/<X>Panel.qml` es un `Column` (o `Item`) que expone opcionalmente:

- `signal open<Y>` — el panel padre dispara otro popup
- `function handleKey(event)` — recibe keys de PopupCard
- `function handleEscape()` — popup quiere cerrar
- `function nextSection(back)` — para Tab
- `function focusItem(entry)` — para `/` search
- `readonly property var searchEntries` — para `/` search

`bindPanel(item)` en `Bar.qml` conecta `openKeys/openWallpaper/openTheme/openBar` si existen.

## Estilo y tema

`Commons/Color.qml` expone las **writable properties** del Singleton. `Themes.qml` las cambia cuando el usuario elige paleta. `Wallpaper.qml` (al aplicar wallpaper) llama a `Themes.refreshFromWallpaper(path)` que deriva colores via `qs-theme-from-wallpaper` (Python+Pillow) y aplica como accent + foreground.

Los popups y widgets leen `Color.accent`, `Color.surface`, etc. directamente, así que cambian en vivo sin reload.

## Tradeoffs y límites

- **No hay plugins de terceros**. First-party only. Discovery en `~/.config/quickshell/plugins/` queda para una versión futura si se justifica.
- **No hay drag visual** (mouse drag & drop) en el Bar editor — sólo teclado. Drag-and-drop en QML es trabajoso y el teclado es suficiente con el modelo pick+arrows.
- **Hot reload a veces pierde foco de teclado**. Si dejás de poder tipear, abrí y cerrá el popup (`Super+Q`).
- **`qs` debe reiniciarse** cuando se agregan nuevos IpcHandler targets (los handlers se registran en `Component.onCompleted`).
