# CLI, terminal e ferramentas de linha de comando (TUIs).
{ pkgs, inputs, ... }:

let
  # torlink (torlnk) — buscador de torrents no terminal (from flake input).
  torlink = inputs.torlink.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  environment.systemPackages =
    with pkgs;
    [
      # Essenciais de CLI/sistema.
      git
      vim
      eza
      bat
      fzf
      zoxide
      unzip

      # TUIs.
      lazydocker
      fastfetch
      cmatrix
      tailscale
      # btop is provided by Home Manager (home/programs/btop) so its config
      # (Catppuccin Mocha theme) is managed there.
      torlink
    ];
}
