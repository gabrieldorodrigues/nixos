# Home Manager configuration for gabrieldorodrigues.
{ config, pkgs, lib, ... }:

{
  imports = [
    ./waybar.nix
  ];

  # Keep this in sync with the system stateVersion.
  home.stateVersion = "26.05";
}
