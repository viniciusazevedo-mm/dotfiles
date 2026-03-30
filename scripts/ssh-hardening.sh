#!/usr/bin/env bash
# ─────────────────────────────────────────
# ssh-hardening.sh
# Hardening de SSH server com boas práticas
# ─────────────────────────────────────────

set -e

echo "ssh-hardening — aplicando configurações de segurança..."

# ─── Verificar se sshd está instalado ────────────────────
if ! command -v sshd &>/dev/null; then
  echo "  OpenSSH Server não instalado. Instalando..."
  sudo apt update -q
  sudo apt install -y openssh-server
fi

SSHD_CONFIG="/etc/ssh/sshd_config"
HARDENED_CONFIG="/etc/ssh/sshd_config.d/99-hardening.conf"

# ─── Backup ───────────────────────────────────────────────
sudo cp "$SSHD_CONFIG" "$SSHD_CONFIG.backup.$(date +%Y%m%d%H%M%S)"
echo "  Backup do sshd_config salvo"

# ─── Detectar porta atual ────────────────────────────────
CURRENT_PORT=$(grep -E "^Port " "$SSHD_CONFIG" 2>/dev/null | awk '{print $2}')
CURRENT_PORT="${CURRENT_PORT:-22}"

echo ""
echo "  Porta SSH atual: $CURRENT_PORT"
read -rp "  Nova porta SSH (Enter para manter $CURRENT_PORT): " NEW_PORT
NEW_PORT="${NEW_PORT:-$CURRENT_PORT}"

# ─── Hardening config ────────────────────────────────────
echo "  Aplicando configurações de hardening..."

sudo tee "$HARDENED_CONFIG" > /dev/null << EOF
# ─────────────────────────────────────────
# SSH Hardening — gerado por dotfiles
# ─────────────────────────────────────────

# Porta
Port ${NEW_PORT}

# Protocolo (v2 only)
Protocol 2

# Autenticação
PermitRootLogin no
MaxAuthTries 3
MaxSessions 3
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Kerberos / GSSAPI (desabilitar se não usar)
KerberosAuthentication no
GSSAPIAuthentication no

# Forwarding
AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no

# Banners e info
PrintMotd no
PrintLastLog yes
Banner none
DebianBanner no

# Timeouts
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 30

# Logging
LogLevel VERBOSE
SyslogFacility AUTH

# Ciphers e algoritmos (modernos e seguros)
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
HostKeyAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256
EOF

# ─── Gerar chave ED25519 se não existir ──────────────────
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  echo ""
  read -rp "  Gerar chave SSH ED25519? (s/n): " GENERATE_KEY
  if [[ "$GENERATE_KEY" =~ ^[sS]$ ]]; then
    read -rp "  Seu e-mail (para a chave): " SSH_EMAIL
    ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$HOME/.ssh/id_ed25519"
    echo ""
    echo "  Chave pública gerada:"
    echo "  $(cat "$HOME/.ssh/id_ed25519.pub")"
    echo ""
    echo "  Adicione essa chave no GitHub/GitLab/server."
  fi
fi

# ─── Permissões corretas ─────────────────────────────────
echo "  Ajustando permissões..."
chmod 700 "$HOME/.ssh" 2>/dev/null || true
chmod 600 "$HOME/.ssh/id_"* 2>/dev/null || true
chmod 644 "$HOME/.ssh/id_"*.pub 2>/dev/null || true
chmod 644 "$HOME/.ssh/authorized_keys" 2>/dev/null || true
chmod 644 "$HOME/.ssh/known_hosts" 2>/dev/null || true
chmod 600 "$HOME/.ssh/config" 2>/dev/null || true

# ─── Testar config ───────────────────────────────────────
echo "  Testando configuração do sshd..."
if sudo sshd -t; then
  echo "  Configuração válida!"
else
  echo "  ERRO: Configuração inválida! Revertendo..."
  sudo rm -f "$HARDENED_CONFIG"
  exit 1
fi

# ─── Restart ──────────────────────────────────────────────
echo ""
read -rp "  Reiniciar SSH agora? (s/n): " RESTART_SSH
if [[ "$RESTART_SSH" =~ ^[sS]$ ]]; then
  sudo systemctl restart sshd
  echo "  SSH reiniciado na porta $NEW_PORT"
else
  echo "  Lembre de reiniciar: sudo systemctl restart sshd"
fi

# ─── SSH config do cliente ────────────────────────────────
SSH_CONFIG="$HOME/.ssh/config"
if [ ! -f "$SSH_CONFIG" ]; then
  mkdir -p "$HOME/.ssh"
  cat > "$SSH_CONFIG" << 'CLIENT'
# ─────────────────────────────────────────
# SSH Client config — gerado por dotfiles
# ─────────────────────────────────────────

Host *
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519
  ServerAliveInterval 60
  ServerAliveCountMax 3
  HashKnownHosts yes
  VisualHostKey yes

# Exemplo de host:
# Host meu-server
#   HostName 192.168.1.100
#   User admin
#   Port 2222
#   IdentityFile ~/.ssh/id_ed25519
CLIENT
  chmod 600 "$SSH_CONFIG"
  echo "  ~/.ssh/config criado"
fi

echo ""
echo "SSH hardening aplicado com sucesso!"
echo ""
echo "Configurações aplicadas:"
echo "  - Porta: $NEW_PORT"
echo "  - Root login: desabilitado"
echo "  - Password auth: desabilitado (somente chave)"
echo "  - Max auth tries: 3"
echo "  - Ciphers: apenas modernos (chacha20, aes-gcm)"
echo "  - Key exchange: apenas curve25519, DH group16/18"
echo "  - Forwarding: desabilitado"
echo "  - Client timeout: 5 min"
echo ""
echo "  IMPORTANTE: Certifique-se de ter uma chave SSH"
echo "  autorizada antes de fechar esta sessão!"
