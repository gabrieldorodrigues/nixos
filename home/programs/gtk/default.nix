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
    # GTK4/libadwaita: use the real "Adwaita" theme. There is no "Adwaita-dark"
    # GTK4 theme; dark mode is a variant selected via color-scheme=prefer-dark.
    # Naming a nonexistent theme here breaks libadwaita rendering.
    "gtk-4.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
      gtk-theme-name=Adwaita
      gtk-icon-theme-name=Papirus-Dark
      gtk-cursor-theme-name=Adwaita
      gtk-cursor-theme-size=24
    '';
  };
}
