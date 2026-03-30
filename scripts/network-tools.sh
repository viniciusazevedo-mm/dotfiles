#!/usr/bin/env bash
# ─────────────────────────────────────────
# network-tools.sh
# Ferramentas de rede e diagnóstico
# ─────────────────────────────────────────

set -e

echo "network-tools — instalando ferramentas de rede..."

# ─── Ferramentas básicas ──────────────────────────────────
echo "  Instalando pacotes base..."
sudo apt update -q
sudo apt install -y \
  net-tools \
  dnsutils \
  traceroute \
  mtr-tiny \
  whois \
  nmap \
  netcat-openbsd \
  tcpdump \
  iperf3 \
  socat \
  wget \
  curl \
  jq \
  httpie 2>/dev/null || true

# ─── Ferramentas avançadas (opcionais) ───────────────────
echo ""
echo "  Instalando ferramentas avançadas..."

# tshark (wireshark CLI)
if ! command -v tshark &>/dev/null; then
  echo "    Instalando tshark..."
  sudo DEBIAN_FRONTEND=noninteractive apt install -y tshark 2>/dev/null || true
fi

# masscan
if ! command -v masscan &>/dev/null; then
  echo "    Instalando masscan..."
  sudo apt install -y masscan 2>/dev/null || true
fi

# ─── Aliases de rede ──────────────────────────────────────
ALIAS_FILE="$HOME/.network_aliases"

cat > "$ALIAS_FILE" << 'ALIASES'
# ─────────────────────────────────────────
# Network aliases — gerado por dotfiles
# ─────────────────────────────────────────

# IP e interfaces
alias myip='curl -s ifconfig.me'
alias myip6='curl -s ifconfig.me/ip6'
alias localip='ip -4 addr show | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | grep -v 127.0.0.1'
alias ips='ip -c -br addr'
alias routes='ip -c route'
alias iface='ip -c link'

# DNS
alias dig='dig +short'
alias ns='nslookup'
alias rdns='dig -x'
alias flush-dns='sudo systemd-resolve --flush-caches 2>/dev/null || sudo resolvectl flush-caches'

# Portas e conexões
alias ports='ss -tulnp'
alias listening='ss -tlnp'
alias conns='ss -tnp'
alias portcheck='nc -zv'

# Scan
alias quickscan='nmap -sn'
alias portscan='nmap -sV -sC -O'
alias fastscan='nmap -F -T4'

# Performance
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3'
alias bandwidth='iperf3 -c'

# HTTP
alias headers='curl -I'
alias status='curl -o /dev/null -s -w "%{http_code}\n"'

# Traceroute visual
alias trace='mtr --report --report-cycles 10'

# tcpdump rápido
alias sniff='sudo tcpdump -i any -n -c 100'
alias sniffhttp='sudo tcpdump -i any -n -s 0 -A "tcp port 80 or tcp port 443"'

# Funções
portof() {
  ss -tlnp | grep ":$1 "
}

whichip() {
  curl -s "https://ipinfo.io/$1" | jq .
}

scanlocal() {
  SUBNET=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+\.\d+\.\d+' | grep -v '127.0.0' | head -1)
  nmap -sn "${SUBNET}.0/24"
}

certinfo() {
  echo | openssl s_client -servername "$1" -connect "$1:443" 2>/dev/null | openssl x509 -noout -dates -subject -issuer
}

dnsall() {
  echo "=== A ===" && dig A "$1"
  echo "=== AAAA ===" && dig AAAA "$1"
  echo "=== MX ===" && dig MX "$1"
  echo "=== NS ===" && dig NS "$1"
  echo "=== TXT ===" && dig TXT "$1"
  echo "=== CNAME ===" && dig CNAME "$1"
}
ALIASES

# ─── Source nos shells ────────────────────────────────────
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "network_aliases" "$RC"; then
    echo "" >> "$RC"
    echo "# Network aliases" >> "$RC"
    echo "[ -f ~/.network_aliases ] && source ~/.network_aliases" >> "$RC"
  fi
done

echo ""
echo "Network tools instalado com sucesso!"
echo ""
echo "Ferramentas instaladas:"
echo "  nmap, netcat, tcpdump, tshark, masscan"
echo "  mtr, traceroute, iperf3, socat, jq, httpie"
echo ""
echo "Aliases disponíveis:"
echo ""
echo "  IP"
echo "  myip           IP público"
echo "  localip        IP local"
echo "  ips            Todas interfaces"
echo ""
echo "  DNS"
echo "  dig <host>     DNS lookup"
echo "  rdns <ip>      Reverse DNS"
echo "  dnsall <host>  Todos os registros DNS"
echo ""
echo "  SCAN"
echo "  quickscan <subnet>   Host discovery"
echo "  portscan <host>      Port scan + versão"
echo "  scanlocal            Scan da rede local"
echo ""
echo "  HTTP"
echo "  headers <url>  Headers HTTP"
echo "  status <url>   HTTP status code"
echo "  certinfo <h>   Info do certificado SSL"
echo ""
echo "  FUNÇÕES"
echo "  portof <port>  Quem está usando a porta"
echo "  whichip <ip>   Info do IP (ipinfo.io)"
