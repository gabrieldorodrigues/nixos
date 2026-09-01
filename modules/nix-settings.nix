# Nix daemon settings: enable flakes and periodic garbage collection.
{ config, pkgs, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # Limpa gerações antigas, builds e cache do store periodicamente.
  # Mantém o sistema mais leve sem apagar o necessário para rollback imediato.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
