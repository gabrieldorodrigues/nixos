# System packages, fonts and nixpkgs settings.
{ config, pkgs, lib, inputs, ... }:

let
  # Zen browser (from flake input).
  zen-browser = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # torlink (torlnk) — buscador de torrents no terminal (from flake input).
  torlink = inputs.torlink.packages.${pkgs.stdenv.hostPlatform.system}.default;

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
      btop
      torlink

      # GUIs
      kdePackages.kate
      # kitty is provided by Home Manager (home/programs/kitty) so its config
      # (font size, Catppuccin theme) is managed there.
      alacritty
      loupe
      deluge
      vscode
      obsidian
      onlyoffice-desktopeditors
      inkscape
      vlc
      upscayl
      foliate
      zen-browser
      discord
      tailscale
      audacity
      mangayomi
      bitwarden-desktop

      # Icon theme (used by Walker and file managers).
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

  # Obsidian ships Electron 39, which nixpkgs marks insecure past its EOL date.
  # Allow it explicitly so rebuilds succeed.
  nixpkgs.config.permittedInsecurePackages = [ "electron-39.8.10" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = systemPackages ++ filteredDiscretionaryPackages;

  # Define o Loupe como visualizador de imagens padrão.
  xdg.mime.defaultApplications = {
    # Firefox como navegador padrão.
    "text/html" = "firefox.desktop";
    "application/xhtml+xml" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    "x-scheme-handler/about" = "firefox.desktop";

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

    # Foliate como leitor de e-books padrão.
    "application/epub+zip" = "com.github.johnfactotum.Foliate.desktop";
    "application/x-mobipocket-ebook" = "com.github.johnfactotum.Foliate.desktop";
    "application/vnd.amazon.mobi8-ebook" = "com.github.johnfactotum.Foliate.desktop";
    "application/x-fictionbook+xml" = "com.github.johnfactotum.Foliate.desktop";
    "application/x-zip-compressed-fb2" = "com.github.johnfactotum.Foliate.desktop";
    "application/vnd.comicbook+zip" = "com.github.johnfactotum.Foliate.desktop";
  };

  # Nerd Font para renderizar os ícones do Starship corretamente.
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
  ];
}
