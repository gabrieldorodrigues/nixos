# Jogos: Steam, emuladores e launchers.
{ pkgs, ... }:

{
  # Enable Steam (sets up 32-bit libs, firewall rules, etc.).
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    pcsx2 # Emulador de PlayStation 2.
    modrinth-app # Launcher de Minecraft (mods).
    lutris # Lutris (gerenciador de jogos e emuladores).
  ];
}
