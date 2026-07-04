{ ... }:

{
  # direnv + nix-direnv: carrega automaticamente ambientes por projeto
  # (`use flake` / `use nix`) ao entrar na pasta. Integração com fish incluída.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableFishIntegration = true;
  };
}
