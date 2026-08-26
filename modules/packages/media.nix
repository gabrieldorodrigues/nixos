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
      audacity
      mangayomi

      # Imagem / gráficos.
      loupe
      inkscape
      upscayl
    ];
  # NB: o Spotify é instalado pelo spicetify-nix (ver home/programs/spotify),
  # então NÃO adicionamos `pkgs.spotify` aqui para evitar conflito.
}
