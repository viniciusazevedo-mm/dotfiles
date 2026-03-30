#!/usr/bin/env bash
# ─────────────────────────────────────────
# sysctl.sh
# Kernel tuning — performance e segurança
# ─────────────────────────────────────────

set -e

echo "sysctl-boost — tunando parâmetros do kernel..."

SYSCTL_CONF="/etc/sysctl.d/99-dotfiles-tuning.conf"

# ─── Backup ───────────────────────────────────────────────
if [ -f "$SYSCTL_CONF" ]; then
  sudo cp "$SYSCTL_CONF" "$SYSCTL_CONF.backup.$(date +%Y%m%d%H%M%S)"
  echo "  Backup salvo"
fi

echo ""
echo "┌──────────────────────────────────────────────────┐"
echo "│  Profiles disponíveis:                            │"
echo "│                                                    │"
echo "│  1) desktop   — Dev/uso diário                    │"
echo "│  2) server    — Servidor web/API                  │"
echo "│  3) hardened  — Máxima segurança                  │"
echo "│                                                    │"
echo "└──────────────────────────────────────────────────┘"

read -rp "  Escolha o profile [1-3]: " PROFILE

# ─── Base config (todos os profiles) ─────────────────────
BASE=$(cat << 'SYSCTL'
# ─────────────────────────────────────────
# Kernel Tuning — gerado por dotfiles
# ─────────────────────────────────────────

# ─── REDE — Performance ──────────────────

# Aumentar buffers de rede
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 4096

# TCP tuning
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_no_metrics_save = 1

# Reuse/recycle de conexões
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5

# ─── REDE — Segurança ────────────────────

# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_synack_retries = 2

# ICMP
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Source routing (desabilitar)
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Log de pacotes suspeitos
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# ─── FILESYSTEM ──────────────────────────

# Proteger links simbólicos e hardlinks
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2

# Aumentar file descriptors
fs.file-max = 2097152
fs.nr_open = 1048576

# Inotify (útil para IDEs, file watchers)
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
fs.inotify.max_queued_events = 32768
SYSCTL
)

# ─── Profile-specific config ─────────────────────────────
case "$PROFILE" in
  1)
    EXTRA=$(cat << 'SYSCTL'

# ─── DESKTOP — Extras ────────────────────

# Swap menos agressivo (desktop)
vm.swappiness = 10
vm.vfs_cache_pressure = 50

# Responsividade do sistema
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# Não desabilitar IP forwarding (pode usar Docker/VMs)
net.ipv4.ip_forward = 1

# Kernel não precisa de magic sysrq em desktop normal
kernel.sysrq = 0
SYSCTL
    )
    ;;
  2)
    EXTRA=$(cat << 'SYSCTL'

# ─── SERVER — Extras ─────────────────────

# Swap moderado
vm.swappiness = 10
vm.vfs_cache_pressure = 50

# Write mais agressivo (throughput)
vm.dirty_ratio = 40
vm.dirty_background_ratio = 10

# Forwarding (para containers/proxies)
net.ipv4.ip_forward = 1

# Mais conexões simultâneas
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_max_tw_buckets = 1440000

# ARP cache
net.ipv4.neigh.default.gc_thresh1 = 1024
net.ipv4.neigh.default.gc_thresh2 = 2048
net.ipv4.neigh.default.gc_thresh3 = 4096

kernel.sysrq = 0
SYSCTL
    )
    ;;
  3)
    EXTRA=$(cat << 'SYSCTL'

# ─── HARDENED — Extras ────────────────────

# Swap mínimo
vm.swappiness = 1
vm.vfs_cache_pressure = 50

vm.dirty_ratio = 10
vm.dirty_background_ratio = 3

# Sem forwarding (máquina standalone)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# ASLR máximo
kernel.randomize_va_space = 2

# Restringir dmesg
kernel.dmesg_restrict = 1

# Restringir kernel pointers
kernel.kptr_restrict = 2

# Desabilitar magic sysrq
kernel.sysrq = 0

# Proibir core dumps
fs.suid_dumpable = 0

# BPF restrito
kernel.unprivileged_bpf_disabled = 1

# Restringir ptrace
kernel.yama.ptrace_scope = 2

# Restringir userns (se suportado)
kernel.unprivileged_userns_clone = 0
SYSCTL
    )
    ;;
  *)
    echo "  Opção inválida."
    exit 1
    ;;
esac

# ─── Aplicar ──────────────────────────────────────────────
echo "$BASE" | sudo tee "$SYSCTL_CONF" > /dev/null
echo "$EXTRA" | sudo tee -a "$SYSCTL_CONF" > /dev/null

echo "  Aplicando configurações..."
sudo sysctl --system > /dev/null 2>&1

echo ""
echo "Sysctl tuning aplicado com sucesso!"
echo ""
echo "Arquivo: $SYSCTL_CONF"
echo "Profile: $([ "$PROFILE" = "1" ] && echo "desktop" || ([ "$PROFILE" = "2" ] && echo "server" || echo "hardened"))"
echo ""
echo "Para verificar: sysctl -a | grep <param>"
echo "Para reverter: sudo rm $SYSCTL_CONF && sudo sysctl --system"
