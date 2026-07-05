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

  environment.systemPackages = with pkgs; [
    pcsx2 # Emulador de PlayStation 2.
    modrinth-app-wayland # Launcher de Minecraft (mods); wrapper p/ Wayland.
    lutris # Lutris (gerenciador de jogos e emuladores).
  ];
}
