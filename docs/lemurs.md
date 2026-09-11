# Lemurs (display manager)

Lemurs es el login TUI de zoi-debian. **No pinta el wallpaper** (no es un greeter gráfico): usa la **paleta** de ese fondo o del tema que elijas. LightDM queda instalado como fallback, deshabilitado.

Por defecto, el primer boot usa los colores extraídos de `assets/default-wallpaper.jpg` (Baby Yoda).

## Quick path

```sh
./scripts/lemurs-setup.sh          # plan
sudo ./scripts/lemurs-setup.sh apply
# reboot — login en TTY2
```

`apply` solo hace `enable`. No arranca Lemurs en caliente. Si `install.sh` avisó fallo pero `systemctl is-enabled lemurs` es `enabled`, era un trap `RETURN`/`set -u` (ya corregido).

## Tema (automático)

Elegir wallpaper o paleta en Quickshell / `zoi-theme set …` reescribe `/etc/lemurs/variables.toml`. Se ve en el **próximo** login.

| Archivo | Rol |
|---|---|
| `/etc/lemurs/config.toml` | Layout (`$variables`). Writable por el usuario de escritorio. |
| `/etc/lemurs/variables.toml` | Hex + títulos. Lo escribe `zoi-theme`. |
| `~/.config/zoi/themed/lemurs-variables.toml` | Copia de la paleta activa |

## Personalizar

| Querés | Archivo | Qué pasa |
|---|---|---|
| Cambiar colores con el resto del desktop | Panel Theme / wallpaper | Automático |
| Títulos, un hex puntual | `~/.config/zoi/lemurs/variables.overlay.toml` | Se mergea encima de la paleta |
| Layout entero (hints, anchos, focus) | `~/.config/zoi/lemurs/config.toml` | Tiene que ser el TOML **completo** (Lemurs v0.4 exige todas las keys). Copiá `/etc/lemurs/config.toml` y editá. |

Ejemplo de overlay:

```sh
cp ~/.config/zoi/lemurs/variables.overlay.toml.example \
   ~/.config/zoi/lemurs/variables.overlay.toml
# editá login_title / accent / …
zoi-theme set wallpaper
```

## First install

`install.sh`:

1. Copia `assets/default-wallpaper.jpg` → `~/Imágenes/baby-yoda-cartoon.jpg`
2. Extrae 22 colores (`qs-theme-from-wallpaper --json`)
3. `zoi-theme apply-json` (Lemurs + el resto)
4. `lemurs-setup.sh apply` (si no hay themed, fallback = paleta Baby Yoda, no tokyo-night)

## Qué no hace

- No borra el paquete `lightdm`
- No hace `systemctl start lemurs` desde una sesión gráfica
- No muestra el jpg en TTY; sí sus colores de fondo, acento y bordes

## Fallback a LightDM

```sh
sudo systemctl disable lemurs.service
sudo systemctl enable lightdm.service
sudo systemctl start lightdm
```

## Checklist

- [ ] `./scripts/lemurs-setup.sh` muestra TTY2 y `/etc/lemurs/wayland/sway`
- [ ] `~/.config/zoi/themed/lemurs-variables.toml` tiene hex del wallpaper o tema actual
- [ ] Después de `apply`, `systemctl is-enabled lemurs` es `enabled`
- [ ] Reboot → login TUI → sesión `sway`
