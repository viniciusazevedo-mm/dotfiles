#!/bin/bash
# ─────────────────────────────────────────
# zsh-boost.sh
# Zsh + Oh My Zsh + Powerlevel10k setup
# Author: Vinicius Azevedo<github.com/viniciusazevedo-mm>
# ─────────────────────────────────────────

set -e

echo "zsh-boost — configurando terminal..."

# ─── Dependências ─────────────────────────────────────────
echo ""
echo "Instalando dependências..."
sudo apt update -q
sudo apt install -y zsh curl git unzip fontconfig

# ─── Oh My Zsh ────────────────────────────────────────────
echo ""
echo "Instalando Oh My Zsh..."

if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "  Oh My Zsh já instalado, pulando..."
else
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ─── Powerlevel10k ────────────────────────────────────────
echo ""
echo "Instalando Powerlevel10k..."

if [ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  echo "  Powerlevel10k já instalado, pulando..."
else
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM/themes/powerlevel10k"
fi

# ─── Plugins ──────────────────────────────────────────────
echo ""
echo "Instalando plugins..."

# zsh-syntax-highlighting
if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  echo "  zsh-syntax-highlighting já instalado, pulando..."
else
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# zsh-autosuggestions
if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  echo "  zsh-autosuggestions já instalado, pulando..."
else
  git clone https://github.com/zsh-users/zsh-autosuggestions.git \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# zsh-completions
if [ -d "$ZSH_CUSTOM/plugins/zsh-completions" ]; then
  echo "  zsh-completions já instalado, pulando..."
else
  git clone https://github.com/zsh-users/zsh-completions.git \
    "$ZSH_CUSTOM/plugins/zsh-completions"
fi

# ─── Ferramentas visuais ──────────────────────────────────
echo ""
echo "🛠  Instalando ferramentas..."
sudo apt install -y btop

# bat — no Ubuntu 24 já vem como bat
sudo apt install -y bat 2>/dev/null || sudo apt install -y batcat
# garante que o comando bat funciona
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
  mkdir -p ~/.local/bin
  ln -sf /usr/bin/batcat ~/.local/bin/bat
fi

# lsd — não está no apt do Ubuntu 24, instala via .deb do GitHub
echo "  Instalando lsd..."
LSD_VERSION=$(curl -s https://api.github.com/repos/lsd-rs/lsd/releases/latest | grep tag_name | cut -d'"' -f4)
curl -fsSL "https://github.com/lsd-rs/lsd/releases/latest/download/lsd_${LSD_VERSION#v}_amd64.deb" \
  -o /tmp/lsd.deb
sudo dpkg -i /tmp/lsd.deb
rm /tmp/lsd.deb

# fastfetch — PPA oficial
echo "  Instalando fastfetch..."
sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch 2>/dev/null || true
sudo apt update -q
sudo apt install -y fastfetch

# ─── Nerd Font (JetBrainsMono) ────────────────────────────
echo ""
echo "Instalando JetBrainsMono Nerd Font..."

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

if fc-list | grep -qi "JetBrainsMono"; then
  echo "  JetBrainsMono já instalada, pulando..."
else
  TMP=$(mktemp -d)
  curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
    -o "$TMP/JetBrainsMono.zip"
  unzip -q "$TMP/JetBrainsMono.zip" -d "$FONT_DIR"
  fc-cache -fv > /dev/null
  rm -rf "$TMP"
  echo "  JetBrainsMono Nerd Font instalada!"
fi

# ─── .zshrc ───────────────────────────────────────────────
echo ""
echo "Configurando .zshrc..."

ZSHRC="$HOME/.zshrc"

# Backup do zshrc atual
if [ -f "$ZSHRC" ]; then
  cp "$ZSHRC" "$ZSHRC.backup.$(date +%Y%m%d%H%M%S)"
  echo "  Backup salvo em $ZSHRC.backup.*"
fi

cat > "$ZSHRC" << 'EOF'
# ─────────────────────────────────────────
# .zshrc — gerado por zsh-boost.sh
# ─────────────────────────────────────────

# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
  zsh-completions
  docker
  npm
  golang
)

source $ZSH/oh-my-zsh.sh

# ─── Aliases ──────────────────────────────────────────────

# Navegação
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# ls
alias ls='lsd'
alias ll='lsd -la'
alias lt='lsd --tree'

# cat
alias cat='bat'

# top
alias top='btop'

# Sistema
alias update='sudo apt update && sudo apt upgrade -y'
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me'
alias path='echo $PATH | tr ":" "\n"'
alias reload='source ~/.zshrc'
alias zshrc='${EDITOR:-nano} ~/.zshrc'

# Dev
alias py='python3'
alias serve='python3 -m http.server'

# ─── Exports ──────────────────────────────────────────────
export EDITOR="nano"
export PATH="$HOME/.local/bin:$PATH"
export LANG=en_US.UTF-8

# ─── Histórico ────────────────────────────────────────────
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# ─── Autosuggestions ──────────────────────────────────────
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ─── Powerlevel10k config ─────────────────────────────────
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ─── Fastfetch no início ──────────────────────────────────
# Descomenta pra mostrar info do sistema ao abrir o terminal
# fastfetch
EOF

# ─── Shell padrão ─────────────────────────────────────────
echo ""
echo "Definindo Zsh como shell padrão..."
chsh -s $(which zsh)

# ─── Summary ──────────────────────────────────────────────
echo ""
echo "zsh-boost instalado com sucesso!"
echo ""
echo "O que foi instalado:"
echo "  + Zsh + Oh My Zsh"
echo "  + Powerlevel10k (tema)"
echo "  + zsh-syntax-highlighting"
echo "  + zsh-autosuggestions"
echo "  + zsh-completions"
echo "  + btop, lsd, bat, fastfetch"
echo "  + JetBrainsMono Nerd Font"
echo ""
echo " Próximos passos:"
echo "  1. Configura a fonte 'JetBrainsMono Nerd Font' no seu terminal"
echo "  2. Abre um novo terminal"
echo "  3. Roda: p10k configure"
echo ""
echo "  Para ativar o fastfetch no início do terminal:"
echo "  Descomenta a linha 'fastfetch' no final do ~/.zshrc"
