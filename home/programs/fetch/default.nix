{ inputs, ... }:

{
  # fetch (areofyl/fetch) — info do sistema com um cubo 3D animado em ASCII.
  # O módulo vem do flake `areofyl-fetch` (importado abaixo).
  imports = [ inputs.areofyl-fetch.homeManagerModules.default ];

  programs.fetch = {
    enable = true;
    labelColor = "magenta";
    info = [
      "os"
      "host"
      "kernel"
      "uptime"
      "packages"
      "shell"
      "wm"
      "cpu"
      "gpu"
      "memory"
    ];
    speed = 1.0;
    spin = "xy";
  };
}
