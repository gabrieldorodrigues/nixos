{ ... }:
{
  # mako (daemon de notificações; iniciado no autostart do Hyprland).
  # default-timeout é em milissegundos → as notificações somem após 10s.
  xdg.configFile."mako/config".text = ''
    default-timeout=10000
  '';
}
