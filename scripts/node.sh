#!/usr/bin/env bash
# ─────────────────────────────────────────
# node.sh
# NVM + Node.js LTS + ferramentas globais
# ─────────────────────────────────────────

set -e

echo "node-boost — instalando Node.js via NVM..."

# ─── NVM ──────────────────────────────────────────────────
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [ -d "$NVM_DIR" ]; then
  echo "  NVM já instalado, atualizando..."
  cd "$NVM_DIR" && git fetch --tags origin && git checkout "$(git describe --abbrev=0 --tags)" > /dev/null 2>&1
  cd - > /dev/null
else
  echo "  Instalando NVM..."
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
fi

# Carregar NVM na sessão atual
export NVM_DIR
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# ─── Node.js LTS ─────────────────────────────────────────
echo "  Instalando Node.js LTS..."
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'

echo "  Node: $(node --version)"
echo "  NPM:  $(npm --version)"

# ─── Global packages ─────────────────────────────────────
echo ""
echo "  Instalando ferramentas globais..."

GLOBAL_PACKAGES=(
  "typescript"
  "ts-node"
  "tsx"
  "eslint"
  "prettier"
  "nodemon"
  "pm2"
  "http-server"
  "tldr"
  "np"
)

for pkg in "${GLOBAL_PACKAGES[@]}"; do
  if npm list -g "$pkg" &>/dev/null; then
    echo "    $pkg já instalado"
  else
    echo "    Instalando $pkg..."
    npm install -g "$pkg" 2>/dev/null || echo "    Aviso: falha ao instalar $pkg"
  fi
done

# ─── NPM config ──────────────────────────────────────────
npm config set fund false 2>/dev/null || true
npm config set audit false 2>/dev/null || true
npm config set update-notifier false 2>/dev/null || true

# ─── Shell integration ───────────────────────────────────
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "NVM_DIR" "$RC"; then
    cat >> "$RC" << 'NVMRC'

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
NVMRC
    echo "  NVM adicionado em $(basename "$RC")"
  fi
done

echo ""
echo "Node.js configurado com sucesso!"
echo ""
echo "Ferramentas instaladas globalmente:"
for pkg in "${GLOBAL_PACKAGES[@]}"; do
  echo "  - $pkg"
done
echo ""
echo "Comandos úteis:"
echo "  nvm ls                Listar versões instaladas"
echo "  nvm install <v>       Instalar versão"
echo "  nvm use <v>           Usar versão"
echo "  nvm alias default <v> Definir padrão"
