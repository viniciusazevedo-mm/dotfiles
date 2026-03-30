#!/usr/bin/env bash
# ─────────────────────────────────────────
# rust.sh
# Rust via rustup + ferramentas essenciais
# ─────────────────────────────────────────

set -e

echo "rust-boost — instalando Rust..."

# ─── Dependências ─────────────────────────────────────────
echo "  Instalando dependências de build..."
sudo apt update -q
sudo apt install -y build-essential pkg-config libssl-dev cmake

# ─── Rustup ───────────────────────────────────────────────
if command -v rustup &>/dev/null; then
  echo "  Rust já instalado, atualizando..."
  rustup update stable
else
  echo "  Instalando via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
fi

echo "  Rust: $(rustc --version)"
echo "  Cargo: $(cargo --version)"

# ─── Componentes ──────────────────────────────────────────
echo ""
echo "  Instalando componentes..."
rustup component add rustfmt clippy rust-analyzer rust-src

# ─── Ferramentas via cargo ────────────────────────────────
echo ""
echo "  Instalando ferramentas via cargo..."

CARGO_TOOLS=(
  "cargo-watch"
  "cargo-edit"
  "cargo-expand"
  "cargo-audit"
  "cargo-nextest"
  "bacon"
  "tokei"
  "hyperfine"
  "bandwhich"
  "bottom"
  "du-dust"
  "procs"
  "sd"
  "zoxide"
)

for tool in "${CARGO_TOOLS[@]}"; do
  if cargo install --list 2>/dev/null | grep -q "^$tool "; then
    echo "    $tool já instalado"
  else
    echo "    Instalando $tool..."
    cargo install "$tool" 2>/dev/null || echo "    Aviso: falha ao instalar $tool"
  fi
done

# ─── Shell integration ───────────────────────────────────
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && ! grep -q "cargo/env" "$RC"; then
    echo '' >> "$RC"
    echo '# Rust' >> "$RC"
    echo '[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"' >> "$RC"
    echo "  Rust PATH adicionado em $(basename "$RC")"
  fi
done

# Zoxide init
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ] && command -v zoxide &>/dev/null && ! grep -q "zoxide init" "$RC"; then
    if [[ "$RC" == *"zshrc"* ]]; then
      echo 'eval "$(zoxide init zsh)"' >> "$RC"
    else
      echo 'eval "$(zoxide init bash)"' >> "$RC"
    fi
  fi
done

echo ""
echo "Rust configurado com sucesso!"
echo ""
echo "Componentes:"
echo "  - rustfmt (formatter)"
echo "  - clippy (linter)"
echo "  - rust-analyzer (LSP)"
echo ""
echo "Ferramentas instaladas:"
echo "  - cargo-watch (file watcher)"
echo "  - cargo-edit (add/rm dependencies)"
echo "  - cargo-expand (macro expansion)"
echo "  - cargo-audit (vulnerability check)"
echo "  - cargo-nextest (test runner rápido)"
echo "  - bacon (background checker)"
echo "  - tokei (code stats)"
echo "  - hyperfine (benchmark CLI)"
echo "  - bandwhich (network monitor)"
echo "  - bottom (system monitor)"
echo "  - du-dust (disk usage)"
echo "  - procs (ps replacement)"
echo "  - sd (sed replacement)"
echo "  - zoxide (cd inteligente)"
echo ""
echo "Dica: use 'z' ao invés de 'cd' (powered by zoxide)"
