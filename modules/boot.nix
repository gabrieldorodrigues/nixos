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

  # Suporte a NTFS (ler/gravar) para os HDs/SSDs internos formatados no Windows.
  # Sem isto o udisks2 (usado pelo Nautilus) não tem o helper mount.ntfs e a
  # montagem falha mesmo com autorização. Puxa o ntfs3g para o sistema.
  boot.supportedFilesystems = [ "ntfs" ];

  # Mouse/teclado USB não eram detectados no boot (era preciso desconectar e
  # reconectar). Em dual boot com Windows, a "Inicialização Rápida" deixa os
  # controladores USB num estado travado; além disso o autosuspend do USB pode
  # deixar dispositivos HID adormecidos. Desligamos o autosuspend do USB para
  # forçar os dispositivos a ficarem sempre ativos já no boot.
  # OBS: o mais eficaz é DESATIVAR o "Fast Startup" no Windows (powercfg /h off).
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];
}
