---
name: zoi-debian
description: Maintain, extend, and debug the zoi-debian Quickshell-on-Sway desktop for Debian 13. Use when the user asks to add a bar widget, panel, overlay, IPC handler, shortcut, theme color, screensaver word, or fix a binding / hot-reload / IpcHandler duplicate in this shell.
---

# zoi-debian — AI skill

You are maintaining a Quickshell-based Wayland shell on Debian 13 + Sway. This is a personal repo that mirrors the user's live `~/.config/quickshell/`. Every change here should also be reflected in their live shell, and vice versa.

## Source of truth

```
~/.config/quickshell/                 # live shell (running)
~/projects/zoi-debian/dotfiles/...    # repo snapshot (this skill's tree)
```

When the user edits the live shell **without going through the repo**, the repo drifts. The bootstrap script (`scripts/install.sh`) does `cp -r dotfiles/quickshell/. ~/.config/quickshell/`, so a re-run re-syncs the live shell with the repo.

If you see a difference between live and repo, ask the user which is canonical before assuming.

## Layout primer

```
Commons/        singletons: Audio, Color, Style, Popups, KeyNav, Media, Weather,
                Wallpaper, Themes, Notifs, Idle, NightLight, Keyboard, Reminders,
                Radio, HoverTip, PluginRegistry.
Ui/             PopupCard, HoverMouse, HoverTipLayer, IndexBadge, StatusIcon.
widgets/        one QML per bar chip.
panels/         one QML per PopupCard panel.
```

## PluginRegistry pattern (canonical)

Adding a new bar widget, panel, or overlay:

1. Edit `Commons/PluginRegistry.qml`. Add the entry to the `catalog` map (or, for first-party-only, append inside the same file).
2. If it's a bar widget, add the id to the relevant section in `~/.config/quickshell/shell.json`.
3. If it's a panel, the catalog entry needs `kinds: ["panel"]` (or `bar-widget, panel`) and `popup: "<name>"`. PopupCard will load it on `screenRoot.popup === "<name>"`.
4. If it's an overlay/service, add the id to `hostOrder` in the same file.

After any catalog change, the shell reloads via `FileView`. If you also added a new IPC `target`, you **must restart qs** (`pkill qs && qs -n --daemonize`) because `IpcHandler` registers at `Component.onCompleted`.

## Bar widget template

```qml
import QtQuick
import "../Commons"
import "../Ui"

Item {
    id: root

    signal togglePanel

    implicitWidth: chip.implicitWidth + 6
    implicitHeight: Style.barHeight

    // ... draw your chip with StatusIcon / Text / Rectangle

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePanel()
        onContainsMouseChanged: {
            if (containsMouse) HoverTip.show(root, "My widget");
            else HoverTip.hide();
        }
    }
}
```

If you add the widget to the catalog with `popup: "<name>"`, the host will call `Popups.toggle("<name>")` on click. If `ipc: [...]`, it calls `qs ipc call <ipc>` instead.

## Panel template

```qml
import QtQuick
import "../Commons"
import "../Ui"

Column {
    id: root
    width: parent ? parent.width : 268
    spacing: 6

    signal openOther        // optional; bindPanel wires this

    property int cursor: 0

    function handleEscape() { return false; }
    function nextSection(back) { /* cycle sections */ }
    function focusItem(entry) { cursor = entry.index; }
    readonly property var searchEntries: { /* return array of {label, index} */ }

    function handleKey(event) {
        // J/K, 0-9, Tab, Enter, Escape
    }

    Repeater {
        model: /* ... */
        Rectangle {
            color: root.cursor === index ? Color.focusFill : Color.surface
            border.width: root.cursor === index ? 2 : 0
            border.color: Color.accent
            // ...
        }
    }
}
```

If the panel needs to spawn another popup, expose `signal openX` and add a line in `Bar.qml`:

```js
if (item.openX !== undefined) item.openX.connect(() => Popups.open("x"));
```

## Singletons

New singleton = new file in `Commons/` + add to `Commons/qmldir`:

```
singleton MyService 1.0 MyService.qml
```

Then `import "../Commons"` gives access as `MyService.foo()`.

## Colors and tokens

- Edit `Color.qml` for raw palette.
- Edit `Style.qml` for tokens (barHeight, radius, font).
- Use `Color.focusFill` for tenue highlight (it's `accent` at 0.22 alpha).
- Use `Color.background` for text on solid accent backgrounds only (mute, connected, shutdown).
- Everywhere else, text is `Color.popupText` (the foreground on a surface).

## Themed on wallpapers

`Wallpaper.apply(path)` calls `Themes.refreshFromWallpaper(path)` → spawns `~/.local/bin/qs-theme-from-wallpaper` which extracts 22 dominant colors via Python + GdkPixbuf (gi) with 5-bit color quantization and 7-sector chroma sorting, enforcing WCAG AAA contrast (> 7:1). Palettes are dispatched across the OS via `zoi-theme`.
`Commons/Color.qml` contains a direct `FileView` observer watching `~/.local/state/quickshell/colors.json`, keeping Quickshell instantly synced on boot and theme switches without restarting the daemon.

## Sway integration

- `exec_always /usr/bin/qs -n --daemonize` is the entrypoint.
- IPC from Sway: `bindsym $mod+X exec /usr/bin/qs ipc call <target> <method> <args>`.
- IPC targets are singletons with `IpcHandler { target: "..."; function ...() { ... } }`.

## Common gotchas

1. **`IpcHandler` duplicates**: two instances of `qs` running, or a plugin hot-reloaded with new IpcHandler target. Kill all and restart.
2. **`ChipLoader` binding loop**: don't bind `height: item.implicitHeight`. Use natural sizing.
3. **`PopupCard.visiblePanel()` for Loader**: must unwrap `kid.item` or keyboard won't reach the loaded panel.
4. **`applyConfig` JSON.stringify guard**: if not, `revision++` triggers needless rebuilds that duplicate IpcHandler.
5. **`Quickshell.execDetached` is fire-and-forget**: don't depend on completion. For shell-json write, use `tmp+rename` via bash so `FileView` watches inotify correctly.

## Test workflow

1. Edit live: `nano ~/.config/quickshell/...`.
2. Watch logs: `ls -t /run/user/$(id -u)/quickshell/by-id/*/log.log | head -1 | xargs tail -f`.
3. If you added a new IPC target: restart `qs`.
4. Test interactions: open popup, hit each key, screenshot with `grim` (helps verify visual state).
5. Once stable, mirror change into `~/projects/zoi-debian/dotfiles/...`.

## Useful commands

```sh
# Restart qs cleanly
pkill qs
swaymsg exec /usr/bin/qs -n --daemonize

# Open a popup
qs ipc call popups toggle audio

# Save bar layout from terminal
echo '{"version":1,"bar":{"layout":{"left":["session","workspaces","window"],"center":["reminders","clock","weather"],"right":["keyboard","media","audio","power","bluetooth","network","notifs","dnd","tray"]}},"disabledPlugins":[]}' > ~/.config/quickshell/shell.json

# Inspect plugin registry state (no IPC, but you can grep the catalog)
grep -A 3 '"workspaces":' ~/.config/quickshell/Commons/PluginRegistry.qml

# Screenshot the popup
grim -g "$(swaymsg -t get_tree | python3 -c '...')" /tmp/x.png
```

## Things you should NOT do

- Don't touch `~/.local/bin/qs-*` without updating `dotfiles/local-bin/` — they're identical, drift breaks `install.sh`.
- Don't add new colors to `Color.qml` without a corresponding `Color.focusFill` decision — focus must always match hover visually.
- Don't reorder `hostOrder` without checking that nothing depends on the previous order.
- Don't add `qs.Ui` or `$OMARCHY_PATH` — first-party only.
- Don't try to reload `foot` terminal config with `pkill -SIGUSR1 foot`. Foot does NOT support signal-based reloading. Use the OSC escape sequence mechanism implemented in `zoi-theme._osc_reload_foot` (writes directly to `/dev/pts/*`).
- Don't run `scripts/limine-setup.sh apply` unless the user explicitly asked to change the bootloader. Default is dry-run. Never call it from `install.sh`. Don't uninstall GRUB as part of Limine setup.
- Don't `systemctl start lemurs` from a live graphical session; `lemurs-setup.sh apply` only enables the unit. Don't remove the lightdm package when switching to Lemurs.

## When to update the docs

Any of:

- New feature → `docs/features.md` (one section).
- New shortcut → `docs/shortcuts.md` table.
- New IPC target → `docs/shortcuts.md` "IPC targets" section.
- New package → `docs/install.md`.
- New config file or env var → `docs/configuration.md`.
- New gotcha or fix → `docs/troubleshooting.md`.
- Architectural change → `docs/architecture.md`.

Keep the repo and `~/.config/quickshell/` in sync. After editing the repo, re-run `scripts/install.sh` (idempotent).
