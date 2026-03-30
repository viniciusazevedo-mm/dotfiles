#!/usr/bin/env bash
# ─────────────────────────────────────────
# tmux.sh
# tmux + config moderna com keybindings produtivos
# ─────────────────────────────────────────

set -e

echo "tmux-boost — instalando e configurando tmux..."

# ─── Instalar tmux ────────────────────────────────────────
if command -v tmux &>/dev/null; then
  echo "  tmux já instalado: $(tmux -V)"
else
  echo "  Instalando tmux..."
  sudo apt update -q
  sudo apt install -y tmux
fi

# ─── TPM (Tmux Plugin Manager) ───────────────────────────
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM_DIR" ]; then
  echo "  TPM já instalado, pulando..."
else
  echo "  Instalando TPM..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

# ─── Backup ───────────────────────────────────────────────
TMUX_CONF="$HOME/.tmux.conf"
if [ -f "$TMUX_CONF" ]; then
  cp "$TMUX_CONF" "$TMUX_CONF.backup.$(date +%Y%m%d%H%M%S)"
  echo "  Backup salvo"
fi

# ─── Config ───────────────────────────────────────────────
cat > "$TMUX_CONF" << 'CONF'
# ─────────────────────────────────────────
# tmux.conf — gerado por dotfiles
# ─────────────────────────────────────────

# ─── Prefix ───────────────────────────────
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# ─── Geral ────────────────────────────────
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"
set -g history-limit 50000
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g set-clipboard on
set -sg escape-time 0
set -g focus-events on
set -g status-interval 5

# ─── Splits ───────────────────────────────
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# Nova janela no diretório atual
bind c new-window -c "#{pane_current_path}"

# ─── Navegação entre panes (vim-style) ───
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Alt+setas sem prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# ─── Resize (vim-style) ──────────────────
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# ─── Navegação entre janelas ─────────────
bind -n S-Left previous-window
bind -n S-Right next-window

# Swap windows
bind -n C-S-Left swap-window -t -1\; select-window -t -1
bind -n C-S-Right swap-window -t +1\; select-window -t +1

# ─── Copy mode (vi) ──────────────────────
setw -g mode-keys vi
bind Enter copy-mode
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-pipe-and-cancel "xclip -selection clipboard"
bind -T copy-mode-vi C-v send -X rectangle-toggle

# ─── Reload config ───────────────────────
bind r source-file ~/.tmux.conf \; display "Config recarregada!"

# ─── Session management ──────────────────
bind S command-prompt -p "Nova session:" "new-session -s '%%'"
bind K confirm-before -p "Kill session #S? (y/n)" kill-session

# ─── Tema hacker ─────────────────────────
set -g status-style "bg=default,fg=#5ebd73"
set -g status-position bottom
set -g status-justify left
set -g status-left-length 40
set -g status-right-length 80

set -g status-left "#[fg=#1a1b26,bg=#5ebd73,bold] #S #[fg=#5ebd73,bg=default] "
set -g status-right "#[fg=#565f89] %H:%M #[fg=#5ebd73]│ #[fg=#565f89]%d/%m/%Y #[fg=#5ebd73]│ #[fg=#565f89]#H "

setw -g window-status-format "#[fg=#565f89] #I:#W "
setw -g window-status-current-format "#[fg=#5ebd73,bold] #I:#W "
setw -g window-status-separator ""

set -g pane-border-style "fg=#3b4261"
set -g pane-active-border-style "fg=#5ebd73"

set -g message-style "bg=default,fg=#5ebd73"
set -g message-command-style "bg=default,fg=#5ebd73"

set -g mode-style "bg=#5ebd73,fg=#1a1b26"

# ─── Plugins ─────────────────────────────
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'

# Resurrect + Continuum (salvar/restaurar sessions)
set -g @continuum-restore 'on'
set -g @resurrect-capture-pane-contents 'on'

# ─── Init TPM ────────────────────────────
run '~/.tmux/plugins/tpm/tpm'
CONF

echo ""
echo "tmux configurado com sucesso!"
echo ""
echo "Keybindings principais (prefix = Ctrl+A):"
echo "  |           Split horizontal"
echo "  -           Split vertical"
echo "  h/j/k/l     Navegar entre panes"
echo "  H/J/K/L     Resize panes"
echo "  Shift+←/→   Navegar entre janelas"
echo "  Enter       Copy mode (vi)"
echo "  r           Reload config"
echo "  S           Nova session"
echo ""
echo "Para instalar plugins: prefix + I (Ctrl+A, I)"
