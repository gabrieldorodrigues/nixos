# Mídia: áudio, vídeo, imagem e gráficos.
{ pkgs, ... }:

{
  environment.systemPackages =
    with pkgs;
    [
      # Áudio / vídeo.
      vlc
      tauon
      amberol
      librespot
      audacity
      mangayomi
      termusic
      pear-desktop

      # Imagem / gráficos.
      loupe
      inkscape
      upscayl
    ];
  # NB: o Spotify é instalado pelo spicetify-nix (ver home/programs/spotify),
  # então NÃO adicionamos `pkgs.spotify` aqui para evitar conflito.

  # ArtCraft Crafting Apps (storytold) via flake nix-craftapps. Binários Rust
  # pré-compilados; o módulo cria os comandos GUI + <app>-cli e os launchers.
  # Em NixOS, linkFonts=true (default) provê /usr/share/fonts, que os apps leem.
  # Obs.: `figcraft` pedido não existe upstream (os 12 apps não incluem Figma).
  programs.craftapps = {
    enable = true;
    apps.photocraft.enable = true;
    apps.vectorcraft.enable = true;
    apps.lightcraft.enable = true;
    apps.designcraft.enable = true;
    apps.filmcraft.enable = true;
  };
}
