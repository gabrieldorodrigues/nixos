{ inputs, ... }:

{
  imports = [
    # Módulo home-manager do DankMaterialShell (vem do input `dms`).
    inputs.dms.homeModules.dank-material-shell

    ./gtk
    ./hypr
    ./btop
    ./kitty
    ./dms
    # Seletor de provedor de DNS (Super+Shift+G). Antes fazia parte do módulo da
    # Waybar; foi extraído para cá quando a Waybar/Walker foram removidas (o DMS
    # assume barra, notificações, launcher, lock, clipboard e wallpaper).
    ./dns
    ./rclone
    ./opencode
    ./direnv.nix
    ./fastfetch
  ];
}
