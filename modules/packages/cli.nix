# CLI, terminal e ferramentas de linha de comando (TUIs).
{ pkgs, ... }:

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
      # torlink (torlnk) runs in a Docker container (modules/torlink.nix); the
      # `torlnk` command on PATH is a thin `docker exec` wrapper installed there.
    ];
}
