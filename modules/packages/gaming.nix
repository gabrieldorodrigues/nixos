# Jogos: Steam, emuladores e launchers.
{ pkgs, ... }:

let
  # O Modrinth App é um app Tauri (WebKitGTK 4.1). Neste host a GPU usa o
  # driver aberto (Mesa nouveau/NVK + zink), que faz o WebKitGTK segfalhar em
  # WebKit::AcceleratedBackingStore::update ao entrar em compositing acelerado
  # (ex.: abrir a página de um modpack) -> "Service Crash".
  #
  # Diagnóstico (via coredumpctl): o crash é o MESMO em nouveau, zink e até
  # llvmpipe, e em Wayland e X11 -> não é a GPU em si. As causas reais são
  # duas, e ambas precisam ser tratadas:
  #   1. WEBKIT_DISABLE_DMABUF_RENDERER=1 deixa o backing store nulo nesta
  #      versão do WebKitGTK -> segfault. Portanto NÃO desabilitamos o DMABUF.
  #   2. Com DMABUF habilitado + GPU nouveau surge o "Error 71 (Protocol
  #      error)". Forçando renderização por software (llvmpipe) o caminho
  #      DMABUF passa a funcionar e o app renderiza sem crashar.
  # Confirmado: Wayland + llvmpipe + DMABUF habilitado = sem crash (baseline
  # crashava em segundos). Não setar WEBKIT_DISABLE_* aqui.
  modrinth-app-wayland = pkgs.symlinkJoin {
    name = "modrinth-app-wayland";
    paths = [ pkgs.modrinth-app ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/ModrinthApp \
        --set GDK_BACKEND wayland \
        --set LIBGL_ALWAYS_SOFTWARE 1 \
        --set GALLIUM_DRIVER llvmpipe
    '';
  };
in
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
    modrinth-app-wayland # Launcher de Minecraft (mods); wrapper p/ Wayland.
    lutris # Lutris (gerenciador de jogos e emuladores).
  ];
}
