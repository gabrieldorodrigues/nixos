# User accounts.
{ config, pkgs, ... }:

{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."gabrieldorodrigues" = {
    isNormalUser = true;
    description = "gabrieldorodrigues";
    # "i2c": acesso a /dev/i2c-* (DDC/CI) para o ddcutil controlar o brilho de
    # monitores externos pelo plugin ddcBrightness do DMS. O grupo é criado por
    # hardware.i2c.enable em modules/hyprland.nix.
    extraGroups = [ "networkmanager" "wheel" "docker" "i2c" ];
    shell = pkgs.fish;
  };
}
