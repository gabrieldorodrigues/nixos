# Home Manager configuration for gabrieldorodrigues.
{ config, pkgs, lib, ... }:

{
  imports = [
    ./programs
  ];

  home = {
    username = "gabrieldorodrigues";
    homeDirectory = "/home/gabrieldorodrigues";
  };

  # Keep this in sync with the system stateVersion.
  home.stateVersion = "26.05";
}
