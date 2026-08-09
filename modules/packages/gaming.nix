# Jogos: Steam, emuladores e launchers.
{ pkgs, ... }:

{
  # Enable Steam (sets up 32-bit libs, firewall rules, etc.).
  programs.steam.enable = true;

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
  ];
}
