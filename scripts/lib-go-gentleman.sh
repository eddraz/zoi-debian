# Shared by install.sh and install-waybar.sh.
# Expects: log, warn, SUDO. Optional: ARCH.
# Installs official Go (>= 1.25.10) plus Gentle-AI, Engram, and gentle-pi.

go_semver_lt() {
  local a="$1" b="$2"
  [ "$(printf '%s\n' "$a" "$b" | sort -V | head -n 1)" = "$a" ] && [ "$a" != "$b" ]
}

install_go_lang() {
  local need="1.25.10" have="" go_arch tarball sha json ver tmp url
  export PATH="/usr/local/go/bin:${HOME}/go/bin:${PATH}"
  if command -v go >/dev/null 2>&1; then
    have="$(go version 2>/dev/null | awk '{print $3}' | sed 's/^go//')"
  fi
  if [ -n "$have" ] && ! go_semver_lt "$have" "$need"; then
    log "Go ya está en $have."
    return 0
  fi
  case "${ARCH:-$(dpkg --print-architecture 2>/dev/null || echo amd64)}" in
    amd64|x86_64) go_arch="amd64" ;;
    arm64|aarch64) go_arch="arm64" ;;
    *)
      warn "Go oficial no tiene tarball para ${ARCH:-unknown}; salteo."
      return 0
      ;;
  esac
  log "Instalando Go (oficial go.dev, hace falta ${need}+ para Gentle-AI)."
  json="$(curl -fsSL 'https://go.dev/dl/?mode=json')" || json=""
  if [ -z "$json" ]; then
    warn "No pude leer https://go.dev/dl/?mode=json."
    return 0
  fi
  ver="$(printf '%s' "$json" | python3 -c '
import json, sys
arch = sys.argv[1]
data = json.load(sys.stdin)
for rel in data:
    if not rel.get("stable"):
        continue
    for f in rel.get("files") or []:
        if f.get("os") == "linux" and f.get("arch") == arch and f.get("kind") == "archive":
            print(rel.get("version", "").lstrip("go"))
            print(f.get("filename", ""))
            print(f.get("sha256", ""))
            raise SystemExit(0)
' "$go_arch")" || ver=""
  tarball="$(printf '%s\n' "$ver" | sed -n '2p')"
  sha="$(printf '%s\n' "$ver" | sed -n '3p')"
  ver="$(printf '%s\n' "$ver" | sed -n '1p')"
  if [ -z "$tarball" ] || [ -z "$sha" ]; then
    warn "No pude resolver el tarball de Go para linux-${go_arch}."
    return 0
  fi
  url="https://go.dev/dl/${tarball}"
  tmp="$(mktemp -d)"
  if ! curl -fL "$url" -o "$tmp/go.tgz"; then
    rm -rf "$tmp"
    warn "No pude descargar $url."
    return 0
  fi
  if ! echo "${sha}  ${tmp}/go.tgz" | sha256sum -c --status; then
    rm -rf "$tmp"
    warn "SHA256 de Go no coincide; no instalo."
    return 0
  fi
  $SUDO rm -rf /usr/local/go
  if $SUDO tar -C /usr/local -xzf "$tmp/go.tgz"; then
    log "Go $(/usr/local/go/bin/go version 2>/dev/null || echo "v$ver") → /usr/local/go"
  else
    warn "tar de Go falló."
  fi
  rm -rf "$tmp"
  export PATH="/usr/local/go/bin:${HOME}/go/bin:${PATH}"
}

install_gentleman_stack() {
  local gobin
  export PATH="/usr/local/go/bin:${HOME}/go/bin:${PATH}"
  gobin="${HOME}/go/bin"
  mkdir -p "$gobin"
  export GOPATH="${GOPATH:-$HOME/go}"
  export GOBIN="$gobin"
  export GOPROXY="${GOPROXY:-https://proxy.golang.org,direct}"
  export CGO_ENABLED=1

  if ! command -v go >/dev/null 2>&1; then
    warn "Sin go; no instalo Gentle-AI / Engram."
  else
    if command -v gentle-ai >/dev/null 2>&1; then
      log "gentle-ai ya está en PATH."
    else
      log "Instalando Gentle-AI (go install @latest)."
      go install github.com/gentleman-programming/gentle-ai/v2/cmd/gentle-ai@latest || \
        warn "go install gentle-ai falló. Fallback: curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash"
    fi
    if command -v engram >/dev/null 2>&1; then
      log "engram ya está en PATH."
    else
      log "Instalando Engram (go install @latest)."
      go install github.com/Gentleman-Programming/engram/cmd/engram@latest || \
        warn "go install engram falló. Docs: https://github.com/Gentleman-Programming/engram"
    fi
  fi

  if command -v pi >/dev/null 2>&1; then
    if pi list 2>/dev/null | grep -qi 'gentle-pi'; then
      log "gentle-pi ya está en Pi."
    else
      log "Instalando gentle-pi (pi install npm:gentle-pi@latest)."
      pi install npm:gentle-pi@latest || warn "pi install gentle-pi falló."
    fi
  else
    warn "Sin pi; no instalo gentle-pi. Después: pi install npm:gentle-pi@latest"
  fi

  if command -v gga >/dev/null 2>&1; then
    log "gga (Gentleman Guardian Angel) ya está en PATH."
  else
    log "Instalando Gentleman Guardian Angel (gga)."
    mkdir -p "$HOME/.local/bin"
    gga_brew=""
    if command -v brew >/dev/null 2>&1; then
      gga_brew="$(command -v brew)"
    elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
      gga_brew=/home/linuxbrew/.linuxbrew/bin/brew
    elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
      gga_brew="$HOME/.linuxbrew/bin/brew"
    fi
    if [ -n "$gga_brew" ]; then
      eval "$("$gga_brew" shellenv)" 2>/dev/null || true
      "$gga_brew" install gentleman-programming/tap/gga || warn "brew no pudo instalar gga."
    fi
    if ! command -v gga >/dev/null 2>&1; then
      gga_tmp="$(mktemp -d)"
      if git clone --depth 1 https://github.com/Gentleman-Programming/gentleman-guardian-angel.git "$gga_tmp/gga" \
        && (cd "$gga_tmp/gga" && ./install.sh); then
        log "gga instalado desde el repo."
      else
        warn "No pude instalar gga. Docs: https://github.com/Gentleman-Programming/gentleman-guardian-angel"
      fi
      rm -rf "$gga_tmp"
    fi
  fi
}

install_codegraph_and_chrome_mcp() {
  mkdir -p "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:${PATH}"

  if command -v codegraph >/dev/null 2>&1; then
    log "codegraph ya está en PATH."
  else
    log "Instalando CodeGraph."
    if curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh; then
      log "codegraph instalado (install.sh)."
    elif command -v npm >/dev/null 2>&1; then
      npm install -g --prefix "$HOME/.local" @colbymchenry/codegraph || \
        warn "npm no pudo instalar @colbymchenry/codegraph."
    else
      warn "Sin npm; no instalo codegraph. https://github.com/colbymchenry/codegraph"
    fi
  fi
  # No `codegraph install --yes`: eso cablea Claude/Cursor/Copilot/…. Solo PATH.

  if command -v chrome-devtools-mcp >/dev/null 2>&1; then
    log "chrome-devtools-mcp ya está en PATH."
  elif command -v npm >/dev/null 2>&1; then
    log "Instalando chrome-devtools-mcp (npm -g)."
    npm install -g --prefix "$HOME/.local" chrome-devtools-mcp || \
      warn "npm no pudo instalar chrome-devtools-mcp."
  else
    warn "Sin npm; no instalo chrome-devtools-mcp. npx -y chrome-devtools-mcp@latest"
  fi
}

install_cloudflare_mcp_servers() {
  # Solo Pi (skills). Como Herdr: no se cablea a todos los IDEs.
  # Los servers MCP de Cloudflare los cablea install_pi_mcp_adapter, no este bloque.
  # https://developers.cloudflare.com/agents/model-context-protocol/cloudflare/servers-for-cloudflare/
  local dest skills_tmp pi_skills
  log "Cloudflare skills para Pi."
  mkdir -p "$HOME/.pi/agent/skills"
  pi_skills="$HOME/.pi/agent/skills"
  if [ ! -f "$pi_skills/cloudflare/SKILL.md" ]; then
    skills_tmp="$(mktemp -d)"
    if git clone --depth 1 https://github.com/cloudflare/skills.git "$skills_tmp/skills"; then
      dest="$HOME/.local/share/zoi/cloudflare-skills"
      rm -rf "$dest"
      mkdir -p "$dest" "$pi_skills"
      cp -a "$skills_tmp/skills/." "$dest/"
      find "$dest" -mindepth 2 -maxdepth 2 -name SKILL.md | while read -r f; do
        d="$(dirname "$f")"
        name="$(basename "$d")"
        if [ ! -e "$pi_skills/$name" ]; then
          ln -sfn "$d" "$pi_skills/$name"
        fi
      done
      log "Skills Cloudflare → Pi ($pi_skills)"
    else
      warn "No pude clonar cloudflare/skills."
    fi
    rm -rf "$skills_tmp"
  else
    log "Skills Cloudflare ya están en Pi."
  fi
}

install_pi_mcp_adapter() {
  # Cablea servers MCP a Pi via la extensión pi-mcp-adapter (https://github.com/nicobailon/pi-mcp-adapter).
  # Pi core NO soporta MCP por diseño del upstream; pi-mcp-adapter es la bridge oficial de la comunidad.
  # La extensión lee ~/.config/mcp/mcp.json (path canónico user-global), con precedencia sobre
  # ~/.pi/agent/mcp.json, .mcp.json, .pi/mcp.json.
  local mcp_json="$HOME/.config/mcp/mcp.json"
  log "Cableando MCPs a Pi vía pi-mcp-adapter."

  if ! command -v pi >/dev/null 2>&1; then
    warn "Sin pi; no instalo pi-mcp-adapter. Después: pi install npm:pi-mcp-adapter@latest"
    return 0
  fi

  if pi list 2>/dev/null | grep -q 'pi-mcp-adapter'; then
    log "pi-mcp-adapter ya está en Pi."
  else
    log "Instalando pi-mcp-adapter (npm:pi-mcp-adapter@latest)."
    pi install npm:pi-mcp-adapter@latest \
      || warn "pi install pi-mcp-adapter falló. Después: pi install npm:pi-mcp-adapter@latest"
  fi

  mkdir -p "$(dirname "$mcp_json")"
  if [ -f "$mcp_json" ] \
    && grep -q '"chrome-devtools"' "$mcp_json" \
    && grep -q '"cloudflare-api"' "$mcp_json" \
    && grep -q '"cloudflare-docs"' "$mcp_json"; then
    log "MCP config ya está sembrado en ${mcp_json#${HOME}/}."
  else
    log "Sembrando MCP config en ${mcp_json#${HOME}/} (chrome-devtools + cloudflare-api + cloudflare-docs)."
    cat > "$mcp_json" <<EOF
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "$HOME/.local/bin/chrome-devtools-mcp",
      "args": []
    },
    "cloudflare-api": {
      "serverUrl": "https://mcp.cloudflare.com/mcp"
    },
    "cloudflare-docs": {
      "serverUrl": "https://docs.mcp.cloudflare.com/mcp"
    }
  }
}
EOF
  fi

  # Limpieza: el viejo ~/.config/zoi/mcp-cloudflare.json quedó huérfano
  # (pi-mcp-adapter lee ~/.config/mcp/mcp.json, no este archivo).
  if [ -f "$HOME/.config/zoi/mcp-cloudflare.json" ]; then
    log "Quitando ~/.config/zoi/mcp-cloudflare.json (obsoleto, reemplazado por pi-mcp-adapter)."
    rm -f "$HOME/.config/zoi/mcp-cloudflare.json"
  fi
}

install_go_and_gentleman() {
  install_go_lang
  install_gentleman_stack
  install_codegraph_and_chrome_mcp
  install_cloudflare_mcp_servers
  install_pi_mcp_adapter
}
