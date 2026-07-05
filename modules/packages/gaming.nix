# Jogos: Steam, emuladores e launchers.
{ pkgs, ... }:

let
  # O Modrinth App é um app Tauri (WebKitGTK). Sob Wayland o renderizador
  # DMABUF do WebKit quebra com "Error 71 (Protocol error) dispatching to
  # Wayland display" e o app não abre. Desabilitar o DMABUF renderer resolve.
  # Embrulhamos o binário para sempre iniciar com a variável definida.
  modrinth-app-wayland = pkgs.symlinkJoin {
    name = "modrinth-app-wayland";
    paths = [ pkgs.modrinth-app ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/ModrinthApp \
        --set WEBKIT_DISABLE_DMABUF_RENDERER 1
    '';
  };
in
{
  # Enable Steam (sets up 32-bit libs, firewall rules, etc.).
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    pcsx2 # Emulador de PlayStation 2.
    modrinth-app-wayland # Launcher de Minecraft (mods); wrapper p/ Wayland.
    lutris # Lutris (gerenciador de jogos e emuladores).
  ];
}
