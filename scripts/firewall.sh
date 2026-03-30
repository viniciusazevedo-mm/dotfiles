#!/usr/bin/env bash
# ─────────────────────────────────────────
# firewall.sh
# UFW setup com regras sane defaults
# ─────────────────────────────────────────

set -e

echo "firewall-boost — configurando UFW..."

# ─── Instalar UFW ─────────────────────────────────────────
if ! command -v ufw &>/dev/null; then
  echo "  Instalando UFW..."
  sudo apt update -q
  sudo apt install -y ufw
fi

# ─── Status atual ─────────────────────────────────────────
echo ""
echo "  Status atual do UFW:"
sudo ufw status verbose 2>/dev/null || echo "  UFW inativo"

echo ""
echo "┌──────────────────────────────────────────────────┐"
echo "│  Profiles disponíveis:                            │"
echo "│                                                    │"
echo "│  1) minimal   — SSH only (servidor remoto)        │"
echo "│  2) webserver — SSH + HTTP + HTTPS                │"
echo "│  3) dev       — SSH + HTTP + HTTPS + portas dev   │"
echo "│  4) custom    — Escolher manualmente               │"
echo "│  5) skip      — Não configurar agora               │"
echo "│                                                    │"
echo "└──────────────────────────────────────────────────┘"

read -rp "  Escolha o profile [1-5]: " PROFILE

# ─── Detectar porta SSH ───────────────────────────────────
SSH_PORT=$(grep -E "^Port " /etc/ssh/sshd_config.d/99-hardening.conf 2>/dev/null | awk '{print $2}')
if [ -z "$SSH_PORT" ]; then
  SSH_PORT=$(grep -E "^Port " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
fi
SSH_PORT="${SSH_PORT:-22}"

apply_base() {
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw default deny routed
  sudo ufw limit "${SSH_PORT}/tcp" comment "SSH rate-limited"
}

case "$PROFILE" in
  1)
    echo "  Aplicando profile: minimal..."
    sudo ufw --force reset
    apply_base
    ;;
  2)
    echo "  Aplicando profile: webserver..."
    sudo ufw --force reset
    apply_base
    sudo ufw allow 80/tcp comment "HTTP"
    sudo ufw allow 443/tcp comment "HTTPS"
    ;;
  3)
    echo "  Aplicando profile: dev..."
    sudo ufw --force reset
    apply_base
    sudo ufw allow 80/tcp comment "HTTP"
    sudo ufw allow 443/tcp comment "HTTPS"
    sudo ufw allow 3000/tcp comment "Dev server (Node/React)"
    sudo ufw allow 5173/tcp comment "Vite dev server"
    sudo ufw allow 8080/tcp comment "Alt HTTP / API"
    sudo ufw allow 5432/tcp comment "PostgreSQL"
    sudo ufw allow 6379/tcp comment "Redis"
    echo ""
    echo "  AVISO: Portas de DB (5432, 6379) abertas."
    echo "  Em produção, restrinja por IP com:"
    echo "  sudo ufw allow from <IP> to any port 5432"
    ;;
  4)
    echo "  Config custom..."
    sudo ufw --force reset
    apply_base
    echo ""
    echo "  SSH (porta $SSH_PORT) já adicionado com rate-limit."
    echo "  Adicione portas extras (vazio para finalizar):"
    while true; do
      read -rp "  Porta (ex: 80/tcp): " CUSTOM_PORT
      [ -z "$CUSTOM_PORT" ] && break
      read -rp "  Comentário: " CUSTOM_COMMENT
      sudo ufw allow "$CUSTOM_PORT" comment "${CUSTOM_COMMENT:-custom}"
    done
    ;;
  5)
    echo "  Pulando configuração do firewall."
    exit 0
    ;;
  *)
    echo "  Opção inválida."
    exit 1
    ;;
esac

# ─── Regras anti-bruteforce extras ───────────────────────
echo "  Adicionando proteções extras..."

# Bloquear IPs que fazem port scanning
sudo ufw deny proto tcp from any to any port 1 comment "Anti port-scan trap"

# ─── Ativar UFW ──────────────────────────────────────────
echo ""
read -rp "  Ativar UFW agora? (s/n): " ENABLE_UFW
if [[ "$ENABLE_UFW" =~ ^[sS]$ ]]; then
  sudo ufw --force enable
  echo "  UFW ativado!"
else
  echo "  Para ativar depois: sudo ufw enable"
fi

# ─── Logging ──────────────────────────────────────────────
sudo ufw logging on

# ─── Status final ─────────────────────────────────────────
echo ""
echo "Regras atuais:"
sudo ufw status numbered

echo ""
echo "Firewall configurado com sucesso!"
echo ""
echo "Comandos úteis:"
echo "  sudo ufw status              Ver regras"
echo "  sudo ufw status numbered     Ver com números"
echo "  sudo ufw delete <N>          Deletar regra N"
echo "  sudo ufw allow from <IP>     Permitir IP específico"
echo "  sudo ufw deny from <IP>      Bloquear IP específico"
echo "  sudo ufw disable             Desativar firewall"
echo "  sudo ufw reset               Resetar tudo"
