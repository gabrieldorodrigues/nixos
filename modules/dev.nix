# Ferramentas padrão de desenvolvimento de software.
# Toolchains: Nix, Node.js/TypeScript e Python. Docker habilitado.
{ config, pkgs, ... }:

{
  # -------------------------------------------------------------------------
  # Docker (daemon rootful). O usuário é adicionado ao grupo "docker" em
  # modules/users.nix para usar o CLI sem sudo. `lazydocker` já vem instalado.
  # -------------------------------------------------------------------------
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true; # limpa imagens/containers órfãos periodicamente
  };

  environment.systemPackages = with pkgs; [
    # --- CLI dev essentials (agnóstico de linguagem) ---
    ripgrep        # rg - busca rápida em código
    fd             # find moderno
    jq             # processador de JSON
    yq-go          # processador de YAML
    tree           # árvore de diretórios
    wget           # downloads
    httpie         # cliente HTTP (http/https)
    gh             # GitHub CLI
    lazygit        # TUI para git
    delta          # diffs de git com syntax highlight
    neovim         # editor
    just           # runner de tarefas (Justfile)

    # --- Build essentials (necessários p/ módulos nativos de Node/Python) ---
    gcc            # compilador C/C++
    gnumake        # make
    cmake          # build system (node-gyp, extensões nativas)
    pkg-config     # descoberta de libs na compilação

    # --- Nix (dev na própria config) ---
    nil                  # language server do Nix
    alejandra            # formatter (mesmo usado na outra config)
    nix-output-monitor   # `nom` - saída de build mais legível
    nix-tree             # explora dependências do closure

    # --- Node.js / TypeScript ---
    nodejs_22                    # Node LTS (inclui npm e corepack)
    pnpm                         # gerenciador de pacotes
    yarn                         # gerenciador de pacotes
    typescript                   # tsc
    typescript-language-server   # LSP do TypeScript

    # --- Python ---
    python3        # interpretador
    uv             # gerenciador de pacotes/venv rápido
    ruff           # linter + formatter
    pyright        # language server
  ];
}
