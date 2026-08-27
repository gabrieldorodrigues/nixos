{ ... }:

{
  # herdr — gerenciador de workspace de terminal para agentes de IA (o binário
  # vem de modules/dev.nix, do nixpkgs-unstable). O "super"/leader do herdr é a
  # tecla de prefixo (`[keys].prefix`), padrão `ctrl+b`. Aqui trocamos para
  # `ctrl+a` (estilo GNU screen). Ações no modo prefixo continuam com os defaults
  # (ex.: prefix+q para detach); só a tecla de entrada no modo prefixo muda.
  xdg.configFile."herdr/config.toml".text = ''
    [keys]
    prefix = "ctrl+a"
  '';
}
