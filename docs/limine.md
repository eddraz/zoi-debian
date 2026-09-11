# Limine (opcional)

Cómo arrancar Debian 13 UEFI con [Limine](https://github.com/Limine-Bootloader/Limine) **sin tocar GRUB**. El bootstrap de zoi-debian no instala Limine.

## Quick path

1. Revisá el plan (no escribe nada):

   ```sh
   ./scripts/limine-setup.sh
   ```

2. Si el preview está bien (fish: un comando; `sudo curl` a veces no resuelve GitHub):

   ```sh
   bash ./scripts/apply-limine.sh --make-default
   ```

3. Reboot. En el menú debería aparecer `Debian <versión>` (el más nuevo primero).

## Qué hace y qué no

| Hace | No hace |
|------|---------|
| Copia `BOOTX64.EFI` a `$ESP/EFI/limine/` | No desinstala `grub-efi-amd64` ni `shim` |
| Escribe `/boot/limine/limine.conf` (temeable) | No deja `limine.conf` en la ESP (taparía el tema) |
| Crea una entrada NVRAM `Limine` | No enciende Secure Boot ni firma el binario |
| Instala `/etc/kernel/postinst.d/zz-limine` | No se corre desde `scripts/install.sh` |
| `--make-default` pone Limine primero en `BootOrder` | No chainloadea Windows ni otros discos |

Upstream: tarball binario `limine-binary.tar.xz` (pin `LIMINE_VERSION`, default `12.9.0`). No compila nada.

## Requisitos

- UEFI (hay `/sys/firmware/efi`).
- ESP montado en `/boot/efi`.
- Secure Boot **off**. Limine no viene firmado para `shimx64.efi`.
- `curl`, `tar`, `efibootmgr` (este último solo en `apply`).
- Pares `/boot/vmlinuz-*` + `/boot/initrd.img-*`.

## Comandos

| Comando | Efecto |
|---------|--------|
| `./scripts/limine-setup.sh` | Plan / dry-run |
| `sudo ./scripts/limine-setup.sh apply` | Instala EFI + conf + NVRAM; GRUB sigue primero |
| `sudo ./scripts/limine-setup.sh apply --make-default` | Igual y Limine queda primero |
| `sudo ./scripts/limine-setup.sh update-config` | Regenera `limine.conf` (también lo hace el hook de kernel) |
| `./scripts/limine-setup.sh status` | ESP, UUID, presencia de archivos, NVRAM |

Variables: `LIMINE_VERSION`, `LIMINE_URL`, `ESP_MOUNT`, `LIMINE_LABEL`.

## Colores del menú (zoi-theme)

Sí: el tema activo pinta Limine. `zoi-theme` renderiza `limine.conf.tpl` (branding, paleta ANSI, fondo/texto) a `~/.config/zoi/themed/limine.conf` y, si `/boot/limine` es escribible, arma el `limine.conf` vivo (colores + kernels).

Por eso el EFI vive en la ESP y el **config no**: un `limine.conf` al lado de `BOOTX64.EFI` taparía `/boot/limine/limine.conf`.

`limine-setup.sh apply` crea `/boot/limine` con ownership del usuario para que un `zoi-theme set …` (o elegir paleta en Theme) actualice el menú **sin sudo**. El cambio se ve en el **próximo** boot (Limine no está corriendo ahora).

Si Limine todavía no está instalado, igual se escribe el snippet temeado; `apply` lo usa al armar el conf.

## Cómo se resuelven kernel e initrd

El kernel vive en ext4 (`/boot` sobre `/`), no en la ESP. Limine lo lee con el UUID del filesystem:

```
path: guid(<UUID-de-/>):/boot/vmlinuz-<ver>
module_path: guid(<UUID-de-/>):/boot/initrd.img-<ver>
cmdline: root=UUID=<UUID-de-/> ro quiet
```

`guid(...)` es alias de `uuid(...)` en Limine.

## Fallback a GRUB

GRUB queda. Si Limine no arranca:

1. En firmware, elegí la entrada `debian` (`\EFI\debian\shimx64.efi`).
2. O, desde un live USB: `efibootmgr -o <id-debian>,...`

No borres paquetes GRUB hasta tener **varios** boots buenos con Limine.

## Secure Boot

No soportado por este helper. Si lo necesitás: firmar `BOOTX64.EFI`, enrolar la clave, y `limine enroll-config` con hash BLAKE3 de 128 bytes (`b3sum --length 128 limine.conf`). Ver [USAGE.md](https://github.com/limine-bootloader/limine/blob/trunk/USAGE.md).

## Checklist

- [ ] `./scripts/limine-setup.sh` muestra los kernels que esperás
- [ ] `apply` copió `BOOTX64.EFI` y `limine.conf` (hace falta root: el ESP tiene `fmask=0077`)
- [ ] `efibootmgr` lista `Limine`
- [ ] Un reboot de prueba **antes** de `--make-default` (elige Limine a mano en el firmware)
- [ ] Recién ahí `--make-default`
- [ ] Un `apt install linux-image-...` regenera el menú vía `zz-limine`

## Next step

Si algo falla al bootear: [troubleshooting.md](troubleshooting.md#limine-no-arranca-debian).
