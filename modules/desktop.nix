# X11 base, display manager (greetd + dms-greeter) e keymaps.
# O ambiente principal é o Hyprland (Wayland) — ver modules/hyprland.nix.
{ config, pkgs, inputs, ... }:

{
  imports = [ inputs.dank-greeter.nixosModules.default ];

  # Servidor X mínimo. Mantido para apps X11 via XWayland; o Hyprland roda em
  # Wayland por cima. (O KDE Plasma foi removido.)
  services.xserver.enable = true;

  # Login pelo dms-greeter (greetd), com a mesma estética do DMS. Substitui o
  # SDDM. O greeter roda dentro do Hyprland e sincroniza tema/wallpaper/settings
  # do DMS do usuário (via configHome). A sessão Hyprland é registrada por
  # programs.hyprland em modules/hyprland.nix.
  programs.dms-greeter = {
    enable = true;
    compositor.name = "hyprland";
    configHome = "/home/gabrieldorodrigues";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "br";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "br-abnt2";

  # Enable CUPS to print documents.
  services.printing.enable = true;
}
