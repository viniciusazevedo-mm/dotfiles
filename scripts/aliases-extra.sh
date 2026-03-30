#!/usr/bin/env bash
# ─────────────────────────────────────────
# aliases-extra.sh
# Aliases e funções extras de produtividade
# ─────────────────────────────────────────

set -e

echo "aliases-extra — instalando aliases de produtividade..."

ALIAS_FILE="$HOME/.extra_aliases"

cat > "$ALIAS_FILE" << 'ALIASES'
# ─────────────────────────────────────────
# Extra aliases — gerado por dotfiles
# ─────────────────────────────────────────

# ─── Navegação rápida ────────────────────
alias h='cd ~'
alias dev='cd ~/dev 2>/dev/null || cd ~/projects 2>/dev/null || cd ~/workspace'
alias dl='cd ~/Downloads'
alias dt='cd ~/Desktop'
alias tmp='cd /tmp'

# ─── Arquivos e diretórios ───────────────
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -Iv'
alias ln='ln -iv'
alias chmod='chmod -v'
alias chown='chown -v'
alias df='df -h'
alias du='du -h'
alias free='free -h'

# Tamanho de diretório
sizeof() {
  du -sh "${1:-.}" 2>/dev/null
}

# Criar e entrar no diretório
mkcd() {
  mkdir -p "$1" && cd "$1" || return
}

# ─── Busca ────────────────────────────────
alias ff='find . -type f -name'
alias fd='find . -type d -name'

# Grep colorido
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# Buscar no histórico
alias hg='history | grep'

# ─── Processos ────────────────────────────
alias psg='ps aux | grep -v grep | grep'
alias psmem='ps aux --sort=-%mem | head -20'
alias pscpu='ps aux --sort=-%cpu | head -20'

# Kill por nome
killname() {
  pgrep -f "$1" | xargs -r kill -9
  echo "Processos '$1' terminados"
}

# ─── Sistema ──────────────────────────────
alias now='date "+%Y-%m-%d %H:%M:%S"'
alias week='date +%V'
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'

# Quem está logado
alias who='w -h'

# Monitorar logs em tempo real
alias syslog='sudo tail -f /var/log/syslog'
alias authlog='sudo tail -f /var/log/auth.log'

# ─── Rede rápida ─────────────────────────
alias ping='ping -c 5'
alias wget='wget -c'
alias fastping='ping -c 100 -s.2'

# ─── Compressão ──────────────────────────
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"     ;;
      *.tar.gz)    tar xzf "$1"     ;;
      *.tar.xz)    tar xJf "$1"     ;;
      *.bz2)       bunzip2 "$1"     ;;
      *.rar)       unrar x "$1"     ;;
      *.gz)        gunzip "$1"      ;;
      *.tar)       tar xf "$1"      ;;
      *.tbz2)      tar xjf "$1"     ;;
      *.tgz)       tar xzf "$1"     ;;
      *.zip)       unzip "$1"       ;;
      *.Z)         uncompress "$1"  ;;
      *.7z)        7z x "$1"        ;;
      *.xz)        unxz "$1"        ;;
      *.zst)       unzstd "$1"      ;;
      *)           echo "'$1' não pode ser extraído" ;;
    esac
  else
    echo "'$1' não é um arquivo válido"
  fi
}

# Comprimir diretório
compress() {
  tar -czf "${1%/}.tar.gz" "$1"
  echo "Criado: ${1%/}.tar.gz"
}

# ─── Git extras ──────────────────────────
alias glog='git log --oneline --graph --decorate --all -20'
alias gdiff='git diff --stat'
alias gstash='git stash list'
alias gwip='git add -A && git commit -m "WIP: $(date +%H:%M)"'

# ─── Encoding ────────────────────────────
alias urlencode='python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))"'
alias urldecode='python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1]))"'
alias b64encode='python3 -c "import sys, base64; print(base64.b64encode(sys.argv[1].encode()).decode())"'
alias b64decode='python3 -c "import sys, base64; print(base64.b64decode(sys.argv[1]).decode())"'

# ─── JSON ─────────────────────────────────
alias jsonpp='python3 -m json.tool'
alias jwt='python3 -c "import sys,json,base64;parts=sys.argv[1].split(\".\");[print(json.dumps(json.loads(base64.urlsafe_b64decode(p+\"==\")),indent=2)) for p in parts[:2]]"'

# ─── Gerador de senhas ───────────────────
genpass() {
  local length="${1:-32}"
  openssl rand -base64 "$length" | tr -d '\n' | head -c "$length"
  echo ""
}

# ─── Cheat sheet rápido ──────────────────
cheat() {
  curl -s "cheat.sh/$1"
}

# ─── Weather ──────────────────────────────
weather() {
  curl -s "wttr.in/${1:-}"
}

# ─── Servir diretório atual ──────────────
serve() {
  local port="${1:-8000}"
  echo "Servindo em http://localhost:$port"
  python3 -m http.server "$port"
}

# ─── Diff bonito ─────────────────────────
if command -v delta &>/dev/null; then
  alias diff='delta'
fi

# ─── Calculator ──────────────────────────
calc() {
  python3 -c "print($*)"
}

# ─── Notes rápidas ───────────────────────
NOTES_DIR="$HOME/.notes"

note() {
  mkdir -p "$NOTES_DIR"
  case "${1:-}" in
    ls)    ls -1 "$NOTES_DIR" ;;
    rm)    rm -i "$NOTES_DIR/$2" ;;
    cat)   cat "$NOTES_DIR/$2" ;;
    "")    echo "Uso: note <ls|rm|cat|texto>" ;;
    *)     echo "$(date '+%Y-%m-%d %H:%M') | $*" >> "$NOTES_DIR/quick.md"
           echo "Nota salva em $NOTES_DIR/quick.md" ;;
  esac
}
ALIASES

# ─── Source nos shells ────────────────────────────────────
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "extra_aliases" "$RC"; then
    echo "" >> "$RC"
    echo "# Extra aliases" >> "$RC"
    echo "[ -f ~/.extra_aliases ] && source ~/.extra_aliases" >> "$RC"
  fi
done

echo ""
echo "Aliases extras instalados com sucesso!"
echo ""
echo "Destaques:"
echo "  extract <file>     Extrair qualquer formato"
echo "  compress <dir>     Comprimir diretório"
echo "  mkcd <dir>         Criar e entrar no diretório"
echo "  genpass [len]      Gerar senha segura"
echo "  cheat <cmd>        Cheat sheet do comando"
echo "  weather [city]     Previsão do tempo"
echo "  serve [port]       HTTP server rápido"
echo "  calc <expr>        Calculadora"
echo "  note <texto>       Notas rápidas"
echo "  jwt <token>        Decodificar JWT"
echo "  b64encode/decode   Base64"
echo "  urlencode/decode   URL encoding"
echo "  psmem / pscpu      Top processos por memória/CPU"
echo "  hg <text>          Buscar no histórico"
