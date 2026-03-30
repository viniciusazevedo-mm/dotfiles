#!/usr/bin/env bash
# ─────────────────────────────────────────
# docker.sh
# Docker CE + Docker Compose + aliases produtivos
# ─────────────────────────────────────────

set -e

echo "docker-boost — instalando Docker e configurando aliases..."

# ─── Detecção de distro ───────────────────────────────────
if [ -f /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  DISTRO_ID="${ID}"
else
  echo "Erro: /etc/os-release não encontrado."
  exit 1
fi

# ─── Instalar Docker ─────────────────────────────────────
if command -v docker &>/dev/null; then
  echo "  Docker já instalado: $(docker --version)"
else
  echo "  Instalando Docker CE..."

  sudo apt update -q
  sudo apt install -y ca-certificates curl gnupg

  sudo install -m 0755 -d /etc/apt/keyrings

  case "$DISTRO_ID" in
    ubuntu)
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      sudo chmod a+r /etc/apt/keyrings/docker.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      ;;
    debian|kali)
      curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      sudo chmod a+r /etc/apt/keyrings/docker.gpg
      CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)
      if [ "$DISTRO_ID" = "kali" ]; then
        CODENAME="bookworm"
      fi
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${CODENAME} stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      ;;
    *)
      echo "  Distro não suportada para instalação automática do Docker."
      exit 1
      ;;
  esac

  sudo apt update -q
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

# ─── Adicionar usuário ao grupo docker ───────────────────
if ! groups "$USER" | grep -q docker; then
  echo "  Adicionando $USER ao grupo docker..."
  sudo usermod -aG docker "$USER"
  echo "  AVISO: faça logout/login para aplicar permissões do grupo docker"
fi

# ─── Aliases Docker ──────────────────────────────────────
ALIAS_FILE="$HOME/.docker_aliases"

cat > "$ALIAS_FILE" << 'ALIASES'
# ─────────────────────────────────────────
# Docker aliases — gerado por dotfiles
# ─────────────────────────────────────────

# Docker
alias d='docker'
alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dpsa='docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias di='docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"'
alias dex='docker exec -it'
alias dl='docker logs -f'
alias dip='docker inspect -f "{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}"'
alias dtop='docker stats --no-stream'

# Docker Compose
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcr='docker compose restart'
alias dcl='docker compose logs -f'
alias dcp='docker compose pull'
alias dcb='docker compose build'
alias dce='docker compose exec'

# Cleanup
alias dprune='docker system prune -af --volumes'
alias drmi='docker rmi $(docker images -q -f dangling=true) 2>/dev/null || echo "Nenhuma imagem dangling"'
alias drm='docker rm $(docker ps -aq -f status=exited) 2>/dev/null || echo "Nenhum container parado"'
alias dvol='docker volume ls -q -f dangling=true | xargs -r docker volume rm'

# Network
alias dnet='docker network ls'
alias dnetin='docker network inspect'

# Build
alias dbuild='docker build -t'

# Shell rápido
dsh() {
  docker exec -it "$1" /bin/bash 2>/dev/null || docker exec -it "$1" /bin/sh
}

# Logs com timestamp
dlog() {
  docker logs -f --timestamps "$1"
}

# Parar todos os containers
dstopall() {
  docker stop $(docker ps -q) 2>/dev/null || echo "Nenhum container rodando"
}
ALIASES

# ─── Adicionar source no .zshrc ou .bashrc ───────────────
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ]; then
    if ! grep -q "docker_aliases" "$RC"; then
      echo "" >> "$RC"
      echo "# Docker aliases" >> "$RC"
      echo "[ -f ~/.docker_aliases ] && source ~/.docker_aliases" >> "$RC"
      echo "  Aliases adicionados em $(basename "$RC")"
    fi
  fi
done

echo ""
echo "Docker configurado com sucesso!"
echo ""
echo "Aliases disponíveis:"
echo ""
echo "  CONTAINERS"
echo "  dps          Containers rodando (formatado)"
echo "  dpsa         Todos os containers"
echo "  dex <c>      Exec -it no container"
echo "  dsh <c>      Shell interativo (bash/sh)"
echo "  dl <c>       Logs em tempo real"
echo "  dip <c>      IP do container"
echo "  dtop         Stats (CPU/MEM)"
echo "  dstopall     Parar todos"
echo ""
echo "  COMPOSE"
echo "  dc           docker compose"
echo "  dcu          up -d"
echo "  dcd          down"
echo "  dcr          restart"
echo "  dcl          logs -f"
echo ""
echo "  CLEANUP"
echo "  dprune       Limpar TUDO (containers, images, volumes)"
echo "  drmi         Remover imagens dangling"
echo "  drm          Remover containers parados"
