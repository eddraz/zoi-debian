# Assets

`default-wallpaper.jpg` es un dibujo estilo cartoon de Baby Yoda. Se copia a `~/Imágenes/baby-yoda-cartoon.jpg` durante la instalación y queda como:

- Wallpaper activo (`~/.local/state/quickshell/wallpaper`).
- Fondo del lock screen (con overlay negro al 55%).

Para reemplazarlo:

```sh
# Backup del original
cp ~/Imágenes/baby-yoda-cartoon.jpg ~/Imágenes/baby-yoda-cartoon.jpg.bak

# Poné tu propio wallpaper
cp /ruta/a/tu/wallpaper.jpg ~/Imágenes/baby-yoda-cartoon.jpg

# Aplicá
~/.local/bin/qs-wallpaper set ~/Imágenes/baby-yoda-cartoon.jpg
```

O usá `Session → Wallpaper` en el shell.
