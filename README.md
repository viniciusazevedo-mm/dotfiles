<!-- ANSI Shadow Font -->
```
 ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
 ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
 ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
 ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
 ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
 ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
```

<div align="center">

```
 ┌──────────────────────────────────────────────────────────────┐
 │  "The quieter you become, the more you are able to hear."   │
 │                                          — Kali Linux       │
 └──────────────────────────────────────────────────────────────┘
```

[![Shell Script](https://img.shields.io/badge/Shell_Script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=green)](https://www.gnu.org/software/bash/)
[![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Kali](https://img.shields.io/badge/Kali-268BEE?style=for-the-badge&logo=kalilinux&logoColor=white)](https://www.kali.org/)
[![Zsh](https://img.shields.io/badge/Zsh-121011?style=for-the-badge&logo=zsh&logoColor=green)](https://www.zsh.org/)

**Scripts, ferramentas e configurações para transformar qualquer terminal Linux em uma máquina de produtividade.**

*Testado em Ubuntu 22.04+ / 24.04+ e Kali Linux.*

---

</div>

```
 ╔═══════════════════════════════════════════════════════╗
 ║                    T A B L E                          ║
 ║                 O F  C O N T E N T S                  ║
 ╠═══════════════════════════════════════════════════════╣
 ║                                                       ║
 ║  [0x01] .... Quick Install                            ║
 ║  [0x02] .... O que tem aqui                           ║
 ║  [0x03] .... git-boost.sh — Git aliases               ║
 ║  [0x04] .... zsh.sh — Terminal setup                  ║
 ║  [0x05] .... Referência rápida                        ║
 ║  [0x06] .... Screenshots                              ║
 ║  [0x07] .... Contribuindo                             ║
 ║                                                       ║
 ╚═══════════════════════════════════════════════════════╝
```

---

## `[0x01]` Quick Install

```bash
# clone
git clone https://github.com/vynazevedo/dotfiles.git && cd dotfiles

# instala tudo
bash install.sh

# ou escolhe o que quer
bash install.sh --git   # só aliases git
bash install.sh --zsh   # só zsh + tema + ferramentas
```

```
 ┌─ REQUISITOS ──────────────────────────────────────────┐
 │                                                        │
 │  OS .......... Ubuntu 22.04+ / 24.04+ / Kali Linux    │
 │  Packages .... curl, git, sudo                         │
 │  Arch ........ amd64, arm64                            │
 │                                                        │
 └────────────────────────────────────────────────────────┘
```

---

## `[0x02]` O que tem aqui

```
dotfiles/
├── install.sh      # entrypoint — roda tudo ou escolhe módulos
├── git-boost.sh    # aliases e config de produtividade pro git
├── zsh.sh          # zsh + oh-my-zsh + p10k + ferramentas CLI
└── README.md       # você está aqui
```

```
                     ┌──────────────┐
                     │  install.sh  │
                     └──────┬───────┘
                            │
                ┌───────────┴───────────┐
                │                       │
         ┌──────┴──────┐        ┌───────┴──────┐
         │ git-boost.sh│        │    zsh.sh     │
         │             │        │              │
         │ • aliases   │        │ • oh-my-zsh  │
         │ • config    │        │ • p10k theme │
         │ • shortcuts │        │ • plugins    │
         └─────────────┘        │ • lsd,bat... │
                                │ • nerd font  │
                                └──────────────┘
```

---

## `[0x03]` git-boost.sh

> *Git aliases para quem não tem tempo a perder.*

Configura aliases globais no Git. Roda uma vez e funciona em qualquer repo.

```
 ┌─ COMMIT ──────────────────────────────────────────────┐
 │                                                        │
 │  git c  "msg"    commit -m                             │
 │  git ca "msg"    add . + commit -m                     │
 │  git amend       adiciona ao último commit             │
 │  git reword      edita mensagem do último commit       │
 │  git squash N    squash dos últimos N commits          │
 │                                                        │
 ├─ PUSH / PULL ─────────────────────────────────────────┤
 │                                                        │
 │  git p           push                                  │
 │  git pf          push --force-with-lease               │
 │  git pu          push -u origin <branch atual>         │
 │  git up          pull --rebase --autostash             │
 │                                                        │
 ├─ STATUS / LOG ────────────────────────────────────────┤
 │                                                        │
 │  git s           status resumido com branch            │
 │  git l           log --oneline --graph (-20)           │
 │  git ll          log --oneline --graph (all)           │
 │                                                        │
 ├─ BRANCH ──────────────────────────────────────────────┤
 │                                                        │
 │  git b           branch                                │
 │  git recent      branches ordenadas por data           │
 │  git co <b>      checkout                              │
 │  git cob <b>     checkout -b                           │
 │  git sw <b>      switch                                │
 │  git swc <b>     switch -c                             │
 │  git cleanup     remove branches mergeadas             │
 │                                                        │
 ├─ STASH / DIFF ────────────────────────────────────────┤
 │                                                        │
 │  git ss          stash                                 │
 │  git sp          stash pop                             │
 │  git d           diff                                  │
 │  git ds          diff --staged                         │
 │  git bdiff       diff entre branches                   │
 │                                                        │
 ├─ UTILS ───────────────────────────────────────────────┤
 │                                                        │
 │  git undo        desfaz último commit (mixed)          │
 │  git blame       blame -w -C -C -C (detalhado)        │
 │                                                        │
 └────────────────────────────────────────────────────────┘
```

---

## `[0x04]` zsh.sh

> *De terminal padrão pra cockpit de nave em um comando.*

```
 ┌─ O QUE INSTALA ───────────────────────────────────────┐
 │                                                        │
 │  Shell ........ Zsh + Oh My Zsh                        │
 │  Tema ......... Powerlevel10k (hacker theme)           │
 │  Plugins ...... syntax-highlighting                    │
 │                 autosuggestions                         │
 │                 completions                             │
 │  Tools ........ lsd (ls melhorado)                     │
 │                 bat (cat com syntax highlight)          │
 │                 btop (top melhorado)                    │
 │                 fastfetch (neofetch moderno)            │
 │  Font ......... JetBrainsMono Nerd Font                │
 │                                                        │
 └────────────────────────────────────────────────────────┘
```

### Aliases do .zshrc

```
 NAVEGAÇÃO              SISTEMA                DEV
 ─────────              ───────                ───
 ..    cd ..            update  apt upgrade    py     python3
 ...   cd ../..         ports   ss -tulnp     serve  http.server
 ....  cd ../../..      myip    ifconfig.me
 ~     cd ~             reload  source .zshrc
                        zshrc   edita .zshrc
 LS (via lsd)
 ─────────              GIT RÁPIDO
 ls    lsd              ──────────
 ll    lsd -la          g     git
 lt    lsd --tree       gs    git s
                        gl    git l
```

### Bloco gerenciado

O `zsh.sh` usa marcadores no `.zshrc`:

```bash
# >>> zsh-boost managed block >>>
# ... config gerenciada aqui ...
# <<< zsh-boost managed block <<<

# Suas customizações aqui embaixo — nunca são sobrescritas
export MY_VAR="safe"
```

Roda quantas vezes quiser — suas customizações são preservadas.

---

## `[0x05]` Referência rápida

```
 ┌─ PÓS-INSTALAÇÃO ─────────────────────────────────────┐
 │                                                        │
 │  1. Configure a fonte no terminal:                     │
 │     → JetBrainsMono Nerd Font                          │
 │                                                        │
 │  2. Ative o Zsh:                                       │
 │     $ exec zsh                                         │
 │                                                        │
 │  3. Customize o tema (opcional):                       │
 │     $ p10k configure                                   │
 │                                                        │
 │  4. Ative extras no ~/.zshrc (descomente):             │
 │     → cat=bat (alias)                                  │
 │     → fastfetch no startup                             │
 │                                                        │
 └────────────────────────────────────────────────────────┘
```

### Compatibilidade

```
 DISTRO              VERSÃO       STATUS
 ──────              ──────       ──────
 Ubuntu              22.04 LTS    ✔ testado
 Ubuntu              24.04 LTS    ✔ testado
 Kali Linux          2024.x+      ✔ testado
 Debian              12+          ✔ compatível
 WSL2 (Ubuntu)       qualquer     ✔ testado
```

---

## `[0x06]` Screenshots

> *em breve — PRs com screenshots são bem-vindos*

```
 ┌────────────────────────────────────────────────────────┐
 │ user@kali ~/projects/dotfiles (main)                   │
 │ >                                                      │
 │                                                        │
 │  A experiência é melhor ao vivo.                       │
 │  Roda o install.sh e vê por conta própria.             │
 │                                                        │
 └────────────────────────────────────────────────────────┘
```

---

## `[0x07]` Contribuindo

```
 1. Fork o repo
 2. Crie uma branch (git swc minha-feature)
 3. Commit (git c "add: minha feature")
 4. Push (git pu)
 5. Abre um PR
```

Ideias pro roadmap:

```
 [ ] vim/neovim config (tema hacker)
 [ ] tmux config + keybindings
 [ ] docker aliases & helpers
 [ ] SSH hardening script
 [ ] pentest toolkit setup (Kali)
 [ ] firewall/iptables templates
 [ ] cron job templates
 [ ] sysctl tuning
```

---

<div align="center">

```
 ┌──────────────────────────────────────────────────────────────┐
 │                                                              │
 │   "Talk is cheap. Show me the code." — Linus Torvalds       │
 │                                                              │
 └──────────────────────────────────────────────────────────────┘
```

**[@vynazevedo](https://github.com/vynazevedo)**

</div>
