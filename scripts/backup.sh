#!/usr/bin/env bash
# ─────────────────────────────────────────
# backup.sh
# Backup automatizado de configs e dados
# ─────────────────────────────────────────

set -e

BACKUP_DIR="${BACKUP_DIR:-$HOME/backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
HOSTNAME=$(hostname)

echo "backup — criando backup do sistema..."

usage() {
  echo "Uso: $0 [dotfiles|full|configs|custom]"
  echo ""
  echo "  dotfiles   Backup de dotfiles (.zshrc, .tmux.conf, etc.)"
  echo "  configs    Backup de configs do sistema (/etc)"
  echo "  full       Backup completo (dotfiles + configs + crontab + packages)"
  echo "  custom     Escolher diretórios manualmente"
  echo "  restore    Restaurar um backup"
  echo ""
  echo "  Sem argumentos: backup full"
}

mkdir -p "$BACKUP_DIR"

backup_dotfiles() {
  echo "  Fazendo backup de dotfiles..."
  local target="$BACKUP_DIR/dotfiles_${TIMESTAMP}.tar.gz"

  local files=()
  for f in \
    "$HOME/.zshrc" \
    "$HOME/.bashrc" \
    "$HOME/.bash_profile" \
    "$HOME/.profile" \
    "$HOME/.tmux.conf" \
    "$HOME/.gitconfig" \
    "$HOME/.ssh/config" \
    "$HOME/.ssh/authorized_keys" \
    "$HOME/.p10k.zsh" \
    "$HOME/.docker_aliases" \
    "$HOME/.network_aliases" \
    "$HOME/.pentest_aliases" \
    "$HOME/.vimrc" \
  ; do
    [ -f "$f" ] && files+=("$f")
  done

  # Config dirs
  for d in \
    "$HOME/.config/nvim" \
    "$HOME/.config/btop" \
  ; do
    [ -d "$d" ] && files+=("$d")
  done

  if [ ${#files[@]} -gt 0 ]; then
    tar -czf "$target" "${files[@]}" 2>/dev/null
    echo "  Dotfiles: $target ($(du -h "$target" | cut -f1))"
  else
    echo "  Nenhum dotfile encontrado"
  fi
}

backup_configs() {
  echo "  Fazendo backup de configs do sistema..."
  local target="$BACKUP_DIR/configs_${HOSTNAME}_${TIMESTAMP}.tar.gz"

  sudo tar -czf "$target" \
    /etc/ssh/sshd_config.d/ \
    /etc/sysctl.d/ \
    /etc/ufw/ \
    /etc/apt/sources.list.d/ \
    /etc/hosts \
    /etc/fstab \
    /etc/crontab \
    2>/dev/null || true

  echo "  Configs: $target ($(du -h "$target" | cut -f1))"
}

backup_packages() {
  echo "  Salvando lista de pacotes..."

  # APT packages
  dpkg --get-selections > "$BACKUP_DIR/packages_apt_${TIMESTAMP}.txt"
  echo "  APT packages: $BACKUP_DIR/packages_apt_${TIMESTAMP}.txt"

  # Snap packages
  if command -v snap &>/dev/null; then
    snap list > "$BACKUP_DIR/packages_snap_${TIMESTAMP}.txt" 2>/dev/null
  fi

  # pip packages
  if command -v pip3 &>/dev/null; then
    pip3 list --format=freeze > "$BACKUP_DIR/packages_pip_${TIMESTAMP}.txt" 2>/dev/null || true
  fi

  # npm global packages
  if command -v npm &>/dev/null; then
    npm list -g --depth=0 > "$BACKUP_DIR/packages_npm_${TIMESTAMP}.txt" 2>/dev/null || true
  fi

  # cargo packages
  if command -v cargo &>/dev/null; then
    cargo install --list > "$BACKUP_DIR/packages_cargo_${TIMESTAMP}.txt" 2>/dev/null || true
  fi
}

backup_crontab() {
  echo "  Salvando crontab..."
  crontab -l > "$BACKUP_DIR/crontab_${TIMESTAMP}.txt" 2>/dev/null || echo "  Nenhum crontab encontrado"
}

backup_custom() {
  echo "  Modo custom — digite os caminhos (vazio para finalizar):"
  local files=()
  while true; do
    read -rp "  Caminho: " custom_path
    [ -z "$custom_path" ] && break
    if [ -e "$custom_path" ]; then
      files+=("$custom_path")
    else
      echo "    Não encontrado: $custom_path"
    fi
  done

  if [ ${#files[@]} -gt 0 ]; then
    local target="$BACKUP_DIR/custom_${TIMESTAMP}.tar.gz"
    tar -czf "$target" "${files[@]}" 2>/dev/null
    echo "  Custom: $target ($(du -h "$target" | cut -f1))"
  fi
}

restore_backup() {
  echo "  Backups disponíveis:"
  echo ""
  local -a backups
  mapfile -t backups < <(find "$BACKUP_DIR" -name "*.tar.gz" -type f | sort -r)

  if [ ${#backups[@]} -eq 0 ]; then
    echo "  Nenhum backup encontrado em $BACKUP_DIR"
    return
  fi

  for i in "${!backups[@]}"; do
    echo "  [$i] $(basename "${backups[$i]}") ($(du -h "${backups[$i]}" | cut -f1))"
  done

  echo ""
  read -rp "  Número do backup para restaurar: " CHOICE

  if [ -z "${backups[$CHOICE]:-}" ]; then
    echo "  Opção inválida"
    return
  fi

  echo "  Restaurando ${backups[$CHOICE]}..."
  echo "  AVISO: Isso vai sobrescrever arquivos existentes."
  read -rp "  Continuar? (s/n): " CONFIRM
  if [[ "$CONFIRM" =~ ^[sS]$ ]]; then
    tar -xzf "${backups[$CHOICE]}" -C / 2>/dev/null || tar -xzf "${backups[$CHOICE]}" -C "$HOME" 2>/dev/null
    echo "  Restauração concluída!"
  fi
}

# ─── Execução ─────────────────────────────────────────────
case "${1:-full}" in
  dotfiles)
    backup_dotfiles
    ;;
  configs)
    backup_configs
    ;;
  full)
    backup_dotfiles
    backup_configs
    backup_packages
    backup_crontab
    ;;
  custom)
    backup_custom
    ;;
  restore)
    restore_backup
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

# ─── Limpar backups antigos (>30 dias) ───────────────────
OLD_COUNT=$(find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +30 | wc -l)
if [ "$OLD_COUNT" -gt 0 ]; then
  echo ""
  echo "  $OLD_COUNT backup(s) com mais de 30 dias encontrado(s)."
  read -rp "  Remover backups antigos? (s/n): " CLEAN_OLD
  if [[ "$CLEAN_OLD" =~ ^[sS]$ ]]; then
    find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +30 -delete
    find "$BACKUP_DIR" -name "*.txt" -type f -mtime +30 -delete
    echo "  Backups antigos removidos"
  fi
fi

echo ""
echo "Backup concluído!"
echo "Diretório: $BACKUP_DIR"
echo ""
ls -lh "$BACKUP_DIR"/ 2>/dev/null | tail -10
