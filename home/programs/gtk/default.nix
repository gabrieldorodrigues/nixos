{ config, lib, pkgs, ... }:

{
  # GTK3/GTK4 dark theme settings.
  xdg.configFile = {
    "gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
      gtk-theme-name=Adwaita-dark
      gtk-icon-theme-name=Papirus-Dark
      gtk-cursor-theme-name=Adwaita
      gtk-cursor-theme-size=24
    '';
    "gtk-4.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
      gtk-theme-name=Adwaita-dark
      gtk-icon-theme-name=Papirus-Dark
      gtk-cursor-theme-name=Adwaita
      gtk-cursor-theme-size=24
    '';
  };
}
