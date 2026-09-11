# Lemurs (display manager)

[Lemurs](https://github.com/coastalwhite/lemurs) es el TUI login de zoi-debian. La UI usa la paleta ZOI. LightDM queda instalado como fallback, deshabilitado.

## Quick path

`scripts/install.sh` ya lo llama. A mano:

```sh
./scripts/lemurs-setup.sh          # plan
sudo ./scripts/lemurs-setup.sh apply
# reboot — login en TTY2
```

No arranca Lemurs en caliente: solo `enable` para el próximo boot.

## Tema

| Archivo | Rol |
|---------|-----|
| `/etc/lemurs/config.toml` | Layout fijo; colores vía `$background`, `$accent`, … |
| `/etc/lemurs/variables.toml` | Hex de la paleta activa (ownership del usuario) |
| `~/.config/zoi/themed/lemurs-variables.toml` | Copia que escribe `zoi-theme` |

Elegir un tema (panel o `zoi-theme set …`) reescribe `variables.toml`. Se ve en el **próximo** login (Lemurs no está corriendo dentro de Sway).

## First install + wallpaper

El fondo default **ya está en el repo**: `assets/default-wallpaper.jpg` (idéntico a `~/Imágenes/baby-yoda-cartoon.jpg`).

`install.sh`:

1. Copia el jpg a `~/Imágenes/baby-yoda-cartoon.jpg`
2. Extrae 22 colores con `qs-theme-from-wallpaper --json`
3. `zoi-theme apply-json` (incluye Lemurs + Limine + el resto)
4. `lemurs-setup.sh apply`

## Qué no hace

- No borra el paquete `lightdm`
- No hace `systemctl start lemurs` (evitaría cortar la sesión actual)
- No es un greeter gráfico: no muestra el wallpaper como imagen, sí sus colores (fondo, acento, bordes)

## Fallback a LightDM

```sh
sudo systemctl disable lemurs.service
sudo systemctl enable lightdm.service
sudo systemctl start lightdm
```

## Checklist

- [ ] `./scripts/lemurs-setup.sh` muestra TTY2 y `/etc/lemurs/wayland/sway`
- [ ] `~/.config/zoi/themed/lemurs-variables.toml` tiene hex del tema actual
- [ ] Después de `apply`, `systemctl is-enabled lemurs` es `enabled`
- [ ] Reboot → login TUI → sesión `sway`
