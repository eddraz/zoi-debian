# Herdr

[Herdr](https://herdr.dev/) es el multiplexer de terminales para agentes de código. ZOI lo instala con el desktop, le pone `fish` de shell, y `zoi-theme` le pinta la paleta (incl. wallpaper).

## Quick path

`install.sh` ya lo hace. A mano:

```sh
curl -fsSL https://herdr.dev/install.sh | sh
cp ~/zoi-debian/dotfiles/config/herdr/config.toml ~/.config/herdr/config.toml
zoi-theme set wallpaper   # o cualquier paleta
herdr                     # TUI (no lo uses solo para --help de subcomandos)
```

Config: `~/.config/herdr/config.toml`. Recarga en caliente: `herdr server reload-config`.

## Qué escribe ZOI

| Key | Origen |
|---|---|
| `onboarding = false` | skip first-run |
| `[terminal] default_shell` | `/usr/bin/fish` |
| `[theme.custom]` + `[ui] accent` | paleta activa (`zoi-theme`) |
| `[ui.toast] delivery` | `herdr` |

Si el archivo no existe, `zoi-theme` no toca Herdr. El install lo crea antes del primer `apply-json`.

## Relación con el agente

El skill de Herdr solo aplica con `HERDR_ENV=1` (pane gestionado). Fuera de Herdr, no inspecciona la sesión.

## Uninstall

`uninstall.sh` **no** borra el binario ni `~/.config/herdr`. Es software de usuario, como Pi.
