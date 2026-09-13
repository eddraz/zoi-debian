# Shared by install.sh and install-waybar.sh.
# K2-Horizon GGUF needs llama.cpp with K2 Horizon arch (not stock Homebrew yet).
# Fork: https://github.com/MBZUAI-IFM/llama.cpp/tree/model/K2Horizon
# Model: https://huggingface.co/IFM/K2-Horizon-0.9B-GGUF

K2_MODEL_DIR="${K2_MODEL_DIR:-$HOME/models}"
K2_MODEL_FILE="${K2_MODEL_FILE:-K2-Horizon-1B-BF16.gguf}"
K2_MODEL_URL="${K2_MODEL_URL:-https://huggingface.co/IFM/K2-Horizon-0.9B-GGUF/resolve/main/K2-Horizon-1B-BF16.gguf?download=true}"
K2_LLAMA_SRC="${K2_LLAMA_SRC:-$HOME/apps/llama.cpp}"
K2_LLAMA_PREFIX="${K2_LLAMA_PREFIX:-$HOME/apps/llama.cpp}"

download_k2_horizon_gguf() {
  local dest="$K2_MODEL_DIR/$K2_MODEL_FILE"
  mkdir -p "$K2_MODEL_DIR"
  if [ -f "$dest" ] && [ "$(stat -c%s "$dest" 2>/dev/null || echo 0)" -gt 100000000 ]; then
    log "K2-Horizon GGUF ya está en $dest."
    return 0
  fi
  log "Descargando K2-Horizon-1B-BF16.gguf → $dest (~1.8 GB, BF16)."
  if curl -fL --retry 3 -C - -o "$dest.partial" "$K2_MODEL_URL"; then
    mv -f "$dest.partial" "$dest"
    log "Modelo listo: $dest"
  else
    warn "No pude descargar el GGUF. URL: $K2_MODEL_URL"
    return 0
  fi
}

install_llama_k2horizon() {
  local jobs
  if [ -x "$HOME/.local/bin/llama-cli" ] && [ -x "$HOME/.local/bin/llama-server" ]; then
    log "llama.cpp ya está en ~/.local/bin (desde ~/apps/llama.cpp)."
    return 0
  fi
  log "Clonando y compilando llama.cpp en ~/apps/llama.cpp (branch model/K2Horizon). No se usa Homebrew."
  $SUDO apt-get install -y --no-install-recommends cmake libcurl4-openssl-dev || \
    warn "Faltan cmake/libcurl para compilar llama.cpp."
  command -v cmake >/dev/null 2>&1 || { warn "Sin cmake; no compilo llama-k2."; return 0; }
  mkdir -p "$HOME/apps" "$K2_LLAMA_PREFIX" "$HOME/.local/bin"
  if [ -d "$K2_LLAMA_SRC/.git" ]; then
    git -C "$K2_LLAMA_SRC" fetch --depth 1 origin model/K2Horizon || true
    git -C "$K2_LLAMA_SRC" checkout model/K2Horizon || true
  else
    git clone --depth 1 -b model/K2Horizon https://github.com/MBZUAI-IFM/llama.cpp.git "$K2_LLAMA_SRC" || {
      warn "No pude clonar MBZUAI-IFM/llama.cpp (branch model/K2Horizon)."
      return 0
    }
  fi
  jobs="$(nproc 2>/dev/null || echo 2)"
  if cmake -S "$K2_LLAMA_SRC" -B "$K2_LLAMA_SRC/build" -DCMAKE_BUILD_TYPE=Release \
    && cmake --build "$K2_LLAMA_SRC/build" -j"$jobs" --target llama-cli llama-server; then
    k2_cli="$(find "$K2_LLAMA_SRC/build" -type f -name llama-cli -perm /111 | head -n 1)"
    k2_srv="$(find "$K2_LLAMA_SRC/build" -type f -name llama-server -perm /111 | head -n 1)"
    if [ -n "$k2_cli" ] && [ -n "$k2_srv" ]; then
      install -m 755 "$k2_cli" "$HOME/.local/bin/llama-cli"
      install -m 755 "$k2_srv" "$HOME/.local/bin/llama-server"
      ln -sfn "$HOME/.local/bin/llama-cli" "$HOME/.local/bin/llama-k2-cli"
      ln -sfn "$HOME/.local/bin/llama-server" "$HOME/.local/bin/llama-k2-server"
      log "llama-cli / llama-server → ~/.local/bin (fuente ~/apps/llama.cpp)"
    else
      warn "El build no dejó llama-cli/llama-server."
    fi
  else
    warn "Build de llama.cpp K2-Horizon falló."
  fi
}

install_k2_wrappers() {
  local model="$K2_MODEL_DIR/$K2_MODEL_FILE"
  mkdir -p "$HOME/.local/bin"
  cat > "$HOME/.local/bin/k2-chat" <<EOF
#!/bin/sh
# K2-Horizon-0.9B via llama.cpp fork. GGUF includes chat template.
# Default ctx 8192 (practical). 128K needs YaRN + lots of RAM:
#   k2-chat -c 131072 --rope-scaling yarn --rope-scale 16 --yarn-orig-ctx 8192
MODEL="\${K2_MODEL:-$model}"
BIN="\${K2_LLAMA_CLI:-\$HOME/.local/bin/llama-k2-cli}"
if [ ! -x "\$BIN" ]; then
  echo "Falta \$BIN (fork K2-Horizon). Re-corré install.sh." >&2
  exit 1
fi
if [ ! -f "\$MODEL" ]; then
  echo "Falta \$MODEL" >&2
  exit 1
fi
exec "\$BIN" -m "\$MODEL" --jinja -cnv -c "\${K2_CTX:-8192}" -n "\${K2_N:-512}" "\$@"
EOF
  cat > "$HOME/.local/bin/k2-server" <<EOF
#!/bin/sh
MODEL="\${K2_MODEL:-$model}"
BIN="\${K2_LLAMA_SERVER:-\$HOME/.local/bin/llama-k2-server}"
if [ ! -x "\$BIN" ]; then
  echo "Falta \$BIN (fork K2-Horizon). Re-corré install.sh." >&2
  exit 1
fi
if [ ! -f "\$MODEL" ]; then
  echo "Falta \$MODEL" >&2
  exit 1
fi
exec "\$BIN" -m "\$MODEL" --jinja --host "\${K2_HOST:-127.0.0.1}" --port "\${K2_PORT:-8080}" -c "\${K2_CTX:-8192}" "\$@"
EOF
  chmod 755 "$HOME/.local/bin/k2-chat" "$HOME/.local/bin/k2-server"
}

install_k2_horizon() {
  download_k2_horizon_gguf
  install_llama_k2horizon
  install_k2_wrappers
}
