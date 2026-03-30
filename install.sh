#!/usr/bin/env bash
# ─────────────────────────────────────────
# install.sh
# Instalador central dos dotfiles
# Author: Vinicius Azevedo <github.com/viniciusazevedo-mm>
# ─────────────────────────────────────────

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔══════════════════════════════════════╗"
echo "║        Dotfiles Installer            ║"
echo "╚══════════════════════════════════════╝"
echo ""

usage() {
  echo "Uso: $0 [--all | --git | --zsh]"
  echo ""
  echo "  --all   Instala tudo (git-boost + zsh-boost)"
  echo "  --git   Instala apenas git-boost (aliases Git)"
  echo "  --zsh   Instala apenas zsh-boost (Zsh + tema)"
  echo ""
  echo "Sem argumentos: instala tudo."
}

install_git() {
  echo "─── Executando git-boost.sh ───"
  bash "${SCRIPT_DIR}/git-boost.sh"
  echo ""
}

install_zsh() {
  echo "─── Executando zsh.sh ───"
  bash "${SCRIPT_DIR}/zsh.sh"
  echo ""
}

case "${1:-}" in
  --all|"")
    install_git
    install_zsh
    ;;
  --git)
    install_git
    ;;
  --zsh)
    install_zsh
    ;;
  --help|-h)
    usage
    exit 0
    ;;
  *)
    echo "Opção desconhecida: $1"
    usage
    exit 1
    ;;
esac

echo "Instalação concluída!"
