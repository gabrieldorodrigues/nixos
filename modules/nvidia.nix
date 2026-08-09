# Driver proprietário NVIDIA (GeForce RTX 2060, Turing).
#
# Motivo: a máquina estava usando o driver aberto `nouveau`, que não fornece a
# biblioteca NVML (`libnvidia-ml`) nem o `nvidia-smi`. Ferramentas como o btop
# leem métricas da GPU NVIDIA justamente via NVML, então sem o driver
# proprietário a GPU simplesmente não aparece. Além do monitoramento, o driver
# proprietário dá muito melhor desempenho/estabilidade em Wayland/Hyprland.
{ config, pkgs, ... }:

{
  # Faz o Xorg/Wayland usarem o driver "nvidia" em vez do nouveau.
  services.xserver.videoDrivers = [ "nvidia" ];

  # Stack gráfica (OpenGL/Vulkan) com libs 32-bit para jogos/Proton.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    # Essencial para Wayland/Hyprland funcionar bem com a NVIDIA.
    modesetting.enable = true;

    # Turing (RTX 20xx) funciona melhor com o módulo FECHADO. O módulo aberto
    # ("open") é recomendado apenas para Ampere+ (RTX 30xx em diante).
    open = false;

    # Disponibiliza o utilitário `nvidia-settings`.
    nvidiaSettings = true;

    # Power management: mantém desligado por padrão (mais estável). Ligue apenas
    # se tiver problemas de suspensão/retorno de sleep.
    powerManagement.enable = false;

    # Usa o driver "stable" casado com o kernel atual (traz NVML + nvidia-smi).
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
