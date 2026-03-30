#!/usr/bin/env bash
# ─────────────────────────────────────────
# security-audit.sh
# Auditoria básica de segurança do sistema
# ─────────────────────────────────────────

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

PASS=0
WARN=0
FAIL=0

pass() { echo -e "  ${GREEN}[PASS]${NC} $1"; ((PASS++)); }
warn() { echo -e "  ${YELLOW}[WARN]${NC} $1"; ((WARN++)); }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; ((FAIL++)); }
info() { echo -e "  ${CYAN}[INFO]${NC} $1"; }
section() { echo -e "\n${BOLD}── $1 ──${NC}"; }

echo ""
echo "╔══════════════════════════════════════╗"
echo "║      Security Audit Report           ║"
echo "║      $(date +%Y-%m-%d\ %H:%M:%S)             ║"
echo "║      $(hostname)                     ║"
echo "╚══════════════════════════════════════╝"

# ─── Sistema ──────────────────────────────────────────────
section "SISTEMA"

info "OS: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
info "Kernel: $(uname -r)"
info "Uptime: $(uptime -p)"

# Atualizações pendentes
UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0")
if [ "$UPDATES" -eq 0 ]; then
  pass "Sistema atualizado"
else
  warn "$UPDATES atualizações pendentes (rode: sudo apt upgrade)"
fi

# ─── Usuários ─────────────────────────────────────────────
section "USUÁRIOS"

# Root login
ROOT_SHELL=$(grep "^root:" /etc/passwd | cut -d: -f7)
if [[ "$ROOT_SHELL" == */nologin || "$ROOT_SHELL" == */false ]]; then
  pass "Root login desabilitado"
else
  warn "Root tem shell ativo: $ROOT_SHELL"
fi

# Usuários com UID 0
UID0_COUNT=$(awk -F: '($3 == 0) {print $1}' /etc/passwd | wc -l)
if [ "$UID0_COUNT" -eq 1 ]; then
  pass "Apenas root tem UID 0"
else
  fail "$UID0_COUNT usuários com UID 0"
fi

# Usuários sem senha
NOPASS=$(sudo awk -F: '($2 == "" || $2 == "!") {print $1}' /etc/shadow 2>/dev/null | grep -v "^$" | wc -l)
if [ "$NOPASS" -eq 0 ]; then
  pass "Nenhum usuário sem senha"
else
  warn "$NOPASS usuário(s) sem senha definida"
fi

# Sudoers sem senha
if sudo grep -r "NOPASSWD" /etc/sudoers /etc/sudoers.d/ 2>/dev/null | grep -v "^#" | grep -q NOPASSWD; then
  warn "Existem regras NOPASSWD no sudoers"
else
  pass "Nenhuma regra NOPASSWD encontrada"
fi

# ─── SSH ──────────────────────────────────────────────────
section "SSH"

if [ -f /etc/ssh/sshd_config ]; then
  # Root login via SSH
  ROOT_SSH=$(sudo sshd -T 2>/dev/null | grep "^permitrootlogin " | awk '{print $2}')
  if [ "$ROOT_SSH" = "no" ]; then
    pass "SSH root login desabilitado"
  else
    fail "SSH root login: $ROOT_SSH (deveria ser 'no')"
  fi

  # Password auth
  PASS_AUTH=$(sudo sshd -T 2>/dev/null | grep "^passwordauthentication " | awk '{print $2}')
  if [ "$PASS_AUTH" = "no" ]; then
    pass "SSH password auth desabilitado"
  else
    warn "SSH password auth habilitado (recomenda-se usar apenas chaves)"
  fi

  # SSH protocol
  SSH_PORT=$(sudo sshd -T 2>/dev/null | grep "^port " | awk '{print $2}')
  if [ "$SSH_PORT" = "22" ]; then
    warn "SSH na porta padrão 22 (considere mudar)"
  else
    pass "SSH em porta não padrão: $SSH_PORT"
  fi

  # Max auth tries
  MAX_AUTH=$(sudo sshd -T 2>/dev/null | grep "^maxauthtries " | awk '{print $2}')
  if [ "$MAX_AUTH" -le 3 ] 2>/dev/null; then
    pass "SSH max auth tries: $MAX_AUTH"
  else
    warn "SSH max auth tries alto: $MAX_AUTH (recomendado: 3)"
  fi
else
  info "SSH server não instalado"
fi

# ─── Firewall ─────────────────────────────────────────────
section "FIREWALL"

if command -v ufw &>/dev/null; then
  UFW_STATUS=$(sudo ufw status | head -1)
  if echo "$UFW_STATUS" | grep -q "active"; then
    pass "UFW ativo"
    RULES_COUNT=$(sudo ufw status | grep -c "ALLOW\|DENY\|LIMIT" || echo "0")
    info "$RULES_COUNT regras configuradas"
  else
    fail "UFW inativo"
  fi
elif command -v iptables &>/dev/null; then
  RULES=$(sudo iptables -L -n 2>/dev/null | grep -c "ACCEPT\|DROP\|REJECT" || echo "0")
  if [ "$RULES" -gt 3 ]; then
    pass "iptables tem $RULES regras"
  else
    warn "iptables com poucas regras ($RULES)"
  fi
else
  fail "Nenhum firewall encontrado"
fi

# ─── Rede ─────────────────────────────────────────────────
section "REDE"

# Portas abertas
OPEN_PORTS=$(ss -tlnp 2>/dev/null | grep LISTEN | wc -l)
info "$OPEN_PORTS portas em LISTEN"

# Listar portas sensíveis expostas
for port in 21 23 25 3306 5432 6379 27017 9200; do
  if ss -tlnp 2>/dev/null | grep -q ":$port "; then
    warn "Porta sensível aberta: $port"
  fi
done

# IP forwarding
IP_FWD=$(cat /proc/sys/net/ipv4/ip_forward)
if [ "$IP_FWD" = "0" ]; then
  pass "IP forwarding desabilitado"
else
  info "IP forwarding habilitado (normal se usa Docker/VMs)"
fi

# ─── Filesystem ───────────────────────────────────────────
section "FILESYSTEM"

# Permissões de arquivos sensíveis
for file in /etc/passwd /etc/shadow /etc/group; do
  if [ -f "$file" ]; then
    perms=$(stat -c %a "$file")
    if [ "$file" = "/etc/shadow" ] && [ "$perms" = "640" ] || [ "$perms" = "600" ]; then
      pass "$file: $perms"
    elif [ "$file" != "/etc/shadow" ] && [ "$perms" = "644" ]; then
      pass "$file: $perms"
    else
      warn "$file: $perms (verificar permissões)"
    fi
  fi
done

# Arquivos SUID
SUID_COUNT=$(find / -perm -4000 -type f 2>/dev/null | wc -l)
info "$SUID_COUNT arquivos com SUID bit"
if [ "$SUID_COUNT" -gt 30 ]; then
  warn "Número alto de SUID binários (verificar com: find / -perm -4000 -type f)"
fi

# World-writable directories
WW_DIRS=$(find / -type d -perm -0002 ! -path "/proc/*" ! -path "/sys/*" ! -path "/tmp" ! -path "/var/tmp" 2>/dev/null | wc -l)
if [ "$WW_DIRS" -eq 0 ]; then
  pass "Nenhum diretório world-writable incomum"
else
  warn "$WW_DIRS diretório(s) world-writable encontrado(s)"
fi

# ─── Kernel ───────────────────────────────────────────────
section "KERNEL"

# ASLR
ASLR=$(cat /proc/sys/kernel/randomize_va_space)
if [ "$ASLR" = "2" ]; then
  pass "ASLR completo ativo"
elif [ "$ASLR" = "1" ]; then
  warn "ASLR parcial (recomendado: 2)"
else
  fail "ASLR desabilitado"
fi

# SYN cookies
SYNCOOKIES=$(cat /proc/sys/net/ipv4/tcp_syncookies)
if [ "$SYNCOOKIES" = "1" ]; then
  pass "SYN cookies habilitado"
else
  fail "SYN cookies desabilitado"
fi

# Core dumps
CORE_DUMP=$(cat /proc/sys/fs/suid_dumpable)
if [ "$CORE_DUMP" = "0" ]; then
  pass "Core dumps para SUID desabilitado"
else
  warn "Core dumps para SUID habilitado"
fi

# ─── Serviços ─────────────────────────────────────────────
section "SERVIÇOS"

UNNECESSARY_SERVICES=("avahi-daemon" "cups" "bluetooth" "rpcbind")
for svc in "${UNNECESSARY_SERVICES[@]}"; do
  if systemctl is-active "$svc" &>/dev/null; then
    warn "Serviço $svc ativo (geralmente desnecessário em servidores)"
  fi
done

# ─── Relatório final ──────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════╗"
echo "║           RESULTADO                  ║"
echo "╠══════════════════════════════════════╣"
echo -e "║  ${GREEN}PASS: $PASS${NC}$(printf '%*s' $((29 - ${#PASS})) '')║"
echo -e "║  ${YELLOW}WARN: $WARN${NC}$(printf '%*s' $((29 - ${#WARN})) '')║"
echo -e "║  ${RED}FAIL: $FAIL${NC}$(printf '%*s' $((29 - ${#FAIL})) '')║"
echo "╚══════════════════════════════════════╝"

TOTAL=$((PASS + WARN + FAIL))
if [ "$TOTAL" -gt 0 ]; then
  SCORE=$(( (PASS * 100) / TOTAL ))
  echo ""
  echo "  Score: ${SCORE}%"
fi

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "  Existem falhas que devem ser corrigidas."
  echo "  Rode os scripts de hardening deste toolkit:"
  echo "    bash scripts/ssh-hardening.sh"
  echo "    bash scripts/firewall.sh"
  echo "    bash scripts/sysctl.sh"
fi

echo ""
