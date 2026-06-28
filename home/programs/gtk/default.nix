{ config, lib, pkgs, ... }:

{
  # GTK3/GTK4 dark theme settings.
  xdg.configFile = {
    "gtk-3.0/settings.ini".source = ./settings.ini;
    "gtk-4.0/settings.ini".source = ./settings.ini;
  };
}
