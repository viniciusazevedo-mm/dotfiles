#!/usr/bin/env bash
# ─────────────────────────────────────────
# neovim.sh
# Neovim + config minimalista de produtividade
# ─────────────────────────────────────────

set -e

echo "neovim-boost — instalando e configurando Neovim..."

# ─── Detecção de distro ───────────────────────────────────
if [ -f /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  DISTRO_ID="${ID}"
else
  DISTRO_ID="unknown"
fi

# ─── Instalar Neovim ─────────────────────────────────────
if command -v nvim &>/dev/null; then
  echo "  Neovim já instalado: $(nvim --version | head -1)"
else
  echo "  Instalando Neovim..."
  case "$DISTRO_ID" in
    ubuntu)
      sudo add-apt-repository -y ppa:neovim-ppa/unstable 2>/dev/null || true
      sudo apt update -q
      sudo apt install -y neovim
      ;;
    kali|debian)
      sudo apt update -q
      sudo apt install -y neovim
      ;;
    fedora)
      sudo dnf install -y neovim
      ;;
    arch|manjaro)
      sudo pacman -S --noconfirm neovim
      ;;
    *)
      echo "  Distro não suportada para instalação automática."
      echo "  Instale manualmente: https://neovim.io"
      exit 1
      ;;
  esac
fi

# ─── Dependências ─────────────────────────────────────────
echo "  Instalando dependências..."
sudo apt install -y ripgrep fd-find xclip 2>/dev/null || true

if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
  mkdir -p ~/.local/bin
  ln -sf "$(command -v fdfind)" ~/.local/bin/fd
fi

# ─── Estrutura de diretórios ──────────────────────────────
NVIM_DIR="$HOME/.config/nvim"
mkdir -p "$NVIM_DIR/lua"

# ─── Backup ───────────────────────────────────────────────
if [ -f "$NVIM_DIR/init.lua" ]; then
  cp "$NVIM_DIR/init.lua" "$NVIM_DIR/init.lua.backup.$(date +%Y%m%d%H%M%S)"
  echo "  Backup do init.lua salvo"
fi

# ─── init.lua ─────────────────────────────────────────────
cat > "$NVIM_DIR/init.lua" << 'LUA'
-- ─────────────────────────────────────────
-- Neovim config — gerado por dotfiles
-- ─────────────────────────────────────────

-- ─── Leader key ──────────────────────────
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ─── Opções ──────────────────────────────
local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.showmode = false
opt.clipboard = "unnamedplus"
opt.breakindent = true
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.signcolumn = "yes"
opt.updatetime = 250
opt.timeoutlen = 300
opt.splitright = true
opt.splitbelow = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.inccommand = "split"
opt.cursorline = true
opt.scrolloff = 10
opt.hlsearch = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.wrap = false
opt.termguicolors = true
opt.background = "dark"
opt.swapfile = false

-- ─── Keymaps ─────────────────────────────
local map = vim.keymap.set

-- Limpar busca com Esc
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Navegação entre splits
map("n", "<C-h>", "<C-w><C-h>")
map("n", "<C-l>", "<C-w><C-l>")
map("n", "<C-j>", "<C-w><C-j>")
map("n", "<C-k>", "<C-w><C-k>")

-- Mover linhas no visual mode
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- Manter cursor centrado
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Buffer navigation
map("n", "<leader>bn", ":bnext<CR>")
map("n", "<leader>bp", ":bprevious<CR>")
map("n", "<leader>bd", ":bdelete<CR>")

-- Salvar e sair rápido
map("n", "<leader>w", ":w<CR>")
map("n", "<leader>q", ":q<CR>")
map("n", "<leader>x", ":x<CR>")

-- File explorer
map("n", "<leader>e", vim.cmd.Ex)

-- Selecionar tudo
map("n", "<C-a>", "ggVG")

-- Copiar para clipboard do sistema
map("v", "<leader>y", '"+y')

-- ─── Lazy.nvim (plugin manager) ─────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ─── Plugins ─────────────────────────────
require("lazy").setup({
  -- Tema hacker
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",
        transparent = true,
        terminal_colors = true,
        styles = {
          comments = { italic = true },
          sidebars = "transparent",
          floats = "transparent",
        },
      })
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "tokyonight",
          component_separators = { left = "│", right = "│" },
          section_separators = { left = "", right = "" },
        },
      })
    end,
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files)
      vim.keymap.set("n", "<leader>fg", builtin.live_grep)
      vim.keymap.set("n", "<leader>fb", builtin.buffers)
      vim.keymap.set("n", "<leader>fh", builtin.help_tags)
      vim.keymap.set("n", "<leader>fr", builtin.oldfiles)
    end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash", "lua", "vim", "vimdoc", "go", "rust",
          "python", "javascript", "typescript", "json",
          "yaml", "toml", "html", "css", "dockerfile",
          "markdown", "sql",
        },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "gopls", "pyright", "ts_ls" },
        automatic_installation = true,
      })

      local lspconfig = require("lspconfig")
      local capabilities = vim.lsp.protocol.make_client_capabilities()

      local servers = { "lua_ls", "gopls", "pyright", "ts_ls", "rust_analyzer" }
      for _, server in ipairs(servers) do
        lspconfig[server].setup({ capabilities = capabilities })
      end

      vim.keymap.set("n", "gd", vim.lsp.buf.definition)
      vim.keymap.set("n", "gr", vim.lsp.buf.references)
      vim.keymap.set("n", "K", vim.lsp.buf.hover)
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)
      vim.keymap.set("n", "<leader>fd", vim.diagnostic.open_float)
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
    end,
  },

  -- Autocomplete
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    end,
  },

  -- Autopairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },

  -- Git signs
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "│" },
          change = { text = "│" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
        },
      })
    end,
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function()
      require("ibl").setup({
        indent = { char = "│" },
        scope = { enabled = true },
      })
    end,
  },

  -- Comment toggle
  { "numToStr/Comment.nvim", config = true },

  -- Surround
  { "kylechui/nvim-surround", event = "VeryLazy", config = true },

  -- Which key
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup()
    end,
  },
})

-- ─── Diagnostic config ───────────────────
vim.diagnostic.config({
  virtual_text = { prefix = "●" },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- ─── Highlight on yank ──────────────────
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- ─── Trim trailing whitespace on save ────
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
})
LUA

echo ""
echo "Neovim configurado com sucesso!"
echo ""
echo "Plugins instalados (via lazy.nvim):"
echo "  - tokyonight (tema)"
echo "  - lualine (status bar)"
echo "  - telescope (fuzzy finder)"
echo "  - treesitter (syntax highlight)"
echo "  - LSP + Mason (autocomplete/go-to-def)"
echo "  - nvim-cmp (autocomplete)"
echo "  - gitsigns, autopairs, comment, surround"
echo "  - which-key (ajuda de keybindings)"
echo ""
echo "Keybindings principais (leader = Space):"
echo "  <leader>ff     Buscar arquivos"
echo "  <leader>fg     Buscar texto (grep)"
echo "  <leader>fb     Listar buffers"
echo "  <leader>e      File explorer"
echo "  <leader>w      Salvar"
echo "  <leader>q      Sair"
echo "  gd             Go to definition"
echo "  gr             Go to references"
echo "  K              Hover (docs)"
echo "  <leader>rn     Rename"
echo "  <leader>ca     Code action"
echo ""
echo "Rode 'nvim' para instalar os plugins automaticamente."
