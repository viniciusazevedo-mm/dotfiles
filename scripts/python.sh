#!/usr/bin/env bash
# ─────────────────────────────────────────
# python.sh
# pyenv + Python + ferramentas de dev
# ─────────────────────────────────────────

set -e

echo "python-boost — instalando Python via pyenv..."

# ─── Dependências de build ────────────────────────────────
echo "  Instalando dependências de build..."
sudo apt update -q
sudo apt install -y make build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
  libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
  libffi-dev liblzma-dev

# ─── pyenv ────────────────────────────────────────────────
PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"

if [ -d "$PYENV_ROOT" ]; then
  echo "  pyenv já instalado, atualizando..."
  cd "$PYENV_ROOT" && git pull > /dev/null 2>&1
  cd - > /dev/null
else
  echo "  Instalando pyenv..."
  curl -fsSL https://pyenv.run | bash
fi

# Carregar pyenv na sessão atual
export PYENV_ROOT
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# ─── Python latest stable ────────────────────────────────
echo ""
echo "  Buscando versão mais recente do Python 3..."
LATEST_PY=$(pyenv install --list | grep -E "^\s+3\.[0-9]+\.[0-9]+$" | tail -1 | tr -d ' ')
echo "  Versão mais recente: $LATEST_PY"

if pyenv versions --bare | grep -q "^${LATEST_PY}$"; then
  echo "  Python $LATEST_PY já instalado"
else
  echo "  Instalando Python $LATEST_PY (pode demorar)..."
  pyenv install "$LATEST_PY"
fi

pyenv global "$LATEST_PY"

echo "  Python: $(python --version)"
echo "  Pip: $(pip --version | awk '{print $1, $2}')"

# ─── Ferramentas globais via pipx ─────────────────────────
echo ""
echo "  Instalando pipx..."
pip install --user pipx 2>/dev/null || true
python -m pipx ensurepath 2>/dev/null || true

export PATH="$HOME/.local/bin:$PATH"

PIPX_TOOLS=(
  "ruff"
  "black"
  "isort"
  "mypy"
  "poetry"
  "httpie"
  "ipython"
  "rich-cli"
  "cookiecutter"
  "pre-commit"
)

echo "  Instalando ferramentas via pipx..."
for tool in "${PIPX_TOOLS[@]}"; do
  if command -v "$tool" &>/dev/null; then
    echo "    $tool já instalado"
  else
    echo "    Instalando $tool..."
    pipx install "$tool" 2>/dev/null || echo "    Aviso: falha ao instalar $tool"
  fi
done

# ─── Shell integration ───────────────────────────────────
PYENV_BLOCK='
# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"'

for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "pyenv init" "$RC"; then
    echo "$PYENV_BLOCK" >> "$RC"
    echo "  pyenv adicionado em $(basename "$RC")"
  fi
done

echo ""
echo "Python configurado com sucesso!"
echo "  Versão: $(python --version)"
echo "  pyenv: $(pyenv --version)"
echo ""
echo "Ferramentas instaladas:"
echo "  - ruff (linter + formatter ultra-rápido)"
echo "  - black (formatter)"
echo "  - isort (import sorter)"
echo "  - mypy (type checker)"
echo "  - poetry (dependency manager)"
echo "  - httpie (HTTP client)"
echo "  - ipython (REPL avançado)"
echo "  - rich-cli (output bonito)"
echo "  - cookiecutter (project templates)"
echo "  - pre-commit (git hooks)"
echo ""
echo "Comandos úteis:"
echo "  pyenv versions       Listar versões"
echo "  pyenv install <v>    Instalar versão"
echo "  pyenv local <v>      Versão do projeto"
echo "  poetry new <name>    Novo projeto"
