{ inputs, ... }:

{
  imports = [
    # Módulo home-manager do DankMaterialShell (vem do input `dms`).
    inputs.dms.homeModules.dank-material-shell

    # Módulo home-manager do spicetify-nix (customização do Spotify).
    inputs.spicetify-nix.homeManagerModules.spicetify

    ./gtk
    ./hypr
    ./btop
    ./kitty
    ./dms
    ./steam
    ./spotify
    # Seletor de provedor de DNS (Super+Shift+G). Antes fazia parte do módulo da
    # Waybar; foi extraído para cá quando a Waybar/Walker foram removidas (o DMS
    # assume barra, notificações, launcher, lock, clipboard e wallpaper).
    ./dns
    ./rclone
    ./opencode
    ./direnv.nix
    ./herdr.nix
    ./fastfetch
    ./fetch
  ];
}
