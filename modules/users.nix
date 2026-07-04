# User accounts.
{ config, pkgs, ... }:

{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."gabrieldorodrigues" = {
    isNormalUser = true;
    description = "gabrieldorodrigues";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.fish;
  };
}
