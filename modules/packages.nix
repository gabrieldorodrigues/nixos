# Configurações de pacotes: nixpkgs, fontes e aplicativos padrão.
# As listas de pacotes ficam em ./packages/<categoria>.nix.
{ pkgs, ... }:

{
  imports = [
    ./packages/cli.nix
    ./packages/apps.nix
    ./packages/gaming.nix
    ./packages/media.nix
  ];

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Obsidian ships Electron 39, which nixpkgs marks insecure past its EOL date.
  # Allow it explicitly so rebuilds succeed.
  nixpkgs.config.permittedInsecurePackages = [ "electron-39.8.10" ];

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
