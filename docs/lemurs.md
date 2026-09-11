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

## Authentication failed (contraseña bien)

Si Lemurs dice **authentication failed** y `/var/log/lemurs.log` tiene `Validated account` + `Failed to open a PAM session`, **no es la contraseña**. El PAM viejo hacía `include login`; Debian marca `pam_loginuid` como `required` y eso revienta en un servicio systemd ([lemurs#166](https://github.com/coastalwhite/lemurs/issues/166)).

```sh
sudo install -m 0644 -o root -g root dotfiles/lemurs/lemurs.pam /etc/pam.d/lemurs
# No hace falta reiniciar Lemurs: el próximo intento en TTY2 relee PAM.
```

El switcher solo ofrece **sway** (script Wayland en `/etc/lemurs/wayland/sway`). No uses **Sway** de xsessions: Debian lo registra como X11 y Lemurs espera 60s a Xorg.

## Tema (automático)

TTY2 es consola del kernel: **no hay truecolor**. Los hex del wallpaper se mapean a 16 colores VGA (`setvtrgb`). El config usa nombres ANSI (`black`, `light yellow` = accent). Se ve en el **próximo** arranque de Lemurs.

| Archivo | Rol |
|---|---|
| `/etc/lemurs/vtrgb` | Mapa 16 colores. Lo escribe `zoi-theme`; `ExecStartPre=setvtrgb`. |
| `/etc/lemurs/config.toml` | Layout + nombres ANSI. Writable por el usuario de escritorio. |
| `/etc/lemurs/variables.toml` | Títulos (`$login_title`). Hex solo documenta la paleta. |
| `~/.config/zoi/themed/lemurs.vtrgb` | Copia de la paleta VGA activa |

## Personalizar

| Querés | Archivo | Qué pasa |
|---|---|---|
| Cambiar colores con el resto del desktop | Panel Theme / wallpaper | Automático |
| Títulos (`login_title`) | `~/.config/zoi/lemurs/variables.overlay.toml` | Se mergea encima. Un hex de `accent` **no** pinta el TTY; eso es `vtrgb`. |
| Layout entero (hints, anchos, focus) | `~/.config/zoi/lemurs/config.toml` | Tiene que ser el TOML **completo** (Lemurs v0.4 exige todas las keys). Copiá `/etc/lemurs/config.toml` y editá. |

Ejemplo de overlay:

```sh
cp ~/.config/zoi/lemurs/variables.overlay.toml.example \
   ~/.config/zoi/lemurs/variables.overlay.toml
# editá login_title / password_title
zoi-theme set wallpaper
```

## First install

`install.sh`:

1. Copia `assets/default-wallpaper.jpg` → `~/Imágenes/baby-yoda-cartoon.jpg`
2. Extrae 22 colores (`qs-theme-from-wallpaper --json`)
3. `zoi-theme apply-json` (Lemurs + el resto)
4. `lemurs-setup.sh apply` instala binario, PAM Debian, `vtrgb`, unit con `setvtrgb` (enable, no start). Fallback de paleta = Baby Yoda, no tokyo-night.

## Qué no hace

- No borra el paquete `lightdm`
- No hace `systemctl start lemurs` desde una sesión gráfica
- No muestra el jpg en TTY; sí 16 colores VGA de esa paleta (`vtrgb`)
- No usa hex en el greeter (el kernel VT los ignora)

## Fallback a LightDM

```sh
sudo systemctl disable lemurs.service
sudo systemctl enable lightdm.service
sudo systemctl start lightdm
```

## Checklist

- [ ] `./scripts/lemurs-setup.sh` muestra TTY2, `vtrgb` y `/etc/lemurs/wayland/sway`
- [ ] `cat /etc/lemurs/vtrgb` tiene 3 líneas de 16 enteros
- [ ] `grep ExecStartPre /etc/systemd/system/lemurs.service` muestra `setvtrgb`
- [ ] `/etc/pam.d/lemurs` incluye `common-auth` (no `include login`)
- [ ] Después de `apply`, `systemctl is-enabled lemurs` es `enabled`
- [ ] Reboot → TTY2 → sesión **sway** (Wayland). Si ves **Sway** (X11) el config todavía apunta a `/usr/share/xsessions`.
