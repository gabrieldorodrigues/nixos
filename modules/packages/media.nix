# Mídia: áudio, vídeo, imagem e gráficos.
{ pkgs, lib, ... }:

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
    ]
    ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
      spotify
    ];
}
