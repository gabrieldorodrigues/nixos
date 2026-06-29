# System packages, fonts and nixpkgs settings.
{ config, pkgs, lib, inputs, ... }:

let
  # Zen browser (from flake input).
  zen-browser = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Pacotes essenciais de CLI/sistema - não devem ser excluídos.
  systemPackages = with pkgs; [
    git
    vim
    eza
    bat
    fzf
    zoxide
    unzip
  ];

  # Pacotes discricionários - podem ser removidos via `excludePackages`.
  discretionaryPackages =
    with pkgs;
    [
      # TUIs
      lazydocker
      fastfetch
      cmatrix
      htop
      btop

      # GUIs
      kdePackages.kate
      kitty
      alacritty
      loupe
      deluge
      vscode
      obsidian
      onlyoffice-desktopeditors
      inkscape
      vlc
      readest
      foliate
      zen-browser

      # Icon theme used by Rofi (config.rasi -> icon-theme "Papirus").
      papirus-icon-theme
    ]
    ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
      spotify
    ];

  # Edite esta lista para remover pacotes discricionários.
  excludePackages = [ ];

  # Só permite excluir os discricionários, pra não quebrar o sistema.
  filteredDiscretionaryPackages =
    lib.lists.subtractLists excludePackages discretionaryPackages;
in
{
  # Install firefox.
  programs.firefox.enable = true;

  # Enable Steam (sets up 32-bit libs, firewall rules, etc.).
  programs.steam.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = systemPackages ++ filteredDiscretionaryPackages;

  # Define o Loupe como visualizador de imagens padrão.
  xdg.mime.defaultApplications = {
    "image/png" = "org.gnome.Loupe.desktop";
    "image/jpeg" = "org.gnome.Loupe.desktop";
    "image/gif" = "org.gnome.Loupe.desktop";
    "image/webp" = "org.gnome.Loupe.desktop";
    "image/bmp" = "org.gnome.Loupe.desktop";
    "image/tiff" = "org.gnome.Loupe.desktop";
    "image/svg+xml" = "org.gnome.Loupe.desktop";
    "image/x-icon" = "org.gnome.Loupe.desktop";
    "image/heif" = "org.gnome.Loupe.desktop";
    "image/avif" = "org.gnome.Loupe.desktop";
  };

  # Nerd Font para renderizar os ícones do Starship corretamente.
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
  ];
}
