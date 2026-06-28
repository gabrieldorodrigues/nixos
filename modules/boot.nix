# Bootloader configuration (GRUB + os-prober for Windows dual boot).
{ config, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = false;

  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    # Detecta automaticamente outros sistemas (Windows) em todos os discos.
    useOSProber = true;
  };
}
