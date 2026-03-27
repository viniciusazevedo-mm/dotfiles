#!/bin/bash
# ─────────────────────────────────────────
# zsh-boost.sh
# Zsh + Oh My Zsh + Powerlevel10k setup
# Author: Vinicius Azevedo <github.com/viniciusazevedo-mm>
# ─────────────────────────────────────────

set -e

echo "zsh-boost  configurando terminal..."

# ─── Dependncias ─────────────────────────────────────────
echo ""
echo "Instalando dependncias..."
sudo apt update -q
sudo apt install -y zsh curl git unzip fontconfig

# ─── Oh My Zsh ────────────────────────────────────────────
echo ""
echo "Instalando Oh My Zsh..."

if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "  Oh My Zsh j instalado, pulando..."
else
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ─── Powerlevel10k ────────────────────────────────────────
echo ""
echo "Instalando Powerlevel10k..."

if [ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  echo "  Powerlevel10k j instalado, pulando..."
else
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM/themes/powerlevel10k"
fi

# ─── Plugins ──────────────────────────────────────────────
echo ""
echo "Instalando plugins..."

# zsh-syntax-highlighting
if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  echo "  zsh-syntax-highlighting j instalado, pulando..."
else
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# zsh-autosuggestions
if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  echo "  zsh-autosuggestions j instalado, pulando..."
else
  git clone https://github.com/zsh-users/zsh-autosuggestions.git \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# zsh-completions
if [ -d "$ZSH_CUSTOM/plugins/zsh-completions" ]; then
  echo "  zsh-completions j instalado, pulando..."
else
  git clone https://github.com/zsh-users/zsh-completions.git \
    "$ZSH_CUSTOM/plugins/zsh-completions"
fi

# ─── Ferramentas visuais ──────────────────────────────────
echo ""
echo "Instalando ferramentas..."
sudo apt install -y btop

# bat  no Ubuntu 24 j vem como bat
sudo apt install -y bat 2>/dev/null || sudo apt install -y batcat
# garante que o comando bat funciona
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
  mkdir -p ~/.local/bin
  ln -sf /usr/bin/batcat ~/.local/bin/bat
fi

# lsd  no est no apt do Ubuntu 24, instala via .deb do GitHub
echo "  Instalando lsd..."
LSD_VERSION=$(curl -s https://api.github.com/repos/lsd-rs/lsd/releases/latest | grep tag_name | cut -d'"' -f4)
curl -fsSL "https://github.com/lsd-rs/lsd/releases/latest/download/lsd_${LSD_VERSION#v}_amd64.deb" \
  -o /tmp/lsd.deb
sudo dpkg -i /tmp/lsd.deb
rm /tmp/lsd.deb

# fastfetch  PPA oficial
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
  echo "  JetBrainsMono j instalada, pulando..."
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
# .zshrc  gerado por zsh-boost.sh
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

# Navegao
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

# Git rpido
alias g='git'
alias gs='git s'
alias gl='git l'

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

# ─── Histrico ────────────────────────────────────────────
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

# ─── Fastfetch no incio ──────────────────────────────────
# Descomenta pra mostrar info do sistema ao abrir o terminal
# fastfetch
EOF

# ─── Powerlevel10k hacker config ─────────────────────────
echo ""
echo "Aplicando tema hacker no Powerlevel10k..."

# Backup se existir e sobrescreve
[ -f "$HOME/.p10k.zsh" ] && cp "$HOME/.p10k.zsh" "$HOME/.p10k.zsh.backup.$(date +%Y%m%d%H%M%S)"

cat > "$HOME/.p10k.zsh" << 'P10K'
# Gerado por zsh-boost.sh — tema hacker

'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob

  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  autoload -Uz is-at-least && is-at-least 5.1 || return

  # Segmentos da esquerda
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    dir
    vcs
    newline
    prompt_char
  )

  # Segmentos da direita
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status
    command_execution_time
    background_jobs
    node_version
    go_version
    python_version
    time
  )

  # Geral
  typeset -g POWERLEVEL9K_MODE=nerdfont-complete
  typeset -g POWERLEVEL9K_ICON_PADDING=moderate
  typeset -g POWERLEVEL9K_BACKGROUND=                   # transparente
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

  # Prompt char — verde se ok, vermelho se erro
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=076
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=196
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='>'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=false

  # Diretorio — verde neon
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=076
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER=
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=040
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=076
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true

  # Git — cores hacker
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='?'
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=076
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=220
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=196
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_FOREGROUND=196
  typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND=240

  typeset -g POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=0
  typeset -g POWERLEVEL9K_VCS_{STAGED,UNSTAGED,UNTRACKED,CONFLICTED,COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=-1

  typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_COLOR=076
  typeset -g POWERLEVEL9K_VCS_BACKENDS=(git)

  # Status
  typeset -g POWERLEVEL9K_STATUS_EXTENDED_STATES=true
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=076
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=196
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=196

  # Tempo de execucao — so mostra se > 3s
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=101
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'

  # Jobs em background
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=false
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=076

  # Node
  typeset -g POWERLEVEL9K_NODE_VERSION_FOREGROUND=070
  typeset -g POWERLEVEL9K_NODE_VERSION_PROJECT_ONLY=true

  # Go
  typeset -g POWERLEVEL9K_GO_VERSION_FOREGROUND=039
  typeset -g POWERLEVEL9K_GO_VERSION_PROJECT_ONLY=true

  # Python
  typeset -g POWERLEVEL9K_PYTHON_VERSION_FOREGROUND=039
  typeset -g POWERLEVEL9K_PYTHON_VERSION_PROJECT_ONLY=true

  # Hora — discreta
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=240
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'
  typeset -g POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=false

  # Instant prompt
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true

  (( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
} always {
  'builtin' 'unset' 'p10k_config_opts'
}
P10K

echo "  .p10k.zsh gerado!"

# ─── Shell padrao ─────────────────────────────────────────
echo ""
echo "Definindo Zsh como shell padrao..."
sudo usermod -s $(which zsh) $USER

# ─── Summary ──────────────────────────────────────────────
echo ""
echo "zsh-boost instalado com sucesso!"
echo ""
echo "O que foi instalado:"
echo "  - Zsh + Oh My Zsh"
echo "  - Powerlevel10k (tema hacker pre-configurado)"
echo "  - zsh-syntax-highlighting"
echo "  - zsh-autosuggestions"
echo "  - zsh-completions"
echo "  - btop, lsd, bat, fastfetch"
echo "  - JetBrainsMono Nerd Font"
echo ""
echo "Proximos passos:"
echo "  1. Configura a fonte 'JetBrainsMono Nerd Font' no seu terminal"
echo "  2. Roda: exec zsh"
echo ""
echo "  Para ajustar o tema: p10k configure"
echo "  Para ativar o fastfetch: descomenta a linha no final do ~/.zshrc"
