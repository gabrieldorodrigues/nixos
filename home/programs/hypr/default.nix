{ config, lib, pkgs, ... }:

{
  # Hyprland configs are deployed to ~/.config/hypr by Home Manager.
  # The compositor itself is enabled at system level (modules/hyprland.nix).
  xdg.configFile = {
    "hypr/hyprland.lua".source = ./hyprland.lua;
    "hypr/hyprlock.conf".source = ./hyprlock.conf;
    "hypr/hypridle.conf".source = ./hypridle.conf;
  };
}
