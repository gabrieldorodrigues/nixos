# Aplicativos gráficos: produtividade, comunicação e utilitários.
{ pkgs, inputs, ... }:

let
  # Zen browser (from flake input).
  zen-browser = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
