# Jogos: Steam, emuladores e launchers.
{ pkgs, inputs, ... }:

let
  edenFixed = pkgs.symlinkJoin {
    name = "eden-fixed";
    paths = [ pkgs.eden ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/eden \
        --set GSETTINGS_SCHEMA_DIR "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas" \
        --set-default QT_QPA_PLATFORM xcb
    '';
  };
in
{
  # Overlay do Millennium (loader de temas/plugins do cliente Steam). Expõe o
  # pacote `millennium-steam` usado abaixo como o pacote da Steam.
  nixpkgs.overlays = [ inputs.millennium.overlays.default ];

  # Enable Steam (sets up 32-bit libs, firewall rules, etc.).
  # `millennium-steam` = Steam empacotada com o Millennium embutido.
  programs.steam = {
    enable = true;
    package = pkgs.millennium-steam;
  };

  # Minecraft/Java em NixOS: o Modrinth baixa uma JRE Zulu genérica
  # (dinamicamente ligada) que espera /lib64/ld-linux-x86-64.so.2, ausente no
  # NixOS -> "Could not check Java version at path .../bin/java". O nix-ld
  # fornece esse loader FHS e as libs em runtime, tanto para a JVM quanto para
  # as libs nativas do LWJGL (GLFW/OpenAL/OpenGL) que o jogo carrega depois.
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # JVM
    zlib
    stdenv.cc.cc.lib # libstdc++
    # LWJGL: render (GLFW + OpenGL/Vulkan)
    libGL
    glfw
    vulkan-loader
    # LWJGL: X11 (GLFW usa Xlib mesmo sob XWayland)
    libx11
    libxext
    libxcursor
    libxrandr
    libxxf86vm
    libxi
    libxrender
    # LWJGL: áudio
    openal
    libpulseaudio
    alsa-lib
    # Narrador (text-to-speech) do Minecraft
    flite
  ];

  environment.systemPackages = with pkgs; [
    pcsx2 # Emulador de PlayStation 2.
    lutris # Lutris (gerenciador de jogos e emuladores).
    shadps4-qtlauncher # Emulador de PlayStation 4 (launcher Qt).
    rpcs3 # Emulador de PlayStation 3.
    dolphin-emu # Emulador de GameCube/Wii.
    edenFixed # Switch 1 emulator; corrige schemas GTK e usa XWayland.
    shipwright
    r2modman
  ];
}
