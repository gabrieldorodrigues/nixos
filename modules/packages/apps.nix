# Aplicativos gráficos: produtividade, comunicação e utilitários.
{ pkgs, inputs, ... }:

let
  # Zen browser (from flake input).
  zen-browser = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # readest is a Tauri/WebKitGTK app. On Wayland its DMABUF renderer triggers
  # "Error 71 (Protocol error) dispatching to Wayland display" and the app
  # crashes on startup. Disabling the DMABUF renderer makes WebKitGTK fall back
  # to a working compositing path. We wrap only readest (via symlinkJoin +
  # wrapProgram) so no other app is affected. Shadows pkgs.readest below.
  readest = pkgs.symlinkJoin {
    name = "readest";
    paths = [ pkgs.readest ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/readest \
        --set WEBKIT_DISABLE_DMABUF_RENDERER 1
    '';
  };
in
{
  environment.systemPackages =
    with pkgs;
    [
      # Editores / produtividade.
      kdePackages.kate
      gnome-calculator
      vscode
      obsidian
      onlyoffice-desktopeditors
      foliate
      readest
      drawing

      # Navegador / comunicação.
      zen-browser
      discord

      # Terminal gráfico (kitty é gerenciado pelo Home Manager).
      alacritty

      # Utilitários.
      bitwarden-desktop
      qdirstat
      localsend
      deluge
      proton-vpn

      # Tema de ícones (usado pelo Walker e gerenciadores de arquivos).
      papirus-icon-theme
    ];
}
